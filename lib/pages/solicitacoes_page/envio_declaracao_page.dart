import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/widgets/time_picker.dart';

class EnvioDeclaracaoPage extends StatefulWidget {
  final String? diaId;

  const EnvioDeclaracaoPage({super.key, this.diaId});

  @override
  State<EnvioDeclaracaoPage> createState() => _EnvioDeclaracaoPageState();
}

class _EnvioDeclaracaoPageState extends State<EnvioDeclaracaoPage> {
  String? _fileName;
  Uint8List? _fileBytes;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;

  final _fmtId = DateFormat('yyyy-MM-dd');

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileName = result.files.single.name;
        _fileBytes = result.files.single.bytes;
      });
    }
  }

  void _clearFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
    });
  }

  Future<void> _pickTime({required bool isInicio}) async {
    final initial = isInicio
        ? (_horaInicio ?? TimeOfDay.now())
        : (_horaFim ?? _horaInicio ?? TimeOfDay.now());
    final picked = await showTimePicker24h(context, initial);

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _horaInicio = picked;
          if (_horaFim != null) {
            final inicioMinutes = picked.hour * 60 + picked.minute;
            final fimMinutes = _horaFim!.hour * 60 + _horaFim!.minute;
            if (fimMinutes < inicioMinutes) {
              _horaFim = null;
            }
          }
        } else {
          _horaFim = picked;
        }
      });
    }
  }

  bool get _canSubmit =>
      _fileName != null &&
      _fileBytes != null &&
      _horaInicio != null &&
      _horaFim != null;

  void _submit() {
    if (!_canSubmit) return;

    final date = widget.diaId != null
        ? DateTime.tryParse(widget.diaId!)
        : DateTime.now();
    if (date == null) return;

    const justificativa = 'Consulta médica - Declaração anexada';

    context.read<JustificativaBloc>().add(
          SubmitJustificativaEvent(
            diaId: _fmtId.format(date),
            justificativa: justificativa,
            fileName: _fileName!,
            fileBytes: _fileBytes!,
            dataInicio: _formatTime(_horaInicio!),
            dataFim: _formatTime(_horaFim!),
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
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Envio de Declaração',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const _SectionLabel(label: 'Período da consulta'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Horário início',
                    value:
                        _horaInicio != null ? _formatTime(_horaInicio!) : null,
                    onTap: () => _pickTime(isInicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Horário fim',
                    value: _horaFim != null ? _formatTime(_horaFim!) : null,
                    onTap: () => _pickTime(isInicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'Declaração médica (PDF)'),
            const SizedBox(height: 12),
            _FilePickerBox(
              fileName: _fileName,
              onPick: _pickPDF,
              onClear: _clearFile,
            ),
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
                      'Enviar',
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
                'A declaração será revisada pela administração.',
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

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
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
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
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
                const Icon(Icons.access_time_rounded,
                    color: AppColors.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePickerBox extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FilePickerBox({
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderLight,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (fileName == null) ...[
              const Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Toque para selecionar o PDF',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Apenas arquivos PDF são aceitos',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arquivo selecionado',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          fileName!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
