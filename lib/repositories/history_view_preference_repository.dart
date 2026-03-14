import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _localKeyPrefix = 'historyViewMode';

  static HistoryViewPreference _cachedMode = HistoryViewPreference.list;
  static String? _cachedUid;
  static bool _initialized = false;

  static HistoryViewPreference get currentMode => _cachedMode;

  static String _localKeyFor(String uid) => '$_localKeyPrefix:$uid';

  static Future<void> initialize({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    final currentAuth = auth ?? FirebaseAuth.instance;
    final currentFirestore = firestore ?? FirebaseFirestore.instance;
    final uid = currentAuth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _cachedMode = HistoryViewPreference.list;
      _cachedUid = null;
      _initialized = true;
      return;
    }

    if (_initialized && _cachedUid == uid) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localRaw = prefs.getString(_localKeyFor(uid));
    _cachedMode = HistoryViewPreferenceX.fromStorage(localRaw);
    _cachedUid = uid;
    _initialized = true;

    try {
      final doc =
          await currentFirestore.collection(_usersCollection).doc(uid).get();
      final remoteRaw = (doc.data()?[_fieldName] ?? '').toString();
      final remoteMode = HistoryViewPreferenceX.fromStorage(remoteRaw);
      _cachedMode = remoteMode;
      await prefs.setString(_localKeyFor(uid), remoteMode.storageValue);
    } catch (_) {
      // Mantém valor local em caso de falha de rede.
    }
  }

  static void clearCache() {
    _cachedMode = HistoryViewPreference.list;
    _cachedUid = null;
    _initialized = false;
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  HistoryViewPreferenceRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<HistoryViewPreference> loadPreferredMode() async {
    await HistoryViewPreferenceRepository.initialize(
      auth: _auth,
      firestore: _firestore,
    );
    return _cachedMode;
  }

  Future<void> savePreferredMode(HistoryViewPreference mode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    _cachedMode = mode;
    _cachedUid = uid;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKeyFor(uid), mode.storageValue);

    await _firestore.collection(_usersCollection).doc(uid).set({
      _fieldName: mode.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
