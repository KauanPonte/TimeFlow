import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Buscar todos os usuários
  Future<List<Map<String, dynamic>>> getEmployees() async {
    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  /// Buscar funcionário específico
  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  /// Buscar registros de ponto do mês
  Future<List<Map<String, dynamic>>> getEmployeePunches(
      String userId, String month) async {
    final snapshot = await _firestore
        .collection('punches')
        .doc(userId)
        .collection(month)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}