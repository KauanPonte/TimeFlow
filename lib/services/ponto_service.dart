import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/pages/home_page/pages/calendar_service.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';

class PontoResult {
  final bool success;
  final String message;
  const PontoResult({required this.success, required this.message});
}

class PontoService {
  static const String _root = 'pontos';

  static String _mesIdFromDiaId(String diaId) => diaId.substring(0, 7);

  static String _hojeId() => ServerTimeService.todayId();
  static String _diaId(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static Future<int> _getWorkloadMinutes(String uid) async {
    final userSnap =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    return (userSnap.data()?['workloadMinutes'] as int?) ?? (8 * 60);
  }

  static Future<DateTime?> _getUserCreatedAt(String uid) async {
    final userSnap =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final ts = userSnap.data()?['createdAt'];
    if (ts is Timestamp) return _startOfDay(ts.toDate());
    return null;
  }

  static Future<int> getCargaHorariaUsuarioAtual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 8 * 60;

    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    return (userSnap.data()?['workloadMinutes'] as int?) ?? (8 * 60);
  }

  static DocumentReference<Map<String, dynamic>> _refDia(
      String uid, String diaId) {
    return FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .doc(diaId);
  }

  static CollectionReference<Map<String, dynamic>> _refEventos(
      String uid, String diaId) {
    return _refDia(uid, diaId).collection('eventos');
  }

  static bool _podeRegistrar(
      {required String? ultimoTipo, required String novoTipo}) {
    if (ultimoTipo == null) return novoTipo == 'entrada';

    switch (ultimoTipo) {
      case 'entrada':
        return novoTipo == 'pausa' || novoTipo == 'saida';
      case 'pausa':
        return novoTipo == 'retorno'; // obrigatório retornar antes de sair
      case 'retorno':
        return novoTipo == 'pausa' || novoTipo == 'saida';
      case 'saida':
        return novoTipo == 'entrada';
      default:
        return false;
    }
  }

  static String _mensagemErroTransicao(String? ultimo, String novo) {
    if (ultimo == null) return 'O primeiro ponto do dia precisa ser "entrada".';
    if (ultimo == 'pausa') {
      return 'Após "pausa", é obrigatório registrar "retorno" antes de qualquer outro ponto.';
    }
    return 'Não é possível registrar "$novo" agora. Último ponto foi "$ultimo".';
  }

  static Future<PontoResult> registrarPonto(String tipo,
      {required String workMode}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const PontoResult(
            success: false, message: 'Você precisa estar logado.');
      }
      final hoje = ServerTimeService.nowBrazilUtc();
      final bool feriado = await isFeriado(hoje);

      if (feriado) {
        return const PontoResult(
            success: false,
            message: 'Hoje é feriado. O registro de ponto está bloqueado.');
      }

      if (!['entrada', 'pausa', 'retorno', 'saida'].contains(tipo)) {
        return PontoResult(success: false, message: 'Tipo inválido: $tipo.');
      }

      final uid = user.uid;
      final diaId = _hojeId();
      final refDia = _refDia(uid, diaId);
      final refEventos = _refEventos(uid, diaId);
      // Registra sem segundos (truncado ao minuto) usando horário corrigido do servidor.
      final now = ServerTimeService.nowTimestampTruncated();

      final int workloadMinutes = await _getWorkloadMinutes(uid);

      //  Escrita atômica com cache incremental e atualização mínima de mês
      final eventId = refEventos.doc().id;
      final eventData = {
        'tipo': tipo,
        'at': now,
        'workMode': workMode,
        'origin': 'registrado',
      };
      final eventCacheEntry = {
        'id': eventId,
        'tipo': tipo,
        'at': now,
        'workMode': workMode,
        'origin': 'registrado',
      };

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final diaSnap = await tx.get(refDia);
        final diaData = diaSnap.data();
        final dynamic rawCache = diaData?['eventosCache'];
        var existingCache = _normalizeEventosCache(rawCache as List<dynamic>?);

