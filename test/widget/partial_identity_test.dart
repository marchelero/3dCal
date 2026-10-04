// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';

/// Identidad estable de una cotizacion (bug: el guardado rapido creaba un
/// borrador nuevo por cada autosave, asi que una sola cotizacion terminaba
/// como N filas "Sin nombre").
///
/// Reglas:
/// - El autosave hace UPSERT sobre el mismo id ([currentPartialIdProvider]).
/// - Guardar definitiva reusa ese id y lo marca no-parcial.
/// - "Reusar" arranca un id nuevo (puntero de parcial reseteado).
void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool newMode = true,
    int? prefillId,
  }) async {
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
        child: MaterialApp(home: CalculatorPage(newMode: newMode)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> fill(WidgetTester tester, String label, String value) async {
    final f = find.widgetWithText(TextField, label);
    if (f.evaluate().isEmpty) return;
    await tester.enterText(f.first, value);
    await tester.pump();
  }

  Future<int> seedRealQuote(WidgetTester tester, ProviderContainer c) async {
    final repo = c.read(calculationRepositoryProvider);
    return repo.create(
      CalculationDraft(
        materials: const [],
        totalHours: Decimal.fromInt(2),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.fromInt(12),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.fromInt(12),
        ),
        clientName: 'Cliente',
      ),
    );
  }

  testWidgets('autosaves repetidos -> UN solo borrador (mismo id)', (
    tester,
  ) async {
    final c = await pump(tester);

    await fill(tester, 'Peso', '100');
    await fill(tester, 'Horas', '2');
    await fill(tester, 'Precio bobina', '120');
    await fill(tester, 'Gramos / bobina', '1000');
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    // Cambiar un valor y esperar otro autosave (otra vez).
    await fill(tester, 'Peso', '250');
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    final repo = c.read(calculationRepositoryProvider);
    final drafts = (await repo.listItems()).where((i) => i.isPartial).toList();
    expect(drafts, hasLength(1), reason: 'no debe crear un borrador por vez');
    expect(drafts.single.totalHours, lessThanOrEqualTo(2.0));
  });

  testWidgets('guardar definitiva reusa el mismo id y deja de ser parcial', (
    tester,
  ) async {
    final c = await pump(tester);

    await fill(tester, 'Peso', '100');
    await fill(tester, 'Horas', '2');
    await fill(tester, 'Precio bobina', '120');
    await fill(tester, 'Gramos / bobina', '1000');
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    final repo = c.read(calculationRepositoryProvider);
    final draft = (await repo.listItems()).firstWhere((i) => i.isPartial);

    // Guardar con cliente: mismo id, ya no parcial.
    final notifier = c.read(calculatorNotifierProvider.notifier);
    final id = await notifier.save(
      clientName: 'Cliente Test',
      updateId: draft.id,
      markDefinitive: true,
    );
    expect(id, draft.id, reason: 'misma identidad');

    final row = await repo.getById(draft.id);
    expect(row, isNotNull);
    expect(row!.isPartial, isFalse, reason: 'dejo de ser borrador');
    expect(row.clientName, 'Cliente Test');
    // No quedo una fila huerfana ni un borrador extra.
    expect((await repo.listItems()).where((i) => i.isPartial), isEmpty);
  });
}
