import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'widgets/profile_image_picker.dart';
import 'widgets/login_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final roleController = TextEditingController();
  File? selectedImage;
  bool _obscurePassword = true;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
  }

  @override
  void dispose() {
    _authBloc.add(
        const AuthReset(fieldNames: ['name', 'email', 'password', 'role']));
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          // Just listens for changes to RegisterSuccess or AuthError
          return (current is RegisterSuccess && previous is! RegisterSuccess) ||
              (current is AuthError && previous is! AuthError);
        },
        listener: (context, state) {
          if (state is RegisterSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/home",
              (route) => false,
              arguments: {
                "employeeName": state.userData['name'],
                "profileImageUrl": state.userData['profileImage'] ?? "",
                "employeeRole": state.userData['role'],
              },
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          return current is AuthFieldsState;
        },
        builder: (context, state) {
          final fieldsState =
              state is AuthFieldsState ? state : const AuthFieldsState();
          final isLoading = fieldsState.isLoading;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: constraints.maxHeight,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title and Subtitle
                          const AuthHeader(
                            title: "Criar Conta",
                            subtitle: "Preencha seus dados para começar",
                            icon: null,
                          ),
                          const SizedBox(height: 32),

                          // Profile Image Picker
                          ProfileImagePicker(
                            onImageSelected: (image) {
                              setState(() => selectedImage = image);
                            },
                          ),
                          const SizedBox(height: 32),

                          // Name Field
                          CustomTextField(
                            controller: nameController,
                            labelText: "Nome Completo",
                            prefixIcon: Icons.person_outline,
                            errorText: fieldsState.fieldErrors['name'],
                            isValid: fieldsState.fieldValid['name'] ?? false,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                context.read<AuthBloc>().add(
                                      NameValidationRequested(name: value),
                                    );
                              } else {
                                context.read<AuthBloc>().add(
                                      const ClearFieldError(fieldName: 'name'),
                                    );
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          CustomTextField(
                            controller: emailController,
                            labelText: "Email",
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            errorText: fieldsState.fieldErrors['email'],
                            isValid: fieldsState.fieldValid['email'] ?? false,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                context.read<AuthBloc>().add(
                                      EmailFormatValidationRequested(
                                        email: value,
                                        fieldName: 'email',
                                      ),
                                    );
                              } else {
                                context.read<AuthBloc>().add(
                                      const ClearFieldError(fieldName: 'email'),
                                    );
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Role Field
                          CustomTextField(
                            controller: roleController,
                            labelText: "Cargo/Função",
                            prefixIcon: Icons.work_outline,
                            errorText: fieldsState.fieldErrors['role'],
                            isValid: fieldsState.fieldValid['role'] ?? false,
                            onChanged: (value) {
                              if (value.trim().isEmpty) {
                                context.read<AuthBloc>().add(
                                      const ClearFieldError(fieldName: 'role'),
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
                            isValid:
                                fieldsState.fieldValid['password'] ?? false,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                context.read<AuthBloc>().add(
                                      PasswordValidationRequested(
                                        password: value,
                                        fieldName: 'password',
                                      ),
                                    );
                              } else {
                                context.read<AuthBloc>().add(
                                      const ClearFieldError(
                                          fieldName: 'password'),
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
                          const SizedBox(height: 32),

                          // Register Button
                          PrimaryButton(
                            text: isLoading ? "Criando..." : "Criar Conta",
                            onPressed: isLoading
                                ? () {}
                                : () {
                                    context.read<AuthBloc>().add(
                                          RegisterRequested(
                                            email: emailController.text.trim(),
                                            password: passwordController.text,
                                            name: nameController.text.trim(),
                                            role: roleController.text.trim(),
                                            profileImage: selectedImage,
                                          ),
                                        );
                                  },
                          ),
                          const SizedBox(height: 16),

                          // Link to Login Page
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Já tem uma conta? ",
                                style: AppTextStyles.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
                                },
                                child: Text(
                                  "Entrar",
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
          );
        },
      ),
    );
  }
}
