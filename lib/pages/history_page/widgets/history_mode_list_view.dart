import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class HistoryModeListView extends StatelessWidget {
  final List<String> dayIds;
  final Widget Function(String dayId) dayBuilder;
  final Future<void> Function() onRefresh;

  const HistoryModeListView({
    super.key,
    required this.dayIds,
    required this.dayBuilder,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: dayIds.length,
        itemBuilder: (context, index) => dayBuilder(dayIds[index]),
      ),
    );
  }
}
