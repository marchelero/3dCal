// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/onboarding/presentation/pages/language_selection_page.dart';
import 'package:tresdcal/l10n/app_locale.dart';

Future<void> _pumpLanguagePage(WidgetTester tester, GoRouter router) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/language',
    routes: [
      GoRoute(path: '/language', builder: (_, _) => const LanguageSelectionPage()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) =>
            Scaffold(appBar: AppBar(), body: const Text('onboarding')),
      ),
    ],
  );

  group('LanguageSelectionPage (primera ejecución)', () {
    testWidgets('persiste el idioma elegido y navega a /onboarding', (
      tester,
    ) async {
      final router = buildRouter();
      await _pumpLanguagePage(tester, router);

      // Estado inicial: español por defecto.
      expect(find.text('Elige tu idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);

      // Cambio de idioma → se persiste en prefs (clave 'locale').
      await tester.tap(find.byType(DropdownButton<AppLocale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inglés').last);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'en');

      // CTA → onboarding.
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('onboarding'), findsOneWidget);
    });

    testWidgets('Continua directo con el idioma por defecto si no cambia', (
      tester,
    ) async {
      final router = buildRouter();
      await _pumpLanguagePage(tester, router);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), isNull); // es = default, no se persiste
      expect(find.text('onboarding'), findsOneWidget);
    });
  });
}
