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
        'role': '',
        'status': 'pending',
        'profileImage': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out — user must wait for admin approval
      await _auth.signOut();

      return {
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': '',
        'status': 'pending',
        'profileImage': '',
      };
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Email já cadastrado');
        case 'weak-password':
          throw Exception('Senha fraca: use pelo menos 6 caracteres');
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'network-request-failed':
          throw Exception('Sem conexão com a internet');
        case 'too-many-requests':
          throw Exception('Muitas tentativas. Tente novamente mais tarde.');
        default:
          throw Exception('Erro ao cadastrar. Tente novamente.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado ao cadastrar. Tente novamente.');
    }
  }

  Future<Map<String, dynamic>> login({
    required email,
    required password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = cred.user!.uid;

      final doc = await _db.collection(_usersCollection).doc(uid).get();
      final data = doc.data();

      if (data == null) {
        await _auth.signOut();
        throw Exception('Perfil do usuário não encontrado');
      }

      // Check user status
      final status = data['status'] ?? '';
      if (status == 'pending') {
        await _auth.signOut();
        throw Exception('Sua conta está aguardando aprovação do administrador');
      }
      if (status != 'active') {
        await _auth.signOut();
        throw Exception('Sua conta não está ativa. Contate o administrador');
      }

      return {
        'uid': uid,
        'email': data['email'] ?? email.trim(),
        'name': data['name'] ?? '',
        'role': data['role'] ?? '',
        'profileImage': data['profileImage'] ?? '',
      };
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          throw Exception('Email ou senha incorretos');
        case 'user-not-found':
          throw Exception('Usuário não encontrado');
        case 'wrong-password':
          throw Exception('Senha incorreta');
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'user-disabled':
          throw Exception('Esta conta foi desativada. Contate o administrador.');
        case 'too-many-requests':
          throw Exception('Muitas tentativas. Tente novamente mais tarde.');
        case 'network-request-failed':
          throw Exception('Sem conexão com a internet');
        case 'channel-error':
          throw Exception('Preencha todos os campos');
        default:
          throw Exception('Erro ao entrar. Tente novamente.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado ao entrar. Tente novamente.');
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // Firebase Auth v5 no longer throws user-not-found for security reasons,
      // so we validate against Firestore first to give proper user feedback.
      final exists = await validateEmail(email.trim());
      if (!exists) {
        throw Exception('Email não cadastrado');
      }

      // ActionCodeSettings ensures Firebase generates a proper email with a
      // working link. Without this, the email may fail to be delivered or the
      // link may not render correctly. handleCodeInApp: false means the reset
      // page opens in the browser — no dynamic links setup required.
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://timeflow-5b4e6.firebaseapp.com',
        handleCodeInApp: false,
      );

      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'too-many-requests':
          throw Exception('Muitas tentativas. Tente novamente mais tarde.');
        case 'network-request-failed':
          throw Exception('Sem conexão com a internet');
        default:
          throw Exception('Erro ao enviar email de recuperação. Tente novamente.');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado. Tente novamente.');
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
    await prefs.setString('userUid', userData['uid'] ?? '');
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
