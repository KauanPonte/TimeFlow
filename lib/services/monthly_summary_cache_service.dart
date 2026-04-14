import 'package:flutter_application_appdeponto/services/ponto_service.dart';

class MonthlySummaryCacheService {
  MonthlySummaryCacheService._();

  static final MonthlySummaryCacheService _instance =
      MonthlySummaryCacheService._();

  factory MonthlySummaryCacheService() => _instance;

  final Map<String, MesResumo> _monthCache = {};

  String keyFor(String uid, DateTime month) =>
      '${uid}_${month.year}_${month.month}';

  MesResumo? get(String uid, DateTime month) => _monthCache[keyFor(uid, month)];

  bool has(String uid, DateTime month) =>
      _monthCache.containsKey(keyFor(uid, month));

  void set(String uid, DateTime month, MesResumo resumo) {
    _monthCache[keyFor(uid, month)] = resumo;
  }

  void invalidateMonth(String uid, DateTime month) {
    _monthCache.remove(keyFor(uid, month));
  }

  void invalidateUid(String uid) {
    _monthCache.removeWhere((key, _) => key.startsWith('${uid}_'));
  }

  void clear() => _monthCache.clear();
}
