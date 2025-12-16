import 'package:equatable/equatable.dart';
import '../../models/auth_field.dart';

/// Base class for authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no authentication action has been initiated
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when login is successful
class LoginSuccess extends AuthState {
  final Map<String, dynamic> userData;

  const LoginSuccess({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// State when registration is successful
class RegisterSuccess extends AuthState {
  final Map<String, dynamic> userData;

  const RegisterSuccess({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// State when password reset email has been sent successfully
class PasswordResetEmailSent extends AuthState {
  final String email;

  const PasswordResetEmailSent({required this.email});

  @override
  List<Object> get props => [email];
}

/// State when a general authentication error occurs
class AuthError extends AuthState {
  final String message;
  final AuthField? field; // Specific field that caused the error

  const AuthError({
    required this.message,
    this.field,
  });

  @override
  List<Object?> get props => [message, field];
}

/// State that holds information about field validation
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

/// State when user is authenticated (for splash screen)
class Authenticated extends AuthState {
  final Map<String, dynamic> userData;

  const Authenticated({required this.userData});

  @override
  List<Object> get props => [userData];
}

/// State when user is not authenticated (for splash screen)
class Unauthenticated extends AuthState {
  const Unauthenticated();
}
