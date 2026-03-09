import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 🔔 Instância principal do plugin
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// -----------------------------------------------------------
  /// 🔧 Inicialização do sistema de notificações
  /// -----------------------------------------------------------
  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings);
  }

  /// -----------------------------------------------------------
  /// 🔔 Solicitar permissão no Android 13+
  /// -----------------------------------------------------------
  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// -----------------------------------------------------------
  /// 🚀 Notificação instantânea
  /// -----------------------------------------------------------
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Notificações Instantâneas',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// -----------------------------------------------------------
  /// ⏰ Notificação diária (ex: todos os dias 09:00)
  /// -----------------------------------------------------------
  static Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // se já passou hoje → agenda amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel',
        'Notificações Diárias',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        999,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback: agendamento inexato quando a permissão de alarme exato
      // não foi concedida pelo usuário (Android 12+).
      await _plugin.zonedSchedule(
        999,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
