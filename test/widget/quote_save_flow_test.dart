// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/money/currency.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/share/quote_share.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculation_detail_page.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/quote_image_template.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests del save flow (guardar imagen en galeria, T2 del plan).
///
/// **Scope**: el boton fusionado "Compartir y guardar" de [ResultSheetContent]
/// (AS-2026: guarda la imagen Y abre el share sheet) y el boton "Guardar
/// imagen" de [CalculationDetailPage] disparan captura + save. En el test env
/// no hay platform channels: `Gal.putImageBytes` falla con [GalException], el
/// mapeo de `saveQuoteImage` lo convierte en [ShareQuoteException] y la UI
/// surfcea un AppSnackBar de error (NUNCA deja la excepcion cruda).
///
/// La rama "compartir" del boton fusionado usa share_plus: se inyecta un
/// [SharePlatform] fake (seam oficial de share_plus 12) para que `share`
/// complete exitoso sin platform channels y el test pueda aislar la rama
/// save (que es lo que ejercita este archivo).
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

/// Tap en el boton fusionado "Compartir y guardar" (solo ResultSheetContent,
/// AS-2026) y espera a que capture + save completen (la captura es
/// engine-async y necesita `runAsync`). El boton puede estar fuera del
/// viewport (ListView virtualizado) → scrollea hasta encontrarlo.
/// Espera hasta que [expected] (el snackbar resultante) aparezca.
Future<void> _tapShareAndSave(WidgetTester tester, Finder expected) async {
  await _tapShareAndSaveButton(tester);
  // toImage (captura) usa el engine real: esperamos (con timeout) hasta que
  // el snackbar resultante aparezca en vez de asumir un delay fijo de 300ms.
  // Los fonts JetBrainsMono estan bundleados como assets, asi que
  // google_fonts no intenta ningun fetch HTTP.
  await _pumpUntilFound(tester, expected);
}

/// Tap en el boton fusionado "Compartir y guardar" SOLAMENTE (scrollea hasta
/// el boton y dispara el handler sin esperar feedback). Usado por los tests
/// que quieren controlar el momento en que el save completa (AC-402).
Future<void> _tapShareAndSaveButton(WidgetTester tester) async {
  final saveBtn = find.byTooltip(EsBO.calcBtnShareSave);
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
}

/// Tap en el boton "Guardar imagen" SOLO de [CalculationDetailPage] (ese
/// boton NO se fusiono — sigue existiendo en el detalle) y espera a que la
/// captura + save completen. Reusa la logica de scroll de
/// [_tapShareAndSaveButton] con el tooltip del detalle.
Future<void> _tapSaveImage(WidgetTester tester, Finder expected) async {
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
  await _pumpUntilFound(tester, expected);
}

/// Espera (con timeout) hasta que [condition] sea true. Mismo mecanismo
/// `runAsync`+`pump` que [_pumpUntilFound] pero para estados arbitrarios
/// (no solo finders).
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (condition()) return;
  }
  fail('timeout esperando condicion');
}

/// Compat: tap en "Guardar imagen" del DETALLE esperando el snackbar de
/// error (caso estandar del save con gal real → GalException).
Future<void> _tapSaveAndSettle(WidgetTester tester) async {
  await _tapSaveImage(
    tester,
    find.textContaining('No se pudo guardar la imagen'),
  );
}

/// Tap en el boton fusionado "Compartir y guardar" del RESULT SHEET
/// esperando el snackbar de error (caso estandar: gal real → GalException
/// en la rama save; la rama share completa OK con el fake).
Future<void> _tapShareAndSaveAndSettle(WidgetTester tester) async {
  await _tapShareAndSave(
    tester,
    find.textContaining('No se pudo guardar la imagen'),
  );
}

/// Fake del share sheet de share_plus 12: `share` completa exitoso sin
/// platform channels. Se inyecta via [SharePlatform.instance] (seam oficial
/// del plugin) para que la rama "compartir" del boton fusionado no reviente
/// con MissingPluginException en estos tests de save flow.
class _FakeSharePlatform extends SharePlatform {
  @override
  Future<ShareResult> share(ShareParams params) async {
    return const ShareResult('', ShareResultStatus.success);
  }
}

