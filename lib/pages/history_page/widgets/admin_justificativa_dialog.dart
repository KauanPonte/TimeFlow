import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/repositories/justificativa_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class AdminJustificativaDialog {
  AdminJustificativaDialog._();

  /// Exibe o diálogo para o admin definir/editar justificativa diretamente.
  ///
  /// [onSaved] é chamado após salvar com sucesso para recarregar as justificativas.
  static void show({
    required BuildContext context,
    required String targetUid,
    required String diaId,
    String? existing,
    required JustificativaRepository justificativaRepository,
    required VoidCallback onSaved,
  }) {
    final controller = TextEditingController(text: existing ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.assignment_late_outlined,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(existing != null
                  ? 'Editar Justificativa'
                  : 'Adicionar Justificativa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A justificativa será salva diretamente sem necessidade de aprovação.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 300,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Descreva a justificativa...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogCtx);
                try {
                  await justificativaRepository.adminSetJustificativa(
                    uid: targetUid,
                    diaId: diaId,
                    justificativa: text,
                  );
                  onSaved();
                  if (context.mounted) {
                    CustomSnackbar.showSuccess(
                        context, 'Justificativa salva.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    CustomSnackbar.showError(context,
                        e.toString().replaceAll('Exception: ', ''));
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
