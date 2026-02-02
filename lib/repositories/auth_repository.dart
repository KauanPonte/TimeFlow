import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';

  Future<Map<String, dynamic>> register({
    required email,
    required password,
    required name,
    required role,
    File? profileImage,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

      final uid = cred.user!.uid;

      await _db.collection(_usersCollection).doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role.trim(),
        'profileImage': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role.trim(),
        'profileImage': '',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email já cadastrado');
      }
      if (e.code == 'weak-password') {
        throw Exception('Senha fraca: use pelo menos 6 caracteres');
      }
      if (e.code == 'invalid-email') {
        throw Exception('Email inválido');
      }
      throw Exception('Erro ao cadastrar: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required email,
    required password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      final doc = await _db.collection(_usersCollection).doc(uid).get();
      final data = doc.data();

      if (data == null) {
        throw Exception('Perfil do usuário não encontrado');
      }

      return {
        'uid': uid,
        'email': data['email'] ?? email.trim(),
        'name': data['name'] ?? '',
        'role': data['role'] ?? '',
        'profileImage': data['profileImage'] ?? '',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-foud' || e.code == 'wrong-password') {
        throw Exception('Email ou senha incorretos');
      }
      if (e.code == 'invalid-email') {
        throw Exception('Email inválido ');
      }
      if (e.code == 'too-many-requests') {
        throw Exception('Muitas tentativas. Tente novamente mais tarde.');
      }
      throw Exception('Erro ao entrar: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('Email inválido');
      }
      if (e.code == 'user-not-found') {
        throw Exception('Email não cadastrado');
      }
      throw Exception('Erro ao enviar email: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<bool> validateEmail(String email) async {
    final snap = await _db
        .collection(_usersCollection)
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
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
    await prefs.setString('userUid', userData['userUid'] ?? '' );
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) return null;

    return {
      'uid': prefs.getString('userUid') ?? '',
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

  Future<void> logout() async {
    await _auth.signOut();
    await clearUserSession();
  }
}
