import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o tema (claro / escuro / sistema) do app.
///
/// É uma preferência **do aparelho** (não por usuário), persistida em
/// `shared_preferences`. O `MaterialApp` escuta este controller, então trocar o
/// modo reconstrói o app com o tema novo.
class ThemeController extends ChangeNotifier {
  static const String _prefsKey = 'themeMode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Carrega o modo salvo. Chamar no `main()` antes do `runApp`.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = _decode(prefs.getString(_prefsKey));
    } catch (_) {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(mode));
    } catch (_) {
      // Mantém em memória mesmo se a persistência falhar.
    }
  }

  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

/// Instância global — o app tem um único `MaterialApp`.
final ThemeController themeController = ThemeController();
