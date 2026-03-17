import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

class RejectRequestDialog extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const RejectRequestDialog({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: 'Rejeitar Solicitação',
      subtitle: 'Tem certeza que deseja rejeitar a solicitação de $userName?\nEsta ação não pode ser desfeita.',
      icon: Icons.close,
      isDestructive: true,
      confirmLabel: 'Rejeitar',
      onConfirm: () {
        onConfirm();
      },
      children: const [],
    );
  }
}
