import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyReminderSettings {
  final TimeOfDay time;
  final bool enabled;

  const DailyReminderSettings({
    required this.time,
    required this.enabled,
  });
}

class NotificationService {
  static const int _dailyNotificationId = 999;
  static const String _dailyChannelId = 'daily_reminder_channel_v2';
  static const String _dailyChannelName = 'Lembrete Diário de Ponto';
  static const int _defaultDailyHour = 9;
  static const int _defaultDailyMinute = 0;
  static const bool _defaultDailyEnabled = true;
  static const String _usersCollection = 'usuarios';
  static const String _dailyReminderHourField = 'dailyReminderHour';
  static const String _dailyReminderMinuteField = 'dailyReminderMinute';
  static const String _dailyReminderEnabledField = 'dailyReminderEnabled';
  static const String _sessionUidKey = 'userUid';

  // Instância principal do plugin
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? _cachedUid;
  static bool _hasCachedSettings = false;
  static TimeOfDay _cachedDailyReminderTime = const TimeOfDay(
    hour: _defaultDailyHour,
    minute: _defaultDailyMinute,
  );
  static bool _cachedDailyReminderEnabled = _defaultDailyEnabled;

  /// Inicialização do sistema de notificações
  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android =
        AndroidInitializationSettings('@drawable/ic_launcher_foreground');

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings);
    await requestPermissions();
  }

  /// Solicitar permissão no Android 13+
  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    // Android 12+ pode exigir permissão explícita para alarmes exatos.
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {
      // Em plataformas/versões sem suporte, segue sem bloquear.
    }
  }

  /// Notificação instantânea
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await requestPermissions();

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

  static Future<String?> _resolveUid() async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) return authUid;

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionUidKey);
    if (uid == null || uid.isEmpty) return null;
    return uid;
  }

  static DailyReminderSettings _defaultSettings() {
    return const DailyReminderSettings(
      time: TimeOfDay(
        hour: _defaultDailyHour,
        minute: _defaultDailyMinute,
      ),
      enabled: _defaultDailyEnabled,
    );
  }

  static DailyReminderSettings _cachedSettings() {
    return DailyReminderSettings(
      time: _cachedDailyReminderTime,
      enabled: _cachedDailyReminderEnabled,
    );
  }

  static void _updateCache({
    required String uid,
    required TimeOfDay time,
    required bool enabled,
  }) {
    _cachedUid = uid;
    _hasCachedSettings = true;
    _cachedDailyReminderTime = time;
    _cachedDailyReminderEnabled = enabled;
  }

  static bool _canUseCache(String uid) {
    return _hasCachedSettings && _cachedUid == uid;
  }

  /// Carrega hora + status do lembrete do servidor e mantém em cache.
  static Future<DailyReminderSettings> preloadDailyReminderSettings({
    String? uid,
  }) async {
    final resolvedUid = uid ?? await _resolveUid();
    if (resolvedUid == null) {
      return _defaultSettings();
    }

    try {
      final snap =
          await _firestore.collection(_usersCollection).doc(resolvedUid).get();
      final data = snap.data() ?? <String, dynamic>{};

      final hour = (data[_dailyReminderHourField] as int?) ?? _defaultDailyHour;
      final minute =
          (data[_dailyReminderMinuteField] as int?) ?? _defaultDailyMinute;
      final enabled =
          (data[_dailyReminderEnabledField] as bool?) ?? _defaultDailyEnabled;

      final settings = DailyReminderSettings(
        time: TimeOfDay(hour: hour, minute: minute),
        enabled: enabled,
      );

      _updateCache(
        uid: resolvedUid,
        time: settings.time,
        enabled: settings.enabled,
      );
      return settings;
    } catch (_) {
      if (_canUseCache(resolvedUid)) return _cachedSettings();
      return _defaultSettings();
    }
  }

  static Future<DailyReminderSettings> getDailyReminderSettings(
      {String? uid}) async {
    final resolvedUid = uid ?? await _resolveUid();
    if (resolvedUid == null) return _defaultSettings();
    if (_canUseCache(resolvedUid)) return _cachedSettings();
    return preloadDailyReminderSettings(uid: resolvedUid);
  }

  /// Retorna o horário diário salvo no servidor para o usuário (ou 09:00).
  static Future<TimeOfDay> getDailyReminderTime({String? uid}) async {
    final settings = await getDailyReminderSettings(uid: uid);
    return settings.time;
  }

  static Future<bool> isDailyReminderEnabled({String? uid}) async {
    final settings = await getDailyReminderSettings(uid: uid);
    return settings.enabled;
  }

  /// Persiste no servidor o horário escolhido para o lembrete diário.
  static Future<void> saveDailyReminderTime({
    required int hour,
    required int minute,
    String? uid,
  }) async {
    final resolvedUid = uid ?? await _resolveUid();
    if (resolvedUid == null) return;

    await _firestore.collection(_usersCollection).doc(resolvedUid).set({
      _dailyReminderHourField: hour,
      _dailyReminderMinuteField: minute,
    }, SetOptions(merge: true));

    _updateCache(
      uid: resolvedUid,
      time: TimeOfDay(hour: hour, minute: minute),
      enabled: _canUseCache(resolvedUid)
          ? _cachedDailyReminderEnabled
          : _defaultDailyEnabled,
    );
  }

  static Future<void> setDailyReminderEnabled({
    required bool enabled,
    String? uid,
  }) async {
    final resolvedUid = uid ?? await _resolveUid();
    if (resolvedUid == null) return;

    await _firestore.collection(_usersCollection).doc(resolvedUid).set({
      _dailyReminderEnabledField: enabled,
    }, SetOptions(merge: true));

    _updateCache(
      uid: resolvedUid,
      time: _canUseCache(resolvedUid)
          ? _cachedDailyReminderTime
          : const TimeOfDay(
              hour: _defaultDailyHour,
              minute: _defaultDailyMinute,
            ),
      enabled: enabled,
    );

    if (enabled) {
      await scheduleSavedDailyReminder(uid: resolvedUid);
    } else {
      await cancelDailyReminder();
    }
  }

  /// Agenda o lembrete diário usando o horário salvo no servidor.
  static Future<void> scheduleSavedDailyReminder({String? uid}) async {
    final settings = await getDailyReminderSettings(uid: uid);
    if (!settings.enabled) {
      await cancelDailyReminder();
      return;
    }

    final time = settings.time;
    await scheduleDailyNotification(
      title: _getGreeting(time.hour),
      body: 'Mais um day office! Já bateu seu ponto hoje?',
      hour: time.hour,
      minute: time.minute,
    );
  }

  /// Garante que o lembrete diário esteja realmente agendado no SO.
  ///
  /// Em alguns aparelhos, o agendamento pode ser removido pelo sistema.
  /// Esse método verifica pendências e recria quando necessário.
  static Future<void> ensureDailyReminderScheduled({String? uid}) async {
    final settings = await getDailyReminderSettings(uid: uid);
    if (!settings.enabled) {
      await cancelDailyReminder();
      return;
    }

    final pending = await _plugin.pendingNotificationRequests();
    final alreadyScheduled = pending.any((n) => n.id == _dailyNotificationId);

    if (alreadyScheduled) return;

    await scheduleDailyNotification(
      title: _getGreeting(settings.time.hour),
      body: 'Mais um day office! Já bateu seu ponto hoje?',
      hour: settings.time.hour,
      minute: settings.time.minute,
    );
  }

  /// Salva e agenda imediatamente o lembrete diário.
  static Future<void> updateAndScheduleDailyReminder({
    required int hour,
    required int minute,
    String? uid,
  }) async {
    await saveDailyReminderTime(hour: hour, minute: minute, uid: uid);
    await scheduleSavedDailyReminder(uid: uid);
  }

  /// Reagenda o lembrete da última conta logada no dispositivo.
  static Future<void> scheduleForLastLoggedUser() async {
    final uid = await _resolveUid();
    if (uid == null) {
      await cancelDailyReminder();
      return;
    }
    await preloadDailyReminderSettings(uid: uid);
    await ensureDailyReminderScheduled(uid: uid);
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  /// Notificação diária
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
        _dailyChannelId,
        _dailyChannelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await requestPermissions();
    // Evita estados inconsistentes quando o SO mantém um agendamento antigo.
    await cancelDailyReminder();

    try {
      await _plugin.zonedSchedule(
        _dailyNotificationId,
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
        _dailyNotificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    final pending = await _plugin.pendingNotificationRequests();
    final isScheduled = pending.any((n) => n.id == _dailyNotificationId);
    if (!isScheduled) {
      throw Exception('Falha ao agendar lembrete diário no sistema.');
    }
  }

  static String _getGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Bom dia! ☀️';
    } else if (hour >= 12 && hour < 18) {
      return 'Boa tarde! 🌤️';
    } else {
      return 'Boa noite! 🌙';
    }
  }
}
