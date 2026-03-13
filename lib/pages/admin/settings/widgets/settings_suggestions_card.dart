import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/place_result.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class SettingsSuggestionsCard extends StatelessWidget {
  final List<PlaceResult> suggestions;
  final ValueChanged<PlaceResult> onSuggestionTap;

  const SettingsSuggestionsCard({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final place = suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            title: Text(
              place.shortName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              place.displayName,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSuggestionTap(place),
          );
        },
      ),
    );
  }
}
