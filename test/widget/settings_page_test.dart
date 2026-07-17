// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/pages/filaments_page.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';

/// Helper: monta [SettingsPage] dentro de un [ProviderScope] con DB in-memory
/// + SharedPreferences mock (necesario para themeModeProvider que la pagina
/// usa via _ThemeModeSelector).
Future<ProviderContainer> _pumpPage(WidgetTester tester) async {
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
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('SettingsPage', () {
    testWidgets('renderiza secciones y defaults', (tester) async {
      // Viewport mas grande para que la seccion "Acerca de" (con el texto
      // "100% local") entre en pantalla sin scrollear. Default es 800x600.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpPage(tester);
      expect(find.text('3dCalc'), findsOneWidget);
      expect(find.text('Parametros globales'), findsOneWidget);
      expect(find.text('Empresa'), findsOneWidget);
      expect(find.text('Nombre de la empresa'), findsOneWidget);
      expect(find.text('Filamentos'), findsOneWidget);
      expect(find.text('Impresoras'), findsOneWidget);
      expect(find.textContaining('100% local'), findsOneWidget);
    });

    testWidgets(
      'auto-save on blur: editar profit base persiste el cambio',
      (tester) async {
        final container = await _pumpPage(tester);

        // _AutoSaveField usa NumericInputField -> TextField (no TextFormField
        // porque validator=null). El valor inicial 200 sale de settings.profitBase.
        final profitField = find.widgetWithText(TextField, '200');
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
        // Viewport alto para que el ListTile de "Filamentos" (que vive
        // en la seccion Catalogos, en el medio de la page) no quede
        // fuera de pantalla. Default 800x600 no alcanza.
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

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
