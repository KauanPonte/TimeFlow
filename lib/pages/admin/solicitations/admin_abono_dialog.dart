import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/repositories/abono_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/pages/history_page/widgets/card/widgets/day_card_helpers.dart';
import 'package:intl/intl.dart';

class AdminAbonoDialog extends StatefulWidget {
  final String targetUid;
  final String diaId;
  final int workedMinutes;
  final List<Map<String, dynamic>> eventos;
  final AbonoRepository abonoRepository;
  final VoidCallback onSaved;

  const AdminAbonoDialog({
    super.key,
    required this.targetUid,
    required this.diaId,
    required this.workedMinutes,
    required this.eventos,
    required this.abonoRepository,
    required this.onSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required String targetUid,
    required String diaId,
    required int workedMinutes,
    required List<Map<String, dynamic>> eventos,
    required AbonoRepository abonoRepository,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdminAbonoDialog(
        targetUid: targetUid,
        diaId: diaId,
        workedMinutes: workedMinutes,
        eventos: eventos,
        abonoRepository: abonoRepository,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AdminAbonoDialog> createState() => _AdminAbonoDialogState();
}

class _AdminAbonoDialogState extends State<AdminAbonoDialog> {
  bool _loading = true;
  bool _saving = false;

  int _workloadMinutes = 480;
  bool _isFullDay = false;
  final _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkload();
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkload() async {
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.targetUid)
          .get();
      final wl = (userSnap.data()?['workloadMinutes'] as int?) ??
          (userSnap.data()?['cargaHorariaMinutos'] as int?) ??
          480;
      if (mounted) setState(() { _workloadMinutes = wl; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _restantMinutes =>
      (_workloadMinutes - widget.workedMinutes).clamp(0, _workloadMinutes);

  String _fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final obs = _obsController.text.trim();
      await widget.abonoRepository.adminApplyAbono(
        uid: widget.targetUid,
        diaId: widget.diaId,
        isFullDay: _isFullDay,
        observacao: obs.isNotEmpty ? obs : 'Abono aplicado pelo administrador',
      );
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        CustomSnackbar.showSuccess(context, 'Abono aplicado com sucesso.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        CustomSnackbar.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Aplicar Abono', style: AppTextStyles.h3),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Registros do dia
                if (widget.eventos.isNotEmpty) ...[
                  Text(
                    'Registros do dia',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.eventos.map((e) {
                      final tipo = (e['tipo'] ?? '').toString();
                      final at = e['at'] as DateTime?;
                      final horaStr = at != null
                          ? DateFormat('HH:mm').format(at)
                          : '--:--';
                      final color = colorForTipo(tipo);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconForTipo(tipo), size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              '${labelForTipo(tipo)} $horaStr',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                // Resumo do dia
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Meta do dia:', _fmt(_workloadMinutes)),
                      _infoRow('Já trabalhado:', _fmt(widget.workedMinutes)),
                      _infoRow('Restante:', _fmt(_restantMinutes),
                          highlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipo de abono',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _AbonoOption(
                  selected: !_isFullDay,
                  title: 'Abonar tempo restante',
                  subtitle: _restantMinutes > 0
                      ? '${_fmt(_restantMinutes)} serão creditados'
                      : 'Meta já cumprida',
                  onTap: _restantMinutes > 0
                      ? () => setState(() => _isFullDay = false)
                      : null,
                ),
                const SizedBox(height: 8),
                _AbonoOption(
                  selected: _isFullDay,
                  title: 'Abonar dia inteiro',
                  subtitle: '${_fmt(_workloadMinutes)} serão creditados',
                  onTap: () => setState(() => _isFullDay = true),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex: Abono por consulta médica',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: (_loading || _saving) ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbonoOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _AbonoOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = disabled ? AppColors.textSecondary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected && !disabled
              ? AppColors.primaryLight10
              : disabled
                  ? AppColors.bgLight
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected && !disabled
                ? AppColors.primary
                : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: disabled ? AppColors.textSecondary : color,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: disabled
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
