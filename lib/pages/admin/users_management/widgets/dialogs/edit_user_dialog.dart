import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class EditUserDialog extends StatefulWidget {
  final String userName;
  final String currentRole;
  final int? currentWorkloadMinutes;

  /// Chamado ao salvar. Recebe (novoRole, workloadMinutes).
  final void Function(String role, int workloadMinutes) onSave;

  const EditUserDialog({
    super.key,
    required this.userName,
    required this.currentRole,
    required this.currentWorkloadMinutes,
    required this.onSave,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _roleController;
  late final TextEditingController _workloadController;
  String? _roleError;
  String? _workloadError;

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.currentRole);
    _workloadController = TextEditingController(
      text: _formatWorkload(widget.currentWorkloadMinutes),
    );
  }

  @override
  void dispose() {
    _roleController.dispose();
    _workloadController.dispose();
    super.dispose();
  }

  String _formatWorkload(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h' : '$h:${m.toString().padLeft(2, '0')}';
  }

  int? _parseWorkload(String input) {
    input = input.trim();
    if (input.isEmpty) return null;

    if (input.contains(':')) {
      final parts = input.split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null || m < 0 || m >= 60 || h < 0) return null;
      return h * 60 + m;
    }

    final h = int.tryParse(input);
    if (h == null || h < 0) return null;
    return h * 60;
  }

  void _submit() {
    bool valid = true;

    final role = _roleController.text.trim();
    if (role.isEmpty) {
      setState(() => _roleError = 'Informe o cargo');
      valid = false;
    } else {
      setState(() => _roleError = null);
    }

    final workloadMinutes = _parseWorkload(_workloadController.text);
    if (workloadMinutes == null) {
      setState(() => _workloadError = 'Use o formato 8 ou 8:30');
      valid = false;
    } else {
      setState(() => _workloadError = null);
    }

    if (!valid) return;

    Navigator.pop(context);
    widget.onSave(role, workloadMinutes!);
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Editar usuário', style: AppTextStyles.h3),
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

            // Campo: Cargo
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

            // Campo: Carga horária
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

            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Salvar'),
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
