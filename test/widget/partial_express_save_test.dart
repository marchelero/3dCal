// ignore_for_file: public_member_api_docs

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';

/// Regresiones del guardado rapido (autosave parcial):
///
/// 1. En Express el formulario tiene UN material implicito (peso + filamento).
///    Antes el parcial se guardaba sin materiales, asi que "Reusar" traia el
///    peso/filamento vacios y el detalle los mostraba en blanco.
/// 2. El parcial debe persistir ese material implicito para reconstruir los
///    campos al reusar.
void main() {
  testWidgets('partial Express persiste el material implicito', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CalculatorPage(newMode: true)),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> fill(String label, String value) async {
      final f = find.widgetWithText(TextField, label);
      if (f.evaluate().isEmpty) return;
      await tester.enterText(f.first, value);
      await tester.pump();
    }

    await fill('Peso', '100');
    await fill('Horas', '2');
    await fill('Precio bobina', '120');
    await fill('Gramos / bobina', '1000');

    // Debounce del parcial (1.5s) + margen.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    final repo = container.read(calculationRepositoryProvider);
    // El borrador SI aparece en el historial (el usuario lo retoma de ahi),
    // pero NO cuenta contra el cap free.
    expect(await repo.countAll(), 0, reason: 'borrador no consume cap');
    expect(await repo.listItems(), hasLength(1));

    // Pero SI existe como parcial con su material implicito.
    final draftRow = await repo.findLatestPartialForMinute(
      DateTime.now().toLocal(),
    );
    // Si no lo encontro por minuto, buscar cualquier parcial del bucket reciente.
    final Calculation? partial;
    if (draftRow != null) {
      partial = draftRow;
    } else {
      final all = await db.select(db.calculations).get();
      partial = all.where((c) => c.isPartial).firstOrNull;
    }
    expect(partial, isNotNull, reason: 'el autosave debe crear un parcial');
    final mats = await repo.materialsOf(partial!.id);
    expect(mats, hasLength(1), reason: 'Express guarda su material implicito');
    expect(mats.single.weightGrams, 100);

    // "Reusar" recupera peso + filamento desde el material persistido.
    final notifier = container.read(calculatorNotifierProvider.notifier);
    await notifier.loadFromCalculation(partial);
    final s = container.read(calculatorNotifierProvider);
    expect(s.mode, CalculatorMode.express);
    expect(s.weight, '100');
    expect(s.filamentPrice, '120.00');
    expect(s.filamentGrams, '1000');
  });

  testWidgets('salir ANTES del debounce igual persiste el parcial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CalculatorPage(newMode: true)),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> fill(String label, String value) async {
      final f = find.widgetWithText(TextField, label);
      if (f.evaluate().isEmpty) return;
      await tester.enterText(f.first, value);
      await tester.pump();
    }

    await fill('Peso', '150');
    await fill('Horas', '3');
    await fill('Precio bobina', '100');
    await fill('Gramos / bobina', '1000');

    // Salir INMEDIATAMENTE (sin esperar los 1.5s del debounce).
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    // Dar tiempo al save fire-and-forget (async en DB).
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final repo = container.read(calculationRepositoryProvider);
    final items = await repo.listItems();
    expect(
      items.where((i) => i.isPartial),
      isNotEmpty,
      reason: 'el parcial debe persistir aunque se salga antes del debounce',
    );
    final partial = items.firstWhere((i) => i.isPartial);
    final mats = await repo.materialsOf(partial.id);
    expect(mats.single.weightGrams, 150);
  });
}
