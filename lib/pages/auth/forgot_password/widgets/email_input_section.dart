import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'login_widgets.dart';

class EmailInputSection extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSendPressed;
  final String? errorText;

  const EmailInputSection({
    super.key,
    required this.emailController,
    required this.onSendPressed,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        CustomTextField(
          controller: emailController,
          labelText: "Email",
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: errorText,
        ),
        const SizedBox(height: 16),

        // Informative Text
        Text(
          "Enviaremos um link de recuperação para o email cadastrado.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Send Button
        PrimaryButton(
          text: "Enviar Link",
          onPressed: onSendPressed,
        ),
      ],
    );
  }
}
