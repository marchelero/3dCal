import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/calculation/data/calculation_repository.dart';
import '../../features/catalog/filaments/data/filament_repository.dart';
import '../../features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../features/catalog/printers/data/printer_repository.dart';
import '../../features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../features/settings/data/discount_tiers_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/domain/discount_tier.dart';
import 'database/app_database.dart';
import 'utils/image_downscale.dart';

/// Downscaler de la foto de la pieza (F2), inyectable.
///
/// Producción: corre en un isolate para no congelar la UI con el decode/
/// resize/encode de una foto de cámara (varios MB). Web: síncrono (no hay
/// isolates de Dart).
///
/// **Tests**: los widget tests corren en fake-async, donde `Isolate.run`
/// nunca resuelve. Los tests de UI que guardan cotizaciones deben override
/// este provider con la versión síncrona (`(b) async => downscalePieceImage(b)`).
final pieceImageDownscalerProvider =
    Provider<Future<Uint8List?> Function(Uint8List?)>((ref) {
      if (kIsWeb) {
        return (bytes) async => downscalePieceImage(bytes);
      }
      return (bytes) => Isolate.run(() => downscalePieceImage(bytes));
    });

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

/// Repo de escalones de descuento por cantidad (feature A — Hito 1).
final discountTiersRepositoryProvider = Provider<DiscountTiersRepository>((ref) {
  return DiscountTiersRepository(ref.watch(appDatabaseProvider));
});

/// Stream reactivo de escalones (ordenado por `sort_order`). El calculator lo
/// escucha para resolver el escalón aplicado sobre la cantidad del lote.
final discountTiersProvider =
    StreamProvider<List<DiscountTier>>((ref) {
      return ref.watch(discountTiersRepositoryProvider).watchAll();
    });

/// Repos de cotizaciones.
final calculationRepositoryProvider = Provider<CalculationRepository>((ref) {
  return CalculationRepository(ref.watch(appDatabaseProvider));
});

/// Filamento marcado como default. `null` si no hay.
///
/// **Uso**: el calculator lo lee para auto-poblar `filamentPrice` y
/// `filamentGrams` al iniciar una cotizacion.
final defaultFilamentProvider = Provider<Filament?>((ref) {
  final list = ref.watch(filamentsNotifierProvider).value;
  if (list == null) return null;
  for (final f in list) {
    if (f.isDefault) return f;
  }
  return null;
});

/// Impresora marcada como default. `null` si no hay.
final defaultPrinterProvider = Provider<PrinterProfile?>((ref) {
  final list = ref.watch(printersNotifierProvider).value;
  if (list == null) return null;
  for (final p in list) {
    if (p.isDefault) return p;
  }
  return null;
});

/// Lista de impresoras. Alias derivado de [printersNotifierProvider] para
/// que el printer-selector (AppBar) no tenga que conocer el notifier.
final printersListProvider = Provider<AsyncValue<List<PrinterProfile>>>((ref) {
  return ref.watch(printersNotifierProvider);
});

/// Key de SharedPreferences donde se persiste el id de la impresora que el
/// usuario eligio en el cotizador (restaurada en la proxima sesion).
const kActivePrinterIdPrefsKey = 'active_printer_id';

/// ID de la impresora activa en la sesion del calculator.
///
/// Inicializa con el default. El user puede cambiarla via el selector
/// del cotizador. La eleccion se persiste en SharedPreferences
/// ([kActivePrinterIdPrefsKey]) y se restaura al reabrir la app.
final activePrinterIdProvider = StateProvider<int?>((ref) {
  return ref.watch(defaultPrinterProvider)?.id;
});

/// Impresora activa resuelta. `null` SOLO si no hay impresoras registradas.
///
/// Resolucion en cascada: id activo (elegido/persistido) → si ya no existe
/// (borrada) → default → si no hay default → primera de la lista. Asi el
/// cotizador nunca muestra "Sin impresora" cuando ya hay impresoras, y el
/// calculo de watts usa SIEMPRE la misma impresora que muestra la UI.
final activePrinterProvider = Provider<PrinterProfile?>((ref) {
  final id = ref.watch(activePrinterIdProvider);
  final list = ref.watch(printersNotifierProvider).value;
  if (list == null || list.isEmpty) return null;
  if (id != null) {
    for (final p in list) {
      if (p.id == id) return p;
    }
  }
  for (final p in list) {
    if (p.isDefault) return p;
  }
  return list.first;
});
