import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===========================================================================
  // Paleta da marca TimeFlow
  //   Lime    #E0F594   ·   Laranja #FA8D57   ·   Teal #62C1B1
  // As três cores exatas da paleta ficam disponíveis abaixo; a primária usa um
  // teal aprofundado para garantir contraste com texto branco (WCAG AA ~4.5:1).
  // ===========================================================================
  static const Color teal = Color(0xFF62C1B1); // teal exato da paleta
  static const Color orange = Color(0xFFFA8D57); // laranja exato da paleta
  static const Color lime = Color(0xFFE0F594); // lime exato da paleta

  static const Color primary = Color(0xFF178573); // teal aprofundado (texto branco)
  static const Color primaryLight = Color(0xFF62C1B1); // teal da paleta
  static const Color accent = Color(0xFFFA8D57); // laranja da paleta

  static const Color bgLight = Color(0xFFF4FAE6); // lavagem lime bem suave
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface90 = Color(0xE6FFFFFF); // 90% opacity
  static const Color surface80 = Color(0xCCFFFFFF); // 80%
  static const Color surface70 = Color(0xB3FFFFFF); // 70%
  static const Color surface50 = Color(0x80FFFFFF); // 50%
  static const Color surface30 = Color(0x4DFFFFFF); // 30%

  static const Color border = Color(0xFFE0E0E0); // grey300
  static const Color borderLight = Color(0xFFE0E0E0); // grey300
  static const Color greyLight = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF212121); // black87
  static const Color textSecondary = Color(0xFF757575); // grey600

  // Sinais de status — mantidos por usabilidade (com aviso reharmonizado p/ a paleta)
  static const Color success = Color(0xFF4CAF50); // verde
  static const Color error = Color(0xFFE53935); // vermelho
  static const Color info = Color(0xFF2BB3A0); // teal (substitui o azul, on-brand)
  static const Color warning = Color(0xFFFA8D57); // laranja da paleta

  // Tipos de batida de ponto — 4 cores distintas, reharmonizadas com a paleta
  static const Color tipoEntrada = Color(0xFF1AA188); // teal
  static const Color tipoPausa = Color(0xFFFA8D57); // laranja
  static const Color tipoRetorno = Color(0xFF7CB342); // verde-lima
  static const Color tipoSaida = Color(0xFFE53935); // vermelho

  // Opacity colors for shadows, overlays and backgrounds
  static const Color shadow = Color(0x08000000); // black 3%
  static const Color shadowMedium = Color(0x14000000); // black 8%

  // Primary variants with opacity (#178573)
  static const Color primaryLight10 = Color(0x1A178573); // primary 10%
  static const Color primaryLight20 = Color(0x33178573); // primary 20%
  static const Color primaryLight30 = Color(0x4D178573); // primary 30%

  // Border variants with opacity
  static const Color borderLight30 = Color(0x4DE0E0E0); // borderLight 30%
  static const Color borderLight50 = Color(0x80E0E0E0); // borderLight 50%

  // Success variants
  static const Color successLight10 = Color(0x1A4CAF50); // success 10%

  // Error variants
  static const Color errorLight10 = Color(0x1AE53935); // error 10%
  static const Color errorLight20 = Color(0x33E53935); // error 20%

  // Warning variants (laranja da paleta #FA8D57)
  static const Color warningLight8 = Color(0x14FA8D57); // warning 8%
  static const Color warningLight10 = Color(0x1AFA8D57); // warning 10%
  static const Color warningLight20 = Color(0x33FA8D57); // warning 20%
  static const Color warningLight30 = Color(0x4DFA8D57); // warning 30%
  static const Color warningLight40 = Color(0x66FA8D57); // warning 40%

  // Text secondary variants
  static const Color textSecondary50 = Color(0x80757575); // textSecondary 50%
}
