import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';

class AtestadoRepository {
  static const String _collection = 'atestados';
  static const String _pontosCollection = 'pontos';

  CollectionReference<Map<String, dynamic>> get _atestadosRef =>
      FirebaseFirestore.instance.collection(_collection);

  Future<void> createAtestado({
    required String dataInicio,
    required String dataFim,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Não autenticado');

    // Upload PDF ao Firebase Storage
    final storageRef = FirebaseStorage.instance.ref(
      'atestados/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    await storageRef.putData(fileBytes, SettableMetadata(contentType: 'application/pdf'));
    final fileUrl = await storageRef.getDownloadURL();

    // Busca nome do funcionário
    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final employeeName = (userSnap.data()?['name'] ?? '').toString();

    await _atestadosRef.add({
      'uid': user.uid,
      'employeeName': employeeName,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'resolvedAt': null,
      'resolvedBy': null,
      'reason': null,
      'seenByEmployee': false,
    });
  }

  Future<List<AtestadoModel>> getMyAtestados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _atestadosRef
        .where('uid', isEqualTo: user.uid)
        .get();

    final list = snap.docs.map((d) => AtestadoModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<AtestadoModel>> getPendingAtestados() async {
    final snap = await _atestadosRef
        .where('status', isEqualTo: 'pending')
        .get();

    final list = snap.docs.map((d) => AtestadoModel.fromDoc(d)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> approveAtestado(String atestadoId) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    final doc = await _atestadosRef.doc(atestadoId).get();
    final atestado = AtestadoModel.fromDoc(doc);

    final fmt = DateFormat('yyyy-MM-dd');
    final start = DateTime.parse(atestado.dataInicio);
    final end = DateTime.parse(atestado.dataFim);

    // Marca cada dia do intervalo como facultativo e recalcula
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final diaId = fmt.format(d);

      await FirebaseFirestore.instance
          .collection(_pontosCollection)
          .doc(atestado.uid)
          .collection('dias')
          .doc(diaId)
          .set({'isExcused': true}, SetOptions(merge: true));

      await PontoService.recalcularBancoDeHorasDoDia(
        uid: atestado.uid,
        diaId: diaId,
      );
    }

    await _atestadosRef.doc(atestadoId).update({
      'status': 'approved',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
    });
  }

  Future<void> rejectAtestado(String atestadoId, {String? reason}) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    await _atestadosRef.doc(atestadoId).update({
      'status': 'rejected',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
      'reason': reason,
    });
  }

  Future<void> markSeenByEmployee(String atestadoId) async {
    await _atestadosRef.doc(atestadoId).update({'seenByEmployee': true});
  }
}
