import 'package:flutter/foundation.dart';
import 'package:flutter_application_appdeponto/repositories/atestado_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço singleton para cache global de dias com atestado (facultativo)
/// Mantém a persistência dos dados entre navegações diferentes páginas/widgets
class ExcusedDaysCacheService {
  static final ExcusedDaysCacheService _instance =
      ExcusedDaysCacheService._internal();

  factory ExcusedDaysCacheService() {
    return _instance;
  }

  ExcusedDaysCacheService._internal();

  /// Cache global: uid → Set de dayIds com atestado aprovado
  /// Estrutura: "2024-01-15", "2024-01-16", etc
  final Map<String, Set<String>> _fullExcusedDaysCache = {};

  /// Controla requests em andamento para evitar recálculo concorrente.
  final Map<String, Future<Set<String>>> _inflightLoads = {};

  final _atestadoRepository = AtestadoRepository();

  /// Obtém dias com atestado aprovado para um UID, usando cache global
  Future<Set<String>> getExcusedDays(String uid) async {
    // Se já temos no cache, retorna imediatamente
    if (_fullExcusedDaysCache.containsKey(uid)) {
      return _fullExcusedDaysCache[uid]!;
    }

    // Se já há carregamento em andamento para o UID, reaproveita o mesmo Future.
    final ongoing = _inflightLoads[uid];
    if (ongoing != null) {
      return await ongoing;
    }

    // Caso contrário, carrega do Firestore
    final future = _loadExcusedDays(uid);
    _inflightLoads[uid] = future;

    try {
      return await future;
    } finally {
      _inflightLoads.remove(uid);
    }
  }

  /// Filtra dias excusados para um mês específico
  Set<String> getExcusedDaysForMonth(String uid, DateTime month) {
    if (!_fullExcusedDaysCache.containsKey(uid)) {
      return {};
    }

    final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final fullSet = _fullExcusedDaysCache[uid]!;
    return fullSet.where((id) => id.startsWith(prefix)).toSet();
  }

  /// Verifica se o UID já possui cache completo carregado em memória.
  bool hasCachedExcusedDays(String uid) {
    return _fullExcusedDaysCache.containsKey(uid);
  }

  /// Retorna os dias do mês a partir do cache em memória, sem I/O.
  /// Retorna null quando o UID ainda não foi carregado.
  Set<String>? peekCachedExcusedDaysForMonth(String uid, DateTime month) {
    if (!_fullExcusedDaysCache.containsKey(uid)) return null;
    return getExcusedDaysForMonth(uid, month);
  }

  /// Carrega os IDs de dias com atestado aprovado (isExcused = true)
  Future<Set<String>> _loadExcusedDays(String uid) async {
    try {
      final Set<String> excused = {};

      // 1. Atestados aprovados (calculando os intervalos)
      final atestados =
          await _atestadoRepository.getApprovedAtestadosForUser(uid);
      for (final a in atestados) {
        final startLocal = DateTime.tryParse(a.dataInicio);
        final endLocal = DateTime.tryParse(a.dataFim);
        if (startLocal != null && endLocal != null) {
          final start = DateTime.utc(
              startLocal.year, startLocal.month, startLocal.day, 12);
          final end =
              DateTime.utc(endLocal.year, endLocal.month, endLocal.day, 12);
          for (var d = start;
              !d.isAfter(end);
              d = d.add(const Duration(days: 1))) {
            excused.add(
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
          }
        }
      }

      // 2. Dias marcados individualmente com isExcused = true
      final diasSnap = await FirebaseFirestore.instance
          .collection('pontos')
          .doc(uid)
          .collection('dias')
          .where('isExcused', isEqualTo: true)
          .get();

      for (final doc in diasSnap.docs) {
        excused.add(doc.id);
      }

      // Armazena no cache global
      _fullExcusedDaysCache[uid] = excused;

      return excused;
    } catch (e) {
      debugPrintStack(label: 'Erro ao carregar dias excusados: $e');
      return {};
    }
  }

  /// Invalida cache para um UID específico (útil após aprovação de atestado)
  void invalidateCache(String uid) {
    _fullExcusedDaysCache.remove(uid);
    _inflightLoads.remove(uid);
  }

  /// Invalida todo o cache global
  void clearAllCache() {
    _fullExcusedDaysCache.clear();
    _inflightLoads.clear();
  }

  /// Força reload dos dados para um UID
  Future<Set<String>> reloadExcusedDays(String uid) async {
    _fullExcusedDaysCache.remove(uid);
    _inflightLoads.remove(uid);
    return await _loadExcusedDays(uid);
  }
}
