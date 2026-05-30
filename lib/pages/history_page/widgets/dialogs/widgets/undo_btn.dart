import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_palette.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class UndoBtn extends StatelessWidget {
  final VoidCallback onTap;
  const UndoBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.undo_rounded,
                size: 14, color: context.palette.textSecondary),
            const SizedBox(width: 2),
            Text(
              'Desfazer',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
