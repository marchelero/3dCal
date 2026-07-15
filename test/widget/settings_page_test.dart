// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/pages/filaments_page.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';

/// Helper: monta [SettingsPage] dentro de un [ProviderScope] con DB in-memory.
Future<ProviderContainer> _pumpPage(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('SettingsPage', () {
    testWidgets('renderiza secciones y defaults', (tester) async {
      await _pumpPage(tester);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Parametros globales'), findsOneWidget);
      expect(find.text('Filamentos'), findsOneWidget);
      expect(find.text('Impresoras'), findsOneWidget);
      expect(find.textContaining('100% local'), findsOneWidget);
    });

    testWidgets(
      'auto-save on blur: editar profit base persiste el cambio',
      (tester) async {
        final container = await _pumpPage(tester);

        final profitField = find.widgetWithText(TextFormField, '200');
        await tester.enterText(profitField, '350');
        await tester.pumpAndSettle();
        // Blur para disparar el listener.
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        final notifier = container.read(settingsNotifierProvider);
        expect(notifier.valueOrNull!.profitBase.toString(), '350');
      },
    );

    testWidgets(
      'tap en "Filamentos" navega a /settings/filaments (AC-9.1)',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ]);
        addTearDown(() async {
          container.dispose();
          await db.close();
        });

        // Mini app con GoRouter porque SettingsPage usa context.push.
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
            GoRoute(
              path: '/settings/filaments',
              builder: (_, _) => const FilamentsPage(),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ListTile, 'Filamentos'));
        await tester.pumpAndSettle();
        expect(find.byType(FilamentsPage), findsOneWidget);
      },
    );
  });
}
