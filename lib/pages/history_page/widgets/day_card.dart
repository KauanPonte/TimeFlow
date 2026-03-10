import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class DayCard extends StatelessWidget {
  final String diaId;
  final List<Map<String, dynamic>> eventos;
  final bool isAdmin;
  final bool isFuture;
  final void Function(Map<String, dynamic> evento)? onEditEvento;
  final void Function(Map<String, dynamic> evento)? onDeleteEvento;
  final VoidCallback? onAddEvento;

  const DayCard({
    super.key,
    required this.diaId,
    required this.eventos,
    this.isAdmin = false,
    this.isFuture = false,
    this.onEditEvento,
    this.onDeleteEvento,
    this.onAddEvento,
  });

  String _formatDate(String diaId) {
    try {
      final date = DateTime.parse(diaId);
      final formatter = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR');
      final formatted = formatter.format(date);
      return formatted[0].toUpperCase() + formatted.substring(1);
    } catch (_) {
      return diaId;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Icons.login;
      case 'pausa':
        return Icons.coffee;
      case 'retorno':
        return Icons.replay;
      case 'saida':
        return Icons.logout;
      default:
        return Icons.access_time;
    }
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return AppColors.success;
      case 'pausa':
        return const Color(0xFF3DB2FF);
      case 'retorno':
        return AppColors.warning;
      case 'saida':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _labelForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Entrada';
      case 'pausa':
        return 'Pausa';
      case 'retorno':
        return 'Retorno';
      case 'saida':
        return 'Saída';
      default:
        return tipo;
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return diaId == today;
  }

  /// Retorna true se o dia (não sendo hoje) tiver entrada sem saída
  /// ou pausa sem retorno — detecta corretamente múltiplos ciclos.
  bool get _isIncomplete {
    if (_isToday) return false;
    if (isFuture) return false;
    if (eventos.isEmpty) return false;

    // Ordena por horário e verifica o último estado da sequência
    final sorted = List<Map<String, dynamic>>.from(eventos)
      ..sort((a, b) {
        final atA = a['at'] as DateTime?;
        final atB = b['at'] as DateTime?;
        if (atA == null || atB == null) return 0;
        return atA.compareTo(atB);
      });

    final lastTipo = (sorted.last['tipo'] ?? '').toString();
    // Completo apenas se o último evento foi 'saida'
    return lastTipo != 'saida';
  }

  String get _motivoIncompleto {
    final sorted = List<Map<String, dynamic>>.from(eventos)
      ..sort((a, b) {
        final atA = a['at'] as DateTime?;
        final atB = b['at'] as DateTime?;
        if (atA == null || atB == null) return 0;
        return atA.compareTo(atB);
      });

    final lastTipo = (sorted.last['tipo'] ?? '').toString();
    switch (lastTipo) {
      case 'pausa':
        return 'Sem retorno da pausa';
      case 'entrada':
      case 'retorno':
        return 'Sem saída';
      default:
        return 'Registro incompleto';
    }
  }

  String _computeWorked() {
    DateTime? openWork;
    Duration total = Duration.zero;

    for (final ev in eventos) {
      final tipo = (ev['tipo'] ?? '').toString();
      final at = ev['at'] as DateTime?;
      if (at == null) continue;

      if (tipo == 'entrada' || tipo == 'retorno') {
        openWork ??= at;
      } else if (tipo == 'pausa' || tipo == 'saida') {
        if (openWork != null && at.isAfter(openWork)) {
          total += at.difference(openWork);
        }
        openWork = null;
      }
    }

    final h = total.inHours;
    final m = total.inMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    if (isFuture) return _buildEmptyCard(context, disabled: true);
    if (eventos.isEmpty) return _buildEmptyCard(context);
    return _buildFilledCard(context);
  }

  Widget _buildEmptyCard(BuildContext context, {bool disabled = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: disabled ? AppColors.bgLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled
              ? AppColors.borderLight.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.borderLight.withValues(alpha: 0.3)
                : AppColors.borderLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_today,
            color: disabled ? AppColors.borderLight : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          _formatDate(diaId),
          style: AppTextStyles.bodyMedium.copyWith(
            color: disabled ? AppColors.borderLight : AppColors.textSecondary,
          ),
        ),
        subtitle: disabled
            ? null
            : Text(
                'Sem registros',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
        trailing: (!disabled && isAdmin)
            ? IconButton(
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
                padding: EdgeInsets.zero,
                onPressed: onAddEvento,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                tooltip: 'Adicionar ponto',
              )
            : null,
      ),
    );
  }

  Widget _buildFilledCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isIncomplete ? AppColors.warningLight8 : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _isIncomplete ? AppColors.warningLight30 : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isIncomplete
                  ? AppColors.warningLight20
                  : AppColors.primaryLight10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isIncomplete
                  ? Icons.warning_amber_rounded
                  : Icons.calendar_today,
              color: _isIncomplete ? AppColors.warning : AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            _formatDate(diaId),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _computeWorked(),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${eventos.length} registro${eventos.length != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              if (_isIncomplete) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight20,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.warningLight30, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 11, color: AppColors.warning),
                      const SizedBox(width: 3),
                      Text(
                        'Incompleto',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...eventos.map((ev) {
              final tipo = (ev['tipo'] ?? '').toString();
              final at = ev['at'] as DateTime?;
              final color = _colorForTipo(tipo);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_iconForTipo(tipo), size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelForTipo(tipo),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatTime(at),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      IconButton(
                        onPressed: () => onEditEvento?.call(ev),
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.primary),
                        tooltip: 'Editar',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onDeleteEvento?.call(ev),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        tooltip: 'Remover',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (_isIncomplete) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight10,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.warningLight30, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _motivoIncompleto,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: onAddEvento,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryLight10.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Adicionar ponto',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
