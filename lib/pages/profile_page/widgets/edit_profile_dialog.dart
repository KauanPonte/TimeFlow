import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

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
    return AppDialogScaffold(
      title: 'Editar perfil',
      icon: Icons.person_outline,
      confirmLabel: 'Salvar',
      onConfirm: _submit,
      children: [
        AppDialogField(
          label: 'Nome',
          hintText: 'Digite seu nome',
          controller: _nameController,
          errorText: _nameError,
          icon: Icons.person_outline,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        if (widget.isAdmin) ...[
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
      ],
    );
  }
}
