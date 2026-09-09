// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/onboarding/presentation/pages/onboarding_page.dart';

Future<void> _pumpOnboarding(WidgetTester tester, GoRouter router) async {
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

/// Lleva el PageView del onboarding hasta la última slide (5 slides).
Future<void> _goToLastSlide(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
  }
}

void main() {
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: '/initial-config',
        builder: (_, _) =>
            Scaffold(appBar: AppBar(), body: const Text('initial-config')),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(appBar: AppBar(), body: const Text('home')),
      ),
      GoRoute(
        path: '/calculator',
        builder: (_, _) =>
            Scaffold(appBar: AppBar(), body: const Text('calculator')),
      ),
    ],
  );

  group('OnboardingPage → configuración inicial', () {
    testWidgets('CTA final "Configurar" navega a /initial-config y NO '
        'persiste onboarding_done (lo hace la config al terminar)', (
      tester,
    ) async {
      final router = buildRouter();
      await _pumpOnboarding(tester, router);
      await _goToLastSlide(tester);

      // Última slide (5): CTA primario para ir a la configuración inicial.
      expect(find.text('Configurar'), findsOneWidget);
      await tester.tap(find.text('Configurar'));
      await tester.pumpAndSettle();

      // Navegó a la config inicial y el onboarding salió del stack.
      expect(find.text('initial-config'), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);

      // El flag se persiste recién al terminar la config (no en el CTA).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsKeys.onboardingDone), isNull);
    });

    testWidgets('no hay botón de saltar y el contador muestra 5 slides', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = buildRouter();
      await _pumpOnboarding(tester, router);

      // Sin skip: la primera slide solo ofrece "Siguiente".
      expect(find.text('Saltar'), findsNothing);
      expect(find.text('Ir al menú'), findsNothing);
      expect(find.text('Siguiente'), findsOneWidget);

      // Contador de página (a11y): 1 de 5 → 5 de 5.
      expect(find.bySemanticsLabel('Página 1 de 5'), findsOneWidget);

      // Última slide: el contador llega a 5 y el CTA es "Configurar".
      await _goToLastSlide(tester);
      expect(find.bySemanticsLabel('Página 5 de 5'), findsOneWidget);
      expect(find.text('Configurar'), findsOneWidget);
      expect(find.text('Siguiente'), findsNothing);
      handle.dispose();
    });
  });
}
