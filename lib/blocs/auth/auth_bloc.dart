import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/repositories/auth_repository.dart';

/// BLoC responsible for managing all authentication logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  AuthFieldsState _fieldsState = const AuthFieldsState();
  AuthRepository get authRepository => _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthFieldsState()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<EmailFormatValidationRequested>(_onEmailFormatValidationRequested);
    on<PasswordValidationRequested>(_onPasswordValidationRequested);
    on<NameValidationRequested>(_onNameValidationRequested);
    on<ClearFieldError>(_onClearFieldError);
    on<AuthReset>(_onAuthReset);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  /// Handler for login event
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _fieldsState = _fieldsState.copyWith(isLoading: true);
    emit(_fieldsState);

    try {
      // Validate email format
      if (!_authRepository.isValidEmailFormat(event.email)) {
        final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
        errors['email'] = 'Email inválido';
        _fieldsState = _fieldsState.copyWith(
          fieldErrors: errors,
          isLoading: false,
        );
        emit(_fieldsState);
        return;
      }

      // Validate password
      final passwordError = _authRepository.validatePassword(event.password);
      if (passwordError != null) {
        final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
        errors['password'] = passwordError;
        _fieldsState = _fieldsState.copyWith(
          fieldErrors: errors,
          isLoading: false,
        );
        emit(_fieldsState);
        return;
      }

      // Try to login
      final userData = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      // Save user session
      await _authRepository.saveUserSession(userData);

      _fieldsState = const AuthFieldsState();
      emit(LoginSuccess(userData: userData));
    } catch (e) {
      _fieldsState = _fieldsState.copyWith(isLoading: false);
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      emit(_fieldsState); // Emit fieldsState so UI knows loading has stopped
    }
  }

  /// Handler for register event
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    _fieldsState = _fieldsState.copyWith(isLoading: true);
    emit(_fieldsState);

    try {
      // Validate all fields
      final errors = <String, String?>{};

      if (!_authRepository.isValidEmailFormat(event.email)) {
        errors['email'] = 'Email inválido';
      }

      final passwordError = _authRepository.validatePassword(event.password);
      if (passwordError != null) {
        errors['password'] = passwordError;
      }

      final nameError = _authRepository.validateName(event.name);
      if (nameError != null) {
        errors['name'] = nameError;
      }

      if (event.role.trim().isEmpty) {
        errors['role'] = 'Cargo não pode estar vazio';
      }

      // If there are validation errors, emit error state
      if (errors.isNotEmpty) {
        _fieldsState = _fieldsState.copyWith(
          fieldErrors: errors,
          isLoading: false,
        );
        emit(_fieldsState);
        return;
      }

      // Try to register
      final userData = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
        profileImage: event.profileImage,
      );

      // Save user session
      await _authRepository.saveUserSession(userData);

      _fieldsState = const AuthFieldsState();
      emit(RegisterSuccess(userData: userData));
    } catch (e) {
      _fieldsState = _fieldsState.copyWith(isLoading: false);
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      emit(_fieldsState); // Emit fieldsState so UI knows loading has stopped
    }
  }

  /// Handler for forgot password event
  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    _fieldsState = _fieldsState.copyWith(isLoading: true);
    emit(_fieldsState);

    try {
      // Validate email format
      if (event.email.trim().isEmpty) {
        final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
        errors['email'] = 'Por favor, insira um email';
        _fieldsState = _fieldsState.copyWith(
          fieldErrors: errors,
          isLoading: false,
        );
        emit(_fieldsState);
        return;
      }

      if (!_authRepository.isValidEmailFormat(event.email)) {
        final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
        errors['email'] = 'Email inválido';
        _fieldsState = _fieldsState.copyWith(
          fieldErrors: errors,
          isLoading: false,
        );
        emit(_fieldsState);
        return;
      }

      // Try to send password reset email
      await _authRepository.sendPasswordResetEmail(event.email);
      _fieldsState = const AuthFieldsState();
      emit(PasswordResetEmailSent(email: event.email));
    } catch (e) {
      // Update field state and emit error with field context
      final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
      errors['email'] = e.toString().replaceAll('Exception: ', '');
      _fieldsState = _fieldsState.copyWith(
        fieldErrors: errors,
        isLoading: false,
      );
      emit(_fieldsState);
    }
  }

  /// Handler for email format validation
  Future<void> _onEmailFormatValidationRequested(
    EmailFormatValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
    final valid = Map<String, bool>.from(_fieldsState.fieldValid);

    if (event.email.isEmpty) {
      errors[event.fieldName] = null;
      valid[event.fieldName] = false;
    } else if (!_authRepository.isValidEmailFormat(event.email)) {
      errors[event.fieldName] = 'Email inválido';
      valid[event.fieldName] = false;
    } else {
      errors[event.fieldName] = null;
      valid[event.fieldName] = true;
    }

    _fieldsState = _fieldsState.copyWith(
      fieldErrors: errors,
      fieldValid: valid,
    );
    emit(_fieldsState);
  }

  /// Handler for password validation
  Future<void> _onPasswordValidationRequested(
    PasswordValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
    final valid = Map<String, bool>.from(_fieldsState.fieldValid);
    final error = _authRepository.validatePassword(event.password);

    if (event.password.isEmpty) {
      errors[event.fieldName] = null;
      valid[event.fieldName] = false;
    } else if (error != null) {
      errors[event.fieldName] = error;
      valid[event.fieldName] = false;
    } else {
      errors[event.fieldName] = null;
      valid[event.fieldName] = true;
    }

    _fieldsState = _fieldsState.copyWith(
      fieldErrors: errors,
      fieldValid: valid,
    );
    emit(_fieldsState);
  }

  /// Handler for name validation
  Future<void> _onNameValidationRequested(
    NameValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
    final valid = Map<String, bool>.from(_fieldsState.fieldValid);
    final error = _authRepository.validateName(event.name);

    if (event.name.isEmpty) {
      errors['name'] = null;
      valid['name'] = false;
    } else if (error != null) {
      errors['name'] = error;
      valid['name'] = false;
    } else {
      errors['name'] = null;
      valid['name'] = true;
    }

    _fieldsState = _fieldsState.copyWith(
      fieldErrors: errors,
      fieldValid: valid,
    );
    emit(_fieldsState);
  }

  /// Handler for clearing specific field error
  Future<void> _onClearFieldError(
    ClearFieldError event,
    Emitter<AuthState> emit,
  ) async {
    final errors = Map<String, String?>.from(_fieldsState.fieldErrors);
    errors[event.fieldName] = null;
    _fieldsState = _fieldsState.copyWith(fieldErrors: errors);
    emit(_fieldsState);
  }

  /// Handler for resetting the auth state
  Future<void> _onAuthReset(
    AuthReset event,
    Emitter<AuthState> emit,
  ) async {
    _fieldsState = const AuthFieldsState();
    emit(_fieldsState);
  }

  /// Handler for logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.clearUserSession();
    _fieldsState = const AuthFieldsState();
    emit(_fieldsState);
  }

  /// Handler to check authentication status
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final userData = await _authRepository.getUserSession();

    if (userData != null) {
      final email = userData['email'] as String?;
      if (email != null && email.isNotEmpty) {
        // Validate that user still exists in registered users
        final userExists = await _authRepository.validateEmail(email);
        if (userExists) {
          // User is authenticated and exists
          emit(Authenticated(userData: userData));
          return;
        }
        // User was deleted, clear session
        await _authRepository.clearUserSession();
      }
    }

    // Not authenticated or user no longer exists
    emit(const Unauthenticated());
  }
}
