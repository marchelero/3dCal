// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import 'package:tresdcal/features/catalog/printers/presentation/widgets/printer_catalog_selector.dart';

typedef _PumpResult = ({
  ProviderContainer container,
  TextEditingController brand,
  TextEditingController model,
  TextEditingController watts,
});

/// Monta el selector aislado con un TextFormField de watts (para verificar
/// que el auto-fill es editable) en un container con DB en memoria.
Future<_PumpResult> _pump(
  WidgetTester tester, {
  String brand = '',
  String model = '',
  String watts = '',
}) async {
  // Superficie alta: el dropdown de marca (29 items + "Otro...") necesita
  // altura para listar todos los items onstage.
  tester.view.physicalSize = const Size(800, 2400);
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

  final brandCtrl = TextEditingController(text: brand);
  final modelCtrl = TextEditingController(text: model);
  final wattsCtrl = TextEditingController(text: watts);
  addTearDown(() {
    brandCtrl.dispose();
    modelCtrl.dispose();
    wattsCtrl.dispose();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PrinterCatalogSelector(
                brandController: brandCtrl,
                modelController: modelCtrl,
                wattsController: wattsCtrl,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: wattsCtrl,
                decoration: const InputDecoration(labelText: 'Watts'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    container: container,
    brand: brandCtrl,
    model: modelCtrl,
    watts: wattsCtrl,
  );
}

Finder _inMenu(String text) => find.text(text, skipOffstage: false);

Future<void> _openBrandDropdown(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
}

Future<void> _openModelDropdown(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).last);
  await tester.pumpAndSettle();
}

Future<void> _selectBrand(WidgetTester tester, String brand) async {
  await _openBrandDropdown(tester);
  await tester.tap(find.text(brand).last);
  await tester.pumpAndSettle();
}

Future<void> _selectModel(WidgetTester tester, String model) async {
  await _openModelDropdown(tester);
  await tester.tap(find.text(model).last);
  await tester.pumpAndSettle();
}

void main() {
  group('PrinterCatalogSelector', () {
    testWidgets('(a) brand dropdown lista marcas del catalogo + "Otro..."', (
      tester,
    ) async {
      await _pump(tester);

      // Brand + modelo deshabilitado -> 2 DropdownButtonFormField.
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

      await _openBrandDropdown(tester);

      // Marcas del catalogo (inicio, medio y fin del orden alfabetico).
      for (final b in <String>[
        'Anet',
        'Anycubic',
        'Bambu Lab',
        'Creality',
        'Prusa',
        'Voron',
        'Wanhao',
      ]) {
        expect(
          _inMenu(b),
          findsWidgets,
          reason: '$b debe estar en el dropdown de marca',
        );
      }
      expect(_inMenu('Otro...'), findsWidgets);
      expect(_inMenu('MarcaInexistente'), findsNothing);
    });

    testWidgets(
      '(a2) brand dropdown incluye marcas registradas por el usuario',
      (tester) async {
        final result = await _pump(tester);
        await result.container
            .read(printersNotifierProvider.notifier)
            .create(
              name: 'Custom Printer',
              brand: 'MyCustomBrand',
              averageWatts: 120,
            );
        await tester.pumpAndSettle();

        await _openBrandDropdown(tester);
        expect(_inMenu('MyCustomBrand'), findsWidgets);
      },
    );

    testWidgets('(b) elegir marca filtra el dropdown de modelo a esa marca', (
      tester,
    ) async {
      await _pump(tester);
      await _selectBrand(tester, 'Bambu Lab');

      await _openModelDropdown(tester);

      // Solo modelos de Bambu Lab + "Otro...".
      for (final m in <String>['A1', 'A1 Combo', 'A1 Mini', 'H2D', 'X1E']) {
        expect(_inMenu(m), findsWidgets, reason: '$m debe estar');
      }
      expect(_inMenu('Otro...'), findsWidgets);
      expect(_inMenu('Ender-3'), findsNothing);
      expect(_inMenu('Kobra'), findsNothing);
    });

    testWidgets(
      '(c) elegir modelo del catalogo auto-completa watts (editable)',
      (tester) async {
        final result = await _pump(tester);
        await _selectBrand(tester, 'Bambu Lab');
        await _selectModel(tester, 'A1 Combo');

        // Auto-fill: A1 Combo = 100 W.
        expect(result.watts.text, '100');

        // El campo watts es editable: se puede escribir otro valor.
        await tester.enterText(find.widgetWithText(TextField, 'Watts'), '120');
        await tester.pump();
        expect(result.watts.text, '120');

        // Hint sutil de watts auto-completado (con sufijo "estimado").
        expect(find.textContaining('puedes editarlo'), findsOneWidget);
      },
    );

    testWidgets(
      '(d) marca "Otro..." muestra campos manuales de marca y modelo',
      (tester) async {
        final result = await _pump(tester);
        await _openBrandDropdown(tester);
        await tester.tap(find.text('Otro...').last);
        await tester.pumpAndSettle();

        // Sin dropdowns: campos manuales de marca y modelo (mas el watts del
        // harness).
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(find.widgetWithText(TextFormField, 'Marca'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Modelo'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Marca'),
          'MyCustomBrand',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Modelo'),
          'Proto 9000',
        );
        await tester.pump();
        expect(result.brand.text, 'MyCustomBrand');
        expect(result.model.text, 'Proto 9000');
      },
    );

    testWidgets('(d2) modelo "Otro..." muestra campo manual y watts vacio', (
      tester,
    ) async {
      final result = await _pump(tester);
      await _selectBrand(tester, 'Bambu Lab');
      await _openModelDropdown(tester);
      await tester.tap(find.text('Otro...').last);
      await tester.pumpAndSettle();

      // Dropdown de modelo reemplazado por TextFormField manual.
      expect(find.widgetWithText(TextFormField, 'Modelo'), findsOneWidget);
      expect(result.watts.text, isEmpty);
    });

    testWidgets('(e) edicion con valores pre-cargados no pisa el watts', (
      tester,
    ) async {
      final result = await _pump(
        tester,
        brand: 'Creality',
        model: 'Ender-3 V2',
        watts: '200',
      );

      // Marca y modelo en el catalogo -> dropdowns seleccionados.
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
      expect(find.text('Creality'), findsWidgets);
      expect(find.text('Ender-3 V2'), findsWidgets);
      // Watts pre-cargado NO se sobreescribe (catalogo diria 125).
      expect(result.watts.text, '200');
    });

    testWidgets('(e2) edicion con marca desconocida -> campos manuales', (
      tester,
    ) async {
      final result = await _pump(
        tester,
        brand: 'UnknownBrand',
        model: 'Custom Thing',
        watts: '145',
      );

      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Marca'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Modelo'), findsOneWidget);
      expect(result.brand.text, 'UnknownBrand');
      expect(result.model.text, 'Custom Thing');
      expect(result.watts.text, '145');
    });

    testWidgets('cambiar de marca limpia modelo y watts', (tester) async {
      final result = await _pump(tester);
      await _selectBrand(tester, 'Bambu Lab');
      await _selectModel(tester, 'H2D');
      expect(result.watts.text, '330');

      // Cambio de marca -> modelo y watts se resetean.
      await _selectBrand(tester, 'Prusa');
      expect(result.model.text, isEmpty);
      expect(result.watts.text, isEmpty);
    });
  });
}
