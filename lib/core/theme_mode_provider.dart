/// Provider del theme mode (Claro / Oscuro / Sistema).
///
/// Persiste en SharedPreferences para mantener la preferencia entre sesiones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage/draft_storage_providers.dart';

/// Key para SharedPreferences.
const _kThemeModeKey = 'theme_mode';

/// Posibles modos de tema.
enum AppThemeMode {
  /// Sigue la config del sistema.
  system('Sistema', ThemeMode.system),

  /// Siempre claro.
  light('Claro', ThemeMode.light),

  /// Siempre oscuro.
  dark('Oscuro', ThemeMode.dark);

  const AppThemeMode(this.label, this.themeMode);

  /// Label visible en UI.
  final String label;

  /// [ThemeMode] de Flutter correspondiente.
  final ThemeMode themeMode;
}

/// Notifier para cambiar y persistir el theme mode.
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static AppThemeMode _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kThemeModeKey);
    if (raw == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Cambiar el modo y persistir.
  void setMode(AppThemeMode mode) {
    state = mode;
    _prefs.setString(_kThemeModeKey, mode.name);
  }
}

/// Provider del [ThemeModeNotifier].
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
