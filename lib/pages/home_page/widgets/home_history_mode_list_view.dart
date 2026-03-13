import 'package:flutter/material.dart';

class HomeHistoryModeListView extends StatelessWidget {
  final List<String> dayIds;
  final Widget Function(String dayId) dayBuilder;

  const HomeHistoryModeListView({
    super.key,
    required this.dayIds,
    required this.dayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: dayIds.map(dayBuilder).toList(),
    );
  }
}
