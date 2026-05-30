import 'package:flutter/material.dart';

/// Cores **neutras** que mudam entre tema claro e escuro (fundos, superfícies,
/// texto, bordas, sombras e o degradê de fundo).
///
/// Os **acentos** (teal, laranja, lima, status e tipos de ponto) continuam em
/// [AppColors] como `static const`, pois não mudam entre os temas.
///
/// Acesse via `context.palette` — assim os widgets recolorem automaticamente
/// ao alternar o tema (dependem do `Theme`).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bgLight;
  final Color surface;
  final Color greyLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textSecondary50;
  final Color border;
  final Color borderLight;
  final Color borderLight30;
  final Color borderLight50;
  final Color shadow;
  final Color shadowMedium;
  final LinearGradient appBackground;

  const AppPalette({
    required this.bgLight,
    required this.surface,
    required this.greyLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textSecondary50,
    required this.border,
    required this.borderLight,
    required this.borderLight30,
    required this.borderLight50,
    required this.shadow,
    required this.shadowMedium,
    required this.appBackground,
  });

  static const LinearGradient _lightBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAF6E6), Color(0xFFEFF3DB), Color(0xFFE0F0EA)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient _darkBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101A17), Color(0xFF0E1714), Color(0xFF0B1310)],
    stops: [0.0, 0.5, 1.0],
  );

  static const AppPalette light = AppPalette(
    bgLight: Color(0xFFF4FAE6),
    surface: Color(0xFFFFFFFF),
    greyLight: Color(0xFFF5F5F5),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textSecondary50: Color(0x80757575),
    border: Color(0xFFE0E0E0),
    borderLight: Color(0xFFE0E0E0),
    borderLight30: Color(0x4DE0E0E0),
    borderLight50: Color(0x80E0E0E0),
    shadow: Color(0x08000000),
    shadowMedium: Color(0x14000000),
    appBackground: _lightBg,
  );

  static const AppPalette dark = AppPalette(
    bgLight: Color(0xFF101714),
    surface: Color(0xFF19211E),
    greyLight: Color(0xFF222B28),
    textPrimary: Color(0xFFECF1EF),
    textSecondary: Color(0xFF9DB1AC),
    textSecondary50: Color(0x809DB1AC),
    border: Color(0xFF2C3733),
    borderLight: Color(0xFF2C3733),
    borderLight30: Color(0x4D2C3733),
    borderLight50: Color(0x802C3733),
    shadow: Color(0x40000000),
    shadowMedium: Color(0x59000000),
    appBackground: _darkBg,
  );

  @override
  AppPalette copyWith({
    Color? bgLight,
    Color? surface,
    Color? greyLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textSecondary50,
    Color? border,
    Color? borderLight,
    Color? borderLight30,
    Color? borderLight50,
    Color? shadow,
    Color? shadowMedium,
    LinearGradient? appBackground,
  }) {
    return AppPalette(
      bgLight: bgLight ?? this.bgLight,
      surface: surface ?? this.surface,
      greyLight: greyLight ?? this.greyLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textSecondary50: textSecondary50 ?? this.textSecondary50,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      borderLight30: borderLight30 ?? this.borderLight30,
      borderLight50: borderLight50 ?? this.borderLight50,
      shadow: shadow ?? this.shadow,
      shadowMedium: shadowMedium ?? this.shadowMedium,
      appBackground: appBackground ?? this.appBackground,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bgLight: Color.lerp(bgLight, other.bgLight, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      greyLight: Color.lerp(greyLight, other.greyLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textSecondary50: Color.lerp(textSecondary50, other.textSecondary50, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderLight30: Color.lerp(borderLight30, other.borderLight30, t)!,
      borderLight50: Color.lerp(borderLight50, other.borderLight50, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowMedium: Color.lerp(shadowMedium, other.shadowMedium, t)!,
      appBackground:
          LinearGradient.lerp(appBackground, other.appBackground, t)!,
    );
  }
}

/// Atalho para ler a paleta neutra do tema atual.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
