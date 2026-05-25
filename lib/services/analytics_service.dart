import 'package:firebase_analytics/firebase_analytics.dart';

/// Serviço centralizado para logging de eventos do Firebase Analytics.
///
/// Uso:
/// ```dart
/// AnalyticsService.logUserLogin(method: 'email');
/// AnalyticsService.logUserLogout();
/// AnalyticsService.logEvent('custom_event', {'key': 'value'});
/// ```
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Registra login de usuário
  static Future<void> logUserLogin({
    required String method,
    String? userId,
  }) async {
    await _analytics.logEvent(
      name: 'user_login',
      parameters: {
        'method': method,
        'actor_user_id': userId ?? 'anonymous',
      },
    );
  }

  /// Registra logout de usuário
  static Future<void> logUserLogout({String? userId}) async {
    await _analytics.logEvent(
      name: 'user_logout',
      parameters: {
        'actor_user_id': userId ?? 'anonymous',
      },
    );
  }

  /// Registra registro de novo usuário
  static Future<void> logUserSignUp({
    required String method,
    String? userId,
  }) async {
    await _analytics.logEvent(
      name: 'sign_up',
      parameters: {
        'method': method,
        'actor_user_id': userId ?? 'anonymous',
      },
    );
  }

  /// Registra abertura de relatório de usuário (admin)
  static Future<void> logAdminOpenUserReport({
    required String userId,
    String? adminUid,
  }) async {
    await _analytics.logEvent(
      name: 'rad_report_opened',
      parameters: {
        'target_user_id': userId,
        'admin_uid': adminUid ?? 'unknown',
      },
    );
  }

  /// Registra o RAD aberto ou recalculado pelo administrador.
  static Future<void> logRadReportViewed({
    required String targetUserId,
    required String month,
    String? adminUid,
    int? daysWithPunches,
    int? workedMinutes,
    int? openDays,
  }) async {
    await _analytics.logEvent(
      name: 'rad_report_viewed',
      parameters: {
        'target_user_id': targetUserId,
        'month': month,
        'admin_uid': adminUid ?? 'unknown',
        'days_with_punches': daysWithPunches ?? 0,
        'worked_minutes': workedMinutes ?? 0,
        'open_days': openDays ?? 0,
      },
    );
  }

  /// Registra visualização de histórico de pontos
  static Future<void> logViewPointHistory({
    required String userId,
    int? entriesCount,
  }) async {
    await _analytics.logEvent(
      name: 'view_point_history',
      parameters: {
        'userId': userId,
        'entriesCount': entriesCount ?? 0,
      },
    );
  }

  /// Registra registro de ponto (clock-in/clock-out)
  static Future<void> logPointEntry({
    required String userId,
    required String type,
    String? workMode,
  }) async {
    await _analytics.logEvent(
      name: 'rad_point_entry',
      parameters: {
        'actor_user_id': userId,
        'type': type,
        'work_mode': workMode ?? 'unknown',
      },
    );
  }

  /// Registra envio de justificativa
  static Future<void> logJustificationSubmitted({
    required String userId,
    required String type,
    int? minutesRequested,
  }) async {
    await _analytics.logEvent(
      name: 'justification_submitted',
      parameters: {
        'actor_user_id': userId,
        'type': type,
        'minutes_requested': minutesRequested ?? 0,
      },
    );
  }

  /// Registra envio de atestado
  static Future<void> logCertificateSubmitted({
    required String userId,
    int? daysRequested,
  }) async {
    await _analytics.logEvent(
      name: 'certificate_submitted',
      parameters: {
        'actor_user_id': userId,
        'days_requested': daysRequested ?? 0,
      },
    );
  }

  /// Registra ação de administrador (editar, deletar usuário)
  static Future<void> logAdminAction({
    required String action,
    required String targetUserId,
    String? adminUid,
  }) async {
    await _analytics.logEvent(
      name: 'admin_action',
      parameters: {
        'action': action,
        'target_user_id': targetUserId,
        'admin_uid': adminUid ?? 'unknown',
      },
    );
  }

  /// Registra erro ou exceção
  static Future<void> logError({
    required String code,
    required String message,
    String? context,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'code': code,
        'message': message,
        'context': context ?? 'unknown',
      },
    );
  }

  /// Registra evento customizado genérico
  static Future<void> logEvent(
    String name,
    Map<String, Object>? parameters,
  ) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Configura ID do usuário para segmentação de analytics
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Remove ID do usuário (logout)
  static Future<void> clearUserId() async {
    await _analytics.setUserId(id: null);
  }

  /// Define propriedade de usuário (ex: role, plano, etc)
  static Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
