import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_appdeponto/services/ponto_validator.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
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

    final resolvedUid = uid;

    final diasSnap = await _firestore
        .collection(_root)
        .doc(resolvedUid)
        .collection('dias')
        .orderBy('date', descending: true)
        .get();

    final result = <Map<String, dynamic>>[];

    for (final diaDoc in diasSnap.docs) {
      final diaId = diaDoc.id;
      var eventos = _extractEventos(diaDoc);

      // Fallback: se não há cache, busca da subcollection
      if (eventos.isEmpty) {
        final eventosSnap = await _firestore
            .collection(_root)
            .doc(resolvedUid)
            .collection('dias')
            .doc(diaId)
            .collection('eventos')
            .orderBy('at', descending: false)
            .get();

        eventos = eventosSnap.docs.map((e) {
          final data = e.data();
          final ts = data['at'] as Timestamp?;
          return {
            'id': e.id,
            'tipo': (data['tipo'] ?? '').toString(),
            'at': ServerTimeService.timestampToBrazil(ts),
            'workMode': (data['workMode'] ?? '').toString(),
            'origin': (data['origin'] ?? 'registrado').toString(),
          };
        }).toList();
      }

      if (eventos.isNotEmpty) {
        result.add({'diaId': diaId, 'eventos': eventos});
      }
    }

    return result;
  }

  /// Carrega os eventos de um dia específico.
  ///
  /// Lê o doc do dia do cache local primeiro (instantâneo) — só é chamado
  /// após um write, então o cache já reflete a alteração. Cai para o servidor
  /// apenas se o doc não estiver em cache.
  Future<List<Map<String, dynamic>>> loadEventsForDay(
      String uid, String diaId) async {
    final diaRef = _firestore
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .doc(diaId);

    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await diaRef.get(const GetOptions(source: Source.cache));
    } catch (_) {
      // Doc ausente do cache — busca no servidor como fallback.
      doc = await diaRef.get();
    }

    if (!doc.exists) return [];

    final cached = _extractEventos(doc);
    if (cached.isNotEmpty) return cached;

    final eventosSnap = await diaRef
        .collection('eventos')
        .orderBy('at', descending: false)
        .get();

    return eventosSnap.docs.map((e) {
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

    final resolvedUid = uid;

    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

    final monthDocsSnap = await _firestore
        .collection(_root)
        .doc(resolvedUid)
        .collection('dias')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$prefix-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$prefix-31')
        .get();

    final monthDocs = monthDocsSnap.docs;
    final result = <String, List<Map<String, dynamic>>>{};

    // Processa todos os dias em PARALELO (antes era sequencial = lento)
    final futures = monthDocs.map((diaDoc) async {
      final diaId = diaDoc.id;
      final data = diaDoc.data();
      final cache = data['eventosCache'];

      // Tenta usar cache inline primeiro (evita query extra)
      if (cache is List && cache.isNotEmpty) {
        final rawCache = List<dynamic>.from(cache);
        if (_isEventosCacheConsistent(data, rawCache)) {
          final eventos = rawCache.map<Map<String, dynamic>>((e) {
            final m = e as Map<String, dynamic>;
            final ts = m['at'] as Timestamp?;
            return {
              'id': (m['id'] ?? '').toString(),
              'tipo': (m['tipo'] ?? '').toString(),
              'at': ServerTimeService.timestampToBrazil(ts),
              'workMode': (m['workMode'] ?? '').toString(),
              'origin': (m['origin'] ?? 'registrado').toString(),
            };
          }).toList();
          if (eventos.isNotEmpty) {
            result[diaId] = eventos;
          }
          return;
        }
      }

      // Sem cache → busca da subcollection (paralelizado)
      final eventosSnap = await _firestore
          .collection(_root)
          .doc(resolvedUid)
          .collection('dias')
          .doc(diaId)
          .collection('eventos')
          .orderBy('at', descending: false)
          .get();

      final eventos = eventosSnap.docs.map((e) {
        final evData = e.data();
        final ts = evData['at'] as Timestamp?;
        return {
          'id': e.id,
          'tipo': (evData['tipo'] ?? '').toString(),
          'at': ts?.toDate(),
          'workMode': (evData['workMode'] ?? '').toString(),
          'origin': (evData['origin'] ?? 'registrado').toString(),
        };
      }).toList();

      if (eventos.isNotEmpty) {
        result[diaId] = eventos;
      }
    });

    await Future.wait(futures);

    return result;
  }

  /// Stream reativo do mês — emite do cache local imediatamente, depois da rede.
  /// Qualquer write em qualquer doc do mês (de qualquer dispositivo) dispara nova emissão.
  Stream<Map<String, List<Map<String, dynamic>>>> streamDaysByMonth({
    required String uid,
    required int year,
    required int month,
  }) {
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

    return _firestore
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$prefix-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$prefix-31')
        .snapshots()
        .asyncMap((querySnap) async {
      final result = <String, List<Map<String, dynamic>>>{};

      await Future.wait(querySnap.docs.map((diaDoc) async {
        final diaId = diaDoc.id;
        final data = diaDoc.data();
        final cache = data['eventosCache'];

        if (cache is List && cache.isNotEmpty) {
          final rawCache = List<dynamic>.from(cache);
          if (_isEventosCacheConsistent(data, rawCache)) {
            final eventos = rawCache.map<Map<String, dynamic>>((e) {
              final m = e as Map<String, dynamic>;
              final ts = m['at'] as Timestamp?;
              return {
                'id': (m['id'] ?? '').toString(),
                'tipo': (m['tipo'] ?? '').toString(),
                'at': ServerTimeService.timestampToBrazil(ts),
                'workMode': (m['workMode'] ?? '').toString(),
                'origin': (m['origin'] ?? 'registrado').toString(),
              };
            }).toList();
            if (eventos.isNotEmpty) result[diaId] = eventos;
            return;
          }
        }

        // Fallback para dados legados sem cache (paralelizado)
        final eventosSnap = await _firestore
            .collection(_root)
            .doc(uid)
            .collection('dias')
            .doc(diaId)
            .collection('eventos')
            .orderBy('at', descending: false)
            .get();

        final eventos = eventosSnap.docs.map((e) {
          final evData = e.data();
          final ts = evData['at'] as Timestamp?;
          return {
            'id': e.id,
            'tipo': (evData['tipo'] ?? '').toString(),
            'at': ServerTimeService.timestampToBrazil(ts),
            'workMode': (evData['workMode'] ?? '').toString(),
            'origin': (evData['origin'] ?? 'registrado').toString(),
          };
        }).toList();

        if (eventos.isNotEmpty) result[diaId] = eventos;
      }));

      return result;
    });
  }

  /// Tenta extrair eventos do `eventosCache` inline.
  /// Retorna lista tipada pronta para a UI.
  List<Map<String, dynamic>> _extractEventos(
      DocumentSnapshot<Map<String, dynamic>> diaDoc) {
    final data = diaDoc.data();
    if (data == null) return [];

    final cache = data['eventosCache'];
    if (cache is List && cache.isNotEmpty) {
      final rawCache = List<dynamic>.from(cache);
      if (!_isEventosCacheConsistent(data, rawCache)) return [];

      return rawCache.map<Map<String, dynamic>>((e) {
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

  /// Detecta cache do dia possivelmente obsoleto (ex: evento removido, mas
  /// `eventosCache` ainda mantém o último tipo antigo).
  bool _isEventosCacheConsistent(
    Map<String, dynamic> dayData,
    List<dynamic> rawCache,
  ) {
    final normalized = rawCache.whereType<Map<String, dynamic>>().toList();
    if (normalized.isEmpty) return true;

    final lastCache = normalized.last;
    final cacheLastTipo = (lastCache['tipo'] ?? '').toString();
    final cacheIsClosed = cacheLastTipo == 'saida';

    final bool? docIsClosed = dayData['isClosed'] as bool?;
    if (docIsClosed != null && docIsClosed != cacheIsClosed) {
      return false;
    }

    final docLastTipo = (dayData['lastTipo'] ?? '').toString();
    if (docLastTipo.isNotEmpty &&
        cacheLastTipo.isNotEmpty &&
        docLastTipo != cacheLastTipo) {
      return false;
    }

    return true;
  }

  //  Edição de ponto — local-first
  //
  //  Lê o estado do dia do cache local (instantâneo), valida no cliente e
  //  persiste via WriteBatch. O cache local é atualizado na hora e o stream
  //  streamDaysByMonth emite imediatamente; o commit sincroniza com o
  //  servidor em background. Substitui o antigo runTransaction.

  /// Estado do dia lido do cache local: `eventosCache` cru (`at` como
  /// Timestamp), se o doc do dia existe, e o delta atual do dia.
  Future<({List<Map<String, dynamic>> cache, bool dayExists, int oldDelta})>
      _loadDayCache(String uid, String diaId) async {
    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);

    DocumentSnapshot<Map<String, dynamic>> diaSnap;
    try {
      diaSnap = await refDia.get(const GetOptions(source: Source.cache));
    } catch (_) {
      diaSnap = await refDia.get();
    }

    if (!diaSnap.exists) {
      return (cache: <Map<String, dynamic>>[], dayExists: false, oldDelta: 0);
    }

    final data = diaSnap.data() ?? {};
    final oldDelta = (data['deltaMinutes'] as int?) ?? 0;
    final raw = data['eventosCache'];

    if (raw is List && raw.isNotEmpty) {
      return (cache: _rawCacheList(raw), dayExists: true, oldDelta: oldDelta);
    }

    // Dado legado sem eventosCache → busca a subcoleção no servidor (1x).
    final eventosSnap = await refDia
        .collection('eventos')
        .orderBy('at', descending: false)
        .get();
    final cache = eventosSnap.docs.map((d) {
      final ev = d.data();
      return <String, dynamic>{
        'id': d.id,
        'tipo': (ev['tipo'] ?? '').toString(),
        'at': ev['at'],
        'workMode': (ev['workMode'] ?? '').toString(),
        'origin': (ev['origin'] ?? 'registrado').toString(),
      };
    }).toList();
    return (cache: cache, dayExists: true, oldDelta: oldDelta);
  }

  /// Normaliza o array `eventosCache` cru mantendo `at` como Timestamp.
  List<Map<String, dynamic>> _rawCacheList(List<dynamic> raw) {
    return raw.whereType<Map<String, dynamic>>().map((m) {
      return <String, dynamic>{
        'id': (m['id'] ?? '').toString(),
        'tipo': (m['tipo'] ?? '').toString(),
        'at': m['at'],
        'workMode': (m['workMode'] ?? '').toString(),
        'origin': (m['origin'] ?? 'registrado').toString(),
      };
    }).toList();
  }

  /// Converte o cache para o formato do PontoValidator
  /// (`at` como DateTime no fuso de Brasília).
  List<Map<String, dynamic>> _toValidatorInput(
      List<Map<String, dynamic>> cache) {
    return cache.map((m) {
      final ts = m['at'];
      return <String, dynamic>{
        'id': m['id'],
        'tipo': m['tipo'],
        'at': ts is Timestamp ? ServerTimeService.timestampToBrazil(ts) : null,
      };
    }).toList();
  }

  /// Ordena o cache por horário (ascendente).
  void _sortCache(List<Map<String, dynamic>> cache) {
    cache.sort((a, b) {
      final ta = a['at'];
      final tb = b['at'];
      if (ta is Timestamp && tb is Timestamp) return ta.compareTo(tb);
      return 0;
    });
  }

  /// Dispara o commit do batch sem aguardar — o cache local já foi atualizado.
  void _commitLocalFirst(WriteBatch batch) {
    unawaited(batch.commit().catchError((_) {
      // Falha de sincronização: o SDK re-tenta sozinho. Offline, o write
      // fica na fila e sincroniza ao reconectar.
    }));
  }

  /// Adiciona ao [batch] a atualização do saldo do mês do [diaId].
  void _writeMonthBalance(
      WriteBatch batch, String uid, String diaId, int balanceDiff) {
    final refMes = _firestore
        .collection(_root)
        .doc(uid)
        .collection('meses')
        .doc(diaId.substring(0, 7));
    batch.set(
      refMes,
      {
        // increment é atômico no servidor — seguro mesmo com edições simultâneas.
        'balanceMinutes': FieldValue.increment(balanceDiff),
        'updatedAt': FieldValue.serverTimestamp(),
        'summaryCache': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }

  /// Adiciona ao [batch] a escrita de metadados do dia (eventosCache,
  /// lastTipo, workedMinutes, deltaMinutes, isClosed) e do saldo do mês, e
  /// dispara o commit. [novoCache] deve estar ordenado e não-vazio.
  void _finalizeDayEdit({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> refDia,
    required String uid,
    required String diaId,
    required List<Map<String, dynamic>> novoCache,
    required bool dayExisted,
    required int oldDelta,
  }) {
    const targetMinutesPerDay = 8 * 60;

    final lastEvento = novoCache.last;
    final lastTipo = (lastEvento['tipo'] ?? '').toString();
    final lastAt = lastEvento['at'];
    final diaFechado = lastTipo == 'saida';
    final workedMinutes = _computeWorkedMinutes(novoCache);
    final deltaMinutes =
        diaFechado ? (workedMinutes - targetMinutesPerDay) : 0;
    final balanceDiff = deltaMinutes - oldDelta;

    final diaUpdate = <String, dynamic>{
      'uid': uid,
      'date': diaId,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastTipo': lastTipo,
      'lastAt': lastAt,
      'workedMinutes': workedMinutes,
      'deltaMinutes': deltaMinutes,
      'isClosed': diaFechado,
      'eventosCache': novoCache,
    };
    if (!dayExisted) diaUpdate['createdAt'] = FieldValue.serverTimestamp();

    batch.set(refDia, diaUpdate, SetOptions(merge: true));
    _writeMonthBalance(batch, uid, diaId, balanceDiff);
    _commitLocalFirst(batch);
  }

  /// Adiciona um evento de ponto para um usuário específico.
  Future<void> addEvento({
    required String uid,
    required String diaId,
    required String tipo,
    required DateTime horario,
  }) async {
    // Bloqueia adição em feriados/recessos (mesmo para admin).
    final date = DateTime.tryParse(diaId);
    if (date != null && await PontoService.isFeriado(date, preferCache: true)) {
      throw Exception(
          'Este dia é feriado/recesso. Não é permitido adicionar pontos.');
    }

    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);
    final refEventos = refDia.collection('eventos');
    final ts = Timestamp.fromDate(horario);

    final estado = await _loadDayCache(uid, diaId);

    final erro = PontoValidator.validarNovoEvento(
      eventosExistentes: _toValidatorInput(estado.cache),
      novoTipo: tipo,
      novoHorario: horario,
    );
    if (erro != null) throw Exception(erro);

    final eventId = refEventos.doc().id;
    final novoCache = [
      ...estado.cache,
      <String, dynamic>{
        'id': eventId,
        'tipo': tipo,
        'at': ts,
        'workMode': '',
        'origin': 'ajustado',
      },
    ];
    _sortCache(novoCache);

    final batch = _firestore.batch();
    batch.set(refEventos.doc(eventId), {
      'tipo': tipo,
      'at': ts,
      'origin': 'ajustado',
    });
    _finalizeDayEdit(
      batch: batch,
      refDia: refDia,
      uid: uid,
      diaId: diaId,
      novoCache: novoCache,
      dayExisted: estado.dayExists,
      oldDelta: estado.oldDelta,
    );
  }

  /// Edita um evento existente.
  Future<void> updateEvento({
    required String uid,
    required String diaId,
    required String eventoId,
    required String tipo,
    required DateTime horario,
  }) async {
    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);
    final refEventos = refDia.collection('eventos');
    final ts = Timestamp.fromDate(horario);

    final estado = await _loadDayCache(uid, diaId);

    final erro = PontoValidator.validarEdicaoEvento(
      eventosExistentes: _toValidatorInput(estado.cache),
      eventoId: eventoId,
      novoTipo: tipo,
      novoHorario: horario,
    );
    if (erro != null) throw Exception(erro);

    final novoCache = estado.cache.map((m) {
      if (m['id'] == eventoId) {
        return <String, dynamic>{
          ...m,
          'tipo': tipo,
          'at': ts,
          'origin': 'ajustado',
        };
      }
      return m;
    }).toList();
    _sortCache(novoCache);

    final batch = _firestore.batch();
    batch.update(refEventos.doc(eventoId), {
      'tipo': tipo,
      'at': ts,
      'origin': 'ajustado',
    });
    _finalizeDayEdit(
      batch: batch,
      refDia: refDia,
      uid: uid,
      diaId: diaId,
      novoCache: novoCache,
      dayExisted: true,
      oldDelta: estado.oldDelta,
    );
  }

  /// Remove um evento.
  Future<void> deleteEvento({
    required String uid,
    required String diaId,
    required String eventoId,
  }) async {
    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);
    final refEventos = refDia.collection('eventos');

    final estado = await _loadDayCache(uid, diaId);

    final erro = PontoValidator.validarExclusaoEvento(
      eventosExistentes: _toValidatorInput(estado.cache),
      eventoId: eventoId,
    );
    if (erro != null) throw Exception(erro);

    final novoCache =
        estado.cache.where((m) => m['id'] != eventoId).toList();

    final batch = _firestore.batch();
    batch.delete(refEventos.doc(eventoId));

    if (novoCache.isEmpty) {
      // Dia sem eventos → remove o doc do dia e desconta seu delta do mês.
      batch.delete(refDia);
      _writeMonthBalance(batch, uid, diaId, -estado.oldDelta);
      _commitLocalFirst(batch);
    } else {
      _finalizeDayEdit(
        batch: batch,
        refDia: refDia,
        uid: uid,
        diaId: diaId,
        novoCache: novoCache,
        dayExisted: true,
        oldDelta: estado.oldDelta,
      );
    }
  }

  int _computeWorkedMinutes(List<Map<String, dynamic>> eventos) {
    DateTime? openWork;
    Duration total = Duration.zero;

    for (final ev in eventos) {
      final tipo = (ev['tipo'] ?? '').toString();
      final ts = ev['at'];
      final at = ts is Timestamp ? ServerTimeService.timestampToBrazil(ts) : null;
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

  /// Aplica edições, adições e exclusões em lote para um dia (local-first).
  Future<void> batchUpdateDay({
    required String uid,
    required String diaId,
    required List<Map<String, dynamic>> updates,
    required List<String> deletes,
    required List<Map<String, dynamic>> adds,
  }) async {
    // Bloqueia edição em feriados/recessos (mesmo para admin).
    final date = DateTime.tryParse(diaId);
    if (date != null && await PontoService.isFeriado(date, preferCache: true)) {
      throw Exception(
          'Este dia é feriado/recesso. Não é permitido editar pontos.');
    }

    final refDia =
        _firestore.collection(_root).doc(uid).collection('dias').doc(diaId);
    final refEventos = refDia.collection('eventos');

    final estado = await _loadDayCache(uid, diaId);

    final updateMap = <String, Map<String, dynamic>>{
      for (final u in updates) u['id'] as String: u,
    };
    final deleteSet = deletes.toSet();

    // estadoFinal: entrada do validador. novoCache: array a persistir.
    final estadoFinal = <Map<String, dynamic>>[];
    final novoCache = <Map<String, dynamic>>[];
    final addedIds = <String>[];

    for (final m in estado.cache) {
      final id = m['id'] as String;
      if (deleteSet.contains(id)) continue;
      if (updateMap.containsKey(id)) {
        final u = updateMap[id]!;
        final horario = u['horario'] as DateTime;
        estadoFinal.add({'id': id, 'tipo': u['tipo'], 'at': horario});
        novoCache.add(<String, dynamic>{
          ...m,
          'tipo': u['tipo'],
          'at': Timestamp.fromDate(horario),
          'origin': 'ajustado',
        });
      } else {
        final ts = m['at'];
        estadoFinal.add({
          'id': id,
          'tipo': m['tipo'],
          'at': ts is Timestamp
              ? ServerTimeService.timestampToBrazil(ts)
              : null,
        });
        novoCache.add(m);
      }
    }
    for (final a in adds) {
      final horario = a['horario'] as DateTime;
      final id = refEventos.doc().id;
      addedIds.add(id);
      estadoFinal.add({'tipo': a['tipo'], 'at': horario});
      novoCache.add(<String, dynamic>{
        'id': id,
        'tipo': a['tipo'],
        'at': Timestamp.fromDate(horario),
        'workMode': '',
        'origin': 'ajustado',
      });
    }

    // Validação da sequência final.
    if (estadoFinal.isNotEmpty) {
      final error = PontoValidator.validarSequenciaCompleta(estadoFinal);
      if (error != null) throw Exception(error);
    }

    _sortCache(novoCache);

    // Monta o batch: exclusões, atualizações e adições na subcoleção.
    final batch = _firestore.batch();
    for (final id in deletes) {
      batch.delete(refEventos.doc(id));
    }
    for (final u in updates) {
      batch.update(refEventos.doc(u['id'] as String), {
        'tipo': u['tipo'],
        'at': Timestamp.fromDate(u['horario'] as DateTime),
        'origin': 'ajustado',
      });
    }
    for (var i = 0; i < adds.length; i++) {
      batch.set(refEventos.doc(addedIds[i]), {
        'tipo': adds[i]['tipo'],
        'at': Timestamp.fromDate(adds[i]['horario'] as DateTime),
        'origin': 'ajustado',
      });
    }

    if (novoCache.isEmpty) {
      // Dia sem eventos → remove o doc do dia e desconta seu delta do mês.
      batch.delete(refDia);
      _writeMonthBalance(batch, uid, diaId, -estado.oldDelta);
      _commitLocalFirst(batch);
    } else {
      _finalizeDayEdit(
        batch: batch,
        refDia: refDia,
        uid: uid,
        diaId: diaId,
        novoCache: novoCache,
        dayExisted: estado.dayExists,
        oldDelta: estado.oldDelta,
      );
    }
  }
}
