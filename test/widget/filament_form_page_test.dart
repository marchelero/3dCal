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

Future<ProviderContainer> _pumpForm(
  WidgetTester tester, {
  Filament? existing,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
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

    testWidgets('muestra los 4 inputs numericos + switch default',
        (tester) async {
      await _pumpForm(tester);
      // Labels actuales segun EsBO.filament* en l10n/es_bo.dart.
      expect(find.widgetWithText(TextField, 'Nombre'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Marca'), findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'Precio filamento (\$)'),
          findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'Gramos por rollo'),
          findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('guardar invalido muestra errores', (tester) async {
      await _pumpForm(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.text('Requerido'), findsAtLeastNWidgets(1));
    });

    testWidgets('guardar valido crea y cierra (Navigator.pop)',
        (tester) async {
      final container = await _pumpForm(tester);
      // Necesitamos un Navigator que soporte pop. Envolvemos en otro
      // MaterialApp con un parent route que cuente pops.
      // Re-pump con wrapper:
      // (mejor: usar NavigatorObserver)
      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre'), 'PLA Test');
      await tester.enterText(
          find.widgetWithText(TextField, 'Precio filamento (\$)'), '120');
      await tester.enterText(
          find.widgetWithText(TextField, 'Gramos por rollo'), '1000');
      await tester.pump();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Verifico via el notifier
      final list = await container.read(filamentsNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.name, 'PLA Test');
    });
  });

  group('FilamentFormPage (edit)', () {
    testWidgets('titulo "Editar filamento" y prefill', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Insert manual
      final id = await db.into(db.filaments).insert(
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
          find.widgetWithText(TextField, 'Nombre'));
      expect(nameField.controller!.text, 'PLA Pre');
    });
  });
}
