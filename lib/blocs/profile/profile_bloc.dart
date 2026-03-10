import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final GlobalLoadingCubit? globalLoading;

  ProfileBloc(
      {required ProfileRepository profileRepository, this.globalLoading})
      : _profileRepository = profileRepository,
        super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<RemoveProfileImageEvent>(_onRemoveProfileImage);
    on<UpdateProfileNameEvent>(_onUpdateProfileName);
  }

  /// Carrega os dados do perfil
  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(const ProfileLoading());

      final data = await _profileRepository.getProfile();

      emit(ProfileLoaded(
        uid: data['uid'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? '',
        profileImageUrl: data['profileImage'] ?? '',
      ));
    } catch (e) {
      emit(ProfileError(
        message:
            'Erro ao carregar perfil: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  /// Faz upload da foto de perfil
  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final previousData = state is ProfileLoaded ? state as ProfileLoaded : null;

    try {
      globalLoading?.show('Enviando foto...');
      if (previousData != null) {
        emit(ProfileImageUploading(previousData: previousData));
      }

      final downloadUrl =
          await _profileRepository.uploadProfileImage(event.imageFile);

      final updatedData =
          previousData?.copyWith(profileImageUrl: downloadUrl) ??
              ProfileLoaded(
                uid: '',
                name: '',
                email: '',
                role: '',
                profileImageUrl: downloadUrl,
              );

      globalLoading?.hide();
      emit(ProfileActionSuccess(
        message: 'Foto atualizada com sucesso!',
        updatedData: updatedData,
      ));

      // Emitir o estado final com os dados atualizados
      await Future.delayed(const Duration(milliseconds: 100));
      emit(updatedData);
    } catch (e) {
      globalLoading?.hide();
      emit(ProfileError(
        message:
            'Erro ao enviar foto: ${e.toString().replaceAll('Exception: ', '')}',
        previousData: previousData,
      ));

      // Restaurar estado anterior
      if (previousData != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(previousData);
      }
    }
  }

  /// Remove a foto de perfil
  Future<void> _onRemoveProfileImage(
    RemoveProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final previousData = state is ProfileLoaded ? state as ProfileLoaded : null;

    try {
      globalLoading?.show('Removendo foto...');
      if (previousData != null) {
        emit(ProfileImageUploading(previousData: previousData));
      }

      await _profileRepository.removeProfileImage();

      final updatedData = previousData?.copyWith(profileImageUrl: '') ??
          const ProfileLoaded(
            uid: '',
            name: '',
            email: '',
            role: '',
            profileImageUrl: '',
          );

      globalLoading?.hide();
      emit(ProfileActionSuccess(
        message: 'Foto removida com sucesso!',
        updatedData: updatedData,
      ));

      await Future.delayed(const Duration(milliseconds: 100));
      emit(updatedData);
    } catch (e) {
      globalLoading?.hide();
      emit(ProfileError(
        message:
            'Erro ao remover foto: ${e.toString().replaceAll('Exception: ', '')}',
        previousData: previousData,
      ));

      if (previousData != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(previousData);
      }
    }
  }

  /// Atualiza o nome do perfil
  Future<void> _onUpdateProfileName(
    UpdateProfileNameEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final previousData = state is ProfileLoaded ? state as ProfileLoaded : null;

    try {
      globalLoading?.show('Atualizando nome...');
      await _profileRepository.updateProfileName(event.newName);

      final updatedData = previousData?.copyWith(name: event.newName.trim()) ??
          ProfileLoaded(
            uid: '',
            name: event.newName.trim(),
            email: '',
            role: '',
            profileImageUrl: '',
          );

      globalLoading?.hide();
      emit(ProfileActionSuccess(
        message: 'Nome atualizado com sucesso!',
        updatedData: updatedData,
      ));

      await Future.delayed(const Duration(milliseconds: 100));
      emit(updatedData);
    } catch (e) {
      globalLoading?.hide();
      emit(ProfileError(
        message:
            'Erro ao atualizar nome: ${e.toString().replaceAll('Exception: ', '')}',
        previousData: previousData,
      ));

      if (previousData != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(previousData);
      }
    }
  }
}
