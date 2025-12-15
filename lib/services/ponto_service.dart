// lib/services/ponto_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class PontoService {
  static const _kRegistrosKey = 'registros';

  /// Registra um ponto com a chave [status] (ex: 'entrada','pausa','retorno','saida').
  /// Precisa do [context] apenas para mostrar SnackBar.
  static Future<void> registrarPonto(
      BuildContext context, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final horaAtual = DateFormat('HH:mm').format(DateTime.now());

    Map<String, dynamic> registros = {};

    final registrosJson = prefs.getString(_kRegistrosKey);
    if (registrosJson != null && registrosJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(registrosJson);
        if (decoded is Map<String, dynamic>) registros = decoded;
      } catch (_) {
        // se JSON estiver inválido, reiniciamos registros
        registros = {};
      }
    }

    // assegura que existe mapa para a data
    final hojeMap = (registros[hoje] is Map)
        ? Map<String, dynamic>.from(registros[hoje])
        : <String, dynamic>{};
    hojeMap[status] = horaAtual;
    registros[hoje] = hojeMap;

    await prefs.setString(_kRegistrosKey, jsonEncode(registros));

    CustomSnackbar.showSuccess(
      context,
      'Ponto "$status" registrado às $horaAtual',
    );
  }

  /// Carrega todos os registros em forma de Map<yyyy-MM-dd, Map<status, hora>>
  static Future<Map<String, Map<String, String>>> loadRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final registrosJson = prefs.getString(_kRegistrosKey);
    if (registrosJson == null || registrosJson.isEmpty) return {};

    try {
      final decoded = jsonDecode(registrosJson) as Map<String, dynamic>;
      final Map<String, Map<String, String>> result = {};
      decoded.forEach((date, map) {
        if (map is Map) {
          result[date] = Map<String, String>.from(
              map.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }
}
