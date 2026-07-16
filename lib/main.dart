import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/draft_storage_providers.dart';

Future<void> main() async {
  // Asegurar inicializacion del binding antes de tocar plugins (SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-cargar fuentes de Google Fonts en build time.
  // Bloquea hasta que todas las fuentes referenciadas en el TextTheme esten
  // descargadas, evitando el "flash of unstyled text" (FOUT) en el primer frame.
  // Ver lib/core/theme/app_theme.dart para las fuentes usadas.
  await GoogleFonts.pendingFonts();

  // Pre-cargar SharedPreferences para que [sharedPreferencesProvider]
  // (usado por DraftStorage) tenga un valor sync disponible al boot.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TresdcalApp(),
    ),
  );
}
