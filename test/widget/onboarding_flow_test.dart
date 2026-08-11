// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/onboarding/presentation/pages/onboarding_page.dart';

Future<void> _pumpOnboarding(
  WidgetTester tester,
  GoRouter router,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
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

/// Lleva el PageView del onboarding hasta la última slide (4 slides).
Future<void> _goToLastSlide(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
  }
}

void main() {
  GoRouter buildRouter() => GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingPage(),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              appBar: AppBar(),
              body: const Text('home'),
            ),
          ),
          GoRoute(
            path: '/calculator',
            builder: (_, _) => Scaffold(
              appBar: AppBar(),
              body: const Text('calculator'),
            ),
          ),
        ],
      );

  group('OnboardingPage → primera cotización', () {
    testWidgets(
      'CTA final persiste onboarding, va a / y abre el calculador; '
      'al volver atrás queda en Home (nunca en onboarding)', (tester) async {
        final router = buildRouter();
        await _pumpOnboarding(tester, router);
        await _goToLastSlide(tester);

        // Última slide: CTA primario para crear la primera cotización.
        expect(
          find.widgetWithText(FilledButton, 'Crear mi primera cotización'),
          findsOneWidget,
        );
        await tester.tap(
          find.widgetWithText(FilledButton, 'Crear mi primera cotización'),
        );
        await tester.pumpAndSettle();

        // Estado persistido + calculador abierto encima de Home.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);
        expect(find.text('calculator'), findsOneWidget);

        // Back desde el calculador → Home. REGRESIÓN: antes quedaba el
        // onboarding vivo en el stack y se volvía a él (ciclo sin salida).
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('home'), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets(
      'última slide: "Ir al menú" cierra el onboarding directo a Home',
      (tester) async {
        final router = buildRouter();
        await _pumpOnboarding(tester, router);
        await _goToLastSlide(tester);

        await tester.tap(find.text('Ir al menú'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);
        expect(find.text('home'), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets('Saltar en la primera slide también llega a Home',
        (tester) async {
      final router = buildRouter();
      await _pumpOnboarding(tester, router);

      await tester.tap(find.text('Saltar'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);
      expect(find.text('home'), findsOneWidget);
    });
  });
}
