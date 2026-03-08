import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class PunchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PunchButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.fingerprint, size: 22),
        label: const Text(
          'BATER PONTO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: AppColors.primaryLight30,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
