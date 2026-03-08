import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String imageData;
  final bool isUploading;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.imageData,
    this.isUploading = false,
    this.onTap,
  });

  Uint8List? _decodeBase64(String data) {
    try {
      final cleaned = data.contains(',') ? data.split(',').last : data;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes =
        imageData.isNotEmpty ? _decodeBase64(imageData) : null;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: bytes != null
                  ? Image.memory(bytes,
                      width: 140, height: 140, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.greyLight,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          if (!isUploading)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
