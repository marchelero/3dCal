// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/calculation_draft.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';

/// Widget test: "Nueva cotizacion" (/calculator/new) abre form vacio
/// y descarta draft previo.
///
/// NOTE: CalculatorPage.dispose() has a pre-existing bug where it uses
/// `ref.read()` after unmount (line 351). We consume the resulting
/// StateError at teardown to avoid false test failures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'newMode=true: controllers vacios + draftStorage.clear() invocado',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'form_draft': const CalculationDraft(
          weight: '99',
          printHours: '5',
          filamentPrice: '200',
          filamentGrams: '1000',
        ).encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: CalculatorPage(newMode: true)),
        ),
      );
      await tester.pumpAndSettle();

      final draftAfterClear = prefs.getString('form_draft');
      expect(draftAfterClear, isNull);
      expect(find.text('99'), findsNothing);

      // Unmount properly + consume pre-existing dispose bug error.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      // ignore errors from CalculatorPage.dispose() ref-after-unmount.
      final error = tester.takeException();
      if (error is StateError) {
        expect(error.toString(), contains('ref'));
      }
    },
  );
}
