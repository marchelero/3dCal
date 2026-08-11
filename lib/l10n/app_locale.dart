/// Locale activo + provider.
library;
// ignore_for_file: public_member_api_docs

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/draft_storage_providers.dart'
    show sharedPreferencesProvider;
import 'app_strings.dart';
import 'de_de.dart';
import 'en_us.dart';
import 'es_bo.dart';
import 'fr_fr.dart';
import 'pt_br.dart';

export 'app_strings.dart' show AppStrings;

// ─── Enum ────────────────────────────────────────

enum AppLocale { es, en, ptBr, de, fr }

// ─── Provider (persistido) ───────────────────────

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<AppLocale> {
  static const _key = 'locale';

  @override
  AppLocale build() {
    final code = ref.read(sharedPreferencesProvider).getString(_key);
    return switch (code) {
      'en' => AppLocale.en,
      'pt-BR' => AppLocale.ptBr,
      'de' => AppLocale.de,
      'fr' => AppLocale.fr,
      _ => AppLocale.es,
    };
  }

  Future<void> setLocale(AppLocale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final code = switch (locale) {
      AppLocale.en => 'en',
      AppLocale.ptBr => 'pt-BR',
      AppLocale.de => 'de',
      AppLocale.fr => 'fr',
      AppLocale.es => 'es',
    };
    await prefs.setString(_key, code);
    state = locale;
  }
}

// ─── Strings segun locale ────────────────────────

final _esImpl = EsImpl();
final _enImpl = EnImpl();
final _ptBrImpl = PtBrImpl();
final _deImpl = DeImpl();
final _frImpl = FrImpl();

/// Provider reactivo que retorna la implementacion concreta de [AppStrings]
/// segun el locale activo. Todos los widgets que usan strings localizados
/// deberian watchear este provider para rebuild al cambiar idioma.
final localeStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return switch (locale) {
    AppLocale.es => _esImpl,
    AppLocale.en => _enImpl,
    AppLocale.ptBr => _ptBrImpl,
    AppLocale.de => _deImpl,
    AppLocale.fr => _frImpl,
  };
});
