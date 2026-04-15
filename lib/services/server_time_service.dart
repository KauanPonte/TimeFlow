import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço que sincroniza o relógio local com o servidor Firebase,
/// garantindo que horários de ponto nunca dependam do relógio do dispositivo.
///
/// Uso:
///   await ServerTimeService.sync();       // chamar no login / init
///   final agora = ServerTimeService.now(); // substitui DateTime.now()
class ServerTimeService {
  ServerTimeService._();

  static Duration _offset = Duration.zero;
  static bool _synced = false;
  static const Duration _brazilOffset = Duration(hours: -3);

  static DateTime _serverUtcNow() => DateTime.now().toUtc().add(_offset);

  static DateTime _brazilServerNowUtc() => _serverUtcNow().add(_brazilOffset);

  /// Retorna o horário atual corrigido pelo offset do servidor, no timezone local do dispositivo.
  static DateTime now() => DateTime.now().add(_offset);

  /// Retorna o horário atual do servidor em UTC.
  static DateTime nowUtc() => _serverUtcNow();

  /// Retorna o horário atual do servidor no padrão do Brasil (UTC-3), mas em UTC.
  /// Use para cálculos de dia/fuso fixos do Brasil.
  static DateTime nowBrazilUtc() => _brazilServerNowUtc();

  /// Indica se já houve pelo menos uma sincronização bem-sucedida.
  static bool get isSynced => _synced;

  /// Sincroniza o offset local ↔ servidor.
  ///
  /// Escreve um timestamp via `FieldValue.serverTimestamp()` num doc
  /// temporário, lê de volta, e calcula a diferença.
  static Future<void> sync() async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('_server_time').doc('probe');

      final localBefore = DateTime.now();

      await ref.set({
        'ts': FieldValue.serverTimestamp(),
      });

      final snap = await ref.get(const GetOptions(source: Source.server));
      final serverTs = snap.data()?['ts'] as Timestamp?;
      if (serverTs == null) return;

      final localAfter = DateTime.now();
      // Ponto médio local ≈ instante em que o servidor gravou.
      final localMid = localBefore.add(
        localAfter.difference(localBefore) ~/ 2,
      );

      _offset = serverTs.toDate().difference(localMid);
      _synced = true;

      // Limpa o doc temporário (fire-and-forget).
      ref.delete().catchError((_) {});
    } catch (_) {
      // Se falhar (offline, permissão, etc.), mantém offset anterior.
      // Em último caso, offset = 0 (comportamento atual).
    }
  }

  /// Retorna um `Timestamp` Firestore usando o horário corrigido do servidor,
  /// truncado ao minuto (sem segundos).
  static Timestamp nowTimestampTruncated() {
    final n = nowUtc();
    return Timestamp.fromDate(
        DateTime.utc(n.year, n.month, n.day, n.hour, n.minute));
  }

  /// Retorna o ID do dia de hoje (yyyy-MM-dd) usando horário padrão do Brasil (UTC-3).
  static String todayId() {
    final n = nowBrazilUtc();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// Retorna o início do dia atual no fuso horário do Brasil em UTC.
  /// Útil para consultas de intervalo em Firestore sobre o dia completo.
  static DateTime todayStartUtc() {
    final n = nowBrazilUtc();
    return DateTime.utc(n.year, n.month, n.day).subtract(_brazilOffset);
  }

  /// Retorna o início do próximo dia no fuso horário do Brasil em UTC.
  static DateTime tomorrowStartUtc() =>
      todayStartUtc().add(const Duration(days: 1));

  /// Retorna o início do dia atual no Brasil em UTC, com horário fixo.
  static DateTime brazilTodayUtcAt(int hour, [int minute = 0]) {
    return todayStartUtc().add(Duration(hours: hour, minutes: minute));
  }

  /// Retorna apenas a data do dia atual no Brasil (sem hora).
  static DateTime todayBrazilDate() {
    final n = nowBrazilUtc();
    return DateTime(n.year, n.month, n.day);
  }
}
