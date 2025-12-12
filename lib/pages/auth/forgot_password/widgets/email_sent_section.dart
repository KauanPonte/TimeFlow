import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'login_widgets.dart';

class EmailSentSection extends StatelessWidget {
  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onResendEmail;

  const EmailSentSection({
    super.key,
    required this.email,
    required this.onBackToLogin,
    required this.onResendEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Um email com instruções para redefinir sua senha foi enviado para:",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),

        Text(
          email,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // Back to Login Button
        PrimaryButton(
          text: "Voltar ao Login",
          onPressed: onBackToLogin,
        ),
        const SizedBox(height: 16),

        // Link to Resend Email
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: onResendEmail,
            child: Text(
              "Não recebeu? Reenviar email",
              style: AppTextStyles.link,
            ),
          ),
        ),
      ],
    );
  }
}
