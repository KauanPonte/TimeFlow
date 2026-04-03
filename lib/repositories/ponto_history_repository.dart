import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_appdeponto/services/ponto_validator.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';

class PontoHistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _root = 'pontos';

  /// Carrega todos os dias com eventos para o uid informado (ou o logado).
  /// Retorna lista ordenada por data decrescente.
  /// Cada item: { diaId, eventos: [ { id, tipo, at (DateTime) } ] }
  Future<List<Map<String, dynamic>>> loadAllDays({String? uid}) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final diasSnap = await _firestore
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .orderBy('date', descending: true)
        .get();

    final result = <Map<String, dynamic>>[];

    for (final diaDoc in diasSnap.docs) {
      final diaId = diaDoc.id;
      final eventos = _extractEventos(diaDoc);

      if (eventos.isNotEmpty) {
        result.add({'diaId': diaId, 'eventos': eventos});
      }
    }

    return result;
  }

  /// Carrega apenas os dias de um mês específico.
  /// Retorna mapa de diaId → eventos para merge na UI.
  ///
  /// lê `eventosCache` direto do doc do dia (1 query),
  /// sem subcollection extra. Fallback para subcollection se `eventosCache`
  /// estiver ausente (dados antigos).
  Future<Map<String, List<Map<String, dynamic>>>> loadDaysByMonth({
    String? uid,
    required int year,
    required int month,
  }) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final startId = '$prefix-01';
    final endId = '$prefix-32'; // 32 garante pegar todos os dias do mês

    final diasSnap = await _firestore
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .orderBy('date', descending: true)
        .get();

    final result = <String, List<Map<String, dynamic>>>{};

    // Coleta dias que precisam de fallback (sem eventosCache)
    final fallbackDays = <String>[];

    for (final diaDoc in diasSnap.docs) {
      final diaId = diaDoc.id;
      final data = diaDoc.data();
      final cache = data['eventosCache'];

      if (cache is List && cache.isNotEmpty) {
        // Lê direto do cache inline — sem query extra
        final eventos = cache.map<Map<String, dynamic>>((e) {
          final m = e as Map<String, dynamic>;
          final ts = m['at'] as Timestamp?;
          return {
            'id': (m['id'] ?? '').toString(),
            'tipo': (m['tipo'] ?? '').toString(),
            'at': ts?.toDate(),
            'workMode': (m['workMode'] ?? '').toString(),
            'origin': (m['origin'] ?? 'registrado').toString(),
          };
        }).toList();
        if (eventos.isNotEmpty) {
          result[diaId] = eventos;
        }
      } else {
        // Dados antigos sem cache — marca para fallback
        fallbackDays.add(diaId);
      }
    }

    // Fallback: busca subcollection apenas para dias sem cache
    if (fallbackDays.isNotEmpty) {
      // Paraleliza as queries de fallback para minimizar latência
      final futures = fallbackDays.map((diaId) async {
        final eventosSnap = await _firestore
            .collection(_root)
            .doc(uid)
            .collection('dias')
            .doc(diaId)
            .collection('eventos')
            .orderBy('at', descending: false)
            .get();

        final eventos = eventosSnap.docs.map((e) {
          final data = e.data();
          final ts = data['at'] as Timestamp?;
          return {
            'id': e.id,
            'tipo': (data['tipo'] ?? '').toString(),
            'at': ts?.toDate(),
            'workMode': (data['workMode'] ?? '').toString(),
            'origin': (data['origin'] ?? 'registrado').toString(),
          };
        }).toList();

        if (eventos.isNotEmpty) {
          result[diaId] = eventos;
        }
      });
      await Future.wait(futures);
    }

    return result;
  }

  /// Tenta extrair eventos do `eventosCache` inline.
  /// Retorna lista tipada pronta para a UI.
  List<Map<String, dynamic>> _extractEventos(
      DocumentSnapshot<Map<String, dynamic>> diaDoc) {
    final data = diaDoc.data();
    if (data == null) return [];

    final cache = data['eventosCache'];
    if (cache is List && cache.isNotEmpty) {
      return cache.map<Map<String, dynamic>>((e) {
        final m = e as Map<String, dynamic>;
        final ts = m['at'] as Timestamp?;
        return {
          'id': (m['id'] ?? '').toString(),
          'tipo': (m['tipo'] ?? '').toString(),
          'at': ts?.toDate(),
          'workMode': (m['workMode'] ?? '').toString(),
          'origin': (m['origin'] ?? 'registrado').toString(),
        };
      }).toList();
    }
    return [];
  }

  /// Adiciona um evento de ponto para um usuário específico.
  Future<void> addEvento({
    required String uid,
    required String diaId,
    required String tipo,
    required DateTime horario,
  }) async {
    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);

    final refEventos = refDia.collection('eventos');
    final ts = Timestamp.fromDate(horario);

    // Carrega eventos existentes para validar a sequência
    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventosExistentes = eventosSnap.docs.map((e) {
      final data = e.data();
      final evTs = data['at'] as Timestamp?;
      return {
        'id': e.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': evTs?.toDate(),
      };
    }).toList();

    final erro = PontoValidator.validarNovoEvento(
      eventosExistentes: eventosExistentes,
      novoTipo: tipo,
      novoHorario: horario,
    );
    if (erro != null) throw Exception(erro);

    final diaSnap = await refDia.get();
    if (!diaSnap.exists) {
      await refDia.set({
        'uid': uid,
        'date': diaId,
        'createdAt': ts,
        'updatedAt': ts,
        'lastTipo': tipo,
        'lastAt': ts,
      });
    }

    await refEventos.add({
      'tipo': tipo,
      'at': ts,
      'origin': 'ajustado',
    });
    await _updateDayMeta(uid: uid, diaId: diaId);
  }

  /// Edita um evento existente.
  Future<void> updateEvento({
    required String uid,
    required String diaId,
    required String eventoId,
    required String tipo,
    required DateTime horario,
  }) async {
    final refEventos = _firestore
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .doc(diaId)
        .collection('eventos');

    // Carrega eventos existentes para validar a sequência após edição
    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventosExistentes = eventosSnap.docs.map((e) {
      final data = e.data();
      final evTs = data['at'] as Timestamp?;
      return {
        'id': e.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': evTs?.toDate(),
      };
    }).toList();

    final erro = PontoValidator.validarEdicaoEvento(
      eventosExistentes: eventosExistentes,
      eventoId: eventoId,
      novoTipo: tipo,
      novoHorario: horario,
    );
    if (erro != null) throw Exception(erro);

    final ts = Timestamp.fromDate(horario);

    await refEventos.doc(eventoId).update({
      'tipo': tipo,
      'at': ts,
      'origin': 'ajustado',
    });

    await _updateDayMeta(uid: uid, diaId: diaId);
  }

  /// Remove um evento.
  Future<void> deleteEvento({
    required String uid,
    required String diaId,
    required String eventoId,
  }) async {
    final refEventos = _firestore
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .doc(diaId)
        .collection('eventos');

    // Carrega eventos existentes para validar a sequência após remoção
    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventosExistentes = eventosSnap.docs.map((e) {
      final data = e.data();
      final evTs = data['at'] as Timestamp?;
      return {
        'id': e.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': evTs?.toDate(),
      };
    }).toList();

    final erro = PontoValidator.validarExclusaoEvento(
      eventosExistentes: eventosExistentes,
      eventoId: eventoId,
    );
    if (erro != null) throw Exception(erro);

    await refEventos.doc(eventoId).delete();

    // Verifica se ainda há eventos no dia
    final remaining = await refEventos.get();

    if (remaining.docs.isEmpty) {
      // Remove o documento do dia se não há mais eventos
      await _firestore
          .collection(_root)
          .doc(uid)
          .collection('dias')
          .doc(diaId)
          .delete();
    } else {
      await _updateDayMeta(uid: uid, diaId: diaId);
    }
  }

  /// Atualiza metadados do dia (lastTipo, lastAt, etc.),
  /// recalcula banco de horas, e **atualiza `eventosCache`**.
  Future<void> _updateDayMeta({
    required String uid,
    required String diaId,
  }) async {
    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);

    final refEventos = refDia.collection('eventos');
    const targetMinutesPerDay = 8 * 60;

    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventos = eventosSnap.docs.map((d) => d.data()).toList();

    if (eventos.isEmpty) return;

    final lastEvento = eventos.last;
    final lastTipo = (lastEvento['tipo'] ?? '').toString();
    final lastAt = lastEvento['at'] as Timestamp?;

    // Calcula minutos trabalhados (só intervalos fechados)
    final workedMinutes = _computeWorkedMinutes(eventos);
    final diaFechado = lastTipo == 'saida';
    final hojeId = ServerTimeService.todayId();
    final ehHoje = diaId == hojeId;
    final falta = !ehHoje && eventos.isEmpty;
    final deltaMinutes = falta
        ? -targetMinutesPerDay
        : (diaFechado ? (workedMinutes - targetMinutesPerDay) : 0);

    // Constrói array de cache para denormalização
    final eventosCache = eventosSnap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': data['at'],
        'workMode': (data['workMode'] ?? '').toString(),
        'origin': (data['origin'] ?? 'registrado').toString(),
      };
    }).toList();

    final mesId = diaId.substring(0, 7);
    final refMes =
        _firestore.collection(_root).doc(uid).collection('meses').doc(mesId);

    await _firestore.runTransaction((tx) async {
      final diaSnap = await tx.get(refDia);
      final mesSnap = await tx.get(refMes);

      final oldDelta = (diaSnap.data()?['deltaMinutes'] as int?) ?? 0;
      final oldBalance = (mesSnap.data()?['balanceMinutes'] as int?) ?? 0;

      final diff = deltaMinutes - oldDelta;
      final newBalance = oldBalance + diff;

      tx.set(
          refDia,
          {
            'updatedAt': FieldValue.serverTimestamp(),
            'lastTipo': lastTipo,
            'lastAt': lastAt,
            'workedMinutes': workedMinutes,
            'deltaMinutes': deltaMinutes,
            'isClosed': diaFechado,
            'eventosCache': eventosCache,
          },
          SetOptions(merge: true));

      tx.set(
          refMes,
          {
            'balanceMinutes': newBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
  }

  int _computeWorkedMinutes(List<Map<String, dynamic>> eventos) {
    DateTime? openWork;
    Duration total = Duration.zero;

    for (final ev in eventos) {
      final tipo = (ev['tipo'] ?? '').toString();
      final ts = ev['at'];
      final at = ts is Timestamp ? ts.toDate() : null;
      if (at == null) continue;

      if (tipo == 'entrada' || tipo == 'retorno') {
        openWork ??= at;
      } else if (tipo == 'pausa' || tipo == 'saida') {
        if (openWork != null && at.isAfter(openWork)) {
          total += at.difference(openWork);
        }
        openWork = null;
      }
    }
    return total.inMinutes;
  }

  /// Aplica edições, adições e exclusões em lote para um dia.
  Future<void> batchUpdateDay({
    required String uid,
    required String diaId,
    required List<Map<String, dynamic>> updates,
    required List<String> deletes,
    required List<Map<String, dynamic>> adds,
  }) async {
    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);
    final refEventos = refDia.collection('eventos');

    // 1. Carrega eventos existentes para simular o estado final e validar.
    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventosExistentes = eventosSnap.docs.map((e) {
      final data = e.data();
      final evTs = data['at'] as Timestamp?;
      return {
        'id': e.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': evTs?.toDate(),
      };
    }).toList();

    // 2. Simula o estado final para validação.
    final estadoFinal = <Map<String, dynamic>>[];
    final updateMap = <String, Map<String, dynamic>>{};
    for (final u in updates) {
      updateMap[u['id'] as String] = u;
    }
    final deleteSet = deletes.toSet();

    for (final ev in eventosExistentes) {
      final id = ev['id'] as String;
      if (deleteSet.contains(id)) continue;
      if (updateMap.containsKey(id)) {
        estadoFinal.add({
          'id': id,
          'tipo': updateMap[id]!['tipo'],
          'at': updateMap[id]!['horario'],
        });
      } else {
        estadoFinal.add(ev);
      }
    }
    for (final a in adds) {
      estadoFinal.add({
        'tipo': a['tipo'],
        'at': a['horario'],
      });
    }

    // Validação da sequência final
    if (estadoFinal.isNotEmpty) {
      final error = PontoValidator.validarSequenciaCompleta(estadoFinal);
      if (error != null) throw Exception(error);
    }

    // 3. Executa todas as operações.
    // Exclusões
    for (final id in deletes) {
      await refEventos.doc(id).delete();
    }

    // Atualizações
    for (final u in updates) {
      final ts = Timestamp.fromDate(u['horario'] as DateTime);
      await refEventos.doc(u['id'] as String).update({
        'tipo': u['tipo'],
        'at': ts,
        'origin': 'ajustado',
      });
    }

    // Adições
    for (final a in adds) {
      final ts = Timestamp.fromDate(a['horario'] as DateTime);
      await refEventos.add({
        'tipo': a['tipo'] as String,
        'at': ts,
        'origin': 'ajustado',
      });
    }

    // 4. Verifica se ainda há eventos no dia.
    final remaining = await refEventos.get();
    if (remaining.docs.isEmpty) {
      await refDia.delete();
    } else {
      // Cria o doc do dia se necessário (pode ser dia novo).
      final diaSnap = await refDia.get();
      if (!diaSnap.exists) {
        await refDia.set({
          'uid': uid,
          'date': diaId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await _updateDayMeta(uid: uid, diaId: diaId);
    }
  }
}
