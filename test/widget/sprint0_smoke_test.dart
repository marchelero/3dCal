// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/app.dart';

import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/decimal_input_field.dart';

void main() {
  Future<void> navigateToCalculator(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TresdcalApp()));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Nueva cotizacion'),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Smoke: home muestra launcher con boton', (
    WidgetTester tester,
  ) async {
    await navigateToCalculator(tester);

    // Re-pump el home para chequear (navigateToCalculator ya dejo calculator)
    // Volvemos atras para inspeccionar el launcher.
    final backBtn = find.byType(BackButton);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn);
      await tester.pumpAndSettle();
    }

    expect(find.text('3dcal'), findsOneWidget);
    expect(find.text('Cotizador 3D'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Nueva cotizacion'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Smoke: tap launcher navega a CalculatorPage con form completo',
    (WidgetTester tester,
    ) async {
      await navigateToCalculator(tester);

      expect(find.byType(CalculatorPage), findsOneWidget);
      expect(find.text('Cotizacion express'), findsOneWidget);
      expect(find.text('Parametros de la pieza'), findsOneWidget);
      expect(find.text('Filamento'), findsOneWidget);
      expect(find.text('Tiempo y equipo'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Tiempo'), findsOneWidget);
      expect(find.text('Precio bobina'), findsOneWidget);
      expect(find.text('Gramos / bobina'), findsOneWidget);
      expect(find.text('Watts'), findsOneWidget);
      expect(find.text('Tarifa kWh'), findsOneWidget);
      expect(find.text('Profit'), findsOneWidget);
      expect(find.text('Descuento'), findsOneWidget);
    },
  );

  testWidgets(
    'Smoke: form vacio muestra hint, form completo muestra output BOB',
    (WidgetTester tester,
    ) async {
      await navigateToCalculator(tester);

      // Default: form vacio (peso/tiempo/precio vacios) → hint visible
      expect(
        find.textContaining('Completa peso, tiempo, precio y gramos'),
        findsOneWidget,
        reason: 'Sin inputs validos debe aparecer el hint',
      );
      expect(find.text('Precio final'), findsNothing);

      // Llenar los inputs requeridos por label (Sprint 4 cambio el orden
      // del form a: peso, precio, gramos, tiempo, watts, kWh, profit, descuento).
      await tester.enterText(
          find.widgetWithText(DecimalInputField, 'Peso'), '100');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(DecimalInputField, 'Tiempo'), '5');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(DecimalInputField, 'Precio bobina'), '120');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(DecimalInputField, 'Gramos / bobina'), '1000');
      await tester.pumpAndSettle();

      // Output card visible con formato BOB
      expect(find.text('Precio final'), findsOneWidget);
      expect(find.text('Costo material'), findsOneWidget);
      expect(find.text('Costo electrico'), findsOneWidget);
      expect(find.text('Costo base'), findsOneWidget);
      expect(find.text('Profit efectivo'), findsOneWidget);
      expect(
        find.textContaining('Bs.'),
        findsWidgets,
        reason: 'Output live debe usar CurrencyFormatter BOB',
      );
    },
  );
}
