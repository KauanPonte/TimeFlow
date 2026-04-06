import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importe a lib intl para formatar datas corretamente

class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nome da coleção centralizado para evitar erros de digitação
  static const String _collectionPath = 'calendar_events';

  // Cache estático para evitar recálculos e queries repetidas na mesma sessão
  static final Map<String, List<String>> _workloadReductionCache = {};
  static final Map<int, Map<DateTime, String>> _brazilHolidaysCache = {};

  /// Formata DateTime para o ID usado nas queries do banco
  String _formatDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> saveEvent(
      DateTime date, String title, Color color, String eventType) async {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await _db.collection(_collectionPath).add({
      'date': Timestamp.fromDate(cleanDate),
      'dateId': _formatDateId(cleanDate),
      'title': title,
      'colorValue': color.toARGB32(),
      'type': eventType.toLowerCase().trim(),
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'year':
          cleanDate.year, // Guardamos o ano para facilitar a query de folgas
      'month': cleanDate.month,
    });
  }

  Future<List<String>> getDaysThatReduceWorkload(int year, int month) async {
    final cacheKey = '$year-$month';
    if (_workloadReductionCache.containsKey(cacheKey)) {
      return _workloadReductionCache[cacheKey]!;
    }

    // 1. Pega os feriados fixos da sua lógica (Brasil/CE)
    final holidaysMap = getBrazilHolidays(year);
    List<String> list = [];

    holidaysMap.forEach((date, name) {
      if (date.month == month) {
        list.add(_formatDateId(date));
      }
    });

    // 2. Busca no Firestore os eventos que o Admin cadastrou como 'feriado' ou 'recesso'
    final snap = await _db
        .collection(_collectionPath)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .where('type', whereIn: ['feriado', 'recesso']).get();

    for (var doc in snap.docs) {
      final data = doc.data();
      if (data.containsKey('dateId')) {
        list.add(data['dateId']);
      }
    }

    final result = list.toSet().toList(); // Remove duplicados
    _workloadReductionCache[cacheKey] = result;
    return result;
  }

  Future<void> deleteEvent(String docId) async {
    await _db.collection(_collectionPath).doc(docId).delete();
  }

  Stream<Map<DateTime, List<Map<String, dynamic>>>> getEventsStream(int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);

    return _db
        .collection(_collectionPath)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .snapshots()
        .map((snapshot) {
      final Map<DateTime, List<Map<String, dynamic>>> result = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        final date = timestamp.toDate();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final event = {
          'id': doc.id,
          'title': data['title'] ?? '',
          'color': Color(data['colorValue'] ?? Colors.blue.toARGB32()),
          'type': data['type'] ?? '',
          'userId': data['userId'] ?? '',
        };

        if (result.containsKey(normalizedDate)) {
          result[normalizedDate]!.add(event);
        } else {
          result[normalizedDate] = [event];
        }
      }
      return result;
    });
  }

  Future<bool> isDayBlocked(DateTime date) async {
    final dateId = _formatDateId(date);

    final snapshot = await _db
        .collection(_collectionPath)
        .where('dateId', isEqualTo: dateId)
        .where('type', whereIn: ['feriado', 'recesso'])
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Lógica de Feriados movida para o Service para ser acessível globalmente
  Map<DateTime, String> getBrazilHolidays(int year) {
    if (_brazilHolidaysCache.containsKey(year)) {
      return _brazilHolidaysCache[year]!;
    }
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
      DateTime(year, 3, 19): "São José (CE)",
      DateTime(year, 3, 25): "Data Magna (CE)",
    };

    // --- Lógica simplificada da Páscoa/Carnaval/Corpus Christi ---
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

    _brazilHolidaysCache[year] = holidays;
    return holidays;
  }
}
