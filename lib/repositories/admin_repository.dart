import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Buscar todos os usuários (exceto admins)
  Future<List<Map<String, dynamic>>> getEmployees() async {
    // Busca na coleção 'usuarios' onde o campo 'role' não é 'ADM'
    final snapshot = await _firestore
        .collection('usuarios')
        .where('role', isNotEqualTo: 'ADM')
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAdmins() async {
    final snapshot = await _firestore
        .collection('usuarios')
        .where('role', isEqualTo: 'ADM') // Busca apenas ADMs
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  /// Buscar funcionário específico
  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    final doc = await _firestore.collection('usuarios').doc(id).get();

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
