// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme_mode_provider.dart';
import 'l10n/app_locale.dart';
import 'l10n/de_de.dart';
import 'l10n/en_us.dart';
import 'l10n/es_bo.dart';
import 'l10n/fr_fr.dart';
import 'l10n/pt_br.dart';

/// Widget raiz de tresdcal.
///
/// Usa [themeModeProvider] para el toggle Claro/Oscuro/Sistema persistido.
/// Soporta light/dark automatico (default: system) y se adapta a mobile/web
/// via [AppScaffold] (NavigationBar en mobile, NavigationRail en web).
class TresdcalApp extends ConsumerWidget {
  const TresdcalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el theme mode persistido.
    final appThemeMode = ref.watch(themeModeProvider);

    // Escuchar locale para rebuild completo + actualizar EsBO estatico.
    final locale = ref.watch(localeProvider);
    ref.listen(localeProvider, (_, next) {
      EsBO.setImpl(_stringsFor(next));
    });
    // Inicializar EsBO en el locale actual (antes del primer render).
    EsBO.setImpl(_stringsFor(locale));

    return MaterialApp.router(
      title: '3dcalc',
      debugShowCheckedModeBanner: false,
      themeMode: appThemeMode.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }

  AppStrings _stringsFor(AppLocale locale) => switch (locale) {
    AppLocale.es => const EsImpl(),
    AppLocale.en => const EnImpl(),
    AppLocale.ptBr => const PtBrImpl(),
    AppLocale.de => const DeImpl(),
    AppLocale.fr => const FrImpl(),
  };
}
