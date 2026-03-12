import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class ApproveRequestDialog extends StatefulWidget {
  final String userName;
  final Function(String role, String cargaHoraria) onApprove;

  const ApproveRequestDialog({
    super.key,
    required this.userName,
    required this.onApprove,
  });

  @override
  State<ApproveRequestDialog> createState() => _ApproveRequestDialogState();
}

class _ApproveRequestDialogState extends State<ApproveRequestDialog> {
  late final TextEditingController _roleController;
  late final TextEditingController _workloadController;
  String? _roleError;
  String? _workloadError;

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController();
    _workloadController = TextEditingController();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _workloadController.dispose();
    super.dispose();
  }

  void _submit() {
    final role = _roleController.text.trim();
    final workload = _workloadController.text.trim();

    var valid = true;

    if (role.isEmpty) {
      _roleError = 'Informe o cargo';
      valid = false;
    } else {
      _roleError = null;
    }

    if (workload.isEmpty) {
      _workloadError = 'Informe a carga horária';
      valid = false;
    } else {
      _workloadError = null;
    }

    if (!valid) {
      setState(() {});
      return;
    }

    Navigator.pop(context);
    widget.onApprove(role, workload);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aprovar usuário', style: AppTextStyles.h3),
                      Text(
                        widget.userName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 20),
            Text(
              'Cargo',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _roleController,
              autofocus: true,
              onChanged: (_) {
                if (_roleError != null) setState(() => _roleError = null);
              },
              decoration: InputDecoration(
                hintText: 'Ex: Funcionário, Gerente, Administrador',
                errorText: _roleError,
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: AppColors.primary, size: 20),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Carga horária diária',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _workloadController,
              keyboardType: TextInputType.text,
              onChanged: (_) {
                if (_workloadError != null) {
                  setState(() => _workloadError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Ex: 8 ou 8:30',
                errorText: _workloadError,
                prefixIcon: const Icon(Icons.schedule_rounded,
                    color: AppColors.primary, size: 20),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
