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
  final String? contractTypeError;
  final String? workDaysError;

  final bool nameValid;
  final bool emailValid;
  final bool passwordValid;
  final bool confirmPasswordValid;
  final bool cargaHorariaValid;
  final bool roleValid;
  final bool contractTypeValid;
  final bool workDaysValid;

  const CreateUserFormState({
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.cargaHorariaError,
    this.roleError,
    this.contractTypeError,
    this.workDaysError,
    this.nameValid = false,
    this.emailValid = false,
    this.passwordValid = false,
    this.confirmPasswordValid = false,
    this.cargaHorariaValid = false,
    this.roleValid = false,
    this.contractTypeValid = false,
    this.workDaysValid = true,
  });

  bool get isFormValid =>
      nameValid &&
      emailValid &&
      passwordValid &&
      confirmPasswordValid &&
      cargaHorariaValid &&
      roleValid &&
      contractTypeValid &&
      workDaysValid;

  @override
  List<Object?> get props => [
        nameError,
        emailError,
        passwordError,
        confirmPasswordError,
        cargaHorariaError,
        roleError,
        contractTypeError,
        workDaysError,
        nameValid,
        emailValid,
        passwordValid,
        confirmPasswordValid,
        cargaHorariaValid,
        roleValid,
        contractTypeValid,
        workDaysValid,
      ];

  CreateUserFormState copyWith({
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? cargaHorariaError,
    String? roleError,
    String? contractTypeError,
    String? workDaysError,
    bool? nameValid,
    bool? emailValid,
    bool? passwordValid,
    bool? confirmPasswordValid,
    bool? cargaHorariaValid,
    bool? roleValid,
    bool? contractTypeValid,
    bool? workDaysValid,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
    bool clearCargaHorariaError = false,
    bool clearRoleError = false,
    bool clearContractTypeError = false,
    bool clearWorkDaysError = false,
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
      confirmPasswordValid: confirmPasswordValid ?? this.confirmPasswordValid,
      cargaHorariaError: clearCargaHorariaError
          ? null
          : (cargaHorariaError ?? this.cargaHorariaError),
      cargaHorariaValid: cargaHorariaValid ?? this.cargaHorariaValid,
      roleError: clearRoleError ? null : (roleError ?? this.roleError),
      roleValid: roleValid ?? this.roleValid,
      contractTypeError: clearContractTypeError
          ? null
          : (contractTypeError ?? this.contractTypeError),
      contractTypeValid: contractTypeValid ?? this.contractTypeValid,
      workDaysError:
          clearWorkDaysError ? null : (workDaysError ?? this.workDaysError),
      workDaysValid: workDaysValid ?? this.workDaysValid,
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
