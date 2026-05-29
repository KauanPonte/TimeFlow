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

/// Página genérica de abono com envio apenas de PDF.
/// Recebe [motivo] (gravado no Firestore), [titulo] (AppBar) e [icone].
class AbonoPdfPage extends StatefulWidget {
  final String? diaId;
  final String motivo;
  final String titulo;
  final IconData icone;
  final bool isFullDayAbono;

  const AbonoPdfPage({
    super.key,
    this.diaId,
    required this.motivo,
    required this.titulo,
    required this.icone,
    this.isFullDayAbono = false,
  });

  @override
  State<AbonoPdfPage> createState() => _AbonoPdfPageState();
}

class _AbonoPdfPageState extends State<AbonoPdfPage> {
  String? _fileName;
  Uint8List? _fileBytes;

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

  // Botão só ativa quando um PDF foi selecionado
  bool get _canSubmit => _fileName != null && _fileBytes != null;

  void _submit() {
    if (!_canSubmit) return;

    final date = widget.diaId != null
        ? DateTime.tryParse(widget.diaId!)
        : DateTime.now();
    if (date == null) return;

    // Reutiliza exatamente o mesmo evento/fluxo do resto do sistema.
    // O motivo vira o campo "justificativa" no Firestore.
    context.read<JustificativaBloc>().add(
          SubmitJustificativaEvent(
            diaId: _fmtId.format(date),
            justificativa: '${widget.motivo} - Declaração anexada',
            fileName: _fileName!,
            fileBytes: _fileBytes!,
            isFullDayAbono: widget.isFullDayAbono,
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
        backgroundColor: Colors.transparent,
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
              'Declaração (PDF)',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Caixa de upload — toque abre o file picker, ícone X remove
            GestureDetector(
              onTap: _pickPDF,
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
                child: _fileName == null ? _emptyState() : _fileSelected(),
              ),
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

  Widget _emptyState() {
    return Column(
      children: [
        const Icon(Icons.cloud_upload_outlined,
            size: 48, color: AppColors.primary),
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
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _fileSelected() {
    return Row(
      children: [
        const Icon(Icons.picture_as_pdf_outlined,
            size: 32, color: AppColors.primary),
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
                _fileName!,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _clearFile,
          icon: const Icon(Icons.close_rounded,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
