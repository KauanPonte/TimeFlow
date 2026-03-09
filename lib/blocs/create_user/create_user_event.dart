import 'package:equatable/equatable.dart';

abstract class CreateUserEvent extends Equatable {
  const CreateUserEvent();

  @override
  List<Object?> get props => [];
}

/// Valida um campo específico
class ValidateFieldEvent extends CreateUserEvent {
  final String fieldName;
  final String value;

  const ValidateFieldEvent({
    required this.fieldName,
    required this.value,
  });

  @override
  List<Object?> get props => [fieldName, value];
}

/// Valida o campo de confirmação de senha
class ValidateConfirmPasswordEvent extends CreateUserEvent {
  final String password;
  final String confirmPassword;

  const ValidateConfirmPasswordEvent({
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [password, confirmPassword];
}

/// Cria um novo usuário
class CreateUserSubmitEvent extends CreateUserEvent {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String role;

  const CreateUserSubmitEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, password, confirmPassword, role];
}

/// Reseta o formulário
class ResetFormEvent extends CreateUserEvent {
  const ResetFormEvent();
}
