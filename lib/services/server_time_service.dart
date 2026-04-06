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

  /// Retorna o horário atual corrigido pelo offset do servidor.
  static DateTime now() => DateTime.now().add(_offset);

  /// Indica se já houve pelo menos uma sincronização bem-sucedida.
  static bool get isSynced => _synced;

  /// Sincroniza o offset local ↔ servidor.
  ///
  /// Escreve um timestamp via `FieldValue.serverTimestamp()` num doc
  /// temporário, lê de volta, e calcula a diferença.
  static Future<void> sync() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('_server_time')
          .doc('probe');

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

  /// Retorna um `Timestamp` Firestore usando o horário corrigido,
  /// truncado ao minuto (sem segundos).
  static Timestamp nowTimestampTruncated() {
    final n = now();
    return Timestamp.fromDate(DateTime(n.year, n.month, n.day, n.hour, n.minute));
  }

  /// Retorna o ID do dia de hoje (yyyy-MM-dd) usando horário do servidor.
  static String todayId() {
    final n = now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }
}
