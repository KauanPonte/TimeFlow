import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class ObservacaoField extends StatelessWidget {
  final TextEditingController controller;

  const ObservacaoField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Observação', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Motivo da solicitação...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
