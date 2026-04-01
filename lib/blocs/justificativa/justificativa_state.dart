import 'package:flutter_application_appdeponto/models/justificativa_model.dart';

abstract class JustificativaState {
  const JustificativaState();
}

class JustificativaInitial extends JustificativaState {
  const JustificativaInitial();
}

class JustificativaLoading extends JustificativaState {
  const JustificativaLoading();
}

class JustificativaLoaded extends JustificativaState {
  final List<JustificativaModel> justificativas;
  final bool isAdmin;

  const JustificativaLoaded({
    required this.justificativas,
    this.isAdmin = false,
  });
}

class JustificativaActionSuccess extends JustificativaState {
  final String message;
  final List<JustificativaModel> justificativas;

  const JustificativaActionSuccess({
    required this.message,
    required this.justificativas,
  });
}

class JustificativaError extends JustificativaState {
  final String message;
  final List<JustificativaModel> justificativas;

  const JustificativaError({
    required this.message,
    this.justificativas = const [],
  });
}
