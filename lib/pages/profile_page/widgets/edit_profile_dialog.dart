import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentName;
  final int? currentWorkloadMinutes;
  final bool isAdmin;
  final void Function(String name, int? workloadMinutes) onSave;

  const EditProfileDialog({
    super.key,
    required this.currentName,
    required this.currentWorkloadMinutes,
    required this.isAdmin,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _workloadController;
  String? _nameError;
  String? _workloadError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _workloadController = TextEditingController(
      text: _formatWorkload(widget.currentWorkloadMinutes),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final name = _nameController.text.trim();
    var valid = true;

    if (name.isEmpty) {
      _nameError = 'Informe o nome';
      valid = false;
    } else {
      _nameError = null;
    }

    int? workloadMinutes;
    if (widget.isAdmin) {
      workloadMinutes = _parseWorkload(_workloadController.text);
      if (workloadMinutes == null) {
        _workloadError = 'Use o formato 8 ou 8:30';
        valid = false;
      } else {
        _workloadError = null;
      }
    }

    if (!valid) {
      setState(() {});
      return;
    }

    Navigator.pop(context);
    widget.onSave(name, widget.isAdmin ? workloadMinutes : null);
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
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Editar perfil', style: AppTextStyles.h3),
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
              'Nome',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                hintText: 'Digite seu nome',
                errorText: _nameError,
                prefixIcon: const Icon(Icons.person_outline,
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
            if (widget.isAdmin) ...[
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
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
            ],
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
