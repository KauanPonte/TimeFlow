import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';

class AbonoRepository {
  static const String _collection = 'abonos';
  static const String _pontosCollection = 'pontos';

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection(_collection);

  // ─── Funcionário ────────────────────────────────────────────────────────────

  /// Funcionário solicita abono. Fica pendente até o admin aprovar.
  Future<void> requestAbono({
    required String diaId,
    required String observacao,
    String? dataInicio,
    String? dataFim,
    int? abonoMinutes,
    bool isFullDay = false,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Não autenticado');

    // Bloqueia qualquer abono duplicado no mesmo dia (pendente ou aprovado)
    final existing = await _ref
        .where('uid', isEqualTo: user.uid)
        .where('diaId', isEqualTo: diaId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final status = (existing.docs.first.data()['status'] ?? '').toString();
      if (status == 'approved') {
        throw Exception('Já existe um abono aprovado para este dia.');
      }
      throw Exception('Já existe um pedido de abono para este dia.');
    }

    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final employeeName = (userSnap.data()?['name'] ?? '').toString();

    String? fileUrl;
    if (fileName != null && fileBytes != null) {
      final ref = FirebaseStorage.instance
          .ref('abonos/${user.uid}/$diaId/$fileName');
      await ref.putData(fileBytes);
      fileUrl = await ref.getDownloadURL();
    }

    await _ref.add({
      'uid': user.uid,
      'employeeName': employeeName,
      'diaId': diaId,
      'status': 'pending',
      'abonoMinutes': abonoMinutes ?? 0,
      'isFullDay': isFullDay,
      'observacao': observacao,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'createdAt': Timestamp.fromDate(ServerTimeService.nowUtc()),
      'resolvedAt': null,
      'resolvedBy': null,
      'rejectionReason': null,
      'seenByEmployee': false,
    });
  }

  /// Funcionário busca os próprios abonos.
  Future<List<AbonoModel>> getMyAbonos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _ref
        .where('uid', isEqualTo: user.uid)
        .get();
    final list = snap.docs.map((d) => AbonoModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Funcionário marca abono como visto.
  Future<void> markSeenByEmployee(String abonoId) async {
    try {
      await _ref.doc(abonoId).update({'seenByEmployee': true});
    } catch (_) {}
  }

  // ─── Admin ───────────────────────────────────────────────────────────────────

  /// Admin aplica abono diretamente (sem fluxo de pedido), já aprovado.
  /// Usado tanto para funcionários quanto para o próprio admin —
  /// nesse caso nunca passa pelo fluxo de pedido/aprovação.
  Future<void> adminApplyAbono({
    required String uid,
    required String diaId,
    required bool isFullDay,
    required String observacao,
    // Usados quando o próprio admin aplica para si via tela de solicitação
    int? abonoMinutesOverride,
    String? dataInicio,
    String? dataFim,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    final workloadMinutes = (userSnap.data()?['workloadMinutes'] as int?) ??
        (userSnap.data()?['cargaHorariaMinutos'] as int?) ??
        480;
    final employeeName = (userSnap.data()?['name'] ?? '').toString();

    final refDia = FirebaseFirestore.instance
        .collection(_pontosCollection)
        .doc(uid)
        .collection('dias')
        .doc(diaId);

    final diaSnap = await refDia.get();
    final workedMinutes = (diaSnap.data()?['workedMinutes'] as int?) ?? 0;

    // Se a tela passou um valor calculado, usa ele; senão calcula internamente
    final abonoMinutes = abonoMinutesOverride ??
        (isFullDay
            ? workloadMinutes
            : (workloadMinutes - workedMinutes).clamp(0, workloadMinutes));

    if (abonoMinutes > 0) {
      await _applyAbonoToDay(
        uid: uid,
        diaId: diaId,
        abonoMinutes: abonoMinutes,
        targetMinutes: workloadMinutes,
      );
    }

    // Faz upload do PDF se o admin enviou um documento
    String? fileUrl;
    if (fileName != null && fileBytes != null) {
      final ref = FirebaseStorage.instance
          .ref('abonos/$uid/$diaId/$fileName');
      await ref.putData(fileBytes);
      fileUrl = await ref.getDownloadURL();
    }

    final existing = await _ref
        .where('uid', isEqualTo: uid)
        .where('diaId', isEqualTo: diaId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'observacao': observacao,
        'status': 'approved',
        'abonoMinutes': abonoMinutes,
        'isFullDay': isFullDay,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        if (fileUrl != null) 'fileName': fileName,
        if (fileUrl != null) 'fileUrl': fileUrl,
        'resolvedAt': Timestamp.now(),
        'resolvedBy': admin.uid,
        'rejectionReason': null,
      });
    } else {
      await _ref.add({
        'uid': uid,
        'employeeName': employeeName,
        'diaId': diaId,
        'status': 'approved',
        'abonoMinutes': abonoMinutes,
        'isFullDay': isFullDay,
        'observacao': observacao,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'fileName': fileUrl != null ? fileName : null,
        'fileUrl': fileUrl,
        'createdAt': Timestamp.fromDate(ServerTimeService.nowUtc()),
        'resolvedAt': Timestamp.now(),
        'resolvedBy': admin.uid,
        'rejectionReason': null,
        'seenByEmployee': false,
      });
    }
  }

  /// Admin aprova pedido pendente de um funcionário.
  Future<void> approveAbono(String abonoId) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    final doc = await _ref.doc(abonoId).get();
    final model = AbonoModel.fromDoc(doc);

    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(model.uid)
        .get();
    final workloadMinutes = (userSnap.data()?['workloadMinutes'] as int?) ??
        (userSnap.data()?['cargaHorariaMinutos'] as int?) ??
        480;

    int abonoToApply = model.abonoMinutes;
    if (model.isFullDay) abonoToApply = workloadMinutes;

    if (abonoToApply > 0) {
      await _applyAbonoToDay(
        uid: model.uid,
        diaId: model.diaId,
        abonoMinutes: abonoToApply,
        targetMinutes: workloadMinutes,
      );
    }

    await _ref.doc(abonoId).update({
      'status': 'approved',
      'abonoMinutes': abonoToApply,
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
      'rejectionReason': null,
    });
  }

