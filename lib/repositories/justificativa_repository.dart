import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';

class JustificativaRepository {
  static const String _collection = 'justificativas';
  static const String _pontosCollection = 'pontos';

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection(_collection);

  /// Funcionário envia uma justificativa de falta para um dia.
  /// Lança exceção se já houver uma justificativa pendente para o mesmo dia.
  Future<void> createJustificativa({
    required String diaId,
    required String justificativa,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Não autenticado');
    if (justificativa.trim().isEmpty) {
      throw Exception('A justificativa não pode estar vazia.');
    }

    // Verifica duplicata pendente para o mesmo dia
    final existing = await _ref
        .where('uid', isEqualTo: user.uid)
        .where('diaId', isEqualTo: diaId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception(
          'Já existe uma justificativa pendente para este dia. Aguarde a revisão do administrador.');
    }

    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final employeeName = (userSnap.data()?['name'] ?? '').toString();

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
    });
  }

  /// Retorna todas as justificativas do funcionário logado.
  Future<List<JustificativaModel>> getMyJustificativas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _ref.where('uid', isEqualTo: user.uid).get();
    final list = snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Retorna todas as justificativas pendentes (uso do admin).
  Future<List<JustificativaModel>> getPendingJustificativas() async {
    final snap =
        await _ref.where('status', isEqualTo: 'pending').get();
    final list = snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Retorna todas as justificativas de um funcionário específico (uso do admin
  /// ao visualizar o histórico).
  Future<List<JustificativaModel>> getJustificativasForEmployee(
      String uid) async {
    final snap = await _ref.where('uid', isEqualTo: uid).get();
    final list = snap.docs.map((d) => JustificativaModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Admin aprova a justificativa e grava o texto no documento do dia
  /// (`pontos/{uid}/dias/{diaId}.justificativa`).
  Future<void> approveJustificativa(String justificativaId) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    final doc = await _ref.doc(justificativaId).get();
    final model = JustificativaModel.fromDoc(doc);

    // Grava o texto no documento do dia (sem alterar saldo)
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

  /// Admin recusa a justificativa com motivo opcional.
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

  /// Admin define diretamente a justificativa de um dia sem fluxo de aprovação.
  /// Grava o texto no documento do dia e cria/atualiza o documento de justificativa
  /// como aprovado.
  Future<void> adminSetJustificativa({
    required String uid,
    required String diaId,
    required String justificativa,
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    // Grava no documento do dia
    await FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(uid)
        .collection('dias')
        .doc(diaId)
        .set({'justificativa': justificativa.trim()}, SetOptions(merge: true));

    // Verifica se já existe documento de justificativa para este dia
    final existing = await _ref
        .where('uid', isEqualTo: uid)
        .where('diaId', isEqualTo: diaId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Atualiza o existente
      await existing.docs.first.reference.update({
        'justificativa': justificativa.trim(),
        'status': 'approved',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': admin.uid,
      });
    } else {
      // Busca nome do funcionário
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
      });
    }
  }

  /// Funcionário marca a justificativa como vista (dispensa notificação).
  Future<void> markSeenByEmployee(String justificativaId) async {
    try {
      await _ref.doc(justificativaId).update({'seenByEmployee': true});
    } catch (_) {}
  }
}
