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
  final String? roleError;

  final bool nameValid;
  final bool emailValid;
  final bool passwordValid;
  final bool confirmPasswordValid;
  final bool roleValid;

  const CreateUserFormState({
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.roleError,
    this.nameValid = false,
    this.emailValid = false,
    this.passwordValid = false,
    this.confirmPasswordValid = false,
    this.roleValid = false,
  });

  bool get isFormValid =>
      nameValid &&
      emailValid &&
      passwordValid &&
      confirmPasswordValid &&
      roleValid;

  @override
  List<Object?> get props => [
        nameError,
        emailError,
        passwordError,
        confirmPasswordError,
        roleError,
        nameValid,
        emailValid,
        passwordValid,
        confirmPasswordValid,
        roleValid,
      ];

  CreateUserFormState copyWith({
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? roleError,
    bool? nameValid,
    bool? emailValid,
    bool? passwordValid,
    bool? confirmPasswordValid,
    bool? roleValid,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
    bool clearRoleError = false,
  }) {
    return CreateUserFormState(
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : (confirmPasswordError ?? this.confirmPasswordError),
      roleError: clearRoleError ? null : (roleError ?? this.roleError),
      nameValid: nameValid ?? this.nameValid,
      emailValid: emailValid ?? this.emailValid,
      passwordValid: passwordValid ?? this.passwordValid,
      confirmPasswordValid: confirmPasswordValid ?? this.confirmPasswordValid,
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
