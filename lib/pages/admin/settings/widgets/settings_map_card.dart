import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SettingsMapCard extends StatelessWidget {
  final MapController mapController;
  final LatLng center;
  final bool hasSavedLocation;
  final bool hasPendingChange;
  final bool capturingGps;
  final double defaultZoom;
  final double focusedZoom;
  final VoidCallback onMyLocationPressed;
  final ValueChanged<LatLng> onCenterChanged;

  const SettingsMapCard({
    super.key,
    required this.mapController,
    required this.center,
    required this.hasSavedLocation,
    required this.hasPendingChange,
    required this.capturingGps,
    required this.defaultZoom,
    required this.focusedZoom,
    required this.onMyLocationPressed,
    required this.onCenterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: hasSavedLocation ? focusedZoom : defaultZoom,
                onPositionChanged: (position, _) {
                  onCenterChanged(position.center);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.com.timeflow.app',
                ),
              ],
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface90,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPendingChange
                          ? Icons.edit_location_alt_outlined
                          : Icons.check_circle_outline,
                      color: hasPendingChange
                          ? AppColors.warning
                          : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasPendingChange
                          ? 'Pin pronto para adicionar'
                          : 'Local já adicionado',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: FloatingActionButton.small(
                heroTag: 'admin_settings_gps_btn',
                backgroundColor: AppColors.surface,
                onPressed: capturingGps ? null : onMyLocationPressed,
                child: capturingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 20,
                      ),
              ),
            ),
            const Center(
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin,
                        color: AppColors.primary, size: 52),
                    SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
