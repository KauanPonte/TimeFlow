import 'package:equatable/equatable.dart';

abstract class CreateUserState extends Equatable {
  const CreateUserState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial do formulário
class CreateUserInitial extends CreateUserState {
  const CreateUserInitial();
}

/// Formulário com validações
class CreateUserFormState extends CreateUserState {
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? cargaHorariaError;
  final String? roleError;

  final bool nameValid;
  final bool emailValid;
  final bool passwordValid;
  final bool confirmPasswordValid;
  final bool cargaHorariaValid;
  final bool roleValid;

  const CreateUserFormState({
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.cargaHorariaError,
    this.roleError,
    this.nameValid = false,
    this.emailValid = false,
    this.passwordValid = false,
    this.confirmPasswordValid = false,
    this.cargaHorariaValid = false,
    this.roleValid = false,
  });

  bool get isFormValid =>
      nameValid &&
      emailValid &&
      passwordValid &&
      confirmPasswordValid &&
      cargaHorariaValid &&
      roleValid;

  @override
  List<Object?> get props => [
        nameError,
        emailError,
        passwordError,
        confirmPasswordError,
        cargaHorariaError,
        roleError,
        nameValid,
        emailValid,
        passwordValid,
        confirmPasswordValid,
        cargaHorariaValid,
        roleValid,
      ];

  CreateUserFormState copyWith({
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? cargaHorariaError,
    String? roleError,
    bool? nameValid,
    bool? emailValid,
    bool? passwordValid,
    bool? confirmPasswordValid,
    bool? cargaHorariaValid,
    bool? roleValid,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
    bool clearCargaHorariaError = false,
    bool clearRoleError = false,
  }) {
    return CreateUserFormState(
    nameError: clearNameError ? null : (nameError ?? this.nameError),
    nameValid: nameValid ?? this.nameValid,
    emailError: clearEmailError ? null : (emailError ?? this.emailError),
    emailValid: emailValid ?? this.emailValid,
    passwordError:
        clearPasswordError ? null : (passwordError ?? this.passwordError),
    passwordValid: passwordValid ?? this.passwordValid,
    confirmPasswordError: clearConfirmPasswordError
        ? null
        : (confirmPasswordError ?? this.confirmPasswordError),
    confirmPasswordValid:
        confirmPasswordValid ?? this.confirmPasswordValid,
    cargaHorariaError: clearCargaHorariaError
        ? null
        : (cargaHorariaError ?? this.cargaHorariaError),
    cargaHorariaValid: cargaHorariaValid ?? this.cargaHorariaValid,
    roleError: clearRoleError ? null : (roleError ?? this.roleError),
    roleValid: roleValid ?? this.roleValid,
  );
  }
}

/// Criando usuário
class CreateUserLoading extends CreateUserState {
  const CreateUserLoading();
}

/// Usuário criado com sucesso
class CreateUserSuccess extends CreateUserState {
  final String userName;

  const CreateUserSuccess(this.userName);

  @override
  List<Object?> get props => [userName];
}

/// Erro ao criar usuário
class CreateUserError extends CreateUserState {
  final String message;

  const CreateUserError(this.message);

  @override
  List<Object?> get props => [message];
}
