import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum HistoryViewPreference {
  list,
  calendar,
}

extension HistoryViewPreferenceX on HistoryViewPreference {
  String get storageValue {
    switch (this) {
      case HistoryViewPreference.list:
        return 'list';
      case HistoryViewPreference.calendar:
        return 'calendar';
    }
  }

  static HistoryViewPreference fromStorage(String? raw) {
    switch (raw) {
      case 'calendar':
        return HistoryViewPreference.calendar;
      case 'list':
      default:
        return HistoryViewPreference.list;
    }
  }
}

class HistoryViewPreferenceRepository {
  static const String _usersCollection = 'usuarios';
  static const String _fieldName = 'historyViewMode';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  HistoryViewPreferenceRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<HistoryViewPreference> loadPreferredMode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return HistoryViewPreference.list;
    }

    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      final raw = (doc.data()?[_fieldName] ?? '').toString();
      return HistoryViewPreferenceX.fromStorage(raw);
    } catch (_) {
      return HistoryViewPreference.list;
    }
  }

  Future<void> savePreferredMode(HistoryViewPreference mode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await _firestore.collection(_usersCollection).doc(uid).set({
      _fieldName: mode.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