        if (diaSnap.exists && rawCache == null) {
          final eventsSnap =
              await refEventos.orderBy('at', descending: false).get();
          existingCache = eventsSnap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'tipo': (data['tipo'] ?? '').toString(),
              'at': data['at'],
              'workMode': (data['workMode'] ?? '').toString(),
              'origin': (data['origin'] ?? 'registrado').toString(),
            };
          }).toList();
        }

        if (diaSnap.exists) {
          final String? ultimoTipo = diaData?['lastTipo']?.toString();
          if (!_podeRegistrar(ultimoTipo: ultimoTipo, novoTipo: tipo)) {
            throw Exception(_mensagemErroTransicao(ultimoTipo, tipo));
          }

          final Timestamp? lastAt = diaData?['lastAt'] as Timestamp?;
          if (lastAt != null) {
            final diffSeconds = now.seconds - lastAt.seconds;
            if (diffSeconds < 60) {
              throw Exception(
                  'Aguarde pelo menos 1 minuto entre cada registro de ponto.');
            }
          }
        } else if (tipo != 'entrada') {
          throw Exception('O primeiro ponto do dia precisa ser "entrada".');
        }

        final updatedCache = [...existingCache, eventCacheEntry];
        final bool diaFechado = tipo == 'saida';
        final int workedMinutes = diaFechado
            ? _computeWorkedMinutesFromEventosFechado(updatedCache)
            : (diaData?['workedMinutes'] as int?) ?? 0;
        final bool isExcused = (diaData?['isExcused'] as bool?) ?? false;
        final String mesId = _mesIdFromDiaId(diaId);
        final DocumentReference<Map<String, dynamic>> refMes =
            _refMes(uid, mesId);
        final bool ehHoje = diaId == _hojeId();
        final DateTime date = DateTime.parse(diaId);
        final holidays = getBrazilHolidays(date.year);
        final bool isWeekend = date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
        final bool isHoliday = holidays.containsKey(date);
        final bool falta = !ehHoje &&
            updatedCache.isEmpty &&
            !isWeekend &&
            !isHoliday &&
            !isExcused;
        final int workloadMinutes =
            await _getWorkloadMinutes(uid); // carrega apenas uma vez
        final int deltaMinutes = isExcused
            ? workedMinutes
            : (falta
                ? -workloadMinutes
                : (diaFechado ? (workedMinutes - workloadMinutes) : 0));
        final int oldDelta = (diaData?['deltaMinutes'] as int?) ?? 0;
        final int balanceDiff = deltaMinutes - oldDelta;

        final Map<String, dynamic> diaUpdate = {
          'uid': uid,
          'date': diaId,
          'updatedAt': now,
          'lastTipo': tipo,
          'lastAt': now,
          'eventosCache': updatedCache,
          'workedMinutes': workedMinutes,
          'deltaMinutes': deltaMinutes,
          'workloadMinutes': workloadMinutes,
          'isClosed': diaFechado,
          'isOpen': !diaFechado && updatedCache.isNotEmpty,
          'isAbsent': falta,
        };

        if (!diaSnap.exists) {
          diaUpdate['createdAt'] = now;
        }

        tx.set(refEventos.doc(eventId), eventData);
        tx.set(refDia, diaUpdate, SetOptions(merge: true));

        if (balanceDiff != 0) {
          final mesSnap = await tx.get(refMes);
          final int oldBalance =
              (mesSnap.data()?['balanceMinutes'] as int?) ?? 0;
          tx.set(
            refMes,
            {
              'balanceMinutes': oldBalance + balanceDiff,
              'updatedAt': now,
              'summaryCache': FieldValue.delete(),
            },
            SetOptions(merge: true),
          );
        }
      });

      final horas =
          DateFormat('HH:mm').format(ServerTimeService.nowBrazilUtc());
      return PontoResult(
          success: true, message: 'Ponto "$tipo" registrado às $horas.');
    } catch (e) {
      return PontoResult(
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  static Future<String?> getUltimoTipoHoje() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final diaId = _hojeId();

    final doc = await _refDia(uid, diaId).get();
    final data = doc.data();
    return data?['lastTipo']?.toString();
  }

  /// Retorna o workMode travado para o dia de hoje, se houver sessão aberta.
  /// Retorna null se não houver lock (sem eventos ou último tipo é 'saida').
  static Future<String?> getLockedWorkModeHoje() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final diaId = _hojeId();

    final diaDoc = await _refDia(uid, diaId).get();
    if (!diaDoc.exists) return null;

    final lastTipo = diaDoc.data()?['lastTipo']?.toString();
    if (lastTipo == null || lastTipo == 'saida') return null;

    final eventosSnap = await _refEventos(uid, diaId)
        .orderBy('at', descending: true)
        .limit(1)
        .get();

    bool hasPresencial = false;
    bool hasRemoto = false;

    for (final doc in eventosSnap.docs) {
      final data = doc.data();
      final tipo = (data['tipo'] ?? '').toString();
      final wm = (data['workMode'] ?? '').toString();

      if (wm == 'presencial') {
        hasPresencial = true;
      } else if (wm == 'remoto') {
        hasRemoto = true;
      }

      if (tipo == 'entrada') {
        break;
      }
    }

    if (hasPresencial) return 'presencial';
    if (hasRemoto) return 'remoto';
    return null;
  }

  static Future<List<Map<String, dynamic>>> loadEventosHoje() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final uid = user.uid;
    final diaId = _hojeId();

    final snap =
        await _refEventos(uid, diaId).orderBy('at', descending: false).get();

    return snap.docs.map((d) {
      final m = d.data();
      return {
        'tipo': (m['tipo'] ?? '').toString(),
        'at': m['at'],
        'workMode': (m['workMode'] ?? '').toString(),
        'origin': (m['origin'] ?? 'registrado').toString(),
      };
    }).toList();
  }

  /// Retorna todos os eventos de hoje como lista ordenada com horário formatado.
  /// Cada item: { 'tipo': String, 'hora': String }
  static Future<List<Map<String, String>>> loadEventosHojeFormatados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final uid = user.uid;
    final diaId = _hojeId();

    final snap =
        await _refEventos(uid, diaId).orderBy('at', descending: false).get();

    return snap.docs.map((d) {
      final m = d.data();
      final tipo = (m['tipo'] ?? '').toString();
      final at = m['at'];
      final hora =
          at is Timestamp ? DateFormat('HH:mm').format(at.toDate()) : '';
      final workMode = (m['workMode'] ?? '').toString();
      final origin = (m['origin'] ?? 'registrado').toString();
      return {
        'tipo': tipo,
        'hora': hora,
        'workMode': workMode,
        'origin': origin,
      };
    }).toList();
  }

  static Future<Map<String, Map<String, String>>> loadRegistros() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final uid = user.uid;

    final diasSnap = await FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .orderBy('date', descending: true)
        .get();

    String ftm(dynamic ts) {
      if (ts is Timestamp) {
        return DateFormat('HH:mm').format(ts.toDate());
      }
      return '';
    }

    final result = <String, Map<String, String>>{};

    for (final diaDoc in diasSnap.docs) {
      final diaId = diaDoc.id;

      final eventosSnap =
          await _refEventos(uid, diaId).orderBy('at', descending: false).get();

      final map = <String, String>{};

      for (final ev in eventosSnap.docs) {
        final data = ev.data();
        final tipo = (data['tipo'] ?? '').toString();
        final at = data['at'];

        if (tipo.isEmpty) continue;

        final hora = ftm(at);
        if (hora.isEmpty) continue;

        map[tipo] = hora;
      }

      if (map.isNotEmpty) {
        result[diaId] = map;
      }
    }

    return result;
  }

  static DocumentReference<Map<String, dynamic>> _refMes(
      String uid, String mesId) {
    return FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('meses')
        .doc(mesId);
  }

  // 1. O NOVO MÉTODO DE VERIFICAÇÃO
  static Future<bool> isFeriado(DateTime date) async {
    try {
      final cleanDate = DateTime(date.year, date.month, date.day);

      // Expande a janela de busca para lidar com diferenças de timezone (ex: salvo em UTC)
      final expandedStart =
          Timestamp.fromDate(cleanDate.subtract(const Duration(days: 1)));
      final expandedEnd =
          Timestamp.fromDate(cleanDate.add(const Duration(days: 2)));

      const blockingTypes = {
        'feriado',
        'recesso',
      };

      final snapshot = await FirebaseFirestore.instance
          .collection('calendar_events')
          .where('date', isGreaterThanOrEqualTo: expandedStart)
          .where('date', isLessThanOrEqualTo: expandedEnd)
          .get();

      for (var doc in snapshot.docs) {
        final evTs = doc.data()['date'] as Timestamp?;
        if (evTs != null) {
          final evDate = evTs.toDate();
          if (evDate.year == cleanDate.year &&
              evDate.month == cleanDate.month &&
              evDate.day == cleanDate.day) {
            final tipo =
                (doc.data()['type'] ?? '').toString().toLowerCase().trim();
            if (blockingTypes.contains(tipo)) return true;
          }
        }
      }

      // Fallback: feriados fixos do código
      final feriadosFixos = getBrazilHolidays(date.year);
      return feriadosFixos.containsKey(cleanDate);
    } catch (_) {
      final cleanDate = DateTime(date.year, date.month, date.day);
      return getBrazilHolidays(date.year).containsKey(cleanDate);
    }
  }

  // 2. RECALCULAR BANCO (SUBSTITUA AS DUAS VERSÕES POR ESTA)
  static Future<void> recalcularBancoDeHorasDoDia({
    required String uid,
    required String diaId,
  }) async {
    final refDia = _refDia(uid, diaId);
    final refEventos = _refEventos(uid, diaId);
    final mesId = _mesIdFromDiaId(diaId);
    final refMes = _refMes(uid, mesId);

    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventos = eventosSnap.docs.map((d) => d.data()).toList();
    final eventosCache = eventosSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': data['at'],
        'workMode': (data['workMode'] ?? '').toString(),
        'origin': (data['origin'] ?? 'registrado').toString(),
      };
    }).toList();

    final workedMinutes = _computeWorkedMinutesFromEventosFechado(eventos);
    final workloadMinutes =
        await _getWorkloadMinutes(uid); // <--- VALOR DEFINIDO AQUI

    final diaSnapPre = await refDia.get();
    final bool isExcused = (diaSnapPre.data()?['isExcused'] as bool?) ?? false;

    final String? ultimoTipoEvento =
        eventos.isNotEmpty ? (eventos.last['tipo'] ?? '').toString() : null;
    final Timestamp? ultimoAtEvento =
        eventos.isNotEmpty ? (eventos.last['at'] as Timestamp?) : null;
    final bool diaFechado = ultimoTipoEvento == 'saida';
    final todayId = _hojeId();
    final bool ehHoje = diaId == todayId;

    final date = DateTime.parse(diaId);
    final holidays = getBrazilHolidays(date.year);
    final bool isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final bool isHoliday = holidays.containsKey(date);

    final bool falta =
        !ehHoje && eventos.isEmpty && !isWeekend && !isHoliday && !isExcused;

    final bool emAberto = !diaFechado && eventos.isNotEmpty;

    final int deltaMinutes = isExcused
        ? workedMinutes
        : (falta
            ? -workloadMinutes
            : (diaFechado ? (workedMinutes - workloadMinutes) : 0));

    // Função interna corrigida usando workloadMinutes
    Future<void> applyUpdate(int oldDelta, int oldBalance) async {
      final diff = deltaMinutes - oldDelta;
      await refDia.set({
        'uid': uid,
        'date': diaId,
        'lastTipo': ultimoTipoEvento,
        'lastAt': ultimoAtEvento,
        'eventosCache': eventosCache,
        'workedMinutes': workedMinutes,
        'deltaMinutes': deltaMinutes,
        'workloadMinutes': workloadMinutes,
        'isClosed': diaFechado,
        'isOpen': emAberto,
        'isAbsent': falta,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await refMes.set({
        'balanceMinutes': oldBalance + diff,
        'updatedAt': FieldValue.serverTimestamp(),
        'summaryCache': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final diaSnap = await tx.get(refDia);
        final mesSnap = await tx.get(refMes);
        final oldDelta = (diaSnap.data()?['deltaMinutes'] as int?) ?? 0;
        final oldBalance = (mesSnap.data()?['balanceMinutes'] as int?) ?? 0;

        final diff = deltaMinutes - oldDelta;
        tx.set(
            refDia,
            {
              'uid': uid,
              'date': diaId,
              'lastTipo': ultimoTipoEvento,
              'lastAt': ultimoAtEvento,
              'eventosCache': eventosCache,
              'workedMinutes': workedMinutes,
              'deltaMinutes': deltaMinutes,
              'workloadMinutes': workloadMinutes,
              'isClosed': diaFechado,
              'isOpen': emAberto,
              'isAbsent': falta,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        tx.set(
            refMes,
            {
              'balanceMinutes': oldBalance + diff,
              'updatedAt': FieldValue.serverTimestamp(),
              'summaryCache': FieldValue.delete(),
            },
            SetOptions(merge: true));
      });
    } catch (_) {
      final diaSnap = await refDia.get();
      final mesSnap = await refMes.get();
      await applyUpdate((diaSnap.data()?['deltaMinutes'] as int?) ?? 0,
          (mesSnap.data()?['balanceMinutes'] as int?) ?? 0);
    }
  }

  // 3. RESUMO DO MÊS (CORRIGIDO)
  static Future<MesResumo> getResumoMesAtualOld() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const MesResumo(
          workedMinutes: 0,
          expectedMinutes: 0,
          businessDaysTotal: 0,
          monthBalance: 0.0);
    }

    final uid = user.uid;
    final now = ServerTimeService.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final workloadMinutes = await _getWorkloadMinutes(uid);
    final holidaysFixos = getBrazilHolidays(now.year);

    final adminHolidaysSnap = await FirebaseFirestore.instance
        .collection('calendar_events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(nextMonthStart))
        .where('type', isEqualTo: 'feriado')
        .get();

    final adminHolidaysDates = adminHolidaysSnap.docs.map((doc) {
      DateTime d = (doc.data()['date'] as Timestamp).toDate();
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    int businessDaysTotal = 0;
    int expectedMinutes = 0;

    for (var d = monthStart;
        d.isBefore(nextMonthStart);
        d = d.add(const Duration(days: 1))) {
      final date = _startOfDay(d);
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final isHoliday =
          holidaysFixos.containsKey(date) || adminHolidaysDates.contains(date);

      if (!isWeekend && !isHoliday) {
        businessDaysTotal++;
        expectedMinutes += workloadMinutes;
      }
    }

    final startId = _diaId(monthStart);
    final endId = _diaId(nextMonthStart);
    final diasSnap = await FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();

    int workedMinutes = 0;
    for (final doc in diasSnap.docs) {
      workedMinutes += (doc.data()['workedMinutes'] as int?) ?? 0;
    }

    final monthBalance = (workedMinutes - expectedMinutes) / 60.0;

    return MesResumo(
      workedMinutes: workedMinutes,
      expectedMinutes: expectedMinutes,
      businessDaysTotal: businessDaysTotal,
      monthBalance: monthBalance,
    );
  }

  static int _computeWorkedMinutesFromEventosFechado(
      List<Map<String, dynamic>> eventos) {
    DateTime? openWork;
    int totalMinutes = 0;

    DateTime? tsToDate(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      return null;
    }

    for (final ev in eventos) {
      final tipo = (ev['tipo'] ?? '').toString();
      final at = tsToDate(ev['at']);
      if (at == null) continue;

      if (tipo == 'entrada' || tipo == 'retorno') {
        openWork ??= at;
      } else if (tipo == 'pausa' || tipo == 'saida') {
        if (openWork != null && at.isAfter(openWork)) {
          final diff = at.difference(openWork);
          totalMinutes += diff.inSeconds ~/ 60;
        }
        openWork = null;
      }
    }
    return totalMinutes;
  }

  static List<Map<String, dynamic>> _normalizeEventosCache(
      List<dynamic>? rawCache) {
    if (rawCache == null) return [];
    return rawCache.whereType<Map<String, dynamic>>().map((data) {
      return {
        'id': data['id']?.toString() ?? '',
        'tipo': (data['tipo'] ?? '').toString(),
        'at': data['at'],
        'workMode': (data['workMode'] ?? '').toString(),
        'origin': (data['origin'] ?? 'registrado').toString(),
      };
    }).toList();
  }

  /// Resumo do mês: horas feitas vs horas previstas (dias úteis),
  /// descontando finais de semana e feriados (BR + CE).
  static Future<MesResumo> calcularResumoMensal(
      String uid, DateTime month) async {
    final now = ServerTimeService.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final mesId = DateFormat('yyyy-MM').format(month);
    final refMes = _refMes(uid, mesId);

    // Se NÃO for o mês atual, tenta carregar o cache persistente do Firestore.
    if (!isCurrentMonth) {
      try {
        final snap = await refMes.get();
        if (snap.exists && snap.data()!.containsKey('summaryCache')) {
          final cacheData =
              snap.data()!['summaryCache'] as Map<String, dynamic>;
          return MesResumo.fromMap(cacheData);
        }
      } catch (_) {}
    }

    final calendarService = CalendarService();
    final folgas = await calendarService.getDaysThatReduceWorkload(
        month.year, month.month);

    // Buscar atestados aprovados que caem neste mês para abonar a meta de saldo
    final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final atestadosSnap = await FirebaseFirestore.instance
        .collection('atestados')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .get();

    final Set<String> atestadoDays = {};
    for (final doc in atestadosSnap.docs) {
      final data = doc.data();
      final startStr = data['dataInicio']?.toString();
      final endStr = data['dataFim']?.toString();
      if (startStr != null && endStr != null) {
        final startLocal = DateTime.tryParse(startStr);
        final endLocal = DateTime.tryParse(endStr);
        if (startLocal != null && endLocal != null) {
          final start = DateTime.utc(
              startLocal.year, startLocal.month, startLocal.day, 12);
          final end =
              DateTime.utc(endLocal.year, endLocal.month, endLocal.day, 12);
          for (var d = start;
              !d.isAfter(end);
              d = d.add(const Duration(days: 1))) {
            final diaId =
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            if (diaId.startsWith(prefix)) atestadoDays.add(diaId);
          }
        }
      }
    }

    final workloadMinutes = await _getWorkloadMinutes(uid);

    // 1. Horas no mês: baseadas na jornada mensal esperada completa do mês consultado
    int diasUteisNoMes = 0;
    final ultimoDia = DateTime(month.year, month.month + 1, 0).day;

    for (int i = 1; i <= ultimoDia; i++) {
      final date = DateTime(month.year, month.month, i);
      final diaId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      bool isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      bool isFolga = folgas.contains(
          diaId); // Inclui feriados fixos e artificiais via CalendarService
      bool isAtestado = atestadoDays.contains(diaId);
      if (!isWeekend && !isFolga && !isAtestado) diasUteisNoMes++;
    }

    final int expectedMinutesTotal = diasUteisNoMes * workloadMinutes;

    // Pega os registros de dias do mês primeiro para verificar status de hoje
    final diasSnap = await FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .where('date', isGreaterThanOrEqualTo: '$prefix-01')
        .where('date', isLessThanOrEqualTo: '$prefix-31')
        .get();

    // Monta mapa para acesso rápido por diaId
    final Map<String, Map<String, dynamic>> dayDataMap = {
      for (final doc in diasSnap.docs) doc.id: doc.data(),
    };

    // Para o mês atual: verifica se hoje está fechado (tem saída registrada).
    // Hoje só entra na expectativa e nas horas trabalhadas após o ponto de saída.
    final todayId = _diaId(now);
    final todayData = isCurrentMonth ? dayDataMap[todayId] : null;
    final todayIsClosed = (todayData?['isClosed'] as bool?) ?? false;

    // "saldo: contabiliza todos os dias uteis ... até o dia atual do mês"
    // Caso seja um mês passado, contabiliza até o último dia daquele mês.
    final limitDay = isCurrentMonth ? now.day : ultimoDia;

    int expectedMinutesUntilLimit = 0;
    for (int i = 1; i <= limitDay; i++) {
      // Hoje só conta na expectativa se o dia estiver fechado (tem saída)
      if (isCurrentMonth && i == now.day && !todayIsClosed) continue;

      final date = DateTime(month.year, month.month, i);
      final diaId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      bool isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      bool isFolga = folgas.contains(diaId);
      bool isAtestado = atestadoDays.contains(diaId);

      // Assim como no user_reports_page, contabiliza apenas dias úteis na meta de saldo.
      if (!isWeekend && !isFolga && !isAtestado) {
        expectedMinutesUntilLimit += workloadMinutes;
      }
    }

    // Soma as horas reais trabalhadas, excluindo hoje se o dia ainda não foi fechado
    int workedMinutes = 0;
    for (final entry in dayDataMap.entries) {
      if (isCurrentMonth && !todayIsClosed && entry.key == todayId) continue;
      workedMinutes += (entry.value['workedMinutes'] as int?) ?? 0;
    }

    // "subtrai isso (expectativa) pelo q realmente tem trabalhado e ent temos os saldo"
    final double monthBalance =
        (workedMinutes - expectedMinutesUntilLimit).toDouble();

    final resumo = MesResumo(
      workedMinutes: workedMinutes,
      expectedMinutes: expectedMinutesTotal,
      businessDaysTotal: diasUteisNoMes,
      monthBalance: monthBalance,
    );

    // Salva o cache persistente no Firestore para consultas futuras mais rápidas.
    // Mesmo pro mês atual, serve de cache, mas pra meses passados é "eterno".
    try {
      await refMes.set({
        'summaryCache': resumo.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    return resumo;
  }

  /// Resumo do mês atual
  static Future<MesResumo> getResumoMesAtual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const MesResumo(
        workedMinutes: 0,
        expectedMinutes: 0,
        businessDaysTotal: 0,
        monthBalance: 0.0,
      );
    }
    return await calcularResumoMensal(user.uid, ServerTimeService.now());
  }

  /// Saldo acumulado total (em minutos) desde a criação da conta até hoje.
  static Future<int> calcularSaldoAcumuladoTotal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final uid = user.uid;

    final createdAt = await _getUserCreatedAt(uid);
    if (createdAt == null) return 0;

    final now = ServerTimeService.now();
    final workloadMinutes = await _getWorkloadMinutes(uid);
    int totalBalance = 0;

    DateTime cursor = DateTime(createdAt.year, createdAt.month, 1);
    final currentMonthStart = DateTime(now.year, now.month, 1);
    bool isFirstMonth = true;

    while (!cursor.isAfter(currentMonthStart)) {
      final resumo = await calcularResumoMensal(uid, cursor);
      int monthBalance = resumo.monthBalance.toInt();

      // Ajuste do primeiro mês: remove expectativa de dias antes de createdAt
      // que não têm registro de ponto (dias com ponto ficam como dias normais).
      if (isFirstMonth && createdAt.day > 1) {
        final prefix =
            '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
        final createdDayId =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

        // Busca dias anteriores à criação que tenham workedMinutes > 0
        final diasAntesSnap = await FirebaseFirestore.instance
            .collection(_root)
            .doc(uid)
            .collection('dias')
            .where('date', isGreaterThanOrEqualTo: '$prefix-01')
            .where('date', isLessThan: createdDayId)
            .get();

        final daysWithPunch = diasAntesSnap.docs
            .where((d) => ((d.data()['workedMinutes'] as int?) ?? 0) > 0)
            .map((d) => d.id)
            .toSet();

        final calendarService = CalendarService();
        final folgas = await calendarService.getDaysThatReduceWorkload(
            cursor.year, cursor.month);

        for (int i = 1; i < createdAt.day; i++) {
          final date = DateTime(cursor.year, cursor.month, i);
          final diaId =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final isWeekend = date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;
          final isFolga = folgas.contains(diaId);
          if (!isWeekend && !isFolga && !daysWithPunch.contains(diaId)) {
            // Dia útil sem ponto antes da criação: reverte a expectativa
            monthBalance += workloadMinutes;
          }
        }
      }
      isFirstMonth = false;

      totalBalance += monthBalance;
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return totalBalance;
  }

  // Para a página de Relatórios (Admin ver saldo de qualquer usuário)
  static Future<int> getSaldoMesPorUsuario(String uid, DateTime date) async {
    final mesId = DateFormat('yyyy-MM').format(date);
    final snap = await FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection(
            'meses') // Verifique se o nome da collection é 'meses' ou 'months'
        .doc(mesId)
        .get();

    return (snap.data()?['balanceMinutes'] as int?) ?? 0;
  }

  static final Map<String, DateTime> _recalcThrottleMap = {};

  /// Garante o desconto de faltas em dias úteis passados (mês atual),
  /// e também para o dia de hoje após o horário de corte.
  static Future<void> recalcularFaltasMesAtual({
    int cutoffHour = 20,
    int cutoffMinute = 0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Cache/Throttle: não recalcula se foi feito nos últimos 5 minutos
    final lastTime = _recalcThrottleMap[uid];
    final now = ServerTimeService.now();
    if (lastTime != null && now.difference(lastTime).inMinutes < 5) {
      return;
    }
    _recalcThrottleMap[uid] = now;
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final userCreatedAt = await _getUserCreatedAt(uid);
    final balanceStart =
        (userCreatedAt != null && userCreatedAt.isAfter(monthStart))
            ? userCreatedAt
            : monthStart;

    final prefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final startId = '$prefix-01';
    final endId = '$prefix-32';

    final diasSnap = await FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('dias')
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();

    final existingDays = diasSnap.docs.map((d) => d.id).toSet();
    final holidays = getBrazilHolidays(now.year);
    final today = _startOfDay(now);
    final cutoffReached = now.isAfter(
      DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute),
    );

    // Remove docs de falta auto-gerados para dias antes do balanceStart.
    // Docs com workedMinutes > 0 são registros manuais e são preservados.
    if (balanceStart.isAfter(monthStart)) {
      for (final doc in diasSnap.docs) {
        final docDate = _startOfDay(DateTime.parse(doc.id));
        if (!docDate.isBefore(balanceStart)) continue;
        final hasWork = ((doc.data()['workedMinutes'] as int?) ?? 0) > 0;
        if (!hasWork) {
          await doc.reference.delete();
          existingDays.remove(doc.id);
        }
      }
    }

    for (var d = balanceStart;
        d.isBefore(nextMonthStart);
        d = d.add(const Duration(days: 1))) {
      final day = _startOfDay(d);
      final isToday = day.isAtSameMomentAs(today);
      if (!day.isBefore(today) && !(isToday && cutoffReached)) continue;

      final isWeekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      final isHoliday = holidays.containsKey(day);
      if (isWeekend || isHoliday) continue;

      final diaId = _diaId(day);
      if (!existingDays.contains(diaId)) {
        await recalcularBancoDeHorasDoDia(uid: uid, diaId: diaId);
      }
    }
  }

  /*static Future<bool> isFeriado(DateTime date) async {
    final cleanDate = DateTime(date.year, date.month, date.day);

    // 1. Verifica no Firebase (Eventos criados pelo Admin)
    final snapshot = await FirebaseFirestore.instance
        .collection('calendar_events')
        .where('date', isEqualTo: Timestamp.fromDate(cleanDate))
        .where('type', isEqualTo: 'feriado')
        .get();

    if (snapshot.docs.isNotEmpty) return true;

    // 2. Verifica Feriados Nacionais/Estaduais (Sua função local)
    final feriadosFixos = getBrazilHolidays(date.year);
    return feriadosFixos.containsKey(cleanDate);
  }*/

  static Map<DateTime, String> getBrazilHolidays(int year) {
    Map<DateTime, String> holidays = {
      DateTime(year, 1, 1): "Confraternização Universal",
      DateTime(year, 4, 21): "Tiradentes",
      DateTime(year, 5, 1): "Dia do Trabalho",
      DateTime(year, 9, 7): "Independência do Brasil",
      DateTime(year, 10, 12): "Nossa Senhora Aparecida",
      DateTime(year, 11, 2): "Finados",
      DateTime(year, 11, 15): "Proclamação da República",
      DateTime(year, 11, 20): "Consciência Negra",
      DateTime(year, 12, 25): "Natal",
    };

    // Cálculo da Páscoa (Algoritmo de Meeus/Jones/Butcher) calendário gregoriano
    int a = year % 19;
    int b = year ~/ 100;
    int c = year % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int month = (h + l - 7 * m + 114) ~/ 31;
    int day = ((h + l - 7 * m + 114) % 31) + 1;

    DateTime pascoa = DateTime(year, month, day);

    holidays[pascoa.subtract(const Duration(days: 2))] = "Sexta-feira Santa";
    holidays[pascoa.subtract(const Duration(days: 47))] = "Carnaval";
    holidays[pascoa.add(const Duration(days: 60))] = "Corpus Christi";

    // ---  feriados do Ceará ---
    holidays[DateTime(year, 3, 19)] = "São José (CE)";
    holidays[DateTime(year, 3, 25)] = "Data Magna (CE)";

    return holidays;
  }
}

class MesResumo {
  final int workedMinutes;
  final int expectedMinutes;
  final int businessDaysTotal;
  final double monthBalance;

  const MesResumo({
    required this.workedMinutes,
    required this.expectedMinutes,
    required this.businessDaysTotal,
    required this.monthBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'workedMinutes': workedMinutes,
      'expectedMinutes': expectedMinutes,
      'businessDaysTotal': businessDaysTotal,
      'monthBalance': monthBalance,
    };
  }

  factory MesResumo.fromMap(Map<String, dynamic> map) {
    return MesResumo(
      workedMinutes: (map['workedMinutes'] as num? ?? 0).toInt(),
      expectedMinutes: (map['expectedMinutes'] as num? ?? 0).toInt(),
      businessDaysTotal: (map['businessDaysTotal'] as num? ?? 0).toInt(),
      monthBalance: (map['monthBalance'] as num? ?? 0).toDouble(),
    );
  }
}
