import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

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
    return AppDialogScaffold(
      title: 'Editar usuário',
      subtitle: widget.userName,
      icon: Icons.manage_accounts_rounded,
      confirmLabel: 'Salvar',
      onConfirm: _submit,
      children: [
        AppDialogField(
          label: 'Cargo',
          hintText: 'Ex: Funcionário, Gerente, Administrador',
          controller: _roleController,
          errorText: _roleError,
          icon: Icons.badge_outlined,
          onChanged: (_) {
            if (_roleError != null) setState(() => _roleError = null);
          },
        ),
        const SizedBox(height: 16),
        AppDialogField(
          label: 'Carga horária diária',
          hintText: 'Ex: 8 ou 8:30',
          controller: _workloadController,
          errorText: _workloadError,
          icon: Icons.schedule_rounded,
          onChanged: (_) {
            if (_workloadError != null) {
              setState(() => _workloadError = null);
            }
          },
        ),
      ],
    );
  }
}
