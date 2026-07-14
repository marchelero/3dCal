import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';

/// Helper: monta [CalculatorPage] dentro de un [ProviderScope] y retorna
/// el [WidgetTester] para que el caller interactue.
Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: CalculatorPage()),
    ),
  );
  await tester.pump();
}

Future<void> _fillValid(WidgetTester tester) async {
  // Localizar los 8 TextField por label. Como los labels son el primer
  // argumento del `TextField`, aparecen en el `labelText` del decoration.
  // Para evitar ambiguedad con `find.byType(TextField)`, usamos
  // `find.widgetWithText` con el texto del label.
  await tester.enterText(find.widgetWithText(TextField, 'Peso'), '100');
  await tester.enterText(find.widgetWithText(TextField, 'Tiempo'), '5');
  await tester.enterText(
      find.widgetWithText(TextField, 'Precio bobina'), '120');
  await tester.enterText(
      find.widgetWithText(TextField, 'Gramos / bobina'), '1000');
  // Watts, Tarifa kWh, Profit, Descuento ya tienen defaults validos.
  await tester.pump();
}

void main() {
  group('CalculatorPage', () {
    testWidgets('renderiza form con todos los labels', (tester) async {
      await _pumpPage(tester);

      expect(find.text('Cotizacion express'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Tiempo'), findsOneWidget);
      expect(find.text('Watts'), findsOneWidget);
      expect(find.text('Tarifa kWh'), findsOneWidget);
      expect(find.text('Profit'), findsOneWidget);
      expect(find.text('Descuento'), findsOneWidget);
      expect(find.text('Precio bobina'), findsOneWidget);
      expect(find.text('Gramos / bobina'), findsOneWidget);
    });

    testWidgets('muestra mensaje inicial cuando form no valido',
        (tester) async {
      await _pumpPage(tester);
      expect(
        find.textContaining('Completa peso, tiempo'),
        findsOneWidget,
      );
      // Output card con "Precio final" NO debe estar visible.
      expect(find.text('Precio final'), findsNothing);
    });

    testWidgets('live output aparece al completar todos los inputs validos',
        (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Output card visible
      expect(find.text('Precio final'), findsOneWidget);
      // Calculo esperado:
      //   materialCost = 100 * (120/1000) = 12
      //   electricCost = 5 * (200/1000) * 0.70 = 0.7
      //   baseCost = 12.7
      //   effProfit = 200 - 0*2 = 200
      //   profitAmount = 12.7 * 2 = 25.4
      //   totalPrice = 38.1
      expect(find.text('Bs. 38,10'), findsOneWidget);
      expect(find.text('Costo material'), findsOneWidget);
      expect(find.text('Costo electrico'), findsOneWidget);
      expect(find.text('Costo base'), findsOneWidget);
      expect(find.text('Profit efectivo'), findsOneWidget);
    });

    testWidgets('output se actualiza al cambiar profit', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Profit inicial = 200% => totalPrice = 38.10
      expect(find.text('Bs. 38,10'), findsOneWidget);

      // Cambiar profit a 100%
      await tester.enterText(find.widgetWithText(TextField, 'Profit'), '100');
      await tester.pump();

      // baseCost = 12.7, effProfit = 100, profitAmount = 12.7
      // totalPrice = 25.4
      expect(find.text('Bs. 25,40'), findsOneWidget);
    });

    testWidgets('output se actualiza al cambiar kwh', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // kwh=0.70 => electricCost=0.7, totalPrice=38.1
      expect(find.text('Bs. 38,10'), findsOneWidget);

      // Cambiar kwh a 0.80
      await tester.enterText(
          find.widgetWithText(TextField, 'Tarifa kWh'), '0.80');
      await tester.pump();

      // electricCost = 5 * 0.2 * 0.80 = 0.8
      // totalPrice = 12 + 0.8 + 12.8*2 = 12.8 + 25.6 = 38.4
      expect(find.text('Bs. 38,40'), findsOneWidget);
    });

    testWidgets('output desaparece al borrar weight', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.text('Precio final'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Peso'), '');
      await tester.pump();

      expect(find.text('Precio final'), findsNothing);
      expect(find.textContaining('Completa peso'), findsOneWidget);
    });

    testWidgets('boton reset restaura defaults', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.text('Precio final'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Output card se fue, vuelve el mensaje inicial
      expect(find.text('Precio final'), findsNothing);
      expect(find.textContaining('Completa peso'), findsOneWidget);

      // Defaults siguen en los controllers:
      expect(find.widgetWithText(TextField, 'Watts'), findsOneWidget);
      final wattsField =
          tester.widget<TextField>(find.widgetWithText(TextField, 'Watts'));
      expect(wattsField.controller!.text, '200');
    });

    testWidgets('descuento agresivo muestra warning', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Profit=200, discount=60 => effProfit = 200 - 120 = 80 (>0, no warning)
      await tester.enterText(
          find.widgetWithText(TextField, 'Descuento'), '60');
      await tester.pump();
      expect(find.textContaining('agresivo'), findsNothing);

      // Profit=200, discount=120 => effProfit = 200 - 240 = -40 (warning)
      await tester.enterText(
          find.widgetWithText(TextField, 'Descuento'), '120');
      await tester.pump();
      expect(find.textContaining('agresivo'), findsOneWidget);
      expect(find.textContaining('no se vende a perdida'), findsOneWidget);
    });
  });
}
