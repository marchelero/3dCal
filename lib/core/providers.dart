import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/calculation/data/calculation_repository.dart';
import '../../features/catalog/filaments/data/filament_repository.dart';
import '../../features/catalog/printers/data/printer_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import 'database/app_database.dart';

/// Provider de la base de datos.
///
/// **Override en main()** con un in-memory database para tests:
/// ```dart
/// ProviderScope(
///   overrides: [appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(...))],
///   child: TresdcalApp(),
/// );
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Repos de impresoras.
final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  return PrinterRepository(ref.watch(appDatabaseProvider));
});

/// Repos de filamentos.
final filamentRepositoryProvider = Provider<FilamentRepository>((ref) {
  return FilamentRepository(ref.watch(appDatabaseProvider));
});

/// Repos de settings.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

/// Repos de cotizaciones.
final calculationRepositoryProvider = Provider<CalculationRepository>((ref) {
  return CalculationRepository(ref.watch(appDatabaseProvider));
});
