import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';

GetOptions _getOpts(bool preferCache) => preferCache
    ? const GetOptions(source: Source.cache)
    : const GetOptions();

class JustificativaRepository {
  static const String _collection = 'justificativas';
  static const String _pontosCollection = 'pontos';

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection(_collection);

  /// Funcionário envia justificativa de falta. Não credita horas.
  Future<void> createJustificativa({
    required String diaId,
    required String justificativa,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Não autenticado');
    if (justificativa.trim().isEmpty) {
      throw Exception('A justificativa não pode estar vazia.');
    }

    final results = await Future.wait([
      _ref
          .where('uid', isEqualTo: user.uid)
          .where('diaId', isEqualTo: diaId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get(),
      FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get(),
    ]);
    final existing = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final userSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;

    if (existing.docs.isNotEmpty) {
      throw Exception(
          'Já existe uma justificativa pendente para este dia. Aguarde a revisão do administrador.');
    }
    final employeeName = (userSnap.data()?['name'] ?? '').toString();

    String? fileUrl;
    if (fileBytes != null && fileName != null) {
      final storageRef = FirebaseStorage.instance.ref(
        'justificativas/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      await storageRef.putData(
          fileBytes, SettableMetadata(contentType: 'application/pdf'));
      fileUrl = await storageRef.getDownloadURL();
    }

    await _ref.add({
      'uid': user.uid,
      'employeeName': employeeName,
      'diaId': diaId,
      'justificativa': justificativa.trim(),
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'resolvedAt': null,
      'resolvedBy': null,
      'reason': null,
      'seenByEmployee': false,
      'fileName': fileName,
      'fileUrl': fileUrl,
    });
  }

  /// Retorna todas as justificativas do funcionário logado.
  Future<List<JustificativaModel>> getMyJustificativas(
      {bool preferCache = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _ref
        .where('uid', isEqualTo: user.uid)
        .get(_getOpts(preferCache));
    final list = snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Retorna todas as justificativas pendentes (admin).
  Future<List<JustificativaModel>> getPendingJustificativas(
      {bool preferCache = false}) async {
    final snap = await _ref
        .where('status', isEqualTo: 'pending')
        .get(_getOpts(preferCache));
    final list = snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Stream em tempo real de justificativas pendentes (admin).
  Stream<List<JustificativaModel>> streamPendingJustificativas() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Retorna todas as justificativas de um funcionário específico (admin).
  Future<List<JustificativaModel>> getJustificativasForEmployee(
      String uid) async {
    final snap = await _ref.where('uid', isEqualTo: uid).get();
    final list = snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Admin aprova justificativa — apenas grava o texto no dia, sem crédito de horas.
  Future<void> approveJustificativa(String justificativaId) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    final doc = await _ref.doc(justificativaId).get();
    final model = JustificativaModel.fromDoc(doc);

    await FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(model.uid)
        .collection('dias')
        .doc(model.diaId)
        .set({'justificativa': model.justificativa}, SetOptions(merge: true));

    await _ref.doc(justificativaId).update({
      'status': 'approved',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
    });
  }

  /// Admin recusa justificativa com motivo opcional.
  Future<void> rejectJustificativa(String justificativaId,
      {String? reason}) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    await _ref.doc(justificativaId).update({
      'status': 'rejected',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
      'reason': reason,
    });
  }

  /// Admin define justificativa diretamente em um dia sem fluxo de aprovação.
  Future<void> adminSetJustificativa({
    required String uid,
    required String diaId,
    required String justificativa,
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    await FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(uid)
        .collection('dias')
        .doc(diaId)
        .set({'justificativa': justificativa.trim()}, SetOptions(merge: true));

    final existing = await _ref
        .where('uid', isEqualTo: uid)
        .where('diaId', isEqualTo: diaId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'justificativa': justificativa.trim(),
        'status': 'approved',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': admin.uid,
      });
    } else {
      final userSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      final employeeName = (userSnap.data()?['name'] ?? '').toString();

      await _ref.add({
        'uid': uid,
        'employeeName': employeeName,
        'diaId': diaId,
        'justificativa': justificativa.trim(),
        'status': 'approved',
        'createdAt': Timestamp.now(),
        'resolvedAt': Timestamp.now(),
        'resolvedBy': admin.uid,
        'reason': null,
        'seenByEmployee': true,
        'fileName': null,
        'fileUrl': null,
      });
    }
  }

  /// Funcionário marca justificativa como vista.
  Future<void> markSeenByEmployee(String justificativaId) async {
    try {
      await _ref.doc(justificativaId).update({'seenByEmployee': true});
    } catch (_) {}
  }

  /// Remove justificativa. Justificativas não creditam horas, então não precisa reverter saldo.
  Future<void> deleteJustificativa(String justificativaId) async {
    final doc = await _ref.doc(justificativaId).get();
    if (!doc.exists) return;
    final model = JustificativaModel.fromDoc(doc);

    await FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(model.uid)
        .collection('dias')
        .doc(model.diaId)
        .set({'justificativa': null}, SetOptions(merge: true));

    await _ref.doc(justificativaId).delete();
  }
}
