import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Carregando perfil
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Perfil carregado com sucesso
class ProfileLoaded extends ProfileState {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String profileImageUrl;

  const ProfileLoaded({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.profileImageUrl,
  });

  @override
  List<Object?> get props => [uid, name, email, role, profileImageUrl];

  ProfileLoaded copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
  }) {
    return ProfileLoaded(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

/// Upload em progresso
class ProfileImageUploading extends ProfileState {
  final ProfileLoaded previousData;

  const ProfileImageUploading({required this.previousData});

  @override
  List<Object?> get props => [previousData];
}

/// Ação realizada com sucesso (upload, remoção, atualização de nome)
class ProfileActionSuccess extends ProfileState {
  final String message;
  final ProfileLoaded updatedData;

  const ProfileActionSuccess({
    required this.message,
    required this.updatedData,
  });

  @override
  List<Object?> get props => [message, updatedData];
}

/// Erro no perfil
class ProfileError extends ProfileState {
  final String message;
  final ProfileLoaded? previousData;

  const ProfileError({
    required this.message,
    this.previousData,
  });

  @override
  List<Object?> get props => [message, previousData];
}
