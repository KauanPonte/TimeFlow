import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_event.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/theme/theme_controller.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/widgets/main_app_bar.dart';
import '../../widgets/bottom_nav.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_card.dart';
import '../ponto_page/widgets/scheduled_reminders_modal.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfilePageView();
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

  bool _isAdminRole(String role) {
    return role.toUpperCase().contains('ADM');
  }

  void _showEditProfileDialog(ProfileLoaded profileData) {
    final isAdmin = _isAdminRole(profileData.role);

    showDialog(
      context: context,
      builder: (_) => EditProfileDialog(
        currentName: profileData.name,
        currentWorkloadMinutes: profileData.workloadMinutes,
        isAdmin: isAdmin,
        onSave: (name, workloadMinutes) {
          context.read<ProfileBloc>().add(
                UpdateProfileNameEvent(
                  newName: name,
                  workloadMinutes: workloadMinutes,
                ),
              );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Carrega o perfil apenas se ainda não foi carregado.
    final profileBloc = context.read<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const LoadProfileEvent());
    }
    final pontoTodayCubit = context.read<PontoTodayCubit>();
    if (!pontoTodayCubit.hasLoadedOnce) {
      pontoTodayCubit.load();
    }
  }

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
      builder: (_) => AppDialogScaffold(
        title: 'Confirmar foto',
        subtitle: 'Deseja usar essa foto como foto de perfil?',
        icon: Icons.preview,
        confirmLabel: 'Confirmar',
        onConfirm: () {
          Navigator.pop(context);
          context.read<ProfileBloc>().add(
                UploadProfileImageEvent(imageFile: _pendingImage!),
              );
          setState(() => _pendingImage = null);
        },
        onCancel: () {
          setState(() => _pendingImage = null);
          Navigator.pop(context);
        },
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: Image.file(
                _pendingImage!,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmação antes de remover a foto
  void _confirmRemoveImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppDialogScaffold(
        title: 'Remover foto',
        subtitle: 'Tem certeza que deseja remover sua foto de perfil?',
        icon: Icons.warning_amber_rounded,
        isDestructive: true,
        confirmLabel: 'Remover',
        onConfirm: () {
          Navigator.pop(context);
          context.read<ProfileBloc>().add(const RemoveProfileImageEvent());
        },
        children: const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const MainAppBar(subtitle: 'Meu Perfil'),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppColors.techDarkBackground
              : AppColors.appBackground,
        ),
        child: BlocConsumer<ProfileBloc, ProfileState>(
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
                        context
                            .read<ProfileBloc>()
                            .add(const LoadProfileEvent());
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

            final isAdmin = _isAdminRole(profileData.role);
            final profile = profileData;

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
                  projectType: profileData.projectType,
                ),
              ),

                const SizedBox(height: 32),

              BlocBuilder<PontoTodayCubit, PontoTodayState>(
                builder: (context, pontoState) {
                  final hasPunchToday = pontoState.eventosHoje.isNotEmpty;
                  final isOnline = pontoState.ultimoTipo == 'entrada' ||
                      pontoState.ultimoTipo == 'retorno';

                  return ProfileInfoCard(
                    name: profile.name,
                    email: profile.email,
                    role: profile.role,
                    workloadMinutes: profile.workloadMinutes,
                    isAdmin: isAdmin,
                    contractType: profile.contractType,
                    workDays: profile.workDays,
                    projectType: profile.projectType,
                    projects: profile.projects,
                    onEdit: () => _showEditProfileDialog(profile),
                    showPresence: hasPunchToday,
                    isOnline: isOnline,
                  );
                },
              ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primaryLight30
                          : AppColors.borderLight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Lembretes personalizados',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Entrada, pausa, volta e saída',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.68),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.68),
                    ),
                    onTap: () => ScheduledRemindersModal.show(context),
                  ),
                ),

                const SizedBox(height: 16),

                const _ThemePreferenceCard(),
              ],
            );
          },
        ),
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

class _ThemePreferenceCard extends StatelessWidget {
  const _ThemePreferenceCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.primaryLight30
              : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeController.mode,
        builder: (context, mode, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aparência',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Tema do aplicativo',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ThemeChoiceButton(
                      icon: Icons.light_mode_outlined,
                      label: 'Claro',
                      selected: mode == ThemeMode.light,
                      onTap: () => AppThemeController.setMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeChoiceButton(
                      icon: Icons.dark_mode_outlined,
                      label: 'Escuro',
                      selected: mode == ThemeMode.dark,
                      onTap: () => AppThemeController.setMode(ThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeChoiceButton(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Sistema',
                      selected: mode == ThemeMode.system,
                      onTap: () => AppThemeController.setMode(ThemeMode.system),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.primaryLight10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? AppColors.primaryLight30 : AppColors.borderLight),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? (isDark ? AppColors.navy : AppColors.white)
                    : (isDark ? AppColors.darkTextPrimary : AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected
                      ? (isDark ? AppColors.navy : AppColors.white)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
