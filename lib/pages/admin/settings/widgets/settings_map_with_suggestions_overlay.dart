import 'package:flutter/material.dart';

class SettingsMapWithSuggestionsOverlay extends StatelessWidget {
  final Widget mapCard;
  final Widget suggestionsCard;
  final bool showSuggestions;

  const SettingsMapWithSuggestionsOverlay({
    super.key,
    required this.mapCard,
    required this.suggestionsCard,
    required this.showSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: mapCard),
        if (showSuggestions)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: suggestionsCard,
          ),
      ],
    );
  }
}
