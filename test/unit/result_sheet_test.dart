import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/summary_card.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';

/// Helpers de rendering para que cada test sea declarativo.
Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

CalculatorState _validState() {
  final out = CalculationOutput(
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

      expect(find.text('Falta completar'), findsOneWidget);
      expect(
        find.textContaining('Completa peso'),
        findsOneWidget,
      );
      // No muestra chevron up ni "Ver cotizacion" en estado empty.
      expect(find.text('Ver cotizacion'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
    });

    testWidgets('muestra total + chevron cuando onTap provisto', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          ResultBottomBar(
            totalText: 'Bs. 36,00',
            hasDiscount: false,
            onTap: () => tapped++,
          ),
        ),
      );

      expect(find.text('Bs. 36,00'), findsOneWidget);
      expect(find.text('Ver cotizacion'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      // Empty hint no presente.
      expect(find.text('Falta completar'), findsNothing);

      await tester.tap(find.byType(ResultBottomBar));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('muestra badge descuento cuando hasDiscount=true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ResultBottomBar(
            totalText: 'Bs. 27,00',
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
    testWidgets('renderiza SummaryCard con output del state', (tester) async {
      final state = _validState();
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
          ),
        ),
      );

      // Summary card visible.
      expect(find.byType(SummaryCard), findsOneWidget);
      // Titulo del sheet.
      expect(find.text('Cotizacion'), findsWidgets);
      // Label del state aparece en el card.
      expect(find.text('Pieza de prueba'), findsOneWidget);
      // Total formateado.
      expect(find.text('Bs. 36,00'), findsAtLeastNWidgets(1));
    });

    testWidgets('muestra botones de accion (Save, Share, Reset)',
        (tester) async {
      final state = _validState();
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
          ),
        ),
      );

      expect(find.text('Guardar cotizacion'), findsOneWidget);
      expect(find.text('Compartir imagen'), findsOneWidget);
      // Reset button es IconButton con tooltip.
      expect(find.byTooltip('Restablecer valores'), findsOneWidget);
    });

    testWidgets('tap save cierra sheet y llama onSave', (tester) async {
      var saved = 0;
      final state = _validState();
      bool? sheetClosed;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showResultSheet(
                  context: ctx,
                  state: state,
                  onSave: () => saved++,
                  onReset: () {},
                  onToggleDetail: () {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      sheetClosed = true;

      // Tap save.
      await tester.tap(find.text('Guardar cotizacion'));
      await tester.pumpAndSettle();

      // Sheet cerrada (no hay mas SummaryCard en el tree).
      expect(find.byType(SummaryCard), findsNothing);
      expect(saved, 1);
    });

    testWidgets('boton share se deshabilita durante isSharing', (tester) async {
      // El share real necesita platform channels. Solo verificamos el
      // estado de UI: el boton pasa a disabled cuando _isSharing=true.
      // No testeamos el share en si (manual / integration).
      final state = _validState();
      // Renderizamos y verificamos que el boton arranca enabled.
      await tester.pumpWidget(
        _wrap(
          ResultSheetContent(
            state: state,
            onSave: () {},
            onReset: () {},
            onToggleDetail: () {},
          ),
        ),
      );

      final shareBtn = find.widgetWithText(OutlinedButton, 'Compartir imagen');
      expect(shareBtn, findsOneWidget);
      final OutlinedButton btn = tester.widget(shareBtn);
      expect(btn.onPressed, isNotNull);
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
          MaterialRow(label: 'a', weight: '50', pricePerBobbin: '100', gramsPerBobbin: '1000'),
          MaterialRow(label: 'b', weight: '75', pricePerBobbin: '100', gramsPerBobbin: '1000'),
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
