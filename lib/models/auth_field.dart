/// Base class for authentication form fields.
///
/// Each field is represented by a specific class, providing type safety
/// and eliminating string-based errors.
abstract class AuthField {
  const AuthField();

  /// Unique identifier for the field
  String get key;

  /// Human-readable name
  String get displayName;

  /// Context where this field is used (login, register, forgot_password)
  String get context;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthField &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

// ==================== Login Fields ====================

/// Email field for login form
class EmailLoginField extends AuthField {
  const EmailLoginField();

  @override
  String get key => 'email_login';

  @override
  String get displayName => 'Email';

  @override
  String get context => 'login';
}

/// Password field for login form
class PasswordLoginField extends AuthField {
  const PasswordLoginField();

  @override
  String get key => 'password_login';

  @override
  String get displayName => 'Senha';

  @override
  String get context => 'login';
}

// ==================== Register Fields ====================

/// Name field for register form
class NameField extends AuthField {
  const NameField();

  @override
  String get key => 'name';

  @override
  String get displayName => 'Nome Completo';

  @override
  String get context => 'register';
}

/// Email field for register form
class EmailRegisterField extends AuthField {
  const EmailRegisterField();

  @override
  String get key => 'email_register';

  @override
  String get displayName => 'Email';

  @override
  String get context => 'register';
}

/// Password field for register form
class PasswordRegisterField extends AuthField {
  const PasswordRegisterField();

  @override
  String get key => 'password_register';

  @override
  String get displayName => 'Senha';

  @override
  String get context => 'register';
}

/// Role field for register form
class RoleField extends AuthField {
  const RoleField();

  @override
  String get key => 'role';

  @override
  String get displayName => 'Cargo/Função';

  @override
  String get context => 'register';
}

// ==================== Forgot Password Fields ====================

/// Email field for forgot password form
class ResetEmailField extends AuthField {
  const ResetEmailField();

  @override
  String get key => 'reset_email';

  @override
  String get displayName => 'Email';

  @override
  String get context => 'forgot_password';
}

// ==================== Field Collections ====================

/// Centralized access to all authentication fields
class AuthFields {
  AuthFields._();

  // Singleton instances
  static const EmailLoginField emailLogin = EmailLoginField();
  static const PasswordLoginField passwordLogin = PasswordLoginField();
  static const NameField name = NameField();
  static const EmailRegisterField emailRegister = EmailRegisterField();
  static const PasswordRegisterField passwordRegister = PasswordRegisterField();
  static const RoleField role = RoleField();
  static const ResetEmailField resetEmail = ResetEmailField();

  /// All fields used in the login form
  static const List<AuthField> loginFields = [
    emailLogin,
    passwordLogin,
  ];

  /// All fields used in the register form
  static const List<AuthField> registerFields = [
    name,
    emailRegister,
    passwordRegister,
    role,
  ];

  /// All fields used in the forgot password form
  static const List<AuthField> forgotPasswordFields = [
    resetEmail,
  ];

  /// All authentication fields across all forms
  static const List<AuthField> allFields = [
    ...loginFields,
    ...registerFields,
    ...forgotPasswordFields,
  ];
}
