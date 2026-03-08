import 'package:equatable/equatable.dart';
import '../../models/auth_field.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Login sucesso (apenas feedback imediato)
class LoginSuccess extends AuthState {
  final Map<String, dynamic> userData;

  const LoginSuccess({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// Registro sucesso
class RegisterSuccess extends AuthState {
  final Map<String, dynamic> userData;

  const RegisterSuccess({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// Registro enviado, aguardando aprovação do administrador
class RegistrationPendingApproval extends AuthState {
  const RegistrationPendingApproval();
}

/// Reset senha enviado
class PasswordResetEmailSent extends AuthState {
  final String email;

  const PasswordResetEmailSent({required this.email});

  @override
  List<Object> get props => [email];
}

/// Erro geral
class AuthError extends AuthState {
  final String message;
  final AuthField? field;

  const AuthError({
    required this.message,
    this.field,
  });

  @override
  List<Object?> get props => [message, field];
}

/// Estado dos campos (validação e loading)
class AuthFieldsState extends AuthState {
  final Map<AuthField, String?> fieldErrors;
  final Map<AuthField, bool> fieldValid;
  final bool isLoading;

  const AuthFieldsState({
    this.fieldErrors = const {},
    this.fieldValid = const {},
    this.isLoading = false,
  });

  AuthFieldsState copyWith({
    Map<AuthField, String?>? fieldErrors,
    Map<AuthField, bool>? fieldValid,
    bool? isLoading,
  }) {
    return AuthFieldsState(
      fieldErrors: fieldErrors ?? this.fieldErrors,
      fieldValid: fieldValid ?? this.fieldValid,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [fieldErrors, fieldValid, isLoading];
}

/// ADMIN autenticado
class AdminAuthenticated extends AuthState {
  final Map<String, dynamic> userData;

  const AdminAuthenticated({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// Usuário normal autenticado
class UserAuthenticated extends AuthState {
  final Map<String, dynamic> userData;

  const UserAuthenticated({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// Não autenticado
class Unauthenticated extends AuthState {
  const Unauthenticated();
}
