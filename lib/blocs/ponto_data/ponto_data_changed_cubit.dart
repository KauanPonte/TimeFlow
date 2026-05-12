import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';

/// Sinaliza que dados de ponto foram alterados.
/// Qualquer tela pode chamar [notifyChanged] para avisar que o Firestore
/// foi atualizado, e outras telas que estejam escutando podem refrescar
/// seus dados silenciosamente.
class PontoDataChangedCubit extends Cubit<DateTime> {
  PontoDataChangedCubit() : super(ServerTimeService.nowBrazilUtc());

  void notifyChanged() => emit(ServerTimeService.nowBrazilUtc());
}
