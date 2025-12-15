import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'widgets/auth_header.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
  }

  @override
  void dispose() {
    _authBloc.add(const AuthReset(fieldNames: ['email', 'password']));
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          // Only listens for changes to LoginSuccess or AuthError
          return (current is LoginSuccess && previous is! LoginSuccess) ||
              (current is AuthError && previous is! AuthError);
        },
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/home",
              (route) => false,
              arguments: {
                "employeeName": state.userData['name'],
                "profileImageUrl": state.userData['profileImage'] ?? "",
                "employeeRole": state.userData['role'] ?? "",
              },
            );
          } else if (state is AuthError) {
            CustomSnackbar.showError(context, state.message);
          }
        },
        buildWhen: (previous, current) {
          // Only rebuilds for AuthFieldsState
          return current is AuthFieldsState;
        },
        builder: (context, state) {
          final fieldsState =
              state is AuthFieldsState ? state : const AuthFieldsState();
          final isLoading = fieldsState.isLoading;

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
                      const AuthHeader(
                        title: "Bem-vindo de volta!",
                        subtitle: "Entre com suas credenciais",
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      CustomTextField(
                        controller: emailController,
                        labelText: "Email",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: fieldsState.fieldErrors['email'],
                        isValid: fieldsState.fieldValid['email'] ?? false,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            context.read<AuthBloc>().add(
                                  const ClearFieldError(fieldName: 'email'),
                                );
                          } else {
                            context.read<AuthBloc>().add(
                                  EmailFormatValidationRequested(
                                    email: value,
                                    fieldName: 'email',
                                  ),
                                );
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        controller: passwordController,
                        labelText: "Senha",
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        errorText: fieldsState.fieldErrors['password'],
                        isValid: fieldsState.fieldValid['password'] ?? false,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            context.read<AuthBloc>().add(
                                  const ClearFieldError(fieldName: 'password'),
                                );
                          } else {
                            context.read<AuthBloc>().add(
                                  PasswordValidationRequested(
                                    password: value,
                                    fieldName: 'password',
                                  ),
                                );
                          }
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            "Esqueceu a senha?",
                            style: AppTextStyles.link,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      PrimaryButton(
                        text: isLoading ? "Entrando..." : "Entrar",
                        onPressed: isLoading
                            ? () {}
                            : () {
                                context.read<AuthBloc>().add(
                                      LoginRequested(
                                        email: emailController.text.trim(),
                                        password: passwordController.text,
                                      ),
                                    );
                              },
                      ),
                      const SizedBox(height: 16),

                      // Link to Register Page
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Não tem uma conta? ",
                            style: AppTextStyles.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, '/register');
                            },
                            child: Text(
                              "Cadastre-se",
                              style: AppTextStyles.link,
                            ),
                          ),
                        ],
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
