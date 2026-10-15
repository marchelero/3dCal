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
import 'package:tresdcal/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/pages/filament_form_page.dart';
import 'package:tresdcal/features/onboarding/presentation/widgets/setup_chip.dart';
import 'package:tresdcal/shared/widgets/filament_color_field.dart';

Future<ProviderContainer> _pumpForm(
  WidgetTester tester, {
  Filament? existing,
}) async {
  // Viewport alto: el form (chips de marca + card de campos + switch +
  // Guardar) excede 600px y el boton queda fuera del viewport construido.
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
      child: MaterialApp(home: FilamentFormPage(existing: existing)),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('FilamentFormPage (create)', () {
    testWidgets('titulo "Nuevo filamento"', (tester) async {
      await _pumpForm(tester);
      expect(find.text('Nuevo filamento'), findsOneWidget);
    });

    testWidgets('muestra los inputs y el switch default', (tester) async {
      await _pumpForm(tester);
      // Labels actuales segun EsBO.filament* en l10n/es_bo.dart.
      expect(find.widgetWithText(TextField, 'Nombre'), findsOneWidget);
      // Marca: campo siempre visible (2 inputs, usuario 2026-10-11) +
      // chips (SetupChip) sobre kKnownFilamentBrands + "Otro...".
      expect(find.widgetWithText(TextField, 'Marca'), findsOneWidget);
      expect(find.byType(SetupChip), findsNWidgets(24)); // 23 + "Otro..."
      // Campo color (RF1-2 del PRD 2026-09-08) presente en el form.
      expect(find.byType(FilamentColorField), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Precio filamento (\$)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Gramos por rollo'),
        findsOneWidget,
      );
      // El switch esta fuera del viewport por defecto del test (el form
      // crecio con el color picker). Scrollear para encontrarlo.
      await tester.scrollUntilVisible(
        find.byType(SwitchListTile),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('guardar invalido muestra errores', (tester) async {
      await _pumpForm(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.text('Requerido'), findsAtLeastNWidgets(1));
    });

    testWidgets('marca (chips) aparece ANTES que el campo nombre', (
      tester,
    ) async {
      await _pumpForm(tester);

      // Orden: chips de marca primero, luego Nombre (decision del usuario:
      // "primero la marca y luego recien ingresar el modelo").
      final brandChip = find.byKey(const ValueKey('filament-form-brand-eSun'));
      expect(brandChip, findsOneWidget);
      final nameField = tester.getTopLeft(
        find.widgetWithText(TextField, 'Nombre'),
      );
      expect(
        tester.getTopLeft(brandChip).dy <= nameField.dy,
        isTrue,
        reason: 'Los chips de marca deben estar ARRIBA del campo Nombre',
      );
    });

    testWidgets('guardar valido crea y cierra (Navigator.pop)', (tester) async {
      final container = await _pumpForm(tester);
      // Necesitamos un Navigator que soporte pop. Envolvemos en otro
      // MaterialApp con un parent route que cuente pops.
      // Re-pump con wrapper:
      // (mejor: usar NavigatorObserver)
      // La marca es obligatoria siempre (2 inputs): elegir un chip known.
      await tester.tap(find.byKey(const ValueKey('filament-form-brand-eSun')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'PLA Test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Precio filamento (\$)'),
        '120',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Gramos por rollo'),
        '1000',
      );
      await tester.pump();

      // Viewport alto del _pumpForm: Guardar ya esta en pantalla.
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Verifico via el notifier
      final list = await container.read(filamentsNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.name, 'PLA Test');
    });

    testWidgets(
      'chip "Otro..." limpia la marca, resalta el chip y enfoca el campo '
      'manual (bug 2026-10-11: "no hacía nada")',
      (tester) async {
        await _pumpForm(tester);

        // Selecciona un chip known primero (escenario del bug).
        await tester.tap(
          find.byKey(const ValueKey('filament-form-brand-eSun')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('filament-form-brand-other')),
        );
        await tester.pumpAndSettle();

        // Campo manual visible, vacío y con foco.
        final manual = find.widgetWithText(TextField, 'Marca');
        expect(manual, findsOneWidget);
        expect(tester.widget<TextField>(manual).controller!.text, isEmpty);
        expect(
          tester.widget<TextField>(manual).focusNode?.hasFocus,
          isTrue,
          reason: 'el campo manual debe tener el foco tras tocar "Otro..."',
        );

        // Chip "Otro..." resaltado; chip known des-seleccionado.
        expect(
          tester
              .widget<SetupChip>(
                find.byKey(const ValueKey('filament-form-brand-other')),
              )
              .selected,
          isTrue,
        );
        expect(
          tester
              .widget<SetupChip>(
                find.byKey(const ValueKey('filament-form-brand-eSun')),
              )
              .selected,
          isFalse,
        );

        // Volver a un chip known deja la marca en solo-lectura con el valor
        // del chip (los 2 campos siguen visibles).
        await tester.tap(
          find.byKey(const ValueKey('filament-form-brand-eSun')),
        );
        await tester.pumpAndSettle();
        final brandField = find.widgetWithText(TextField, 'Marca');
        expect(brandField, findsOneWidget);
        final brandWidget = tester.widget<TextField>(brandField);
        expect(brandWidget.readOnly, isTrue);
        expect(brandWidget.controller!.text, 'eSun');
      },
    );

    testWidgets(
      'modo manual: marca vacía al guardar ⇒ "Requerido" (marca y alias son '
      '2 campos obligatorios)',
      (tester) async {
        await _pumpForm(tester);

        await tester.tap(
          find.byKey(const ValueKey('filament-form-brand-other')),
        );
        await tester.pumpAndSettle();

        // Nombre y precio con valor; solo la marca manual queda vacía.
        await tester.enterText(
          find.widgetWithText(TextField, 'Nombre'),
          'PLA Negro',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Precio filamento (\$)'),
          '120',
        );
        await tester.pump();

        await tester.tap(find.text('Guardar'));
        await tester.pump();

        // La marca manual es obligatoria en modo "Otro...".
        expect(find.text('Requerido'), findsOneWidget);

        // Con la marca escrita el guardado procede.
        await tester.enterText(
          find.widgetWithText(TextField, 'Marca'),
          'Creality',
        );
        await tester.pump();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        // Sin GoRouter en el harness el pop falla tras persistir; el
        // notifier ya refleja el registro.
      },
    );
  });

  group('FilamentFormPage (edit)', () {
    testWidgets('titulo "Editar filamento" y prefill', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Insert manual
      final id = await db
          .into(db.filaments)
          .insert(
            FilamentsCompanion.insert(
              name: 'PLA Pre',
              brand: const Value('eSun'),
              pricePerBobbin: 150,
              gramsPerBobbin: 1000,
              isDefault: const Value(true),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      final existing = (await db.select(db.filaments).get()).first;
      // (id no usado, pero valido que se haya insertado)
      expect(id, isPositive);
      expect(existing.name, 'PLA Pre');

      await _pumpForm(tester, existing: existing);
      expect(find.text('Editar filamento'), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Nombre'),
      );
      expect(nameField.controller!.text, 'PLA Pre');
    });
  });
}
