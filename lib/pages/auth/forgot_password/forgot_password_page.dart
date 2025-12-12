import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/pages/auth/forgot_password/widgets/email_input_section.dart';
import 'package:flutter_application_appdeponto/pages/auth/forgot_password/widgets/email_sent_section.dart';
import 'package:flutter_application_appdeponto/pages/auth/forgot_password/widgets/login_widgets.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            context.read<AuthBloc>().add(const AuthReset());
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          // Only listens when email is successfully sent
          return current is PasswordResetEmailSent &&
              previous is! PasswordResetEmailSent;
        },
        listener: (context, state) {
          // Email sent successfully - state already managed by BLoC
          // Errors are shown in the email field itself
        },
        buildWhen: (previous, current) {
          return current is AuthFieldsState ||
              current is PasswordResetEmailSent ||
              current is AuthInitial;
        },
        builder: (context, state) {
          final fieldsState =
              state is AuthFieldsState ? state : const AuthFieldsState();
          final isLoading = fieldsState.isLoading;
          final isEmailSent = state is PasswordResetEmailSent;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgLight,
                  AppColors.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthHeader(
                        title: isEmailSent
                            ? "Email Enviado!"
                            : "Esqueceu a senha?",
                        subtitle: isEmailSent
                            ? "Verifique sua caixa de entrada"
                            : "Insira seu email para recuperação",
                        icon: isEmailSent ? Icons.email : Icons.lock_reset,
                      ),
                      const SizedBox(height: 32),
                      if (!isEmailSent)
                        EmailInputSection(
                          emailController: emailController,
                          errorText: fieldsState.fieldErrors['email'],
                          onSendPressed: isLoading
                              ? () {}
                              : () {
                                  context.read<AuthBloc>().add(
                                        ForgotPasswordRequested(
                                          email: emailController.text.trim(),
                                        ),
                                      );
                                },
                        )
                      else
                        EmailSentSection(
                          email: emailController.text,
                          onBackToLogin: () {
                            context.read<AuthBloc>().add(const AuthReset());
                            Navigator.pop(context);
                          },
                          onResendEmail: () {
                            context.read<AuthBloc>().add(const AuthReset());
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
