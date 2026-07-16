import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';

/// Helper: monta [CalculatorPage] dentro de un [ProviderScope] y retorna
/// el [WidgetTester] para que el caller interactue.
Future<void> _pumpPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: CalculatorPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(
      find.widgetWithText(TextField, 'Peso de la pieza'), '100');
  await tester.enterText(
      find.widgetWithText(TextField, 'Precio bobina'), '120');
  await tester.enterText(find.widgetWithText(TextField, 'Horas'), '2');
  // Gramos / bobina ya no se muestra — default 1000 internamente.
  // Descuento default 0 es valido.
  await tester.pumpAndSettle();
}

void main() {
  group('CalculatorPage', () {
    testWidgets('renderiza form con todos los labels', (tester) async {
      await _pumpPage(tester);

      expect(find.text('Cotizacion'), findsOneWidget);
      expect(find.text('Peso de la pieza'), findsOneWidget);
      expect(find.text('Horas'), findsOneWidget);
      expect(find.text('Minutos'), findsOneWidget);
      // 'Descuento' aparece 2 veces legitimas: titulo de seccion + label del field.
      expect(find.text('Descuento'), findsAtLeastNWidgets(1));
      expect(find.text('Precio bobina'), findsOneWidget);
      expect(find.text('Gramos / bobina'), findsNothing);
      // Printer indicator
      expect(find.text('Impresora'), findsOneWidget);
      expect(find.text('Sin impresora registrada'), findsOneWidget);
      // Ya no existen Watts, Tarifa kWh, Profit
      expect(find.text('Watts'), findsNothing);
      expect(find.text('Tarifa kWh'), findsNothing);
      expect(find.text('Profit'), findsNothing);
    });

    testWidgets('muestra mensaje inicial cuando form no valido',
        (tester) async {
      await _pumpPage(tester);
      expect(
        find.textContaining('Completa peso'),
        findsOneWidget,
      );
      // Output card NO debe estar visible (form vacio).
      expect(find.textContaining('Completa peso'), findsOneWidget);
    });

    testWidgets('live output aparece al completar todos los inputs validos',
        (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Output card visible con precio grande en Bs
      expect(find.textContaining('Bs.'), findsWidgets);
      // Calculo esperado:
      //   materialCost = 100 * (120/1000) = 12
      //   discountAmount = 0 (sin descuento)
      //   totalPrice = 12
      //   profitBase default 200% → profitAmount = 12 * 200% = 24
      //   totalFinal = materialCost + profit = 36
      // Bs. 36,00 aparece como precio grande (costo total final)
      expect(find.text('Bs. 36,00'), findsAtLeastNWidgets(1));
      // Costo material solo en ojito detail (oculto por default)
      expect(find.text('Costo material'), findsNothing);
      // Detalle electrico/base/profit solo aparece al tocar ojito
      expect(find.text('Costo energia'), findsNothing);
      expect(find.text('Costo base'), findsNothing);
      expect(find.text('Ganancia'), findsNothing);
    });

    testWidgets('output desaparece al borrar weight', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.textContaining('Bs.'), findsWidgets);

      await tester.enterText(
          find.widgetWithText(TextField, 'Peso de la pieza'), '');
      await tester.pumpAndSettle();

      expect(find.textContaining('Bs. 12,00'), findsNothing);
      expect(find.textContaining('Completa peso'), findsOneWidget);
    });

    testWidgets('boton reset restaura defaults', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.textContaining('Bs.'), findsWidgets);

      // El label del boton es 'Restablecer valores' (EsBO.calcBtnReset).
      await tester.ensureVisible(find.text('Restablecer valores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restablecer valores'));
      await tester.pumpAndSettle();

      // Output card se fue, vuelve el mensaje inicial
      expect(find.textContaining('Completa peso'), findsOneWidget);
      expect(find.textContaining('Bs.'), findsNothing);
    });

    testWidgets('descuento reduce precio final', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Sin descuento: totalFinal = 36 (materialCost 12 + profit 200%)
      expect(find.text('Bs. 36,00'), findsAtLeastNWidgets(1));

      // Aplicar descuento 25%
      await tester.enterText(
          find.widgetWithText(TextField, 'Descuento'), '25');
      await tester.pumpAndSettle();

      // Big number = finalPrice (totalFinal 36 - 25% = 27)
      expect(find.text('Bs. 27,00'), findsAtLeastNWidgets(1));
      // Aparece el contenedor de descuento
      expect(find.textContaining('Descuento 25%'), findsOneWidget);
      expect(find.textContaining('Bs. 9,00'), findsOneWidget);
    });
  });
}
