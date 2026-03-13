import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

class ProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';

  /// Obtém os dados do perfil do usuário logado
  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userUid') ?? '';

    if (uid.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final doc = await _db.collection(_usersCollection).doc(uid).get();
    final data = doc.data();

    if (data == null) {
      throw Exception('Perfil não encontrado');
    }

    final workloadMinutes = (data['workloadMinutes'] ??
        data['cargaHorariaMinutos'] ??
        data['cargaHorairaMinutos']) as int?;

    return {
      'uid': uid,
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'role': data['role'] ?? '',
      'profileImage': data['profileImage'] ?? '',
      'workloadMinutes': workloadMinutes,
    };
  }

  /// Converte a imagem em Base64, redimensiona e salva no Firestore
  Future<String> uploadProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userUid') ?? '';

    if (uid.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    // Ler bytes e redimensionar para 200x200
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Não foi possível processar a imagem.');
    }

    final img.Image resized = img.copyResize(decoded, width: 200, height: 200);
    final Uint8List compressed = Uint8List.fromList(
      img.encodeJpg(resized, quality: 60),
    );

    final String base64Data =
        'data:image/jpeg;base64,${base64Encode(compressed)}';

    if (base64Data.length > 900000) {
      throw Exception('Imagem muito grande. Tente outra foto.');
    }

    // Salvar Base64 no Firestore
    await _db.collection(_usersCollection).doc(uid).update({
      'profileImage': base64Data,
    });

    // Atualizar sessão local
    await prefs.setString('profileImage', base64Data);

    return base64Data;
  }

  /// Remove a foto de perfil
  Future<void> removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userUid') ?? '';

    if (uid.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    // Limpar campo no Firestore
    await _db.collection(_usersCollection).doc(uid).update({
      'profileImage': '',
    });

    // Limpar sessão local
    await prefs.setString('profileImage', '');
  }

  /// Atualiza o nome do perfil
  Future<void> updateProfileName(String newName, {int? workloadMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userUid') ?? '';

    if (uid.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final payload = <String, dynamic>{
      'name': newName.trim(),
    };

    if (workloadMinutes != null) {
      payload['workloadMinutes'] = workloadMinutes;
    }

    await _db.collection(_usersCollection).doc(uid).update(payload);

    // Atualizar FirebaseAuth displayName
    await _auth.currentUser?.updateDisplayName(newName.trim());

    // Atualizar sessão local
    await prefs.setString('userName', newName.trim());
  }
}
