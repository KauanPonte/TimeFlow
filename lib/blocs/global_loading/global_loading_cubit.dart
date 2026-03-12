import 'package:flutter_bloc/flutter_bloc.dart';
import 'global_loading_state.dart';

/// Cubit global para controlar o overlay de carregamento.
///
/// Qualquer parte do app (blocs, services, UI) pode chamar
/// [show] para exibir o overlay e [hide] para removê-lo.
class GlobalLoadingCubit extends Cubit<GlobalLoadingState> {
  GlobalLoadingCubit() : super(const GlobalLoadingState());

  /// Exibe o overlay com a [message] fornecida.
  void show(String message) =>
      emit(GlobalLoadingState(isLoading: true, message: message));

  /// Remove o overlay de carregamento.
  void hide() => emit(const GlobalLoadingState());
}
