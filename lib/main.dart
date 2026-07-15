import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/draft_storage_providers.dart';

Future<void> main() async {
  // Asegurar inicializacion del binding antes de tocar plugins (SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

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
