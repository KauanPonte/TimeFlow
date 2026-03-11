import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class UploadAtestadoPage extends StatefulWidget {
  const UploadAtestadoPage({super.key});

  @override
  State<UploadAtestadoPage> createState() => _UploadAtestadoPageState();
}

class _UploadAtestadoPageState extends State<UploadAtestadoPage> {
  String? _fileName;

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
    }
  }

  // Função para limpar o arquivo selecionado
  void _clearFile() {
    setState(() {
      _fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Anexar PDF'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Caixinha para selecionar arquivo
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
                  onTap: _fileName == null
                      ? _pickPDF
                      : null, // Só permite selecionar se estiver vazio
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fileName ?? 'Selecionar arquivo',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _fileName == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Ícone muda entre 'X' (para remover) e 'Attach' (para selecionar)
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
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _fileName == null ? null : () {/* Lógica de Envio */},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Confirmar Envio',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
