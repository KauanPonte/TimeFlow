import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette from Realtime Colors:
  // Text #050316, background #FBFBFE, lime #E0F594, orange #FA8D57, teal #62C1B1.
  static const Color navy = Color(0xFF050316);
  static const Color teal = Color(0xFF62C1B1);
  static const Color orange = Color(0xFFFA8D57);
  static const Color lime = Color(0xFFE0F594);

  // A deeper teal keeps primary buttons readable with white text.
  static const Color primary = Color(0xFF178573);
  static const Color primaryLight = teal;
  static const Color accent = orange;

  static const Color bgLight = Color(0xFFF4FAE6);

  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF6E6),
      Color(0xFFEFF3DB),
      Color(0xFFE0F0EA),
    ],
    stops: [0.0, 0.52, 1.0],
  );

  static const LinearGradient techDarkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF071A1D),
      Color(0xFF0B2D2F),
      Color(0xFF123F39),
    ],
    stops: [0.0, 0.48, 1.0],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF178573),
      Color(0xFF0F6356),
    ],
  );

  static const LinearGradient softBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD27A),
      Color(0xFFE9EDB9),
      Color(0xFFB7E4D7),
    ],
  );

  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF102326);
  static const Color darkSurfaceAlt = Color(0xFF173136);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface90 = Color(0xE6FFFFFF);
  static const Color surface80 = Color(0xCCFFFFFF);
  static const Color surface70 = Color(0xB3FFFFFF);
  static const Color surface50 = Color(0x80FFFFFF);
  static const Color surface30 = Color(0x4DFFFFFF);

  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFE9E6DC);
  static const Color greyLight = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textSecondary50 = Color(0x80757575);
  static const Color darkTextPrimary = Color(0xFFF5FFFC);
  static const Color darkTextSecondary = Color(0xFFB7CAC5);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2BB3A0);
  static const Color warning = orange;

  static const Color tipoEntrada = Color(0xFF1AA188);
  static const Color tipoPausa = orange;
  static const Color tipoRetorno = Color(0xFF7CB342);
  static const Color tipoSaida = Color(0xFFE53935);

  static const Color shadow = Color(0x08000000);
  static const Color shadowMedium = Color(0x14000000);

  static const Color primaryLight10 = Color(0x1A178573);
  static const Color primaryLight20 = Color(0x33178573);
  static const Color primaryLight30 = Color(0x4D178573);

  static const Color tealLight10 = Color(0x1A62C1B1);
  static const Color limeLight20 = Color(0x33E0F594);
  static const Color orangeLight12 = Color(0x1FFA8D57);

  static const Color borderLight30 = Color(0x4DE0E0E0);
  static const Color borderLight50 = Color(0x80E0E0E0);

  static const Color successLight10 = Color(0x1A4CAF50);

  static const Color errorLight10 = Color(0x1AE53935);
  static const Color errorLight20 = Color(0x33E53935);

  static const Color warningLight8 = Color(0x14FA8D57);
  static const Color warningLight10 = Color(0x1AFA8D57);
  static const Color warningLight20 = Color(0x33FA8D57);
  static const Color warningLight30 = Color(0x4DFA8D57);
  static const Color warningLight40 = Color(0x66FA8D57);
}
