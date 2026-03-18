import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';

class DeleteUserDialog extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const DeleteUserDialog({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: 'Excluir Usuário',
      subtitle: 'Tem certeza que deseja excluir $userName?\nEsta ação não pode ser desfeita.',
      icon: Icons.delete,
      isDestructive: true,
      confirmLabel: 'Excluir',
      onConfirm: () {
        Navigator.pop(context);
        onConfirm();
      },
      children: const [],
    );
  }
}
