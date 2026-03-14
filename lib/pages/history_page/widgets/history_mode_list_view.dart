import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class HistoryModeListView extends StatelessWidget {
  final List<String> dayIds;
  final Widget Function(String dayId) dayBuilder;
  final Future<void> Function()? onRefresh;
  final bool embedInParentScroll;

  const HistoryModeListView({
    super.key,
    required this.dayIds,
    required this.dayBuilder,
    this.onRefresh,
    this.embedInParentScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    if (embedInParentScroll) {
      return Column(
        children: dayIds.map(dayBuilder).toList(),
      );
    }

    final listView = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dayIds.length,
      itemBuilder: (context, index) => dayBuilder(dayIds[index]),
    );

    if (onRefresh == null) {
      return listView;
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: AppColors.primary,
      child: listView,
    );
  }
}
