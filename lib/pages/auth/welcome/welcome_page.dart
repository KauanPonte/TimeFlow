import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'widgets/app_logo.dart';
import 'widgets/auth_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(),
                const SizedBox(height: 48),
                Column(
                  children: [
                    AuthButton(
                      text: 'Criar Conta',
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      text: 'Entrar',
                      isPrimary: false,
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
