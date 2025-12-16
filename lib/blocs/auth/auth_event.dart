import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/auth_field.dart';

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
  final AuthField field; // To identify which field (login, register, etc)

  const EmailFormatValidationRequested({
    required this.email,
    required this.field,
  });

  @override
  List<Object> get props => [email, field];
}

/// Event triggered to validate a password
class PasswordValidationRequested extends AuthEvent {
  final String password;
  final AuthField field;

  const PasswordValidationRequested({
    required this.password,
    required this.field,
  });

  @override
  List<Object> get props => [password, field];
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
  final AuthField field;

  const ClearFieldError({required this.field});

  @override
  List<Object> get props => [field];
}

/// Event triggered to reset the authentication state
/// If [fields] is provided, only those fields will be reset
/// If [fields] is null or empty, all fields will be reset
class AuthReset extends AuthEvent {
  final List<AuthField>? fields;

  const AuthReset({this.fields});

  @override
  List<Object?> get props => [fields];
}

/// Event triggered to log out
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event triggered to check authentication status on app start
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
