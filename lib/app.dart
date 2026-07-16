import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme_mode_provider.dart';

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

    return MaterialApp.router(
      title: '3dcal',
      debugShowCheckedModeBanner: false,
      themeMode: appThemeMode.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
