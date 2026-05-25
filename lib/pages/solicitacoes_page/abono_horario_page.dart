import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

/// Página de abono com apenas horário de saída + retorno, sem PDF.
/// Usada para "Aula".
class AbonoHorarioPage extends StatefulWidget {
  final String? diaId;
  final String motivo;
  final String titulo;
  final IconData icone;

  const AbonoHorarioPage({
    super.key,
    this.diaId,
    required this.motivo,
    required this.titulo,
    required this.icone,
  });

  @override
  State<AbonoHorarioPage> createState() => _AbonoHorarioPageState();
}

class _AbonoHorarioPageState extends State<AbonoHorarioPage> {
  TimeOfDay? _horaSaida;
  TimeOfDay? _horaRetorno;

  final _fmtId = DateFormat('yyyy-MM-dd');

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int? get _durationMinutes {
    if (_horaSaida == null || _horaRetorno == null) return null;
    final saida = _horaSaida!.hour * 60 + _horaSaida!.minute;
    final retorno = _horaRetorno!.hour * 60 + _horaRetorno!.minute;
    if (retorno <= saida) return null;
    return retorno - saida;
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Future<void> _pickTime({required bool isSaida}) async {
    final initial = isSaida
        ? (_horaSaida ?? TimeOfDay.now())
        : (_horaRetorno ?? _horaSaida ?? TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isSaida) {
          _horaSaida = picked;
          if (_horaRetorno != null) {
            final s = picked.hour * 60 + picked.minute;
            final r = _horaRetorno!.hour * 60 + _horaRetorno!.minute;
            if (r <= s) _horaRetorno = null;
          }
        } else {
          _horaRetorno = picked;
        }
      });
    }
  }

  bool get _canSubmit => _horaSaida != null;

  void _submit() {
    if (!_canSubmit) return;

    final date = widget.diaId != null
        ? DateTime.tryParse(widget.diaId!)
        : DateTime.now();
    if (date == null) return;

    context.read<JustificativaBloc>().add(
          SubmitJustificativaEvent(
            diaId: _fmtId.format(date),
            justificativa: widget.motivo,
            dataInicio: _formatTime(_horaSaida!),
            dataFim: _horaRetorno != null ? _formatTime(_horaRetorno!) : null,
            abonoMinutes: _durationMinutes,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JustificativaBloc, JustificativaState>(
      listener: (context, state) {
        if (state is JustificativaActionSuccess) {
          CustomSnackbar.showSuccess(context, state.message);
          if (mounted) Navigator.pop(context);
        } else if (state is JustificativaError) {
          CustomSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icone, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                widget.titulo,
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Text(
              'Período de ausência',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Informe quando saiu e, se já retornou, o horário de retorno.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Saída',
                    required: true,
                    value: _horaSaida != null ? _formatTime(_horaSaida!) : null,
                    onTap: () => _pickTime(isSaida: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'Retorno',
                    required: false,
                    value: _horaRetorno != null
                        ? _formatTime(_horaRetorno!)
                        : null,
                    onTap: () => _pickTime(isSaida: false),
                  ),
                ),
              ],
            ),
            if (_durationMinutes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Duração da ausência: ',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      _formatDuration(_durationMinutes!),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_horaRetorno == null && _horaSaida != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sem retorno informado, o abono de horas será definido pelo administrador na aprovação.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Enviar solicitação',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'A solicitação será revisada pela administração.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final bool required;
  final String? value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.required,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? AppColors.primary : AppColors.borderLight,
            width: value != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (required)
                  Text(' *',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Selecionar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  color: value != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
