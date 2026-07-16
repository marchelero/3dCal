// ignore_for_file: public_member_api_docs

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/app.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/shared/widgets/numeric_input_field.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Smoke: tap launcher navega a CalculatorPage con form completo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TresdcalApp(),
      ),
    );
    await tester.pumpAndSettle();

    // tap el boton por texto. FilledButton.icon retorna _FilledButtonWithIcon
    // (no subtipo de FilledButton para find.byType), asi que widgetWithText
    // falla. El tap sobre el Text bubblea al FilledButton.
    await tester.tap(find.text('Nueva cotizacion'));
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(find.text('Cotizacion'), findsOneWidget);
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('Horas'), findsOneWidget);
    expect(find.text('Precio bobina'), findsOneWidget);
    expect(find.text('Gramos / bobina'), findsNothing);
    expect(find.text('Impresora'), findsOneWidget);
    expect(find.text('Sin impresora registrada'), findsOneWidget);
    expect(find.text('Tarifa kWh'), findsNothing);

    // Cleanup: volver a home para no contaminar el siguiente test.
    // Con go_router StatefulShellRoute, dejar el calculator en la
    // pila hace que el siguiente pumpWidget no termine de montar
    // el home a tiempo.
    final back = find.byType(BackButton);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'Smoke: form vacio muestra hint, form completo muestra output BOB',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const TresdcalApp(),
        ),
      );
      await tester.pumpAndSettle();

      // tap launcher → calculator
      await tester.tap(find.text('Nueva cotizacion'));
      await tester.pumpAndSettle();

      // Default: form vacio (peso/precio vacios) → hint visible
      expect(
        find.textContaining('Completa peso'),
        findsOneWidget,
        reason: 'Sin inputs validos debe aparecer el hint',
      );
      expect(find.text('Precio final'), findsNothing);

      // Llenar los inputs requeridos por label.
      await tester.enterText(
        find.widgetWithText(NumericInputField, 'Peso'),
        '100',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(NumericInputField, 'Horas'),
        '5',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(NumericInputField, 'Precio bobina'),
        '120',
      );
      await tester.pumpAndSettle();
      // Gramos / bobina ya no se muestra — default 1000 internamente.

      // Output card visible con formato BOB
      expect(find.textContaining('Bs.'), findsWidgets);
      // Costo material solo en ojito detail (oculto por default)
      expect(find.text('Costo material'), findsNothing);
      expect(
        find.textContaining('Bs.'),
        findsWidgets,
        reason: 'Output live debe usar CurrencyFormatter BOB',
      );
    },
  );
}
