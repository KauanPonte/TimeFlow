import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing authentication and related operations
/// Will be connected to a real database in the future
class AuthRepository {
  // Simulated list of registered users (remove when integrating with backend)
  final List<Map<String, dynamic>> _registeredUsers = [
    {
      'email': 'usuario@exemplo.com',
      'password': '123456',
      'name': 'Usuário Exemplo',
      'role': 'Desenvolvedor',
    },
    {
      'email': 'teste@teste.com',
      'password': 'senha123',
      'name': 'Teste da Silva',
      'role': 'Gerente',
    },
  ];

  /// Performs user login
  /// Returns user data if credentials are valid
  /// Throws exception if credentials are invalid
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Simulates network request delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with real API call
    // Example: final response = await http.post('$baseUrl/login', body: {...});
    final user = _registeredUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => throw Exception('Email ou senha incorretos'),
    );

    return {
      'email': user['email'],
      'name': user['name'],
      'role': user['role'],
    };
  }

  /// Registers a new user
  /// Returns created user data
  /// Throws exception if email is already registered
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    File? profileImage,
  }) async {
    // Simulates network request delay
    await Future.delayed(const Duration(seconds: 1));

    // Checks if email is already registered
    final emailExists = _registeredUsers.any((u) => u['email'] == email);
    if (emailExists) {
      throw Exception('Email já cadastrado');
    }

    // TODO: Replace with real API call
    // Example: final response = await http.post('$baseUrl/register', body: {...});
    // If there is an image, upload it: await uploadImage(profileImage);

    final newUser = {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'profileImage': profileImage?.path,
    };

    _registeredUsers.add(newUser);

    return {
      'email': newUser['email'],
      'name': newUser['name'],
      'role': newUser['role'],
      'profileImage': newUser['profileImage'],
    };
  }

  /// Sends password reset email
  /// Returns true if email was sent successfully
  /// Throws exception if email is not registered
  Future<bool> sendPasswordResetEmail(String email) async {
    // Simulates network request delay
    await Future.delayed(const Duration(seconds: 1));

    // Checks if email is registered
    final emailExists = _registeredUsers.any((u) => u['email'] == email);
    if (!emailExists) {
      throw Exception('Email não cadastrado');
    }

    // TODO: Replace with real API call
    // Example: await http.post('$baseUrl/forgot-password', body: {'email': email});

    return true;
  }

  /// Validates if an email is registered in the system
  /// Returns true if email exists
  Future<bool> validateEmail(String email) async {
    // Simula delay de requisição de rede
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: Replace with real API call
    // Example: final response = await http.get('$baseUrl/validate-email?email=$email');

    return _registeredUsers.any((u) => u['email'] == email);
  }

  /// Validates email format
  bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates password strength
  /// Returns error message or null if password is valid
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Senha não pode estar vazia';
    }
    if (password.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  /// Validates if name is filled
  String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Nome não pode estar vazio';
    }
    if (name.trim().length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }
    return null;
  }

  /// Saves user session after successful login
  Future<void> saveUserSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', userData['email'] ?? '');
    await prefs.setString('userName', userData['name'] ?? '');
    await prefs.setString('userRole', userData['role'] ?? '');
    await prefs.setString('profileImage', userData['profileImage'] ?? '');
  }

  /// Gets current user session if logged in
  Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {
      return null;
    }

    return {
      'email': prefs.getString('userEmail') ?? '',
      'name': prefs.getString('userName') ?? '',
      'role': prefs.getString('userRole') ?? '',
      'profileImage': prefs.getString('profileImage') ?? '',
    };
  }

  /// Checks if user is currently logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// Clears user session (logout)
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
