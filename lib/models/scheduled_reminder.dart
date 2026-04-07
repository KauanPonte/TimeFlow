import 'package:flutter/material.dart';

/// Categoria de lembrete de ponto.
enum ReminderCategory {
  entrada,
  pausa,
  volta,
  saida;

  String get label {
    switch (this) {
      case ReminderCategory.entrada:
        return 'Entrada';
      case ReminderCategory.pausa:
        return 'Pausa';
      case ReminderCategory.volta:
        return 'Volta';
      case ReminderCategory.saida:
        return 'Saída';
    }
  }

  String get notificationTitle {
    switch (this) {
      case ReminderCategory.entrada:
        return 'Hora de começar! 🚀';
      case ReminderCategory.pausa:
        return 'Hora da pausa! ☕';
      case ReminderCategory.volta:
        return 'Hora de voltar! 💪';
      case ReminderCategory.saida:
        return 'Hora de ir! 🏠';
    }
  }

  String get notificationBody {
    switch (this) {
      case ReminderCategory.entrada:
        return 'Não esqueça de registrar sua entrada.';
      case ReminderCategory.pausa:
        return 'Que tal uma pausa para descansar?';
      case ReminderCategory.volta:
        return 'Hora de retornar ao trabalho!';
      case ReminderCategory.saida:
        return 'Não esqueça de registrar sua saída.';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderCategory.entrada:
        return Icons.login_rounded;
      case ReminderCategory.pausa:
        return Icons.coffee_rounded;
      case ReminderCategory.volta:
        return Icons.replay_rounded;
      case ReminderCategory.saida:
        return Icons.logout_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ReminderCategory.entrada:
        return const Color(0xFF18A999);
      case ReminderCategory.pausa:
        return const Color(0xFF3DB2FF);
      case ReminderCategory.volta:
        return const Color(0xFFF7A500);
      case ReminderCategory.saida:
        return const Color(0xFFE53935);
    }
  }
}

/// Representa uma notificação agendada para um horário específico.
class ScheduledReminder {
  final String id;
  final ReminderCategory category;
  final int hour;
  final int minute;
  final bool enabled;
  final String? label;

  const ScheduledReminder({
    required this.id,
    required this.category,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.label,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// ID único para a notificação no sistema (evita colisões).
  int get notificationId {
    // Base 2000 + hash do ID para garantir unicidade
    return 2000 + id.hashCode.abs() % 10000;
  }

  ScheduledReminder copyWith({
    String? id,
    ReminderCategory? category,
    int? hour,
    int? minute,
    bool? enabled,
    String? label,
  }) {
    return ScheduledReminder(
      id: id ?? this.id,
      category: category ?? this.category,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'category': category.name,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      if (label != null) 'label': label,
    };
  }

  factory ScheduledReminder.fromFirestore(Map<String, dynamic> data) {
    return ScheduledReminder(
      id: data['id'] as String,
      category: ReminderCategory.values.byName(data['category'] as String),
      hour: data['hour'] as int,
      minute: data['minute'] as int,
      enabled: data['enabled'] as bool? ?? true,
      label: data['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledReminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
