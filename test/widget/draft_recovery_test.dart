// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/calculation_draft.dart';
import 'package:tresdcal/core/storage/draft_storage.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';

/// Tests minimos del draft recovery (PRD NFR-3).
///
/// Cubre:
/// 1. El draft se persiste al cambiar inputs.
/// 2. Un draft pre-existente se restaura al montar CalculatorPage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DraftStorage unit', () {
    test('save + load roundtrip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = DraftStorage(prefs);

      const draft = CalculationDraft(
        weight: '120',
        printHours: '5',
        profitPct: '25',
        filamentPrice: '150.00',
      );
      await storage.save(draft);

      final loaded = await storage.load();
      expect(loaded, isNotNull);
      expect(loaded!.weight, '120');
      expect(loaded.printHours, '5');
      expect(loaded.profitPct, '25');
      expect(loaded.filamentPrice, '150.00');
    });

    test('clear() borra el draft', () async {
      SharedPreferences.setMockInitialValues({
        'form_draft': '{"weight":"50"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = DraftStorage(prefs);

      expect(await storage.load(), isNotNull);
      await storage.clear();
      expect(await storage.load(), isNull);
    });
  });

  testWidgets(
    'CalculatorPage restaura draft pre-existente al montar (NFR-3)',
    (tester) async {
      // Pre-cargar un draft en SharedPreferences antes de montar la pagina.
      SharedPreferences.setMockInitialValues({
        'form_draft': const CalculationDraft(
          weight: '77',
          printHours: '3',
          profitPct: '30',
          discountPct: '10',
          filamentPrice: '200',
          filamentGrams: '1000',
        ).encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: CalculatorPage()),
        ),
      );
      // Esperar restore (post-frame callback + load async).
      await tester.pumpAndSettle();

      // Verificar que los inputs reflejan el draft.
      expect(find.widgetWithText(TextField, '77'), findsOneWidget);
      expect(find.widgetWithText(TextField, '3'), findsOneWidget);

      await db.close();
    },
  );
}
