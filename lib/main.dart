// ignore_for_file: public_member_api_docs
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/draft_storage_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'features/entitlement/presentation/providers/entitlement_providers.dart';

Future<void> main() async {
  // Asegurar inicializacion del binding antes de tocar plugins (SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-cargar fuentes en build time para evitar el "flash of unstyled text"
  // (FOUT). Todas las fuentes usadas por el TextTheme (Inter + JetBrains Mono)
  // estan bundleadas en assets/fonts/; `allowRuntimeFetching = false` hace que
  // google_fonts NUNCA descargue en runtime (falla rapido si falta un peso).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Materializar ambos TextTheme ANTES de runApp: esto registra las familias
  // en google_fonts y hace que `pendingFonts()` espere de verdad (si se llama
  // antes, espera cero familias y retorna al instante = no-op).
  AppTheme.light();
  AppTheme.dark();
  await GoogleFonts.pendingFonts();

  // Pre-cargar SharedPreferences para que [sharedPreferencesProvider]
  // (usado por DraftStorage) tenga un valor sync disponible al boot.
  final prefs = await SharedPreferences.getInstance();

  // ProviderContainer en vez de ProviderScope: permite inicializar el SDK
  // de pagos (async) antes del primer frame via `await configure()`.
  // UncontrolledProviderScope conserva los overrides al montar el tree.
  // Patron del report `docs/reports/2026-07-22_1230-t9-payment-service-wire.report.md`.
  final overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    // El dashboard refleja el entitlement real (isProProvider) en vez del
    // default conservador `false` de dashboardIsProProvider (T17 wiring).
    dashboardIsProProvider.overrideWith((ref) => ref.watch(isProProvider)),
  ];

  if (kIsWeb) {
    // Q-Web: la web queda 100% free — todos los gates abiertos (advanced,
    // history cap, CSV, dashboard charts). No hay store/paywall en web:
    // isProProvider siempre `true`. El override propaga al dashboard via
    // dashboardIsProProvider (wiring de arriba).
    overrides.add(isProProvider.overrideWithValue(true));
  }

  final container = ProviderContainer(overrides: overrides);

  // Inicializa RevenueCat (purchases_flutter). Dev mode sin SDK key →
  // log warning + no-op (la app arranca free, ver payment_service_revenuecat.dart).
  // En web no aplica (purchases_flutter no soporta web) → skip.
  if (!kIsWeb) {
    await container.read(paymentServiceProvider).configure();
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const TresdcalApp()),
  );
}
