import 'package:flutter/material.dart';

/// Rota de navegação sem animação e com duração de transição **zero**.
///
/// Substitui [MaterialPageRoute] em todo o app. Como os scaffolds são
/// transparentes (o degradê de fundo é global, pintado uma única vez atrás do
/// Navigator), uma transição com duração faria a tela anterior aparecer por
/// baixo da nova durante a animação. Com duração zero a rota opaca cobre a
/// anterior instantaneamente — sem "fantasma" da tela antiga.
class InstantPageRoute<T> extends PageRouteBuilder<T> {
  InstantPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          settings: settings,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        );
}
