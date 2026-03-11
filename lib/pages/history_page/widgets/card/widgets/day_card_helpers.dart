import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:intl/intl.dart';

// Formatação

String formatDate(String diaId) {
  try {
    final date = DateTime.parse(diaId);
    final formatter = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR');
    final formatted = formatter.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  } catch (_) {
    return diaId;
  }
}

String formatTime(DateTime? dt) {
  if (dt == null) return '--:--';
  return DateFormat('HH:mm').format(dt);
}

// Tipo helpers

IconData iconForTipo(String tipo) {
  switch (tipo) {
    case 'entrada':
      return Icons.login;
    case 'pausa':
      return Icons.coffee;
    case 'retorno':
      return Icons.replay;
    case 'saida':
      return Icons.logout;
    default:
      return Icons.access_time;
  }
}

Color colorForTipo(String tipo) {
  switch (tipo) {
    case 'entrada':
      return AppColors.success;
    case 'pausa':
      return const Color(0xFF3DB2FF);
    case 'retorno':
      return AppColors.warning;
    case 'saida':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

String labelForTipo(String tipo) {
  switch (tipo) {
    case 'entrada':
      return 'Entrada';
    case 'pausa':
      return 'Pausa';
    case 'retorno':
      return 'Retorno';
    case 'saida':
      return 'Saída';
    default:
      return tipo;
  }
}

// Ação helpers

String actionLabel(SolicitationAction action) {
  switch (action) {
    case SolicitationAction.add:
      return 'Adicionar';
    case SolicitationAction.edit:
      return 'Editar';
    case SolicitationAction.delete:
      return 'Remover';
  }
}

Color actionColor(SolicitationAction action) {
  switch (action) {
    case SolicitationAction.add:
      return AppColors.success;
    case SolicitationAction.edit:
      return AppColors.primary;
    case SolicitationAction.delete:
      return AppColors.error;
  }
}

// Lógica de eventos

bool isIncomplete(
  List<Map<String, dynamic>> eventos, {
  required bool isToday,
  required bool isFuture,
}) {
  if (isToday || isFuture || eventos.isEmpty) return false;
  final sorted = List<Map<String, dynamic>>.from(eventos)
    ..sort((a, b) {
      final atA = a['at'] as DateTime?;
      final atB = b['at'] as DateTime?;
      if (atA == null || atB == null) return 0;
      return atA.compareTo(atB);
    });
  return (sorted.last['tipo'] ?? '').toString() != 'saida';
}

String motivoIncompleto(List<Map<String, dynamic>> eventos) {
  final sorted = List<Map<String, dynamic>>.from(eventos)
    ..sort((a, b) {
      final atA = a['at'] as DateTime?;
      final atB = b['at'] as DateTime?;
      if (atA == null || atB == null) return 0;
      return atA.compareTo(atB);
    });
  final lastTipo = (sorted.last['tipo'] ?? '').toString();
  switch (lastTipo) {
    case 'pausa':
      return 'Sem retorno da pausa';
    case 'entrada':
    case 'retorno':
      return 'Sem saída';
    default:
      return 'Registro incompleto';
  }
}

String computeWorked(List<Map<String, dynamic>> eventos) {
  DateTime? openWork;
  Duration total = Duration.zero;
  for (final ev in eventos) {
    final tipo = (ev['tipo'] ?? '').toString();
    final at = ev['at'] as DateTime?;
    if (at == null) continue;
    if (tipo == 'entrada' || tipo == 'retorno') {
      openWork ??= at;
    } else if (tipo == 'pausa' || tipo == 'saida') {
      if (openWork != null && at.isAfter(openWork)) {
        total += at.difference(openWork);
      }
      openWork = null;
    }
  }
  final h = total.inHours;
  final m = total.inMinutes % 60;
  return '${h}h ${m}m';
}
