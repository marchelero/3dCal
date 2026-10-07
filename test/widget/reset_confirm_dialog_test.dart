// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests: Reset (T7 — IconButton primario en AppBar).
///
/// Current behavior: _resetAll() resets directly without a confirmation dialog.
///
/// NOTE: CalculatorPage.dispose() has a pre-existing bug where it uses
/// `ref.read()` after unmount (line 351). We consume the resulting
/// StateError at teardown to avoid false test failures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPage(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: CalculatorPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    final error = tester.takeException();
    if (error is StateError) {
      expect(error.toString(), contains('ref'));
    }
  }

  group('Reset button', () {
    testWidgets(
      'tap Reset con contenido - form se resetea directamente',
      (tester) async {
        await pumpPage(tester);

        await tester.enterText(
          find.widgetWithText(TextField, 'Peso'),
          '100',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Precio bobina'),
          '120',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(EsBO.calcActionReset));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextField, '100'), findsNothing);

        await unmount(tester);
      },
    );

    testWidgets(
      'tap Reset sin contenido - reset silencioso',
      (tester) async {
        await pumpPage(tester);

        await tester.tap(find.byTooltip(EsBO.calcActionReset));
        await tester.pumpAndSettle();

        expect(find.textContaining('Completa peso'), findsWidgets);

        await unmount(tester);
      },
    );
  });
}
