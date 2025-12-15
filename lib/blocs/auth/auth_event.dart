import 'dart:io';
import 'package:equatable/equatable.dart';

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when a user attempts to log in
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Event triggered when a user attempts to register
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;
  final File? profileImage;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.profileImage,
  });

  @override
  List<Object?> get props => [email, password, name, role, profileImage];
}

/// Event triggered when a user requests password recovery
class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

/// Event triggered to validate email format
class EmailFormatValidationRequested extends AuthEvent {
  final String email;
  final String fieldName; // To identify which field (login, register, etc)

  const EmailFormatValidationRequested({
    required this.email,
    required this.fieldName,
  });

  @override
  List<Object> get props => [email, fieldName];
}

/// Event triggered to validate a password
class PasswordValidationRequested extends AuthEvent {
  final String password;
  final String fieldName;

  const PasswordValidationRequested({
    required this.password,
    required this.fieldName,
  });

  @override
  List<Object> get props => [password, fieldName];
}

/// Event triggered to validate a name
class NameValidationRequested extends AuthEvent {
  final String name;

  const NameValidationRequested({required this.name});

  @override
  List<Object> get props => [name];
}

/// Event triggered to clear validation errors
class ClearFieldError extends AuthEvent {
  final String fieldName;

  const ClearFieldError({required this.fieldName});

  @override
  List<Object> get props => [fieldName];
}

/// Event triggered to reset the authentication state
/// If [fieldNames] is provided, only those fields will be reset
/// If [fieldNames] is null or empty, all fields will be reset
class AuthReset extends AuthEvent {
  final List<String>? fieldNames;

  const AuthReset({this.fieldNames});

  @override
  List<Object?> get props => [fieldNames];
}

/// Event triggered to log out
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event triggered to check authentication status on app start
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
