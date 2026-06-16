import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/create_user/create_user_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/create_user/create_user_event.dart';
import 'package:flutter_application_appdeponto/blocs/create_user/create_user_state.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
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
      create: (context) => CreateUserBloc(
        globalLoading: context.read<GlobalLoadingCubit>(),
      ),
      child: const CreateUserView(),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 2),
          confirmText: 'Confirmar',
          cancelText: 'Cancelar',
        );
        if (picked != null) onDateSelected(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(date),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
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
  final List<TextEditingController> _projectControllers = [
    TextEditingController(),
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isAdmin = false;
  String _contractType = '';
  String _projectType = '';
  String _selectedBolsistaHour = '4';
  final List<String> _selectedWorkDays = [];
  DateTime _startDate = DateTime.now();

  static const List<Map<String, String>> _weekDayOptions = [
    {'label': 'D', 'value': 'Dom'},
    {'label': 'S', 'value': 'Seg'},
    {'label': 'T', 'value': 'Ter'},
    {'label': 'Q', 'value': 'Qua'},
    {'label': 'Q', 'value': 'Qui'},
    {'label': 'S', 'value': 'Sex'},
    {'label': 'S', 'value': 'Sab'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cargaHorariaController.dispose();
    _roleController.dispose();
    for (final c in _projectControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setContractType(String type) {
    setState(() {
      _contractType = type;
      if (type == 'CLT') {
        _selectedBolsistaHour = '8';
        _cargaHorariaController.text = '8';
        _selectedWorkDays.clear();
        _projectType = '';
        _projectControllers
          ..forEach((c) => c.dispose())
          ..clear()
          ..add(TextEditingController());
      } else if (type == 'Bolsista') {
        _selectedBolsistaHour = '4';
        _cargaHorariaController.text = '4';
      } else if (type == 'Voluntário') {
        _cargaHorariaController.text = '0';
        _selectedWorkDays.clear();
        _selectedBolsistaHour = '4';
      }
    });
    context.read<CreateUserBloc>().add(
          ValidateFieldEvent(fieldName: 'contractType', value: type),
        );
    if (_contractType == 'Bolsista') {
      _validateSelectedWorkDays();
    }
  }

  void _setBolsistaHour(String hours) {
    setState(() {
      _selectedBolsistaHour = hours;
      _cargaHorariaController.text = hours;
    });
  }

  void _toggleWorkDay(String day) {
    setState(() {
      if (_selectedWorkDays.contains(day)) {
        _selectedWorkDays.remove(day);
      } else {
        _selectedWorkDays.add(day);
      }
    });
    _validateSelectedWorkDays();
  }

  void _validateSelectedWorkDays() {
    final value = _selectedWorkDays.join(',');
    context.read<CreateUserBloc>().add(
          ValidateFieldEvent(fieldName: 'workDays', value: value),
        );
  }

  String _getSelectedSchedule() {
    if (_selectedWorkDays.isEmpty) return '';

    final orderedDays = _weekDayOptions
        .where((option) => _selectedWorkDays.contains(option['value']))
        .map((option) => option['value']!)
        .toList();

    if (orderedDays.isEmpty) return '';
    return 'A cada ${orderedDays.join(', ')}';
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
            contractType: _contractType,
            workDays: List.unmodifiable(_selectedWorkDays),
            projectType: _projectType,
            projects: _projectControllers.map((c) => c.text).toList(),
            startDate: _startDate,
            isAdmin: _isAdmin,
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface),
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
                    color: Theme.of(context).colorScheme.onSurface,
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
                  if (_contractType != 'Voluntário') ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _cargaHorariaController,
                      labelText: 'Carga Horária',
                      prefixIcon: Icons.access_time_outlined,
                      errorText: formState?.cargaHorariaError,
                      isValid: formState?.cargaHorariaValid ?? false,
                      readOnly: _contractType.isNotEmpty,
                      onChanged: _contractType.isEmpty
                          ? (value) {
                              context.read<CreateUserBloc>().add(
                                    ValidateFieldEvent(
                                        fieldName: 'cargaHoraria',
                                        value: value),
                                  );
                            }
                          : null,
                    ),
                  ],
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
                  const SizedBox(height: 16),

                  _DatePickerField(
                    label: 'Data de início',
                    date: _startDate,
                    onDateSelected: (d) => setState(() => _startDate = d),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Nível de Acesso',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_isAdmin
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            side: BorderSide.none,
                          ),
                          onPressed: () => setState(() => _isAdmin = false),
                          child: Text(
                            'Usuário',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight:
                                  !_isAdmin ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isAdmin
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            side: BorderSide.none,
                          ),
                          onPressed: () => setState(() => _isAdmin = true),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Administrador',
                              maxLines: 1,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: _isAdmin
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Tipo de Contrato',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['CLT', 'Bolsista', 'Voluntário'].map((type) {
                      final selected = _contractType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _setContractType(type),
                            child: Text(
                              type,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (formState?.contractTypeError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        formState!.contractTypeError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (_contractType == 'Bolsista') ...[
                    Text(
                      'Carga horária bolsista',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['4', '6', '8'].map((hour) {
                        final selected = _selectedBolsistaHour == hour;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: selected
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                side: BorderSide.none,
                              ),
                              onPressed: () => _setBolsistaHour(hour),
                              child: Text(
                                '$hour hrs',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Dias de trabalho',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekDayOptions.map((option) {
                        final selected =
                            _selectedWorkDays.contains(option['value']);
                        return ChoiceChip(
                          label: Text(
                            option['label']!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) => _toggleWorkDay(option['value']!),
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: AppColors.primary,
                          side: BorderSide(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.white.withValues(alpha: 0.72)
                                : selected
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_getSelectedSchedule().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _getSelectedSchedule(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    if (formState?.workDaysError != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          formState!.workDaysError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Projetos',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['LAPADA', 'IRACEMA'].map((type) {
                        final selected = _projectType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: selected
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                side: BorderSide.none,
                              ),
                              onPressed: () {
                                setState(() => _projectType = type);
                              },
                              child: Text(
                                type,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    ..._projectControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: controller,
                                labelText: 'Projeto ${index + 1}',
                                prefixIcon: Icons.work_outline,
                              ),
                            ),
                            if (_projectControllers.length > 1)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller.dispose();
                                    _projectControllers.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.redAccent,
                                tooltip: 'Remover projeto',
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _projectControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar projeto'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF178573),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_contractType == 'Voluntário') ...[
                    Text(
                      'Projetos',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['LAPADA', 'IRACEMA'].map((type) {
                        final selected = _projectType == type;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: selected
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                side: BorderSide.none,
                              ),
                              onPressed: () {
                                setState(() => _projectType = type);
                              },
                              child: Text(
                                type,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    ..._projectControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: controller,
                                labelText: 'Projeto ${index + 1}',
                                prefixIcon: Icons.work_outline,
                              ),
                            ),
                            if (_projectControllers.length > 1)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller.dispose();
                                    _projectControllers.removeAt(index);
                                  });
                                },
                                icon:
                                    const Icon(Icons.remove_circle_outline),
                                color: Colors.redAccent,
                                tooltip: 'Remover projeto',
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _projectControllers
                                .add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar projeto'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF178573),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
