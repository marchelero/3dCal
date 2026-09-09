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
import 'package:tresdcal/features/catalog/printers/presentation/widgets/printer_catalog_selector.dart';

Future<ProviderContainer> _pumpForm(
  WidgetTester tester, {
  PrinterProfile? existing,
}) async {
  // Viewport alto: el form (selector + watts + costo + vida + switch)
  // excede 600px y el boton Guardar queda fuera sin scroll.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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

/// Selecciona marca + modelo del catalogo via los dropdowns.
Future<void> _selectCatalogModel(
  WidgetTester tester,
  String brand,
  String model,
) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(brand).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(model).last);
  await tester.pumpAndSettle();
}

void main() {
  group('PrinterFormPage (create)', () {
    testWidgets('titulo "Nueva impresora"', (tester) async {
      await _pumpForm(tester);
      expect(find.text('Nueva impresora'), findsOneWidget);
    });

    testWidgets('muestra selector de catalogo + watts + switch default', (
      tester,
    ) async {
      await _pumpForm(tester);
      expect(find.byType(PrinterCatalogSelector), findsOneWidget);
      // Brand dropdown + modelo dropdown (deshabilitado sin marca).
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
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

    testWidgets('selector de catalogo aparece ANTES que el campo watts', (
      tester,
    ) async {
      await _pumpForm(tester);

      final selector = tester.getTopLeft(find.byType(PrinterCatalogSelector));
      final wattsField = tester.getTopLeft(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
      );
      expect(
        selector.dy <= wattsField.dy,
        isTrue,
        reason: 'PrinterCatalogSelector debe estar ARRIBA del campo watts',
      );
    });

    testWidgets('guardar valido (cascada) crea y persiste', (tester) async {
      final container = await _pumpForm(tester);
      await _selectCatalogModel(tester, 'Creality', 'Ender-3 V2');
      // Watts auto-completado desde el catalogo (Ender-3 V2 = 125 W).
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final list = await container.read(printersNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.name, 'Ender-3 V2');
      expect(list.first.brand, 'Creality');
      expect(list.first.averageWatts, 125);
    });

    testWidgets('F5: muestra campos de costo y vida util', (tester) async {
      await _pumpForm(tester);
      expect(find.widgetWithText(TextField, 'Costo (Bs)'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Vida útil (horas)'),
        findsOneWidget,
      );
    });

    testWidgets('F5: guardar con costo + vida persiste amortizacion', (
      tester,
    ) async {
      final container = await _pumpForm(tester);
      await _selectCatalogModel(tester, 'Creality', 'Ender-3 V2');
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '120',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Costo (Bs)'),
        '3500',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Vida útil (horas)'),
        '4000',
      );
      await tester.pump();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final list = await container.read(printersNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.purchaseCost, closeTo(3500.0, 0.0001));
      expect(list.first.usefulLifeHours, 4000);
    });

    testWidgets('F5: costo sin vida util muestra error de validacion', (
      tester,
    ) async {
      await _pumpForm(tester);
      await _selectCatalogModel(tester, 'Creality', 'Ender-3 V2');
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '120',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Costo (Bs)'),
        '3500',
      );
      await tester.pump();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('La vida útil debe ser ≥ 1 si hay costo'),
        findsOneWidget,
      );
    });

    testWidgets('F5: vida util 0 con costo → error (sin division por cero)', (
      tester,
    ) async {
      await _pumpForm(tester);
      await _selectCatalogModel(tester, 'Creality', 'Ender-3 V2');
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '120',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Costo (Bs)'),
        '3500',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Vida útil (horas)'),
        '0',
      );
      await tester.pump();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('La vida útil debe ser ≥ 1 si hay costo'),
        findsOneWidget,
      );
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
      // Marca "Creality" esta en el catalogo -> dropdown; modelo "Ender Pre"
      // no coincide con un modelo de catalogo -> campo manual con el valor.
      expect(find.byType(PrinterCatalogSelector), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Modelo'),
      );
      expect(nameField.controller!.text, 'Ender Pre');
    });
  });
}
