import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Widget raiz de tresdcal.
///
/// **Sprint 7**: usa [MaterialApp.router] con [appRouter] (go_router).
/// Soporta light/dark automatico (themeMode.system) y se adapta a mobile/web
/// via [AppScaffold] (NavigationBar en mobile, NavigationRail en web).
class TresdcalApp extends StatelessWidget {
  /// Crea el widget raiz con la configuracion por defecto.
  const TresdcalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '3dcal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
