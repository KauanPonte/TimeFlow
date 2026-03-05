/// Repository for managing users and registration requests
class UserRepository {
  UserRepository._();

  // Mock data - simula dados do backend
  static final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'João Silva',
      'email': 'joao@empresa.com',
      'role': 'Administrador',
      'status': 'active',
      'registeredAt': '2024-01-15',
    },
    {
      'id': '2',
      'name': 'Maria Santos',
      'email': 'maria@empresa.com',
      'role': 'Funcionário',
      'status': 'active',
      'registeredAt': '2024-02-20',
    },
    {
      'id': '3',
      'name': 'Pedro Costa',
      'email': 'pedro@empresa.com',
      'role': 'Gerente',
      'status': 'active',
      'registeredAt': '2024-03-10',
    },
  ];

  static final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': 'req1',
      'name': 'Ana Oliveira',
      'email': 'ana@empresa.com',
      'requestedAt': '2024-12-15',
      'status': 'pending',
    },
    {
      'id': 'req2',
      'name': 'Carlos Ferreira',
      'email': 'carlos@empresa.com',
      'requestedAt': '2024-12-16',
      'status': 'pending',
    },
  ];

  /// Get all registered users
  static Future<List<Map<String, dynamic>>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_users);
  }

  /// Get pending registration requests
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_pendingRequests);
  }

  /// Get total users count
  static Future<int> getTotalUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _users.length;
  }

  /// Get pending requests count
  static Future<int> getPendingRequestsCount() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _pendingRequests.length;
  }

  /// Approve registration request with role
  static Future<bool> approveRequest({
    required String requestId,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final requestIndex =
        _pendingRequests.indexWhere((req) => req['id'] == requestId);

    if (requestIndex == -1) return false;

    final request = _pendingRequests[requestIndex];

    // Add to users with role
    _users.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': request['name'],
      'email': request['email'],
      'role': role,
      'status': 'active',
      'registeredAt': DateTime.now().toString().split(' ')[0],
    });

    // Remove from pending
    _pendingRequests.removeAt(requestIndex);

    return true;
  }

  /// Reject registration request
  static Future<bool> rejectRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final requestIndex =
        _pendingRequests.indexWhere((req) => req['id'] == requestId);

    if (requestIndex == -1) return false;

    _pendingRequests.removeAt(requestIndex);
    return true;
  }

  /// Delete user
  static Future<bool> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final userIndex = _users.indexWhere((user) => user['id'] == userId);

    if (userIndex == -1) return false;

    _users.removeAt(userIndex);
    return true;
  }

  /// Update user role
  static Future<bool> updateUserRole(String userId, String newRole) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final userIndex = _users.indexWhere((user) => user['id'] == userId);

    if (userIndex == -1) return false;

    _users[userIndex]['role'] = newRole;
    return true;
  }
}
