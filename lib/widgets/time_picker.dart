import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

/// Exibe o seletor de horário Material (relógio analógico) sempre em 24h.
///
/// Retorna o [TimeOfDay] escolhido, ou null se o usuário cancelar.
Future<TimeOfDay?> showTimePicker24h(
  BuildContext context,
  TimeOfDay initial,
) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    ),
  );
}
