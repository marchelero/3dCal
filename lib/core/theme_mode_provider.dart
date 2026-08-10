// ignore_for_file: public_member_api_docs
/// Provider del theme mode (Claro / Oscuro / Sistema).
///
/// Persiste en SharedPreferences para mantener la preferencia entre sesiones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/es_bo.dart';
import 'storage/draft_storage_providers.dart';

/// Key para SharedPreferences.
const _kThemeModeKey = 'theme_mode';

/// Posibles modos de tema.
enum AppThemeMode {
  /// Sigue la config del sistema.
  system(ThemeMode.system),

  /// Siempre claro.
  light(ThemeMode.light),

  /// Siempre oscuro.
  dark(ThemeMode.dark);

  const AppThemeMode(this.themeMode);

  /// [ThemeMode] de Flutter correspondiente.
  final ThemeMode themeMode;

  /// Label visible en UI (localizado vía EsBO).
  String get label => switch (this) {
    AppThemeMode.system => EsBO.themeModeSystem,
    AppThemeMode.light => EsBO.themeModeLight,
    AppThemeMode.dark => EsBO.themeModeDark,
  };
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
