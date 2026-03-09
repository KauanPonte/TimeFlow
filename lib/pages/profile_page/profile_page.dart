import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_event.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_state.dart';
import 'package:flutter_application_appdeponto/repositories/profile_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/widgets/main_app_bar.dart';
import '../../widgets/bottom_nav.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(profileRepository: ProfileRepository())
        ..add(const LoadProfileEvent()),
      child: const _ProfilePageView(),
    );
  }
}

class _ProfilePageView extends StatefulWidget {
  const _ProfilePageView();

  @override
  State<_ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<_ProfilePageView> {
  final _picker = ImagePicker();
  File? _pendingImage;

  /// Mostra bottom sheet com opções: câmera, galeria, remover
  void _showImageOptions(BuildContext context, {bool hasImage = false}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Foto de perfil', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Escolher da galeria'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (hasImage)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: const Text(
                      'Remover foto',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmRemoveImage(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Selecionar imagem, recortar 1:1 e mostrar preview/confirmação
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar foto',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Recortar foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped != null) {
        setState(() => _pendingImage = File(cropped.path));
        if (mounted) {
          _showPreviewDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro ao selecionar imagem');
      }
    }
  }

  /// Dialog de preview antes do upload
  void _showPreviewDialog() {
    if (_pendingImage == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.preview, color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Text('Confirmar foto', style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: Image.file(
                _pendingImage!,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Deseja usar essa foto como foto de perfil?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _pendingImage = null);
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancelar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileBloc>().add(
                    UploadProfileImageEvent(imageFile: _pendingImage!),
                  );
              setState(() => _pendingImage = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// Confirmação antes de remover a foto
  void _confirmRemoveImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 20),
            SizedBox(width: 12),
            Text('Remover foto', style: AppTextStyles.h3),
          ],
        ),
        content: Text(
          'Tem certeza que deseja remover sua foto de perfil?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileBloc>().add(const RemoveProfileImageEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const MainAppBar(subtitle: 'Meu Perfil'),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileActionSuccess) {
            CustomSnackbar.showSuccess(context, state.message);
          } else if (state is ProfileError) {
            CustomSnackbar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (state is ProfileError && state.previousData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(const LoadProfileEvent());
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          // Extrair dados do perfil de qualquer estado que os contenha
          ProfileLoaded? profileData;
          bool isUploading = false;

          if (state is ProfileLoaded) {
            profileData = state;
          } else if (state is ProfileImageUploading) {
            profileData = state.previousData;
            isUploading = true;
          } else if (state is ProfileActionSuccess) {
            profileData = state.updatedData;
          } else if (state is ProfileError && state.previousData != null) {
            profileData = state.previousData;
          }

          if (profileData == null) {
            return const Center(child: Text('Carregando...'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),

              // Avatar
              Center(
                child: ProfileAvatar(
                  imageData: profileData.profileImageUrl,
                  isUploading: isUploading,
                  onTap: () => _showImageOptions(
                    context,
                    hasImage: profileData!.profileImageUrl.isNotEmpty,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: ProfileHeader(
                  name: profileData.name,
                  role: profileData.role,
                ),
              ),

              const SizedBox(height: 32),

              ProfileInfoCard(
                email: profileData.email,
                role: profileData.role,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNav(
        index: (args?['employeeRole'] ?? '')
                .toString()
                .toUpperCase()
                .contains('ADM')
            ? 2
            : 1,
        isAdmin: (args?['employeeRole'] ?? '')
            .toString()
            .toUpperCase()
            .contains('ADM'),
        args: args,
      ),
    );
  }
}
