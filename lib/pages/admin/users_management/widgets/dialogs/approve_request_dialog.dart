import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

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
    return AppDialogScaffold(
      title: 'Aprovar usuário',
      subtitle: widget.userName,
      icon: Icons.check_circle,
      confirmLabel: 'Aprovar',
      onConfirm: _submit,
      children: [
        AppDialogField(
          label: 'Cargo',
          hintText: 'Ex: Funcionário, Gerente, Administrador',
          controller: _roleController,
          errorText: _roleError,
          icon: Icons.badge_outlined,
          autofocus: true,
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
