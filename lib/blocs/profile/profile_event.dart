import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega os dados do perfil
class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

/// Faz upload de uma nova foto de perfil
class UploadProfileImageEvent extends ProfileEvent {
  final File imageFile;

  const UploadProfileImageEvent({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

/// Remove a foto de perfil
class RemoveProfileImageEvent extends ProfileEvent {
  const RemoveProfileImageEvent();
}

/// Atualiza o nome do perfil
class UpdateProfileNameEvent extends ProfileEvent {
  final String newName;
  final int? workloadMinutes;

  const UpdateProfileNameEvent({
    required this.newName,
    this.workloadMinutes,
  });

  @override
  List<Object?> get props => [newName, workloadMinutes];
}

/// Reseta o perfil para o estado inicial (logout).
class ResetProfileEvent extends ProfileEvent {
  const ResetProfileEvent();
}
