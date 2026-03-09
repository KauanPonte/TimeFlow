import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing users and registration requests via Firebase
class UserRepository {
  UserRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';

  /// Get all registered users (status == 'active'), excluding [excludeUid],
  /// sorted alphabetically by role.
  static Future<List<Map<String, dynamic>>> getUsers({
    String? excludeUid,
  }) async {
    final snapshot = await _db
        .collection(_usersCollection)
        .where('status', isEqualTo: 'active')
        .get();

    final users = snapshot.docs
        .where((doc) => excludeUid == null || doc.id != excludeUid)
        .map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'role': data['role'] ?? '',
        'status': data['status'] ?? '',
        'registeredAt': _formatTimestamp(data['createdAt']),
        'profileImage': data['profileImage'] ?? '',
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

  /// Approve registration request with role
  static Future<bool> approveRequest({
    required String requestId,
    required String role,
  }) async {
    try {
      await _db.collection(_usersCollection).doc(requestId).update({
        'status': 'active',
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
