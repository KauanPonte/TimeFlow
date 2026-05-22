import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';

/// Opções de leitura: cache local (instantâneo) para re-buscas pós-escrita,
/// servidor (padrão) para o carregamento inicial.
GetOptions _getOpts(bool preferCache) => preferCache
    ? const GetOptions(source: Source.cache)
    : const GetOptions();

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
    String? fileName,
    Uint8List? fileBytes,
    String? dataInicio,
    String? dataFim,
    int? abonoMinutes,
    bool isFullDayAbono = false,
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
      'fileName': fileName,
      'fileBytes': fileBytes,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'abonoMinutes': abonoMinutes,
      'isFullDayAbono': isFullDayAbono,
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

  /// Retorna todas as justificativas pendentes (uso do admin).
  Future<List<JustificativaModel>> getPendingJustificativas(
      {bool preferCache = false}) async {
    final snap = await _ref
        .where('status', isEqualTo: 'pending')
        .get(_getOpts(preferCache));
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

  /// Admin aprova a justificativa e grava o texto no documento do dia.
  /// Credita horas conforme o tipo de abono usando a carga horária real do funcionário.
  Future<void> approveJustificativa(String justificativaId) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    final doc = await _ref.doc(justificativaId).get();
    final model = JustificativaModel.fromDoc(doc);

    // Grava o texto no documento do dia
    await FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(model.uid)
        .collection('dias')
        .doc(model.diaId)
        .set({'justificativa': model.justificativa}, SetOptions(merge: true));

    // Busca carga horária real do funcionário
    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(model.uid)
        .get();
    final workloadMinutes = (userSnap.data()?['workloadMinutes'] ??
        userSnap.data()?['cargaHorariaMinutos'] as int?) ?? 8 * 60;

    int? abonoToApply;

    if (model.isFullDayAbono) {
      // Ponto facultativo: abono = carga horária completa do funcionário
      abonoToApply = workloadMinutes;
    } else if (model.abonoMinutes != null && model.abonoMinutes! > 0) {
      // Abono parcial (consulta/aula): duração da ausência salva no envio
      abonoToApply = model.abonoMinutes;
    }

    if (abonoToApply != null && abonoToApply > 0) {
      await _applyAbonoToDay(
        uid: model.uid,
        diaId: model.diaId,
        abonoMinutes: abonoToApply,
        targetMinutes: workloadMinutes,
      );
    }

    await _ref.doc(justificativaId).update({
      'status': 'approved',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
    });
  }

  /// Grava `abonoMinutes` no dia e recalcula `deltaMinutes` e saldo mensal.
  /// [targetMinutes] é a carga horária diária do funcionário.
  Future<void> _applyAbonoToDay({
    required String uid,
    required String diaId,
    required int abonoMinutes,
    required int targetMinutes,
  }) async {
    final targetMinutesPerDay = targetMinutes;
    final refDia = FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(uid)
        .collection('dias')
        .doc(diaId);
    final mesId = diaId.substring(0, 7);
    final refMes = FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(uid)
        .collection('meses')
        .doc(mesId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final diaSnap = await tx.get(refDia);
      final mesSnap = await tx.get(refMes);

      final workedMinutes = (diaSnap.data()?['workedMinutes'] as int?) ?? 0;
      final isClosed = (diaSnap.data()?['isClosed'] as bool?) ?? false;
      final oldDelta = (diaSnap.data()?['deltaMinutes'] as int?) ?? 0;
      final oldBalance = (mesSnap.data()?['balanceMinutes'] as int?) ?? 0;

      // Só recalcula delta se o dia já foi fechado
      final newDelta = isClosed
          ? (workedMinutes + abonoMinutes - targetMinutesPerDay)
          : oldDelta;
      final diff = newDelta - oldDelta;
      final newBalance = oldBalance + diff;

      tx.set(refDia, {
        'abonoMinutes': abonoMinutes,
        if (isClosed) 'deltaMinutes': newDelta,
      }, SetOptions(merge: true));

      if (isClosed && diff != 0) {
        tx.set(refMes, {
          'balanceMinutes': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
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

  /// Remove a justificativa e reverte o abono caso já tenha sido aprovado.
  Future<void> deleteJustificativa(String justificativaId) async {
    final doc = await _ref.doc(justificativaId).get();
    if (!doc.exists) return;
    final model = JustificativaModel.fromDoc(doc);

    final refDia = FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(model.uid)
        .collection('dias')
        .doc(model.diaId);

    // Remove texto de justificativa do dia
    await refDia.set({'justificativa': null}, SetOptions(merge: true));

    // Se aprovado com abono creditado, reverte
    if (model.status == JustificativaStatus.approved) {
      final diaSnap = await refDia.get();
      final appliedAbono = (diaSnap.data()?['abonoMinutes'] as int?) ?? 0;

      if (appliedAbono > 0) {
        final mesId = model.diaId.substring(0, 7);
        final refMes = FirebaseFirestore.instance
            .collection(_pontosCollection)
            .doc(model.uid)
            .collection('meses')
            .doc(mesId);

        final userSnap = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(model.uid)
            .get();
        final workloadMinutes =
            (userSnap.data()?['workloadMinutes'] as int?) ??
                (userSnap.data()?['cargaHorariaMinutos'] as int?) ??
                8 * 60;

        await FirebaseFirestore.instance.runTransaction((tx) async {
          final dSnap = await tx.get(refDia);
          final mSnap = await tx.get(refMes);

          final workedMinutes = (dSnap.data()?['workedMinutes'] as int?) ?? 0;
          final isClosed = (dSnap.data()?['isClosed'] as bool?) ?? false;
          final oldDelta = (dSnap.data()?['deltaMinutes'] as int?) ?? 0;
          final oldBalance = (mSnap.data()?['balanceMinutes'] as int?) ?? 0;

          final newDelta = isClosed
              ? (workedMinutes - workloadMinutes)
              : oldDelta;
          final diff = newDelta - oldDelta;

          tx.set(refDia, {'abonoMinutes': null}, SetOptions(merge: true));

          if (isClosed && diff != 0) {
            tx.set(refMes, {
              'balanceMinutes': oldBalance + diff,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        });
      }
    }

    await _ref.doc(justificativaId).delete();
  }
}
