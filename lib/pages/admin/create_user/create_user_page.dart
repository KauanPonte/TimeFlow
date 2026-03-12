import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/create_user/create_user_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/create_user/create_user_event.dart';
import 'package:flutter_application_appdeponto/blocs/create_user/create_user_state.dart';
import 'package:flutter_application_appdeponto/pages/auth/login/widgets/custom_text_field.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'widgets/create_user_header.dart';
import 'widgets/create_user_action_buttons.dart';

class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateUserBloc(),
      child: const CreateUserView(),
    );
  }
}

class CreateUserView extends StatefulWidget {
  const CreateUserView({super.key});

  @override
  State<CreateUserView> createState() => _CreateUserViewState();
}

class _CreateUserViewState extends State<CreateUserView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _cargaHorariaController = TextEditingController();
  final _roleController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cargaHorariaController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _submitForm() {
    context.read<CreateUserBloc>().add(
          CreateUserSubmitEvent(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            cargaHoraria: _cargaHorariaController.text,
            role: _roleController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateUserBloc, CreateUserState>(
      listener: (context, state) {
        if (state is CreateUserSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.userName} cadastrado com sucesso!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is CreateUserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CreateUserLoading;
        final formState = state is CreateUserFormState ? state : null;
        return Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cadastrar Usuário',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  const CreateUserHeader(),
                  const SizedBox(height: 24),

                  // Form Fields
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nome Completo',
                    prefixIcon: Icons.person_outline,
                    errorText: formState?.nameError,
                    isValid: formState?.nameValid ?? false,
                    onChanged: (value) {
                      context.read<CreateUserBloc>().add(
                            ValidateFieldEvent(fieldName: 'name', value: value),
                          );
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    errorText: formState?.emailError,
                    isValid: formState?.emailValid ?? false,
                    onChanged: (value) {
                      context.read<CreateUserBloc>().add(
                            ValidateFieldEvent(
                                fieldName: 'email', value: value),
                          );
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Senha',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    errorText: formState?.passwordError,
                    isValid: formState?.passwordValid ?? false,
                    onChanged: (value) {
                      context.read<CreateUserBloc>().add(
                            ValidateFieldEvent(
                                fieldName: 'password', value: value),
                          );
                      // Revalidar confirmação de senha quando a senha mudar
                      if (_confirmPasswordController.text.isNotEmpty) {
                        context.read<CreateUserBloc>().add(
                              ValidateConfirmPasswordEvent(
                                password: value,
                                confirmPassword:
                                    _confirmPasswordController.text,
                              ),
                            );
                      }
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirmar Senha',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    errorText: formState?.confirmPasswordError,
                    isValid: formState?.confirmPasswordValid ?? false,
                    onChanged: (value) {
                      context.read<CreateUserBloc>().add(
                            ValidateConfirmPasswordEvent(
                              password: _passwordController.text,
                              confirmPassword: value,
                            ),
                          );
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _cargaHorariaController,
                    labelText: 'Carga Horária',
                    prefixIcon: Icons.access_time_outlined,
                    errorText: formState?.cargaHorariaError,
                    isValid: formState?.cargaHorariaValid ?? false,
                    onChanged: (value) {
                       context.read<CreateUserBloc>().add(
                         ValidateFieldEvent(fieldName: 'cargaHoraria', value: value),
                       );
                     },
                  ),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Ex: 8 ou 8:30 ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),


                  CustomTextField(
                    controller: _roleController,
                    labelText: 'Cargo',
                    prefixIcon: Icons.work_outline,
                    errorText: formState?.roleError,
                    isValid: formState?.roleValid ?? false,
                    onChanged: (value) {
                      context.read<CreateUserBloc>().add(
                            ValidateFieldEvent(fieldName: 'role', value: value),
                          );
                    },
                  ),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Ex: Funcionário, Gerente, Administrador',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  CreateUserActionButtons(
                    isLoading: isLoading,
                    onCancel: () => Navigator.pop(context),
                    onSubmit: _submitForm,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
