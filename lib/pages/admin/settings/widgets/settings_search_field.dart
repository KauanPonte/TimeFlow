import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class SettingsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loadingSuggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SettingsSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.loadingSuggestions,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.streetAddress,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Buscar endereço ou empresa',
                hintStyle: AppTextStyles.bodyMedium,
                border: InputBorder.none,
                isCollapsed: true,
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 0,
                  minWidth: 0,
                ),
                suffixIcon: loadingSuggestions
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                    : controller.text.isNotEmpty
                        ? IconButton(
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: onClear,
                          )
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