/// Notifier que devuelve un estado fijo (mismo patron que result_sheet_test).
class _FixedStateNotifier extends CalculatorNotifier {
  _FixedStateNotifier(this.fixedState);
  final CalculatorState fixedState;

  @override
  CalculatorState build() => fixedState;
}

/// Guardado de galeria exitoso (sin platform channels).
class _FakeGallerySaver extends GallerySaver {
  const _FakeGallerySaver();

  @override
  Future<void> saveImage(Uint8List imageBytes, {required String name}) async {}
}

/// Saver con compuerta controlada por el test: `saveImage` queda PENDIENTE
/// hasta que el test llama [gate.complete]. Simula un save "en vuelo" que
/// el user interrumpe al cerrar el sheet (AC-402).
class _ControlledGallerySaver extends GallerySaver {
  final Completer<void> gate = Completer<void>();
  bool saveCalled = false;

  @override
  Future<void> saveImage(Uint8List imageBytes, {required String name}) {
    saveCalled = true;
    return gate.future;
  }
}

/// Repositorio de entitlement in-memory (same pattern paywall_navigation).
class _FakeEntitlementRepository implements EntitlementRepository {
  @override
  Future<Entitlement?> getActive() async => null;

  @override
  Future<int> save(EntitlementsCompanion entry) async => 1;

  @override
  Future<int> clear() async => 0;

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}

/// Payment service in-memory (same pattern paywall_navigation).
class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;

  @override
  Future<void> configure() async {}

  @override
  Future<PaymentResult> purchase({required String productId}) async =>
      const PaymentCancelled();

  @override
  Future<RestoreResult> restore() async => const RestoreEmpty();

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Future<bool?> isProActiveOnStore() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

