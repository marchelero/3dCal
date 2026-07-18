/// Locale activo + provider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/draft_storage_providers.dart'
    show sharedPreferencesProvider;
import 'app_strings.dart';
import 'en_us.dart';
import 'es_bo.dart';

// ─── Enum ────────────────────────────────────────

enum AppLocale { es, en }

// ─── Provider (persistido) ───────────────────────

final localeProvider =
    NotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<AppLocale> {
  static const _key = 'locale';

  @override
  AppLocale build() {
    final code = ref.read(sharedPreferencesProvider).getString(_key);
    return code == 'en' ? AppLocale.en : AppLocale.es;
  }

  Future<void> setLocale(AppLocale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale == AppLocale.en ? 'en' : 'es');
    state = locale;
  }
}

// ─── Strings segun locale ────────────────────────

final _esImpl = EsImpl();
final _enImpl = EnImpl();

/// Provider reactivo que retorna la implementacion concreta de [AppStrings]
/// segun el locale activo. Todos los widgets que usan strings localizados
/// deberian watchear este provider para rebuild al cambiar idioma.
final localeStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return locale == AppLocale.en ? _enImpl : _esImpl;
});
