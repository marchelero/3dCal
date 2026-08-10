// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import 'package:tresdcal/features/catalog/printers/presentation/pages/printer_form_page.dart';
import 'package:tresdcal/shared/widgets/brand_selector_field.dart';

Future<ProviderContainer> _pumpForm(
  WidgetTester tester, {
  PrinterProfile? existing,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: PrinterFormPage(existing: existing)),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('PrinterFormPage (create)', () {
    testWidgets('titulo "Nueva impresora"', (tester) async {
      await _pumpForm(tester);
      expect(find.text('Nueva impresora'), findsOneWidget);
    });

    testWidgets('muestra marca + modelo + watts + switch default', (
      tester,
    ) async {
      await _pumpForm(tester);
      // Marca es un BrandSelectorField (dropdown + Otro...) desde la feature
      // de selector de marcas — no un TextField plano.
      expect(find.byType(BrandSelectorField), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Modelo'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('guardar invalido muestra errores', (tester) async {
      await _pumpForm(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.text('Requerido'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'marca (BrandSelectorField) aparece ANTES que el campo modelo',
      (tester) async {
        await _pumpForm(tester);

        // Orden: Marca primero, luego Modelo (decision del usuario:
        // "primero la marca y luego recien ingresar el modelo").
        final brandField = tester.getTopLeft(find.byType(BrandSelectorField));
        final modelField = tester.getTopLeft(
          find.widgetWithText(TextField, 'Modelo'),
        );
        expect(
          brandField.dy <= modelField.dy,
          isTrue,
          reason: 'BrandSelectorField debe estar ARRIBA del campo Modelo',
        );
      },
    );

    testWidgets('guardar valido crea y persiste', (tester) async {
      final container = await _pumpForm(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Modelo'),
        'Ender 3 V2',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '120',
      );
      await tester.pump();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final list = await container.read(printersNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.name, 'Ender 3 V2');
    });
  });

  group('PrinterFormPage (edit)', () {
    testWidgets('titulo "Editar impresora" y prefill', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final id = await db
          .into(db.printers)
          .insert(
            PrintersCompanion.insert(
              name: 'Ender Pre',
              brand: const Value('Creality'),
              averageWatts: 165,
              isDefault: const Value(true),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      final existing = (await db.select(db.printers).get()).first;
      expect(id, isPositive);
      expect(existing.name, 'Ender Pre');

      await _pumpForm(tester, existing: existing);
      expect(find.text('Editar impresora'), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Modelo'),
      );
      expect(nameField.controller!.text, 'Ender Pre');
    });
  });
}
