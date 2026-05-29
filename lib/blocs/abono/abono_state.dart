import 'package:flutter/foundation.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';

@immutable
abstract class AbonoState {
  const AbonoState();
}

class AbonoInitial extends AbonoState {
  const AbonoInitial();
}

class AbonoLoading extends AbonoState {
  const AbonoLoading();
}

class AbonoLoaded extends AbonoState {
  final List<AbonoModel> abonos;
  final bool isAdmin;
  const AbonoLoaded({required this.abonos, required this.isAdmin});
}

class AbonoActionSuccess extends AbonoState {
  final String message;
  final List<AbonoModel> abonos;
  const AbonoActionSuccess({required this.message, required this.abonos});
}

class AbonoError extends AbonoState {
  final String message;
  final List<AbonoModel> abonos;
  const AbonoError({required this.message, this.abonos = const []});
}
