import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PontoResult {
  final bool success;
  final String message;
  const PontoResult({required this.success, required this.message});
}

class PontoService {
  static const String _root = 'pontos';
  static String _mesIdFromDiaId(String diaId) => diaId.substring(0, 7);

  static String _hojeId() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static Future<int> _getWorkloadMinutes(String uid) async {
    final userSnap =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    return (userSnap.data()?['workloadMinutes'] as int?) ?? (8 * 60);
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

      if (!['entrada', 'pausa', 'retorno', 'saida'].contains(tipo)) {
        return PontoResult(success: false, message: 'Tipo inválido: $tipo.');
      }

      final uid = user.uid;
      final diaId = _hojeId();
      final refDia = _refDia(uid, diaId);
      final refEventos = _refEventos(uid, diaId);
      // Registra sem segundos (truncado ao minuto).
      final nowRaw = DateTime.now();
      final now = Timestamp.fromDate(DateTime(
          nowRaw.year, nowRaw.month, nowRaw.day, nowRaw.hour, nowRaw.minute));

      //  Validação antes da transação
      // Lemos o documento do dia fora da transação para evitar o erro
      // "Bad state: Future already completed" que ocorre ao lançar exceções
      // dentro do callback de runTransaction no cloud_firestore.
      final diaSnapPre = await refDia.get();

      if (!diaSnapPre.exists) {
        if (tipo != 'entrada') {
          throw Exception('O primeiro ponto do dia precisa ser "entrada".');
        }
      } else {
        final diaDataPre = diaSnapPre.data() as Map<String, dynamic>;
        final String? ultimoTipo = diaDataPre['lastTipo']?.toString();

        if (!_podeRegistrar(ultimoTipo: ultimoTipo, novoTipo: tipo)) {
          throw Exception(_mensagemErroTransicao(ultimoTipo, tipo));
        }

        final Timestamp? lastAt = diaDataPre['lastAt'] as Timestamp?;
        if (lastAt != null) {
          final diffSeconds = now.seconds - lastAt.seconds;
          if (diffSeconds < 60) {
            throw Exception(
                'Aguarde pelo menos 1 minuto entre cada registro de ponto.');
          }
        }
      }

      //  Escrita atômica (sem throws dentro da transação)
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final newDoc = refEventos.doc();
        tx.set(newDoc, {
          'tipo': tipo,
          'at': now,
          'workMode': workMode,
          'origin': 'registrado',
        });

        if (!diaSnapPre.exists) {
          tx.set(refDia, {
            'uid': uid,
            'date': diaId,
            'createdAt': now,
            'updatedAt': now,
            'lastTipo': tipo,
            'lastAt': now,
          });
        } else {
          tx.update(refDia, {
            'updatedAt': now,
            'lastTipo': tipo,
            'lastAt': now,
          });
        }
      });

      await recalcularBancoDeHorasDoDia(uid: uid, diaId: diaId);

      final horas = DateFormat('HH:mm').format(DateTime.now());
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

    // Busca o último evento 'entrada' para obter o workMode da sessão
    final eventosSnap =
        await _refEventos(uid, diaId).orderBy('at', descending: true).get();

    for (final doc in eventosSnap.docs) {
      final data = doc.data();
      if (data['tipo'] == 'entrada') {
        final wm = (data['workMode'] ?? '').toString();
        return wm.isEmpty ? null : wm;
      }
    }
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

    final workedMinutes = _computeWorkedMinutesFromEventosFechado(eventos);
    final workloadMinutes = await _getWorkloadMinutes(uid);

    final String? ultimoTipoEvento =
        eventos.isNotEmpty ? (eventos.last['tipo'] ?? '').toString() : null;

    final bool diaFechado = ultimoTipoEvento == 'saida';

    final hojeId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool ehHoje = diaId == hojeId;

    final bool falta = !ehHoje && eventos.isEmpty;

    final bool emAberto = !diaFechado && eventos.isNotEmpty;

    final int deltaMinutes = falta
        ? -workloadMinutes
        : (diaFechado ? (workedMinutes - workloadMinutes) : 0);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final diaSnap = await tx.get(refDia);
      final mesSnap = await tx.get(refMes);

      final oldDelta = (diaSnap.data()?['deltaMinutes'] as int?) ?? 0;
      final oldBalance = (mesSnap.data()?['balanceMinutes'] as int?) ?? 0;

      final diff = deltaMinutes - oldDelta;
      final newBalance = oldBalance + diff;

      tx.set(
          refDia,
          {
            'workedMinutes': workedMinutes,
            'deltaMinutes': deltaMinutes,
            'workloadMinutes': workloadMinutes,
            'isClosed': diaFechado,
            'isOpen': emAberto,
            'isAbsent': falta,
            'updatedAt': Timestamp.now(),
          },
          SetOptions(merge: true));

      tx.set(
          refMes,
          {
            'balanceMinutes': newBalance,
            'updatedAt': Timestamp.now(),
          },
          SetOptions(merge: true));
    });
  }

  static int _computeWorkedMinutesFromEventosFechado(
      List<Map<String, dynamic>> eventos) {
    DateTime? openWork;
    Duration total = Duration.zero;

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
          total += at.difference(openWork);
        }
        openWork = null;
      }
    }
    return total.inMinutes;
  }

  static Future<double> getSaldoMesAtualHoras() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final uid = user.uid;
    final mesId = DateFormat('yyyy-MM').format(DateTime.now());

    final snap = await _refMes(uid, newMethod(mesId)).get();
    final minutes = (snap.data()?['balanceMinutes'] as int?) ?? 0;

    return minutes / 60.0;
  }

  static String newMethod(String mesId) => mesId;
}
