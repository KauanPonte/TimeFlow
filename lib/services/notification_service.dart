import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/scheduled_reminder.dart';

class NotificationService {
  static const String _usersCollection = 'usuarios';
  static const String _sessionUidKey = 'userUid';

  // Instância principal do plugin
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? _cachedUid;

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

  /// Reagenda o lembrete da última conta logada no dispositivo.
  static Future<void> scheduleForLastLoggedUser() async {
    final uid = await _resolveUid();
    if (uid == null) {
      await cancelAllScheduledReminders();
      return;
    }
    await scheduleAllReminders(uid: uid);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 NOTIFICAÇÕES AGENDADAS POR CATEGORIA (entrada, pausa, volta, saída)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _scheduledRemindersField = 'scheduledReminders';
  static const String _scheduledChannelId = 'scheduled_reminders_channel';
  static const String _scheduledChannelName = 'Lembretes Agendados';

  // Cache de lembretes agendados
  static List<ScheduledReminder> _cachedScheduledReminders = [];
  static bool _hasLoadedScheduledReminders = false;

  /// Carrega todos os lembretes agendados do usuário.
  static Future<List<ScheduledReminder>> getScheduledReminders({
    String? uid,
  }) async {
    final resolvedUid = uid ?? await _resolveUid();
    if (resolvedUid == null) return [];

    // Retorna do cache se já carregado para o mesmo usuário
    if (_hasLoadedScheduledReminders && _cachedUid == resolvedUid) {
      return List.unmodifiable(_cachedScheduledReminders);
    }

    try {
      final snap =
          await _firestore.collection(_usersCollection).doc(resolvedUid).get();
      final data = snap.data();
      if (data == null || !data.containsKey(_scheduledRemindersField)) {
        _cachedScheduledReminders = [];
        _hasLoadedScheduledReminders = true;
        _cachedUid = resolvedUid;
        return [];
      }

      final remindersList = data[_scheduledRemindersField] as List<dynamic>;
      _cachedScheduledReminders = remindersList
          .map((e) => ScheduledReminder.fromFirestore(e as Map<String, dynamic>))
          .toList();
      _hasLoadedScheduledReminders = true;
      _cachedUid = resolvedUid;

      return List.unmodifiable(_cachedScheduledReminders);
    } catch (_) {
      return List.unmodifiable(_cachedScheduledReminders);
    }
  }

  /// Salva a lista de lembretes agendados no Firestore.
  static Future<void> saveScheduledReminders(
    List<ScheduledReminder> reminders, {
    String? uid,
  }) async {
    final resolvedUid = uid ?? await _resolveUid();
    if (resolvedUid == null) return;

    await _firestore.collection(_usersCollection).doc(resolvedUid).set({
      _scheduledRemindersField: reminders.map((r) => r.toFirestore()).toList(),
    }, SetOptions(merge: true));

    _cachedScheduledReminders = List.from(reminders);
    _hasLoadedScheduledReminders = true;
    _cachedUid = resolvedUid;
  }

  /// Adiciona um novo lembrete agendado.
  static Future<void> addScheduledReminder(
    ScheduledReminder reminder, {
    String? uid,
  }) async {
    final current = await getScheduledReminders(uid: uid);
    final updated = [...current, reminder];
    await saveScheduledReminders(updated, uid: uid);
    
    if (reminder.enabled) {
      await _scheduleReminder(reminder);
    }
  }

  /// Atualiza um lembrete existente.
  static Future<void> updateScheduledReminder(
    ScheduledReminder reminder, {
    String? uid,
  }) async {
    final current = await getScheduledReminders(uid: uid);
    final index = current.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;

    final updated = List<ScheduledReminder>.from(current);
    updated[index] = reminder;
    await saveScheduledReminders(updated, uid: uid);

    // Cancela a notificação anterior e reagenda se habilitada
    await _cancelReminder(reminder);
    if (reminder.enabled) {
      await _scheduleReminder(reminder);
    }
  }

  /// Remove um lembrete agendado.
  static Future<void> removeScheduledReminder(
    String reminderId, {
    String? uid,
  }) async {
    final current = await getScheduledReminders(uid: uid);
    final reminder = current.cast<ScheduledReminder?>().firstWhere(
          (r) => r?.id == reminderId,
          orElse: () => null,
        );

    if (reminder != null) {
      await _cancelReminder(reminder);
    }

    final updated = current.where((r) => r.id != reminderId).toList();
    await saveScheduledReminders(updated, uid: uid);
  }

  /// Alterna o estado habilitado/desabilitado de um lembrete.
  static Future<void> toggleScheduledReminder(
    String reminderId, {
    required bool enabled,
    String? uid,
  }) async {
    final current = await getScheduledReminders(uid: uid);
    final index = current.indexWhere((r) => r.id == reminderId);
    if (index == -1) return;

    final updated = List<ScheduledReminder>.from(current);
    updated[index] = updated[index].copyWith(enabled: enabled);
    await saveScheduledReminders(updated, uid: uid);

    if (enabled) {
      await _scheduleReminder(updated[index]);
    } else {
      await _cancelReminder(updated[index]);
    }
  }

  /// Agenda todas as notificações habilitadas do usuário.
  static Future<void> scheduleAllReminders({String? uid}) async {
    final reminders = await getScheduledReminders(uid: uid);
    
    for (final reminder in reminders) {
      if (reminder.enabled) {
        await _scheduleReminder(reminder);
      }
    }
  }

  /// Cancela todas as notificações agendadas do usuário.
  static Future<void> cancelAllScheduledReminders({String? uid}) async {
    final reminders = await getScheduledReminders(uid: uid);
    
    for (final reminder in reminders) {
      await _cancelReminder(reminder);
    }
  }

  /// Agenda uma notificação individual.
  static Future<void> _scheduleReminder(ScheduledReminder reminder) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );

    // Se já passou hoje, agenda para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _scheduledChannelId,
        _scheduledChannelName,
        importance: Importance.max,
        priority: Priority.high,
        color: reminder.category.color,
      ),
    );

    final title = reminder.label ?? reminder.category.notificationTitle;
    final body = reminder.category.notificationBody;

    try {
      await _plugin.zonedSchedule(
        reminder.notificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback para agendamento inexato
      await _plugin.zonedSchedule(
        reminder.notificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Cancela uma notificação individual.
  static Future<void> _cancelReminder(ScheduledReminder reminder) async {
    await _plugin.cancel(reminder.notificationId);
  }

  /// Invalida o cache de lembretes agendados.
  static void invalidateScheduledRemindersCache() {
    _hasLoadedScheduledReminders = false;
    _cachedScheduledReminders = [];
  }
}
