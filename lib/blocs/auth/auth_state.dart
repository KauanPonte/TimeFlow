import 'package:equatable/equatable.dart';

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
  final String? fieldName; // Specific field that caused the error

  const AuthError({
    required this.message,
    this.fieldName,
  });

  @override
  List<Object?> get props => [message, fieldName];
}

/// State that holds information about field validation
class AuthFieldsState extends AuthState {
  final Map<String, String?> fieldErrors;
  final Map<String, bool> fieldValid;
  final bool isLoading;

  const AuthFieldsState({
    this.fieldErrors = const {},
    this.fieldValid = const {},
    this.isLoading = false,
  });

  AuthFieldsState copyWith({
    Map<String, String?>? fieldErrors,
    Map<String, bool>? fieldValid,
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