  /// Admin recusa pedido com motivo opcional.
  Future<void> rejectAbono(String abonoId, {String? reason}) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) throw Exception('Não autenticado');

    await _ref.doc(abonoId).update({
      'status': 'rejected',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin.uid,
      'rejectionReason': reason,
    });
  }

  /// Admin busca todos os pedidos pendentes.
  Future<List<AbonoModel>> getPendingAbonos() async {
    final snap = await _ref.where('status', isEqualTo: 'pending').get();
    final list = snap.docs.map((d) => AbonoModel.fromDoc(d)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Stream em tempo real de abonos pendentes (admin dashboard).
  Stream<List<AbonoModel>> streamPendingAbonos() {
    return _ref.where('status', isEqualTo: 'pending').snapshots().map((snap) {
      final list = snap.docs.map((d) => AbonoModel.fromDoc(d)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Admin busca todos os abonos de um funcionário específico.
  Future<List<AbonoModel>> getAbonosForEmployee(String uid) async {
    final snap = await _ref.where('uid', isEqualTo: uid).get();
    final list = snap.docs.map((d) => AbonoModel.fromDoc(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Apaga o abono e reverte o crédito de horas se estava aprovado.
  Future<void> deleteAbono(String abonoId) async {
    final doc = await _ref.doc(abonoId).get();
    if (!doc.exists) return;
    final model = AbonoModel.fromDoc(doc);

    if (model.status == AbonoStatus.approved && model.abonoMinutes > 0) {
      final refDia = FirebaseFirestore.instance
          .collection(_pontosCollection)
          .doc(model.uid)
          .collection('dias')
          .doc(model.diaId);
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
      final workloadMinutes = (userSnap.data()?['workloadMinutes'] as int?) ??
          (userSnap.data()?['cargaHorariaMinutos'] as int?) ??
          480;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final dSnap = await tx.get(refDia);
        final mSnap = await tx.get(refMes);

        final workedMinutes = (dSnap.data()?['workedMinutes'] as int?) ?? 0;
        final isClosed = (dSnap.data()?['isClosed'] as bool?) ?? false;
        final oldDelta = (dSnap.data()?['deltaMinutes'] as int?) ?? 0;
        final oldBalance = (mSnap.data()?['balanceMinutes'] as int?) ?? 0;

        final newDelta =
            isClosed ? (workedMinutes - workloadMinutes) : oldDelta;
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

    await _ref.doc(abonoId).delete();
  }

  // ─── Interno ────────────────────────────────────────────────────────────────

  /// Grava `abonoMinutes` no dia e recalcula `deltaMinutes` e saldo mensal
  /// se o dia já estiver fechado (isClosed = true).
  Future<void> _applyAbonoToDay({
    required String uid,
    required String diaId,
    required int abonoMinutes,
    required int targetMinutes,
  }) async {
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

      final newDelta = isClosed
          ? (workedMinutes + abonoMinutes - targetMinutes)
          : oldDelta;
      final diff = newDelta - oldDelta;

      tx.set(refDia, {
        'abonoMinutes': abonoMinutes,
        if (isClosed) 'deltaMinutes': newDelta,
      }, SetOptions(merge: true));

      if (isClosed && diff != 0) {
        tx.set(refMes, {
          'balanceMinutes': oldBalance + diff,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }
}
