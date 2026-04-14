import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing users and registration requests via Firebase
class UserRepository {
  UserRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';

//conversor de cargaHoraria
  static int _parseCargaHoraria(String input) {
    input = input.trim();

    if (input.contains(':')) {
      final parts = input.split(':');

      if (parts.length != 2) {
        throw Exception('Formato inválido. Use 8 ou 8:30');
      }

      final horas = int.parse(parts[0]);
      final minutos = int.parse(parts[1]);

      if (minutos >= 60) {
        throw Exception('Minutos inválidos');
      }

      return horas * 60 + minutos;
    }

    return int.parse(input) * 60;
  }

  /// Get all registered users (status == 'active'), excluding [excludeUid],
  /// sorted alphabetically by role.
  static Future<List<Map<String, dynamic>>> getUsers({
    String? excludeUid,
    bool includeTodayStatus = false,
  }) async {
    final todayWorkModes =
        includeTodayStatus ? await _loadTodayPunchWorkModes() : {};

    final snapshot = await _db
        .collection(_usersCollection)
        .where('status', isEqualTo: 'active')
        .get();

    final users = snapshot.docs
        .where((doc) => excludeUid == null || doc.id != excludeUid)
        .map((doc) {
      final data = doc.data();
      final todayWorkMode = todayWorkModes[doc.id];

      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'role': data['role'] ?? '',
        'status': data['status'] ?? '',
        'workloadMinutes': data['workloadMinutes'] ?? 0,
        'registeredAt': _formatTimestamp(data['createdAt']),
        'profileImage': data['profileImage'] ?? '',
        'todayWorkMode': todayWorkMode ?? '',
        'didPunchToday': todayWorkMode != null,
      };
    }).toList();

    // Sort alphabetically by role, then by name within the same role
    users.sort((a, b) {
      final roleComp = (a['role'] as String)
          .toLowerCase()
          .compareTo((b['role'] as String).toLowerCase());
      if (roleComp != 0) return roleComp;
      return (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase());
    });

    return users;
  }

  static Future<Map<String, String>> _loadTodayPunchWorkModes() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final snapshot = await _db
        .collectionGroup('eventos')
        .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('at', isLessThan: Timestamp.fromDate(tomorrowStart))
        .orderBy('at', descending: false)
        .get();

    final Map<String, String> workModes = {};

    for (final doc in snapshot.docs) {
      final workMode = (doc.data()['workMode'] ?? '').toString().toLowerCase();
      if (workMode != 'presencial' && workMode != 'remoto') continue;

      final segments = doc.reference.path.split('/');
      if (segments.length < 2) continue;
      final userId = segments[1];

      if (!workModes.containsKey(userId)) {
        workModes[userId] = workMode;
      }
    }

    return workModes;
  }

  /// Get pending registration requests (status == 'pending')
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final snapshot = await _db
        .collection(_usersCollection)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'requestedAt': _formatTimestamp(data['createdAt']),
        'status': 'pending',
      };
    }).toList();
  }

  /// Get total active users count
  static Future<int> getTotalUsers() async {
    final snapshot = await _db
        .collection(_usersCollection)
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get pending requests count
  static Future<int> getPendingRequestsCount() async {
    final snapshot = await _db
        .collection(_usersCollection)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Approve registration request with role e cargaHoraria
  static Future<bool> approveRequest({
    required String requestId,
    required String cargaHoraria,
    required String role,
  }) async {
    try {
      final workloadMinutes = _parseCargaHoraria(cargaHoraria);
      await _db.collection(_usersCollection).doc(requestId).update({
        'status': 'active',
        'workloadMinutes': workloadMinutes,
        'role': role,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject registration request
  static Future<bool> rejectRequest(String requestId) async {
    try {
      // Remove the Firestore document
      await _db.collection(_usersCollection).doc(requestId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete user
  static Future<bool> deleteUser(String userId) async {
    try {
      await _db.collection(_usersCollection).doc(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user role
  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _db.collection(_usersCollection).doc(userId).update({
        'role': newRole,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user workload in minutes.
  /// Uses merge to avoid NOT_FOUND when the document does not exist yet.
  static Future<bool> updateUserWorkload(
    String userId,
    int workloadMinutes,
  ) async {
    try {
      await _db.collection(_usersCollection).doc(userId).set({
        'workloadMinutes': workloadMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper to format Firestore Timestamp to a date string
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }
}