void main() {
  // JetBrainsMono-SemiBold (w600) NO esta bundleado como asset (solo
  // Bold/Medium): sin esto google_fonts intenta un fetch HTTP en el test env
  // y la captura toImage de la cotizacion falla con una excepcion cruda.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Rama "compartir" del boton fusionado: share fake (completa exitoso sin
  // platform channels). SharePlus.instance captura SharePlatform.instance de
  // forma lazy en el primer uso → el fake se toma al correr el handler.
  SharePlatform.instance = _FakeSharePlatform();

  group('ResultSheetContent save button', () {
    testWidgets('error de save → AppSnackBar de error (no excepcion cruda)', (
      tester,
    ) async {
      final state = _validState();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultSheetContent(
                state: state,
                isPro: false,
                onSave: (_) {},
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

      await _tapShareAndSaveAndSettle(tester);

      // Error surfceado como SnackBar (sin crash ni spinner colgado).
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('No se pudo guardar la imagen'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ResultSheetContent — SnackBar sobre el sheet (F4)', () {
    /// Abre el sheet REAL via [showResultSheet] (con el wrap F4 de
    /// ScaffoldMessenger + Scaffold local), inyectando [saver] como seam de
    /// galeria.
    ///
    /// Necesita overrides de entitlement (repo/payment/cache) para que el
    /// gate "Cantidad" no boote un AppDatabase real (que dispararia
    /// path_provider → MissingPluginException fuera de runAsync).
    Future<void> openSheetInModal(
      WidgetTester tester, {
      GallerySaver saver = const GallerySaver(),
    }) async {
      final state = _validState();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementRepositoryProvider.overrideWithValue(
            _FakeEntitlementRepository(),
          ),
          paymentServiceProvider.overrideWithValue(_FakePaymentService()),
          calculatorNotifierProvider.overrideWith(
            () => _FixedStateNotifier(state),
          ),
        ],
      );
      addTearDown(container.dispose);

      // El contenido del sheet supera el viewport default: agrandar.
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showResultSheet(
                      context: ctx,
                      state: state,
                      onSave: (_) {},
                      onReset: () {},
                      onToggleDetail: () {},
                      onDiscountChanged: (_) {},
                      gallerySaver: saver,
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'F4: save exitoso → snackbar de exito visible CON el sheet abierto',
      (tester) async {
        await openSheetInModal(tester, saver: const _FakeGallerySaver());

        // El boton fusionado corre save (fake OK) + share (fake OK) en
        // paralelo → ambas ramas completan → snackbar de exito.
        await _tapShareAndSave(tester, find.text(EsBO.commonImageSavedGallery));

        // La hoja sigue abierta (guardar imagen no la cierra).
        expect(find.byType(QuoteImageTemplate), findsOneWidget);

        // Snackbar presente y unico (sin duplicacion).
        final msg = find.text(EsBO.commonImageSavedGallery);
        expect(msg, findsOneWidget);

        // El snackbar vive en el Scaffold del sheet (wrap F4), no en el de
        // atras: su Scaffold host es descendiente del BottomSheet modal.
        final host = find.ancestor(of: msg, matching: find.byType(Scaffold));
        expect(host, findsOneWidget);
        expect(
          find.ancestor(of: host, matching: find.byType(BottomSheet)),
          findsOneWidget,
          reason:
              'El snackbar debe hostearse en el Scaffold local del sheet '
              '(visible sobre la hoja, no oculto detras del barrier).',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('F4: save fallido → snackbar de error tambien sobre el sheet', (
      tester,
    ) async {
      // Gal REAL (default): sin platform channels el save falla →
      // ShareQuoteException → snackbar de error (la rama share completa OK
      // con el fake). Debe verse sobre el sheet.
      await openSheetInModal(tester, saver: const GallerySaver());

      await _tapShareAndSave(
        tester,
        find.textContaining('No se pudo guardar la imagen'),
      );

      expect(find.byType(QuoteImageTemplate), findsOneWidget);
      final msg = find.textContaining('No se pudo guardar la imagen');
      final host = find.ancestor(of: msg, matching: find.byType(Scaffold));
      expect(host, findsOneWidget);
      expect(
        find.ancestor(of: host, matching: find.byType(BottomSheet)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'AC-402: sheet cerrado durante el save → snackbar de exito en el '
      'messenger ROOT de la page',
      (tester) async {
        final saver = _ControlledGallerySaver();
        await openSheetInModal(tester, saver: saver);

        // Dispara el save; la captura (engine real) y la cadena avanazan
        // con runAsync hasta el seam: el save queda "en vuelo" (gate
        // pendiente, saveCalled=true) con el sheet todavia abierto. La rama
        // share (fake) completa OK al instante; el Future.wait del handler
        // fusionado espera igualmente al save.
        await _tapShareAndSaveButton(tester);
        await _pumpUntil(tester, () => saver.saveCalled);

        // El user cierra la hoja ANTES de que el save complete. Se usa pop
        // (no drag-dismiss): el drag caeria sobre la zona scrolleable del
        // contenido (ya scrolleado por ensureVisible) y scrollearia la lista
        // en vez de cerrar la hoja.
        final sheetContext = tester.element(find.byType(ResultSheetContent));
        Navigator.of(sheetContext).pop();
        await tester.pumpAndSettle();
        expect(
          find.byType(ResultSheetContent),
          findsNothing,
          reason: 'El sheet debe estar cerrado antes de completar el save.',
        );

        // El save completa con la hoja ya desmontada.
        saver.gate.complete();

        // El snackbar de exito aparece en el ROOT messenger (fallback) —
        // el messenger local del sheet murio con el widget.
        await _pumpUntilFound(tester, find.text(EsBO.commonImageSavedGallery));
        final msg = find.text(EsBO.commonImageSavedGallery);
        expect(msg, findsOneWidget);

        final host = find.ancestor(of: msg, matching: find.byType(Scaffold));
        expect(host, findsOneWidget);
        expect(
          find.ancestor(of: host, matching: find.byType(BottomSheet)),
          findsNothing,
          reason:
              'Con el sheet cerrado, el feedback debe hostearse en el '
              'Scaffold de la page (messenger ROOT), no dentro de la hoja.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('CalculationDetailPage save button', () {
    testWidgets('error de save → AppSnackBar de error (no excepcion cruda)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
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
          child: MaterialApp(home: CalculationDetailPage(calcId: calcId)),
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

  group('CalculationDetailPage — foto persistida (F2)', () {
    // 1x1 PNG transparente valido (mismo asset de result_sheet_test).
    const tinyPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=';
    Uint8List tinyPng() => base64Decode(tinyPngBase64);

    Future<int> seedAndPumpForPhoto(
      WidgetTester tester, {
      Uint8List? pieceImageBytes,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
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
          pieceName: 'Pieza de prueba',
          pieceImageBytes: pieceImageBytes,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: CalculationDetailPage(calcId: calcId)),
        ),
      );
      await tester.pumpAndSettle();
      return calcId;
    }

    /// El detalle usa una ListView lazy: el template puede no estar inflado
    /// hasta scrollear. (El test del boton "Guardar imagen" ya depende de
    /// esta misma logica via `_tapSaveAndSettle`.)
    Future<void> scrollToTemplate(WidgetTester tester) async {
      final template = find.byType(QuoteImageTemplate);
      if (template.evaluate().isNotEmpty) return;
      await tester.scrollUntilVisible(
        template,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }

    testWidgets('preview del template usa el BLOB persistido (AC-205)', (
      tester,
    ) async {
      await seedAndPumpForPhoto(tester, pieceImageBytes: tinyPng());
      await scrollToTemplate(tester);

      // El engine real decodifica async: le damos un tick real antes de
      // asertar (el errorBuilder del template absorbe falls de decode).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      final templateFinder = find.byType(QuoteImageTemplate);
      expect(
        templateFinder,
        findsOneWidget,
        reason: 'El detalle debe renderizar el preview del template.',
      );
      final template = tester.widget<QuoteImageTemplate>(templateFinder);
      expect(
        template.pieceImageBytes,
        equals(tinyPng()),
        reason: 'El preview del detalle debe usar el BLOB persistido.',
      );
    });

    testWidgets('sin foto: el preview no tiene pieceImageBytes', (
      tester,
    ) async {
      await seedAndPumpForPhoto(tester);
      await scrollToTemplate(tester);

      final template = tester.widget<QuoteImageTemplate>(
        find.byType(QuoteImageTemplate),
      );
      expect(template.pieceImageBytes, isNull);
    });
  });

  group('Snapshot batch (feature A — Hito 1)', () {
    testWidgets('guarda batch fields cuando hay escalón', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final repo = CalculationRepository(db);
      final draft = CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA',
            weightGrams: Decimal.parse('50'),
            pricePerBobbin: Decimal.parse('120'),
            gramsPerBobbin: Decimal.parse('1000'),
          ),
        ],
        totalHours: Decimal.parse('2'),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.parse('6'),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.parse('6'),
        ),
        quantity: 10,
        batchDiscountPercent: Decimal.parse('10'),
        batchDiscountAmount: Decimal.parse('6'),
      );
      final id = await repo.create(draft);
      final saved = await repo.getById(id);

      expect(saved, isNotNull);
      expect(saved!.batchDiscountPercent, '10');
      expect(saved.batchDiscountAmount, '6');
    });

    testWidgets('batch fields null cuando no hay escalón', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final repo = CalculationRepository(db);
      final draft = CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA',
            weightGrams: Decimal.parse('50'),
            pricePerBobbin: Decimal.parse('120'),
            gramsPerBobbin: Decimal.parse('1000'),
          ),
        ],
        totalHours: Decimal.parse('2'),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.parse('6'),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.parse('6'),
        ),
        quantity: 1,
      );
      final id = await repo.create(draft);
      final saved = await repo.getById(id);

      expect(saved, isNotNull);
      expect(saved!.batchDiscountPercent, isNull);
      expect(saved.batchDiscountAmount, isNull);
    });
  });
}
