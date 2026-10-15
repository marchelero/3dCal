// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../providers.dart' show appDatabaseProvider, kActivePrinterIdPrefsKey;
import 'draft_storage.dart';
import 'draft_storage_providers.dart'
    show draftStorageProvider, sharedPreferencesProvider;
import 'setup_draft_storage.dart';

/// Borra los datos de trabajo locales (AC-004).
///
/// Elimina, en una transacción Drift: cotizaciones (definitivas, parciales y
/// plantillas — sus materiales por CASCADE), catálogos de filamentos e
/// impresoras, ajustes de cálculo y escalones de descuento. Después elimina
/// las prefs de sesión: `form_draft`, `setup_printer_draft`,
/// `setup_filament_draft`, `active_printer_id` y `onboarding_done`
/// (que reinicia el onboarding para reconfigurar catálogos).
///
/// **Preserva**: locale, tema, entitlement Pro (tabla + cache en prefs),
/// identidad RevenueCat y las claves de firma HMAC / install id. No toca
/// archivos `.3dcal` exportados.
///
/// **Reglas de seguridad**:
/// - NO usa `SharedPreferences.clear()` (deletedría claves protegidas).
/// - NO toca la tabla/`EntitlementRepository` (clear() ahí es soft-delete y
///   además fuera del alcance: el Pro debe seguir verificable tras el wipe).
/// - Orden de fallo seguro: DB primero (atómica), prefs después (idempotente).
///   Si una etapa falla, la operación lanza y la UI no reporta éxito.
class LocalDataWipeService {
  const LocalDataWipeService({
    required this.db,
    required this.prefs,
    required this.draftStorage,
  });

  final AppDatabase db;
  final SharedPreferences prefs;
  final DraftStorage draftStorage;

  /// Ejecuta el borrado completo. Lanza si falla (sin éxito falso).
  Future<void> wipeWorkData() async {
    // 1) DB: transacción atómica que nunca toca `entitlements`.
    await db.transaction(() async {
      await db.delete(db.calculationMaterials).go();
      await db.delete(db.calculations).go();
      await db.delete(db.filaments).go();
      await db.delete(db.printers).go();
      await db.delete(db.settingsTable).go();
      await db.delete(db.discountTiersTable).go();
    });

    // 2) Prefs de sesión: borrado explícito (idempotente, reintentable).
    await draftStorage.clear();
    // MED-2: los borradores de los pasos del setup también son datos de
    // sesión (sobreviven matar la app); el wipe los limpia junto con
    // form_draft.
    await prefs.remove(SetupDraftStorage.printerKey);
    await prefs.remove(SetupDraftStorage.filamentKey);
    await prefs.remove(kActivePrinterIdPrefsKey);
    await prefs.remove(SettingsKeys.onboardingDone);
  }
}

/// Provider del servicio de borrado local.
final localDataWipeServiceProvider = Provider<LocalDataWipeService>((ref) {
  return LocalDataWipeService(
    db: ref.watch(appDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    draftStorage: ref.watch(draftStorageProvider),
  );
});
