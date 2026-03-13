import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class SettingsSavedLocationItem {
  final String title;
  final String? subtitle;

  const SettingsSavedLocationItem({
    required this.title,
    this.subtitle,
  });
}

class SettingsBottomCard extends StatelessWidget {
  final bool hasPendingChange;
  final int savedLocationsCount;
  final String address;
  final List<SettingsSavedLocationItem> savedLocations;
  final ValueChanged<int>? onSelectLocation;
  final ValueChanged<int>? onDeleteLocation;
  final bool saving;
  final VoidCallback onConfirm;

  const SettingsBottomCard({
    super.key,
    required this.hasPendingChange,
    required this.savedLocationsCount,
    required this.address,
    required this.savedLocations,
    this.onSelectLocation,
    this.onDeleteLocation,
    required this.saving,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final description = hasPendingChange
        ? 'Posicione o pin no ponto exato e confirme para adicionar este local a lista presencial.'
        : 'Este endereco ja esta na lista e pode ser usado como referencia do ponto presencial.';

    final addressLabel = address.isNotEmpty
        ? address
        : 'Nenhum local salvo proximo ao pin atual.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locais salvos: $savedLocationsCount',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      addressLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (savedLocations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Locais cadastrados',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 96),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: savedLocations.length,
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.borderLight,
                  ),
                  itemBuilder: (context, index) {
                    final location = savedLocations[index];

                    return ListTile(
                      dense: true,
                      onTap: onSelectLocation == null
                          ? null
                          : () => onSelectLocation!(index),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      title: Text(
                        location.title,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: (location.subtitle != null &&
                              location.subtitle!.trim().isNotEmpty)
                          ? Text(
                              location.subtitle!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: IconButton(
                        onPressed: onDeleteLocation == null
                            ? null
                            : () => onDeleteLocation!(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        tooltip: 'Excluir local',
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                saving ? 'Salvando local...' : 'Adicionar local a lista',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
