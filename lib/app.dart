import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/calculation/presentation/pages/home_page.dart';

/// Widget raiz de tresdcal.
///
/// Configura MaterialApp con tema M3, soporte light/dark automatico y
/// un placeholder de HomePage. Sprint 7 reemplazara el `home:` por go_router.
class TresdcalApp extends StatelessWidget {
  /// Crea el widget raiz con la configuracion por defecto.
  const TresdcalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3dcal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomePage(),
    );
  }
}
