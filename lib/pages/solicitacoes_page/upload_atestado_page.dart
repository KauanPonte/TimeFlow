import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class UploadAtestadoPage extends StatefulWidget {
  const UploadAtestadoPage({super.key});

  @override
  State<UploadAtestadoPage> createState() => _UploadAtestadoPageState();
}

class _UploadAtestadoPageState extends State<UploadAtestadoPage> {
  String? _fileName;
  Uint8List? _fileBytes;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final _fmt = DateFormat('dd/MM/yyyy');
  final _fmtId = DateFormat('yyyy-MM-dd');

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

  Future<void> _pickDate({required bool isInicio}) async {
    final initial = isInicio ? (_dataInicio ?? DateTime.now()) : (_dataFim ?? _dataInicio ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
          // Se dataFim for antes de dataInicio, reseta
          if (_dataFim != null && _dataFim!.isBefore(picked)) {
            _dataFim = null;
          }
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  bool get _canSubmit =>
      _fileName != null &&
      _fileBytes != null &&
      _dataInicio != null &&
      _dataFim != null;

  void _submit() {
    if (!_canSubmit) return;
    context.read<AtestadoBloc>().add(
          SubmitAtestadoEvent(
            dataInicio: _fmtId.format(_dataInicio!),
            dataFim: _fmtId.format(_dataFim!),
            fileName: _fileName!,
            fileBytes: _fileBytes!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AtestadoBloc, AtestadoState>(
      listener: (context, state) {
        if (state is AtestadoActionSuccess) {
          CustomSnackbar.showSuccess(context, state.message);
          Navigator.pop(context);
        } else if (state is AtestadoError) {
          CustomSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: const Text('Enviar Atestado'),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Período
            const _SectionLabel(label: 'Período do atestado'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Data início',
                    value: _dataInicio != null ? _fmt.format(_dataInicio!) : null,
                    onTap: () => _pickDate(isInicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Data fim',
                    value: _dataFim != null ? _fmt.format(_dataFim!) : null,
                    onTap: () => _pickDate(isInicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // PDF
            const _SectionLabel(label: 'Arquivo PDF'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _fileName == null ? _pickPDF : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fileName ?? 'Selecionar arquivo PDF',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _fileName == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _fileName != null
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    color: AppColors.error, size: 20),
                                onPressed: _clearFile,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            : const Icon(Icons.attach_file,
                                color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirmar Envio',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
