import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DateFormat {
  static String format(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveEvent(
      DateTime date, String title, Color color, String eventType) async {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Usa coleção com subcoleção para suportar múltiplos eventos por dia
    await _db.collection('calendar_events').add({
      'date': Timestamp.fromDate(cleanDate),
      'dateId': DateFormat.format(cleanDate), // para facilitar queries
      'title': title,
      'colorValue': color.value,
      'type': eventType.toLowerCase().trim(),
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent(String docId) async {
    await _db.collection('calendar_events').doc(docId).delete();
  }

  Stream<Map<DateTime, List<Map<String, dynamic>>>> getEventsStream(int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);

    return _db
        .collection('calendar_events')
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
          'color': Color(data['colorValue'] ?? Colors.blue.value),
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
    final cleanDate = DateTime(date.year, date.month, date.day);
    final dateId = DateFormat.format(cleanDate);

    final snapshot = await _db
        .collection('calendar_events')
        .where('dateId', isEqualTo: dateId)
        .where('type', whereIn: ['feriado', 'recesso'])
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
