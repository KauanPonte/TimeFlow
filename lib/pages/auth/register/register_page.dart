import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
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
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title and Subtitle
                    const AuthHeader(
                      title: "Criar Conta",
                      subtitle: "Preencha seus dados para começar",
                      icon: null,
                    ),
                    const SizedBox(height: 30),

                    // Profile Image Picker
                    ProfileImagePicker(
                      onImageSelected: (image) {
                        setState(() => selectedImage = image);
                      },
                    ),
                    const SizedBox(height: 30),

                    // Name Field
                    CustomTextField(
                      controller: nameController,
                      labelText: "Nome Completo",
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    CustomTextField(
                      controller: emailController,
                      labelText: "Email",
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Role Field
                    CustomTextField(
                      controller: roleController,
                      labelText: "Cargo/Função",
                      prefixIcon: Icons.work_outline,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      controller: passwordController,
                      labelText: "Senha",
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
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
                    const SizedBox(height: 30),

                    // Register Button
                    PrimaryButton(
                      text: "Criar Conta",
                      onPressed: () {
                        // TODO: Implement registration logic
                        Navigator.pushNamed(
                          context,
                          "/home",
                          arguments: {
                            "employeeName": nameController.text,
                            "profileImageUrl": selectedImage?.path ?? "",
                            "employeeRole": roleController.text,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Link to Login Page
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Já tem uma conta? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            "Entrar",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
