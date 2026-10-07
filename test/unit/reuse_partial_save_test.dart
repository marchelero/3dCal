// ignore_for_file: public_member_api_docs, avoid_print
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';

/// Flujo EXACTO del usuario: cotizacion definitiva -> "Reusar" -> editar peso
/// -> SALIR con el boton X -> historial debe mostrar 2 (definitiva + borrador).
///
/// Verifica tambien que el stream del historial ([CalculationsNotifier])
/// emita el borrador (no solo que este en la DB).
Future<int> _seedDefinitiveWithMaterial(AppDatabase db, String pieceName) async {
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
          isTemplate: const Value(false),
          isPartial: const Value(false),
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
  // Material implicito Express (peso + precio + gramos) para que loadFromCalculation
  // precargue el form como en el caso real del usuario.
  await db
      .into(db.calculationMaterials)
      .insert(
        CalculationMaterialsCompanion.insert(
          calculationId: id,
          label: 'PLA',
          weightGrams: 100,
          pricePerBobbinSnapshot: 120,
          gramsPerBobbinSnapshot: 1000,
        ),
      );
  return id;
}

void main() {
  testWidgets('Reusar + editar + SALIR con X deja borrador visible en historial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = CalculationRepository(db);

    final definitiveId = await tester.runAsync(
      () => _seedDefinitiveWithMaterial(db, 'Pieza original'),
    );
    final definitive = await tester.runAsync(() => repo.getById(definitiveId!));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: CalculatorPage(prefillCalc: definitive)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Editar el peso (como el usuario: "le cambie el valor del peso").
    await tester.enterText(find.widgetWithText(TextField, 'Peso'), '250');
    await tester.pump(const Duration(milliseconds: 300));

    // SALIR con el boton X (tooltip EsBO.calcCloseAction = 'Cerrar').
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget, reason: 'hay un boton X de salida');
    await tester.tap(closeBtn);
    // Esperar el guardado async real (await _persistPartialSync) + pop.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Desmontar para cancelar el timer del debounce pendiente (si no, el test
    // falla con "A Timer is still pending": el X no cancela _partialSaveTimer).
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 1) La DB debe tener 2 filas.
    final items = (await tester.runAsync(repo.listItems))!;
    final drafts = items.where((c) => c.isPartial).toList();
    print('DB: items=${items.length} drafts=${drafts.length}');

    // 2) El stream del historial debe emitir el borrador (como lo ve la UI).
    final historyItems = (await tester.runAsync(() async {
      // Consumir watchItems() (el stream que usa CalculationsNotifier).
      return repo.watchItems().first;
    }))!;
    print('HISTORIAL (stream): count=${historyItems.length} '
        'drafts=${historyItems.where((c) => c.isPartial).length}');

    final okDb = items.length == 2 && drafts.length == 1;
    final okHistory = historyItems.length == 2;
    print('VEREDICTO: db=$okDb historial=$okHistory '
        '${okDb && okHistory ? "PASS" : "FAIL"}');

    expect(okDb, isTrue, reason: 'DB debe tener original + borrador');
    expect(okHistory, isTrue,
        reason: 'el stream del historial debe mostrar 2 (incluye el borrador)');
  });

  testWidgets('Reusar + editar GRAMOS + BACK (PopScope) deja borrador', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = CalculationRepository(db);

    final definitiveId = await tester.runAsync(
      () => _seedDefinitiveWithMaterial(db, 'Pieza gramos'),
    );
    final definitive = await tester.runAsync(() => repo.getById(definitiveId!));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: CalculatorPage(prefillCalc: definitive)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Editar SOLO GRAMOS / bobina (campo exacto del usuario en su 1er reporte:
    // "modifique los gramos se recalculo"). NO tocar peso: confiar en que el
    // prefill deja el form valido. Si no lo deja, output=null y no se guarda.
    await tester.enterText(
      find.widgetWithText(TextField, 'Gramos / bobina'),
      '750',
    );
    await tester.pump(const Duration(milliseconds: 300));

    // BACK del sistema: dispara PopScope.onPopInvokedWithResult.
    // (pageBack busca un CupertinoBackButton que aqui no existe: el
    // CalculatorPage usa leading X custom. handlePopRoute simula el back real.)
    await tester.binding.handlePopRoute();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Desmontar para cancelar timers pendientes.
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final items = (await tester.runAsync(repo.listItems))!;
    final drafts = items.where((c) => c.isPartial).toList();
    final historyItems = (await tester.runAsync(() => repo.watchItems().first))!;
    print('BACK: db=${items.length} drafts=${drafts.length} '
        'historial=${historyItems.length}');

    expect(items.length, 2, reason: 'DB: original + borrador');
    expect(drafts.length, 1, reason: 'un borrador nuevo');
    expect(historyItems.length, 2, reason: 'historial muestra 2');
  });
}
