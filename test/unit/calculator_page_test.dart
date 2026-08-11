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
  await tester.enterText(find.widgetWithText(TextField, 'Peso'), '100');
  await tester.enterText(
    find.widgetWithText(TextField, 'Precio bobina'),
    '120',
  );
  await tester.enterText(find.widgetWithText(TextField, 'Horas'), '2');
  // Gramos / bobina ya no se muestra — default 1000 internamente.
  // Descuento default 0 es valido.
  await tester.pumpAndSettle();
}

void main() {
  group('CalculatorPage', () {
    testWidgets('renderiza form con todos los labels', (tester) async {
      await _pumpPage(tester);

      expect(find.text('Cotización'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Horas'), findsOneWidget);
      expect(find.text('Minutos'), findsOneWidget);
      // 'Descuento' ya NO vive en el form: el campo se movio al result
      // sheet (Bug #1, commit que agrego imagen/PDF).
      expect(find.text('Descuento'), findsNothing);
      expect(find.text('Precio bobina'), findsOneWidget);
      expect(find.text('Gramos / bobina'), findsOneWidget);
      // Printer indicator (SectionHeader renderiza el titulo en mayusculas)
      expect(find.text('IMPRESORA'), findsOneWidget);
      expect(find.text('Sin impresora registrada'), findsOneWidget);
      // Ya no existen Watts, Tarifa kWh, Profit
      expect(find.text('Watts'), findsNothing);
      expect(find.text('Tarifa kWh'), findsNothing);
      expect(find.text('Profit'), findsNothing);
    });

    testWidgets('muestra mensaje inicial cuando form no valido', (
      tester,
    ) async {
      await _pumpPage(tester);
      expect(find.textContaining('Completa peso'), findsOneWidget);
      // Output card NO debe estar visible (form vacio).
      expect(find.textContaining('Completa peso'), findsOneWidget);
    });

    testWidgets('live output aparece al completar todos los inputs validos', (
      tester,
    ) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Output card visible con precio grande en Bs
      expect(find.textContaining(r'$ '), findsWidgets);
      // Calculo esperado:
      //   materialCost = 100 * (120/1000) = 12
      //   discountAmount = 0 (sin descuento)
      //   totalPrice = 12
      //   profitBase default 200% → profitAmount = 12 * 200% = 24
      //   totalFinal = materialCost + profit = 36
      // Bs. 36,00 aparece como precio grande (costo total final)
      expect(find.text(r'$ 36,00'), findsAtLeastNWidgets(1));
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
      expect(find.textContaining(r'$ '), findsWidgets);

      await tester.enterText(find.widgetWithText(TextField, 'Peso'), '');
      await tester.pumpAndSettle();

      expect(find.textContaining(r'$ 12,00'), findsNothing);
      expect(find.textContaining('Completa peso'), findsOneWidget);
    });

    testWidgets('boton reset restaura defaults', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.textContaining(r'$ '), findsWidgets);

      // Reset ahora vive en el AppBar (siempre accesible) Y en el modal
      // sheet. Usamos el AppBar para este test (mas simple, no requiere
      // abrir el sheet). Tooltip del IconButton: 'Restablecer'.
      await tester.tap(find.byTooltip('Restablecer'));
      await tester.pumpAndSettle();

      // Output card se fue, vuelve el empty hint del bar
      expect(find.textContaining('Completa peso'), findsOneWidget);
      expect(find.textContaining(r'$ 36,00'), findsNothing);
    });

    testWidgets('descuento reduce precio final', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // Sin descuento: totalFinal = 36 (materialCost 12 + profit 200%).
      // El total vive en el ResultBottomBar.
      expect(find.text(r'$ 36,00'), findsAtLeastNWidgets(1));

      // El campo Descuento vive en el result sheet (ya no en el form).
      await tester.tap(find.text(r'$ 36,00'));
      await tester.pumpAndSettle();

      // Aplicar descuento 25% en el field del sheet. Escribe en el notifier
      // (engine) — unica fuente de verdad. Bug #1: antes habia una caja
      // local del sheet (15%) + otra stale del engine (25%).
      final discountField = find.byWidgetPredicate(
        (w) => w is InputDecorator && (w.decoration.suffixText ?? '') == '%',
      );
      await tester.enterText(discountField, '25');
      await tester.pumpAndSettle();

      // Engine: totalFinal 36 - 25% = 27. Total del template + bar.
      expect(find.text(r'$ 27,00'), findsAtLeastNWidgets(1));
      // UNA sola caja de descuento con el monto correcto.
      expect(find.textContaining('Descuento 25%'), findsOneWidget);
      expect(find.textContaining(r'$ 9,00'), findsOneWidget);
    });
  });
}
