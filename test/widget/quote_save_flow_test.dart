// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/money/currency.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculation_detail_page.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';

/// Widget tests del save flow (guardar imagen en galeria, T2 del plan).
///
/// **Scope**: el boton "Guardar imagen" de [ResultSheetContent] y de
/// [CalculationDetailPage] dispara captura + save. En el test env no hay
/// platform channels: `Gal.putImageBytes` falla con [GalException], el mapeo
/// de `saveQuoteImage` lo convierte en [ShareQuoteException] y la UI surfcea
/// un AppSnackBar de error (NUNCA deja la excepcion cruda).
///
/// **Async**: la captura usa `RenderRepaintBoundary.toImage` (engine) y
/// completa en el event loop real → corre dentro de `tester.runAsync`. Para
/// que google_fonts no intente un fetch HTTP en el test env, las fuentes
/// JetBrainsMono (500/700) estan bundleadas como assets (`assets/fonts/`):
/// google_fonts las resuelve via assets antes que el runtime fetch.
CalculatorState _validState() {
  final out = CalculationOutput.simple(
    materialCost: Decimal.fromInt(12),
    discountAmount: Decimal.zero,
    totalPrice: Decimal.fromInt(36),
  );
  return CalculatorState(
    mode: CalculatorMode.express,
    weight: '100',
    filamentPrice: '120',
    filamentGrams: '1000',
    printHours: '2',
    printMinutes: '0',
    discountPct: '0',
    label: 'Pieza de prueba',
    materials: const [],
    output: out,
    showDetail: false,
    detailDiscountPct: null,
    detailElectricCost: Decimal.fromInt(2),
    detailBaseCost: Decimal.fromInt(14),
    detailProfitAmount: Decimal.fromInt(22),
    detailTotalFinal: Decimal.fromInt(36),
    computeVersion: 1,
  );
}

/// Espera (con timeout) hasta que [finder] matchee 1+ widgets.
///
/// El save de imagen usa engine real (`RenderRepaintBoundary.toImage`), que
/// bajo carga del suite completo puede tardar mas que un delay fijo (era el
/// flake 289/290). Intercalar `runAsync` (deja avanzar el event loop real)
/// con `pump` (builds la SnackBar cuando la cadena async completa) hace el
/// poll deterministico en vez de asumir timing fijo.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// Tap en "Guardar imagen" y espera a que capture + save completen (la
/// captura es engine-async y necesita `runAsync`). El boton puede estar
/// fuera del viewport (ListView virtualizado) → scrollea hasta encontrarlo.
Future<void> _tapSaveAndSettle(WidgetTester tester) async {
  final saveBtn = find.byTooltip('Guardar imagen');
  if (saveBtn.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      saveBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(saveBtn);
  await tester.pumpAndSettle();
  await tester.tap(saveBtn);
  await tester.pump();
  // toImage (captura) usa el engine real: esperamos (con timeout) hasta que
  // la SnackBar de error aparezca en vez de asumir un delay fijo de 300ms.
  // Los fonts JetBrainsMono estan bundleados como assets, asi que
  // google_fonts no intenta ningun fetch HTTP.
  await _pumpUntilFound(
    tester,
    find.textContaining('No se pudo guardar la imagen'),
  );
}

void main() {
  // JetBrainsMono-SemiBold (w600) NO esta bundleado como asset (solo
  // Bold/Medium): sin esto google_fonts intenta un fetch HTTP en el test env
  // y la captura toImage de la cotizacion falla con una excepcion cruda.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('ResultSheetContent save button', () {
    testWidgets('error de save → AppSnackBar de error (no excepcion cruda)',
        (tester) async {
      final state = _validState();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultSheetContent(
                state: state,
                isPro: false,
                onSave: () {},
                onReset: () {},
                onToggleDetail: () {},
                onDiscountChanged: (_) {},
                currency: WorldCurrency.usd,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapSaveAndSettle(tester);

      // Error surfceado como SnackBar (sin crash ni spinner colgado).
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('No se pudo guardar la imagen'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CalculationDetailPage save button', () {
    testWidgets('error de save → AppSnackBar de error (no excepcion cruda)',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(calculationRepositoryProvider);
      final calcId = await repo.create(
        CalculationDraft(
          materials: [
            MaterialInput(
              label: 'PLA Test',
              weightGrams: Decimal.parse('100'),
              pricePerBobbin: Decimal.parse('120'),
              gramsPerBobbin: Decimal.parse('1000'),
            ),
          ],
          totalHours: Decimal.parse('5'),
          discountPercentage: Decimal.zero,
          output: CalculationOutput.simple(
            materialCost: Decimal.parse('12'),
            discountAmount: Decimal.zero,
            totalPrice: Decimal.parse('12'),
          ),
          pieceName: 'Test piece',
          clientName: 'Test client',
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: CalculationDetailPage(calcId: calcId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapSaveAndSettle(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('No se pudo guardar la imagen'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
