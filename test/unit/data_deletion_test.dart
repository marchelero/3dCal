// ignore_for_file: public_member_api_docs, avoid_print
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tresdcal/core/backup/backup_signature.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart' show kActivePrinterIdPrefsKey;
import 'package:tresdcal/core/storage/draft_storage.dart';
import 'package:tresdcal/core/storage/local_data_wipe_service.dart';
import 'package:tresdcal/features/settings/data/settings_repository.dart';

/// AC-004: borrado local de datos de trabajo tras confirmación.
///
/// Verifica que el wipe:
/// - elimina cotizaciones (definitivas, parciales y plantillas), materiales,
///   filamentos, impresoras, settings y escalones de descuento;
/// - elimina draft de sesión, impresora activa y onboarding_done;
/// - PRESERVA locale, tema, entitlement DB + cache, claves HMAC e install id;
/// - es idempotente sobre una base vacía;
/// - lanza (y no informa éxito) si la DB falla, dejando prefs intactas.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  /// Inserta una cotización con 1 material Express implícito.
  Future<Map<String, Object>> seedWorkData() async {
    // --- Settings (3 filas representativas: cálculo, empresa, moneda) ---
    final settings = SettingsRepository(db);
    await settings.setKwhRate(Decimal.parse('0.5'));
    await settings.setCompanyName('Mi Taller');
    await settings.setCurrencyCode('BOB');

    // --- Cotizaciones: definitiva + parcial + plantilla, cada una con material ---
    Future<void> insertCalc({
      required String pieceName,
      required bool isPartial,
      required bool isTemplate,
    }) async {
      final id = await db
          .into(db.calculations)
          .insert(
            CalculationsCompanion(
              createdAt: Value(DateTime(2026, 10, 4, 10, 0)),
              pieceName: Value(pieceName),
              clientName: const Value('Cliente X'),
              totalHours: const Value(2),
              printMinutes: const Value(30),
              discountPercentage: const Value(0),
              kwhRateSnapshot: const Value(0),
              profitBaseSnapshot: const Value(0),
              quantity: const Value(1),
              isSold: const Value(false),
              isTemplate: Value(isTemplate),
              isPartial: Value(isPartial),
              isAdvanced: const Value(false),
              materialCostSnapshot: const Value(10),
              electricCostSnapshot: const Value(0),
              amortizationCostSnapshot: const Value(0),
              laborCostSnapshot: const Value(0),
              postProcessCostSnapshot: const Value(0),
              baseCostSnapshot: const Value(10),
              failureCostSnapshot: const Value(0),
              markupCostSnapshot: const Value(0),
              profitAmountSnapshot: const Value(0),
              minimumChargeAppliedSnapshot: const Value(0),
              effectiveTotalSnapshot: const Value(10),
              totalPriceSnapshot: const Value(10),
              laborRateSnapshot: const Value(0),
              postProcessRateSnapshot: const Value(0),
              failureRateSnapshot: const Value(0),
              minimumChargeSnapshot: const Value(0),
              markupOnMaterialsSnapshot: const Value(0),
            ),
          );
      await db
          .into(db.calculationMaterials)
          .insert(
            CalculationMaterialsCompanion.insert(
              calculationId: id,
              label: 'PLA',
              weightGrams: 50,
              pricePerBobbinSnapshot: 100,
              gramsPerBobbinSnapshot: 1000,
            ),
          );
    }

    await insertCalc(
      pieceName: 'Definitiva',
      isPartial: false,
      isTemplate: false,
    );
    await insertCalc(pieceName: 'Parcial', isPartial: true, isTemplate: false);
    await insertCalc(
      pieceName: 'Plantilla',
      isPartial: false,
      isTemplate: true,
    );

    // --- Catálogos: 1 filamento + 1 impresora ---
    await db
        .into(db.filaments)
        .insert(
          FilamentsCompanion.insert(
            name: 'PLA',
            brand: const Value('Generic'),
            pricePerBobbin: 100,
            gramsPerBobbin: 1000,
            isDefault: const Value(false),
            color: const Value('Negro'),
            createdAt: DateTime(2026, 10, 1),
          ),
        );
    await db
        .into(db.printers)
        .insert(
          PrintersCompanion.insert(
            brand: const Value('Creality'),
            name: 'Ender 3',
            averageWatts: 150,
            isDefault: const Value(false),
            createdAt: DateTime(2026, 10, 1),
          ),
        );

    // --- Escalón de descuento por cantidad ---
    await db
        .into(db.discountTiersTable)
        .insert(
          DiscountTiersTableCompanion.insert(
            id: 'tier-1',
            minQty: 5,
            percent: '10',
            sortOrder: 0,
          ),
        );

    // --- Entitlement Pro en DB (debe sobrevivir) ---
    await db
        .into(db.entitlements)
        .insert(
          EntitlementsCompanion.insert(
            source: kSourceLifetimePurchase,
            productId: kProProductId,
            purchasedAt: DateTime.utc(2026, 1, 1),
          ),
        );

    // --- Prefs: sesión/onboarding a borrar + protegidas a preservar ---
    return <String, Object>{
      SettingsKeys.onboardingDone: true,
      kActivePrinterIdPrefsKey: 3,
      DraftStorage.key: '{"weight":"50"}',
      'locale': 'es',
      'theme_mode': 'dark',
      kIsProKey: true,
      kEntitlementSourceKey: kSourceLifetimePurchase,
      kEntitlementValidatedAtKey: '2026-10-01T00:00:00.000Z',
      kBackupHmacKeyPref: 'aa' * 32,
      kInstallIdPref: 'install-abc',
    };
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalDataWipeService.wipeWorkData', () {
    test(
      'borra datos de trabajo y preserva entitlements + prefs protegidas',
      () async {
        final seed = await seedWorkData();
        SharedPreferences.setMockInitialValues(seed);
        prefs = await SharedPreferences.getInstance();
        final service = LocalDataWipeService(
          db: db,
          prefs: prefs,
          draftStorage: DraftStorage(prefs),
        );

        await service.wipeWorkData();

        // Tablas de trabajo vacías.
        expect(await db.select(db.calculationMaterials).get(), isEmpty);
        expect(await db.select(db.calculations).get(), isEmpty);
        expect(await db.select(db.filaments).get(), isEmpty);
        expect(await db.select(db.printers).get(), isEmpty);
        expect(await db.select(db.settingsTable).get(), isEmpty);
        expect(await db.select(db.discountTiersTable).get(), isEmpty);

        // Entitlement Pro sobrevive (fila activa).
        final entitlements = await db.select(db.entitlements).get();
        expect(entitlements, hasLength(1));
        expect(entitlements.single.isActive, isTrue);
        expect(entitlements.single.source, kSourceLifetimePurchase);

        // Prefs de sesión/onboarding borradas.
        expect(prefs.getString(DraftStorage.key), isNull);
        expect(prefs.getInt(kActivePrinterIdPrefsKey), isNull);
        expect(prefs.getBool(SettingsKeys.onboardingDone), isNull);

        // Prefs protegidas intactas.
        expect(prefs.getString('locale'), 'es');
        expect(prefs.getString('theme_mode'), 'dark');
        expect(prefs.getBool(kIsProKey), isTrue);
        expect(prefs.getString(kEntitlementSourceKey), kSourceLifetimePurchase);
        expect(prefs.getString(kEntitlementValidatedAtKey), isNotNull);
        expect(prefs.getString(kBackupHmacKeyPref), 'aa' * 32);
        expect(prefs.getString(kInstallIdPref), 'install-abc');
      },
    );

    test(
      'es idempotente sobre una base vacía con solo prefs protegidas',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'locale': 'de',
          'theme_mode': 'light',
          kIsProKey: false,
          kBackupHmacKeyPref: 'bb' * 32,
          kInstallIdPref: 'install-empty',
        });
        prefs = await SharedPreferences.getInstance();
        final service = LocalDataWipeService(
          db: db,
          prefs: prefs,
          draftStorage: DraftStorage(prefs),
        );

        await service.wipeWorkData(); // no debe lanzar
        await service.wipeWorkData(); // segunda pasada idempotente

        expect(prefs.getString('locale'), 'de');
        expect(prefs.getString(kBackupHmacKeyPref), 'bb' * 32);
        expect(prefs.getString(kInstallIdPref), 'install-empty');
        expect(await db.select(db.calculations).get(), isEmpty);
      },
    );

    test(
      'si la DB falla lanza, hace rollback y NO borra prefs (sin éxito falso)',
      () async {
        final seed = await seedWorkData();
        SharedPreferences.setMockInitialValues(seed);
        prefs = await SharedPreferences.getInstance();
        // Trigger que aborta el DELETE de cotizaciones (mismo patrón RAISE ABORT
        // usado en tests de persistencia del onboarding: fallo determinista).
        await db.customStatement(
          'CREATE TRIGGER fail_wipes BEFORE DELETE ON calculations '
          'BEGIN SELECT RAISE(ABORT, "boom"); END;',
        );

        final service = LocalDataWipeService(
          db: db,
          prefs: prefs,
          draftStorage: DraftStorage(prefs),
        );
        await expectLater(service.wipeWorkData(), throwsA(anything));

        // Rollback transaccional: ninguna tabla de trabajo quedó tocada.
        expect(await db.select(db.calculations).get(), hasLength(3));
        expect(await db.select(db.calculationMaterials).get(), hasLength(3));
        expect(await db.select(db.filaments).get(), hasLength(1));
        expect(await db.select(db.printers).get(), hasLength(1));
        expect(await db.select(db.settingsTable).get(), isNotEmpty);
        expect(await db.select(db.discountTiersTable).get(), hasLength(1));

        // Prefs intactas: el flujo NO debe reportar éxito.
        expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);
        expect(prefs.getString(DraftStorage.key), '{"weight":"50"}');
        expect(prefs.getInt(kActivePrinterIdPrefsKey), 3);
        expect(prefs.getString('locale'), 'es');
        expect(prefs.getString(kBackupHmacKeyPref), 'aa' * 32);
      },
    );
  });
}
