import 'package:flutter_bloc/flutter_bloc.dart';

/// Sinaliza que dados de ponto foram alterados.
/// Qualquer tela pode chamar [notifyChanged] para avisar que o Firestore
/// foi atualizado, e outras telas que estejam escutando podem refrescar
/// seus dados silenciosamente.
class PontoDataChangedCubit extends Cubit<DateTime> {
  PontoDataChangedCubit() : super(DateTime.now());

  void notifyChanged() => emit(DateTime.now());
}
