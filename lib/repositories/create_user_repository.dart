import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_appdeponto/firebase_options.dart';

class CreateUserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';

  /// Cria um novo usuário no Firebase Auth sem deslogar o admin.
  /// Usa um app secundário do Firebase para isolar a sessão.
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      // Inicia um app secundário isolado para não deslogar o admin
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_create_user',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Cria o usuário no Firebase Auth via app secundário
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      // Deslogar do app secundário imediatamente
      await secondaryAuth.signOut();

      // Salvar dados no Firestore (usa a instância principal, sem conflito)
      await _db.collection(_usersCollection).doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role.trim(),
        'status': 'active',
        'profileImage': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
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
    } finally {
      // Sempre deleta o app secundário para liberar recursos
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }
}
