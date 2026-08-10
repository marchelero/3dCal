// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/money/currency.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/quote_image_template.dart';

/// Template mínimo con descuento aplicado (caso real del usuario):
/// unitario con descuento 16.43, descuento 2.90 (15% de 19.33).
Widget _template({int quantity = 1}) {
  final output = CalculationOutput.simple(
    materialCost: Decimal.fromInt(12),
    discountAmount: Decimal.parse('2.90'),
    totalPrice: Decimal.parse('16.43'),
  );
  return MaterialApp(
    home: Scaffold(
      body: RepaintBoundary(
        child: QuoteImageTemplate(
          output: output,
          label: 'Pieza de prueba',
          discountPct: '15',
          showDetail: false,
          detailMaterialBreakdown: const [],
          detailElectricCost: Decimal.zero,
          detailLaborCost: Decimal.zero,
          detailPostProcessCost: Decimal.zero,
          detailBaseCost: Decimal.zero,
          detailFailureCost: Decimal.zero,
          detailMarkupCost: Decimal.zero,
          detailProfitAmount: Decimal.zero,
          detailTotalFinal: Decimal.zero,
          metaGrams: '100 g',
          metaTime: '2 h',
          companyName: null,
          currency: WorldCurrency.usd,
          quantity: quantity,
        ),
      ),
    ),
  );
}

void main() {
  group('QuoteImageTemplate — cuadro de descuento × cantidad', () {
    /// En tests el font de prueba es mas ancho que Roboto real: bajar el
    /// textScale para que las filas del cuadro quepan en los 309px internos.
    Future<void> pumpWith(WidgetTester tester, {required int quantity}) async {
      tester.platformDispatcher.textScaleFactorTestValue = 0.75;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_template(quantity: quantity));
    }

    testWidgets('quantity 1: muestra valores unitarios', (tester) async {
      await pumpWith(tester, quantity: 1);

      expect(find.text(r'$ 19,33'), findsOneWidget); // sin descuento (unit)
      expect(find.text(r'-$ 2,90'), findsOneWidget); // descuento 15% (unit)
      // Total con descuento: aparece en el total grande + en la fila del cuadro.
      expect(find.text(r'$ 16,43'), findsNWidgets(2));
    });

    testWidgets(
      'quantity 7: el cuadro recalcula multiplicando por la cantidad',
      (tester) async {
        await pumpWith(tester, quantity: 7);

        // 19.33 × 7 = 135.31 | −2.90 × 7 = −20.30 | 16.43 × 7 = 115.01
        expect(find.text(r'$ 135,31'), findsOneWidget);
        expect(find.text(r'-$ 20,30'), findsOneWidget);
        // Total con descuento: total grande + fila del cuadro.
        expect(find.text(r'$ 115,01'), findsNWidgets(2));

        // Desglose "7 u. × $ 16,43" en el subtitulo.
        expect(find.text('7 u. × \$ 16,43'), findsOneWidget);
      },
    );
  });
}
