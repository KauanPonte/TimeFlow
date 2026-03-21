import 'package:flutter_application_appdeponto/models/atestado_model.dart';

abstract class AtestadoState {
  const AtestadoState();
}

class AtestadoInitial extends AtestadoState {
  const AtestadoInitial();
}

class AtestadoLoading extends AtestadoState {
  const AtestadoLoading();
}

class AtestadoLoaded extends AtestadoState {
  final List<AtestadoModel> atestados;
  final bool isAdmin;

  const AtestadoLoaded({
    required this.atestados,
    this.isAdmin = false,
  });
}

class AtestadoActionSuccess extends AtestadoState {
  final String message;
  final List<AtestadoModel> atestados;

  const AtestadoActionSuccess({
    required this.message,
    required this.atestados,
  });
}

class AtestadoError extends AtestadoState {
  final String message;
  final List<AtestadoModel> atestados;

  const AtestadoError({
    required this.message,
    this.atestados = const [],
  });
}
