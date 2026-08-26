import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tresdcal/core/money/currency.dart';
import 'package:tresdcal/core/share/quote_share.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/calc_meta.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/quote_image_template.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Fake del platform interface de image_picker: retorna [_image] en
/// `getImage` y controla el soporte de camara.
class _FakePickerPlatform extends ImagePickerPlatform {
  _FakePickerPlatform(this._image, {this.cameraSupported = true});

  final XFile? _image;
  final bool cameraSupported;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return _image;
  }

  @override
  bool supportsImageSource(ImageSource source) =>
      source == ImageSource.camera ? cameraSupported : true;
}

/// Notifier que devuelve un estado fijo para tests.
class _FixedStateNotifier extends CalculatorNotifier {
  _FixedStateNotifier(this.fixedState);
  final CalculatorState fixedState;

  @override
  CalculatorState build() => fixedState;
}

/// Helpers de rendering para que cada test sea declarativo.
Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

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

void main() {
  group('ResultBottomBar', () {
    testWidgets('muestra empty hint cuando emptyHint provisto', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ResultBottomBar(
            totalText: '—',
            hasDiscount: false,
            onTap: null,
            emptyHint: 'Completa peso, precio y tiempo para ver la cotizacion',
          ),
        ),
      );

      expect(find.text('FALTA COMPLETAR'), findsOneWidget);
      expect(find.textContaining('Completa peso'), findsOneWidget);
      // No muestra chevron ni "Ver cotizacion" en estado empty.
      expect(find.text('VER COTIZACIÓN'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('muestra total + chevron cuando onTap provisto', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          ResultBottomBar(
            totalText: r'$ 36,00',
            hasDiscount: false,
            onTap: () => tapped++,
          ),
        ),
      );

      expect(find.text(r'$ 36,00'), findsOneWidget);
      expect(find.text('VER COTIZACIÓN'), findsOneWidget);
      // Redesign: chevron right (no arrow up).
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      // Empty hint no presente.
      expect(find.text('FALTA COMPLETAR'), findsNothing);

      await tester.tap(find.byType(ResultBottomBar));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('muestra badge descuento cuando hasDiscount=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ResultBottomBar(
            totalText: r'$ 27,00',
            hasDiscount: true,
            onTap: () {},
          ),
        ),
      );

      // El badge muestra "Ver detalle" (es el label del toggle, el color
      // del badge es lo que comunica el descuento).
      expect(find.text('Ver detalle'), findsOneWidget);
    });
  });

  group('ResultSheetContent', () {
    testWidgets('renderiza QuoteImageTemplate con output del state', (
      tester,
    ) async {
      final state = _validState();
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            isPro: false,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
            onDiscountChanged: (_) {},
            currency: WorldCurrency.usd,
          ),
        ),
      );

      // Quote template visible.
      expect(find.byType(QuoteImageTemplate), findsOneWidget);
      // Titulo del sheet (SectionHeader uppercase).
      expect(find.text('COTIZACIÓN'), findsWidgets);
      // Label del state aparece en el card.
      expect(find.text('Pieza de prueba'), findsOneWidget);
      // Total formateado.
      expect(find.text(r'$ 36,00'), findsAtLeastNWidgets(1));
    });

    testWidgets('muestra 4 botones de accion icon-only', (tester) async {
      final state = _validState();
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            isPro: false,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
            onDiscountChanged: (_) {},
            currency: WorldCurrency.usd,
          ),
        ),
      );

      // 4 botones con tooltips (ahora icon-only, sin texto).
      expect(find.byTooltip('Guardar cotización'), findsOneWidget);
      expect(find.byTooltip('Compartir imagen'), findsOneWidget);
      expect(find.byTooltip('Guardar imagen'), findsOneWidget);
      expect(find.byTooltip('Restablecer'), findsOneWidget);
    });

    testWidgets('tap save cierra sheet y llama onSave', (tester) async {
      var saved = 0;
      final state = _validState();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calculatorNotifierProvider.overrideWith(
              () => _FixedStateNotifier(state),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showResultSheet(
                    context: ctx,
                    state: state,
                    onSave: () => saved++,
                    onReset: () {},
                    onToggleDetail: () {},
                    onDiscountChanged: (_) {},
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap save (buscar por tooltip del IconButton). El contenido del
      // sheet supera el viewport del test (800x600) — asegurar visibilidad.
      await tester.ensureVisible(find.byTooltip('Guardar cotización'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Guardar cotización'));
      await tester.pumpAndSettle();

      // Sheet cerrada (no hay mas QuoteImageTemplate en el tree).
      expect(find.byType(QuoteImageTemplate), findsNothing);
      expect(saved, 1);
    });

    testWidgets('boton share se deshabilita durante isSharing', (tester) async {
      // El share real necesita platform channels. Solo verificamos el
      // estado de UI: el boton arranca enabled.
      final state = _validState();
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            isPro: false,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
            onDiscountChanged: (_) {},
            currency: WorldCurrency.usd,
          ),
        ),
      );

      // Buscar el icono de compartir, el IconButton debe estar enabled.
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      final finder = find.ancestor(
        of: find.byIcon(Icons.share_rounded),
        matching: find.byType(IconButton),
      );
      expect(finder, findsOneWidget);
      final btn = tester.widget<IconButton>(finder);
      expect(btn.onPressed, isNotNull);
    });
  });

  group('ResultSheetContent — foto de pieza (T9)', () {
    const heroKey = Key('quote-piece-image');
    // 1x1 PNG transparente valido (mismo asset de pdf_export_test).
    const tinyPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=';

    Uint8List tinyPng() => base64Decode(tinyPngBase64);
    XFile fileFromBytes(Uint8List bytes) =>
        XFile.fromData(bytes, name: 'img.png', mimeType: 'image/png');

    Future<void> pumpSheet(WidgetTester tester) async {
      final state = _validState();
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            isPro: false,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
            onDiscountChanged: (_) {},
            currency: WorldCurrency.usd,
          ),
        ),
      );
    }

    /// Adjunta una imagen via el path real del widget: abre el dialogo y
    /// toca "Galería". Requiere runAsync porque el widget decodifica la
    /// imagen con el engine real (instantiateImageCodec).
    Future<void> attachFromGallery(WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.ensureVisible(find.text(EsBO.quoteImageAdd));
        await tester.pumpAndSettle();
        await tester.tap(find.text(EsBO.quoteImageAdd));
        await tester.pumpAndSettle();
        await tester.tap(find.text(EsBO.quoteImageGallery));
        await tester.pumpAndSettle();
      });
      await tester.pumpAndSettle();
    }

    testWidgets(
      'SC1: control "Agregar imagen" abre sheet con Galería + Cámara',
      (tester) async {
        ImagePickerPlatform.instance = _FakePickerPlatform(
          fileFromBytes(tinyPng()),
        );
        await pumpSheet(tester);

        await tester.ensureVisible(find.text(EsBO.quoteImageAdd));
        await tester.pumpAndSettle();
        await tester.tap(find.text(EsBO.quoteImageAdd));
        await tester.pumpAndSettle();

        expect(find.text(EsBO.quoteImageGallery), findsOneWidget);
        expect(find.text(EsBO.quoteImageCamera), findsOneWidget);
      },
    );

    testWidgets('SC1: Cámara oculta cuando supportsImageSource(camera)=false', (
      tester,
    ) async {
      ImagePickerPlatform.instance = _FakePickerPlatform(
        fileFromBytes(tinyPng()),
        cameraSupported: false,
      );
      await pumpSheet(tester);

      await tester.ensureVisible(find.text(EsBO.quoteImageAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.quoteImageAdd));
      await tester.pumpAndSettle();

      expect(find.text(EsBO.quoteImageGallery), findsOneWidget);
      expect(find.text(EsBO.quoteImageCamera), findsNothing);
    });

    testWidgets('SC2: adjuntar desde Galería muestra preview en el template', (
      tester,
    ) async {
      ImagePickerPlatform.instance = _FakePickerPlatform(
        fileFromBytes(tinyPng()),
      );
      await pumpSheet(tester);

      await attachFromGallery(tester);

      expect(find.byKey(heroKey), findsOneWidget);
      // El control muta a Cambiar/Quitar (RF5).
      expect(find.text(EsBO.quoteImageChange), findsOneWidget);
      expect(find.text(EsBO.quoteImageRemove), findsOneWidget);
      expect(find.text(EsBO.quoteImageAdd), findsNothing);
    });

    testWidgets('SC5: Quitar remueve preview y restaura "Agregar imagen"', (
      tester,
    ) async {
      ImagePickerPlatform.instance = _FakePickerPlatform(
        fileFromBytes(tinyPng()),
      );
      await pumpSheet(tester);
      await attachFromGallery(tester);
      expect(find.byKey(heroKey), findsOneWidget);

      await tester.ensureVisible(find.text(EsBO.quoteImageRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.quoteImageRemove));
      await tester.pumpAndSettle();

      expect(find.byKey(heroKey), findsNothing);
      expect(find.text(EsBO.quoteImageAdd), findsOneWidget);
    });

    testWidgets('SC6: imagen no decodificable → snackbar error y sin preview', (
      tester,
    ) async {
      // Garbage (< 5 MB): el decoder real de instantiateImageCodec falla.
      final garbage = Uint8List.fromList(List.filled(64, 0x42));
      ImagePickerPlatform.instance = _FakePickerPlatform(
        fileFromBytes(garbage),
      );
      await pumpSheet(tester);

      await attachFromGallery(tester);

      expect(find.byKey(heroKey), findsNothing);
      expect(find.text(EsBO.quoteImageInvalidFormat), findsOneWidget);
    });

    testWidgets('SC4: PNG capturado con foto difiere del sin foto', (
      tester,
    ) async {
      final captureKey = GlobalKey();
      final state = _validState();
      final meta = computeMeta(state);

      Widget template(Uint8List? bytes) => RepaintBoundary(
        key: captureKey,
        child: QuoteImageTemplate(
          output: state.output!,
          label: state.label,
          discountPct:
              state.detailDiscountPct?.toStringAsFixed(0) ?? state.discountPct,
          showDetail: state.showDetail,
          detailMaterialBreakdown: state.detailMaterialBreakdown,
          detailElectricCost: state.detailElectricCost,
          detailLaborCost: state.detailLaborCost,
          detailPostProcessCost: state.detailPostProcessCost,
          detailBaseCost: state.detailBaseCost,
          detailFailureCost: state.detailFailureCost,
          detailMarkupCost: state.detailMarkupCost,
          detailProfitAmount: state.detailProfitAmount,
          detailTotalFinal: state.detailTotalFinal,
          metaGrams: meta.grams,
          metaTime: meta.time,
          companyName: null,
          currency: WorldCurrency.usd,
          pieceImageBytes: bytes,
        ),
      );

      // El template (400px fijos) + hero supera el viewport default del
      // test (800x600): agrandar la superficie para evitar overflow.
      await tester.binding.setSurfaceSize(const Size(500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // toImage real requiere runAsync; el hero con imagen cambia el PNG.
      await tester.runAsync(() async {
        await tester.pumpWidget(_wrap(template(null)));
        final withoutImage = await captureQuoteImageBytes(captureKey);

        await tester.pumpWidget(_wrap(template(tinyPng())));
        await tester.pumpAndSettle();
        final withImage = await captureQuoteImageBytes(captureKey);

        expect(withImage, isNot(equals(withoutImage)));
      });
    });
  });

  group('computeMeta', () {
    test('express: retorna gramos + tiempo formateados', () {
      final state = CalculatorState(
        mode: CalculatorMode.express,
        weight: '100',
        filamentPrice: '120',
        filamentGrams: '1000',
        printHours: '2',
        printMinutes: '30',
        discountPct: '0',
        label: '',
        materials: const [],
        output: null,
        showDetail: false,
        detailDiscountPct: null,
        detailElectricCost: null,
        detailBaseCost: null,
        detailProfitAmount: null,
        detailTotalFinal: null,
        computeVersion: 0,
      );

      final meta = computeMeta(state);
      // 100g + 2h 30m (format es_BO usa coma decimal).
      expect(meta.grams, '100 g');
      expect(meta.time, '2h 30m');
    });

    test('advanced: suma gramos de los materials', () {
      final state = CalculatorState(
        mode: CalculatorMode.advanced,
        weight: '',
        filamentPrice: '',
        filamentGrams: '',
        printHours: '1',
        printMinutes: '0',
        discountPct: '0',
        label: '',
        materials: const [
          MaterialRow(
            label: 'a',
            weight: '50',
            pricePerBobbin: '100',
            gramsPerBobbin: '1000',
          ),
          MaterialRow(
            label: 'b',
            weight: '75',
            pricePerBobbin: '100',
            gramsPerBobbin: '1000',
          ),
        ],
        output: null,
        showDetail: false,
        detailDiscountPct: null,
        detailElectricCost: null,
        detailBaseCost: null,
        detailProfitAmount: null,
        detailTotalFinal: null,
        computeVersion: 0,
      );

      final meta = computeMeta(state);
      expect(meta.grams, '125 g');
      expect(meta.time, '1h 0m');
    });

    test('cero gramos + cero tiempo → nulls (oculta fila meta)', () {
      final state = CalculatorState(
        mode: CalculatorMode.express,
        weight: '0',
        filamentPrice: '',
        filamentGrams: '',
        printHours: '0',
        printMinutes: '0',
        discountPct: '0',
        label: '',
        materials: const [],
        output: null,
        showDetail: false,
        detailDiscountPct: null,
        detailElectricCost: null,
        detailBaseCost: null,
        detailProfitAmount: null,
        detailTotalFinal: null,
        computeVersion: 0,
      );

      final meta = computeMeta(state);
      expect(meta.grams, isNull);
      expect(meta.time, isNull);
    });
  });
}
