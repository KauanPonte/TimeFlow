import 'package:flutter/material.dart';

class SettingsPageContent extends StatelessWidget {
  final bool loading;
  final Widget headerCard;
  final Widget searchField;
  final Widget mapWithSuggestions;
  final Widget bottomCard;

  const SettingsPageContent({
    super.key,
    required this.loading,
    required this.headerCard,
    required this.searchField,
    required this.mapWithSuggestions,
    required this.bottomCard,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              headerCard,
              const SizedBox(height: 8),
              searchField,
              const SizedBox(height: 8),
              Expanded(child: mapWithSuggestions),
              const SizedBox(height: 8),
              bottomCard,
            ],
          ),
        ),
      ),
    );
  }
}
