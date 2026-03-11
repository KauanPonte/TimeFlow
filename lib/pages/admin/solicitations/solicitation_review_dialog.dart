import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/services/ponto_validator.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'widgets/review_dialog_helpers.dart';
import 'widgets/review_current_events.dart';
import 'widgets/review_item_row.dart';

/// Dialog de revisão para o admin processar uma solicitação.
/// Mostra antes/depois de cada item e permite aceitar ou rejeitar cada um,
/// com cascata de rejeição automática.
class SolicitationReviewDialog extends StatefulWidget {
  final SolicitationModel solicitation;

  /// Eventos reais atuais do dia (para comparação antes/depois).
  final List<Map<String, dynamic>> eventosAtuais;

  const SolicitationReviewDialog({
    super.key,
    required this.solicitation,
    required this.eventosAtuais,
  });

  @override
  State<SolicitationReviewDialog> createState() =>
      _SolicitationReviewDialogState();
}

class _SolicitationReviewDialogState extends State<SolicitationReviewDialog> {
  late List<SolicitationItemStatus> _itemStatuses;

  /// Índices rejeitados manualmente pelo admin (não por cascata automática).
  final Set<int> _manuallyRejected = {};
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemStatuses = List.filled(
      widget.solicitation.items.length,
      SolicitationItemStatus.accepted,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _toggleItem(int index) {
    setState(() {
      if (_manuallyRejected.contains(index)) {
        // Era manualmente rejeitado → desfaz rejeição manual
        _manuallyRejected.remove(index);
      } else if (_itemStatuses[index] == SolicitationItemStatus.accepted) {
        // Está aceito → rejeitar manualmente
        _manuallyRejected.add(index);
      }
      // Se cascata-rejeitado (not manual) → ignora tap; usuário deve aceitar o item anterior
      _applyCascade();
    });
  }

  /// Constrói os status a partir das rejeições manuais e propaga em cascata
  /// por ordem de horário. Em seguida valida o estado resultante contra os
  /// eventos reais do dia e rejeita itens adicionais se a sequência for inválida.
  void _applyCascade() {
    final items = widget.solicitation.items;
    final indices = List<int>.generate(items.length, (i) => i);
    indices.sort((a, b) => items[a].horario.compareTo(items[b].horario));

    // Passo 1 — cascata por ordem de tempo a partir das rejeições manuais.
    bool foundRejection = false;
    for (final i in indices) {
      if (_manuallyRejected.contains(i) || foundRejection) {
        _itemStatuses[i] = SolicitationItemStatus.rejected;
        foundRejection = true;
      } else {
        _itemStatuses[i] = SolicitationItemStatus.accepted;
      }
    }

    // Passo 2 — valida o estado resultante contra os eventos reais do dia.
    // Rejeita itens (do mais tardio para o mais cedo) até ficar válido.
    bool changed = true;
    while (changed) {
      changed = false;
      final virtualEvents = _buildVirtualState();
      final error = PontoValidator.validarSequenciaCompleta(virtualEvents);
      if (error == null) break; // Válido!

      // Rejeita o item aceito mais tardio (excluindo os manualmente rejeitados).
      int latestIdx = -1;
      DateTime? latestTime;
      for (int i = 0; i < items.length; i++) {
        if (_itemStatuses[i] != SolicitationItemStatus.accepted) continue;
        final t = items[i].horario;
        if (latestTime == null || t.isAfter(latestTime)) {
          latestTime = t;
          latestIdx = i;
        }
      }
      if (latestIdx == -1) break;
      _itemStatuses[latestIdx] = SolicitationItemStatus.rejected;
      changed = true;
    }
  }

  /// Simula o estado final do dia: eventos reais + itens aceitos aplicados.
  List<Map<String, dynamic>> _buildVirtualState() {
    final items = widget.solicitation.items;
    // Base: apenas eventos reais (não pendentes)
    final events = widget.eventosAtuais
        .where((e) => e['pending'] != true)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 1. Deletes
    for (int i = 0; i < items.length; i++) {
      if (_itemStatuses[i] != SolicitationItemStatus.accepted) continue;
      final item = items[i];
      if (item.action == SolicitationAction.delete && item.eventoId != null) {
        events.removeWhere((e) => e['id'] == item.eventoId);
      }
    }
    // 2. Edições
    for (int i = 0; i < items.length; i++) {
      if (_itemStatuses[i] != SolicitationItemStatus.accepted) continue;
      final item = items[i];
      if (item.action == SolicitationAction.edit && item.eventoId != null) {
        final idx = events.indexWhere((e) => e['id'] == item.eventoId);
        if (idx >= 0) {
          events[idx] = {
            'id': item.eventoId,
            'tipo': item.tipo,
            'at': item.horario,
          };
        }
      }
    }
    // 3. Adições
    for (int i = 0; i < items.length; i++) {
      if (_itemStatuses[i] != SolicitationItemStatus.accepted) continue;
      final item = items[i];
      if (item.action == SolicitationAction.add) {
        events.add({'tipo': item.tipo, 'at': item.horario});
      }
    }
    return events;
  }

  /// Retorna true se o item foi rejeitado por cascata (não manualmente).
  bool _isCascadeRejected(int index) =>
      _itemStatuses[index] == SolicitationItemStatus.rejected &&
      !_manuallyRejected.contains(index);

  void _acceptAll() {
    setState(() {
      _manuallyRejected.clear();
      for (int i = 0; i < _itemStatuses.length; i++) {
        _itemStatuses[i] = SolicitationItemStatus.accepted;
      }
    });
  }

  void _rejectAll() {
    setState(() {
      _manuallyRejected.addAll(List.generate(_itemStatuses.length, (i) => i));
      for (int i = 0; i < _itemStatuses.length; i++) {
        _itemStatuses[i] = SolicitationItemStatus.rejected;
      }
    });
  }

  void _submit() {
    Navigator.pop(context, {
      'itemStatuses': _itemStatuses,
      'reason': _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final sol = widget.solicitation;
    final date = DateTime.tryParse(sol.diaId);
    final dateStr = date != null
        ? DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(date)
        : sol.diaId;
    final formattedDate = dateStr.isNotEmpty
        ? dateStr[0].toUpperCase() + dateStr.substring(1)
        : dateStr;

    final acceptedCount =
        _itemStatuses.where((s) => s == SolicitationItemStatus.accepted).length;
    final rejectedCount =
        _itemStatuses.where((s) => s == SolicitationItemStatus.rejected).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review_rounded,
                        color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Revisar Solicitação',
                            style: AppTextStyles.h3),
                        Text(
                          sol.employeeName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(formattedDate,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),

              if (sol.reason != null && sol.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sol.reason!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Registros atuais do dia (eventos já cadastrados)
              ReviewCurrentEvents(eventosAtuais: widget.eventosAtuais),

              // Ações rápidas
              Row(
                children: [
                  QuickActionChip(
                    label: 'Aceitar todos',
                    color: AppColors.success,
                    onTap: _acceptAll,
                  ),
                  const SizedBox(width: 8),
                  QuickActionChip(
                    label: 'Rejeitar todos',
                    color: AppColors.error,
                    onTap: _rejectAll,
                  ),
                  const Spacer(),
                  Text(
                    '$acceptedCount aceito(s), $rejectedCount rejeitado(s)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Lista de itens
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sol.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return ReviewItemRow(
                      item: sol.items[index],
                      status: _itemStatuses[index],
                      isCascadeRejected: _isCascadeRejected(index),
                      onTap: () => _toggleItem(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Observação do admin
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Observação do admin (opcional)',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: AppTextStyles.bodySmall,
              ),

              const SizedBox(height: 16),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Text(
                        'Voltar',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
