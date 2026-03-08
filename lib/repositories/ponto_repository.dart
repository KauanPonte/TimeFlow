import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
//Onde os dados são salvos e lidos 
class PontoRepository {
  static const _kRegistrosKey = 'registros';

  Future<Map<String, dynamic>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final registrosJson = prefs.getString(_kRegistrosKey);

    if (registrosJson == null || registrosJson.isEmpty) return {};

    try {
      return jsonDecode(registrosJson) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveRegistro(
      String data, String status, String hora) async {
    final prefs = await SharedPreferences.getInstance();
    final registros = await _loadRaw();

    final hojeMap = (registros[data] is Map)
        ? Map<String, dynamic>.from(registros[data])
        : <String, dynamic>{};

    hojeMap[status] = hora;
    registros[data] = hojeMap;

    await prefs.setString(_kRegistrosKey, jsonEncode(registros));
  }

  Future<Map<String, Map<String, String>>> loadRegistros() async {
    final raw = await _loadRaw();
    final Map<String, Map<String, String>> result = {};

    raw.forEach((date, map) {
      if (map is Map) {
        result[date] =
            Map<String, String>.from(map.map((k, v) => MapEntry(
                  k.toString(),
                  v.toString(),
                )));
      }
    });

    return result;
  }
}
