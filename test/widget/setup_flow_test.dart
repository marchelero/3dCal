// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/core/theme/app_theme.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import 'package:tresdcal/features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import 'package:tresdcal/features/onboarding/presentation/pages/setup_flow_page.dart';
import 'package:tresdcal/features/onboarding/presentation/widgets/progress_pills.dart';
import 'package:tresdcal/features/onboarding/presentation/widgets/ticket_preview_card.dart';
import 'package:tresdcal/l10n/app_locale.dart';
import 'package:tresdcal/l10n/de_de.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/l10n/fr_fr.dart';
import 'package:tresdcal/l10n/pt_br.dart';

/// Replica el `ref.listen(localeProvider)` de `app.dart` (setImpl global de
/// EsBO) para que los strings estáticos reflejen el cambio de idioma al
/// instante también en el harness de tests.
class _LocaleBridge extends ConsumerWidget {
  const _LocaleBridge({required this.child});

  final Widget child;

  AppStrings _stringsFor(AppLocale locale) => switch (locale) {
    AppLocale.es => const EsImpl(),
    AppLocale.en => const EnImpl(),
    AppLocale.ptBr => const PtBrImpl(),
    AppLocale.de => const DeImpl(),
    AppLocale.fr => const FrImpl(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(localeProvider, (_, next) => EsBO.setImpl(_stringsFor(next)));
    return child;
  }
}

GoRouter _buildTestRouter({String initialLocation = '/setup'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('home-marker'))),
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupFlowPage()),
      GoRoute(
        path: '/calculator',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('calculator-marker'))),
      ),
    ],
  );
}

/// Harness: patrón de initial_config_stepper_test (prefs mock + drift memory
/// + UncontrolledProviderScope + viewport 800x2000).
Future<ProviderContainer> _pumpSetup(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  // Evita que el impl activo (ej: EnImpl tras un tap de idioma) contamine
  // los tests siguientes del mismo archivo.
  addTearDown(() => EsBO.setImpl(const EsImpl()));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _LocaleBridge(child: MaterialApp.router(routerConfig: router)),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

AnimatedContainer _gradientContainer(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.byType(PageView),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
}

/// Color de gradiente de la página actual (mapeo `onboardingSlideColors`).
Color _gradientColor(WidgetTester tester) {
  final deco = _gradientContainer(tester).decoration! as BoxDecoration;
  return (deco.gradient! as LinearGradient).colors.first;
}

/// Registra impresora + filamento default vía los notifiers (patrón
/// reanudación AC-13) para superar el gate de obligatoriedad del flujo.
Future<void> _registerPrinterAndFilament(ProviderContainer container) async {
  await container
      .read(printersNotifierProvider.notifier)
      .create(
        name: 'P1S',
        brand: 'Bambu Lab',
        averageWatts: 105,
        usefulLifeHours: 8000,
        asDefault: true,
      );
  await container
      .read(filamentsNotifierProvider.notifier)
      .create(
        name: 'Sunlu 1000g',
        brand: 'Sunlu',
        pricePerBobbin: Decimal.parse('125'),
        gramsPerBobbin: Decimal.fromInt(1000),
        asDefault: true,
      );
}

/// Swipe horizontal del PageView arrancando en la zona de títulos (arriba).
/// En el centro de la pantalla los campos de texto (precio del filamento,
/// watts custom) y la paleta de colores de los pasos 2–3 ganan el gesto
/// horizontal en el arena (selección de texto / scroll de la paleta), igual
/// que con el dedo del usuario: el swipe "fiable" es desde una zona no
/// interactiva.
Future<void> _swipePage(WidgetTester tester, double dx) async {
  final area = find.byType(PageView);
  final topLeft = tester.getTopLeft(area);
  final size = tester.getSize(area);
  await tester.dragFrom(topLeft + Offset(size.width / 2, 48), Offset(dx, 0));
  await tester.pumpAndSettle();
}

/// El write async de drift (NativeDatabase.memory) en el harness necesita
/// ~2 s de frames fake para resolver; `pumpAndSettle` solo bombea mientras
/// haya frames agendados y se planta antes. Este helper bombear reloj fake
/// hasta que aparezca el texto [text] (p. ej. el SnackBar de confirmación).
Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// Los SnackBars (2 s) se superponen a la barra inferior Atrás/Siguiente y
/// interceptan los taps de los tests; además pueden encolarse (hint del
/// gate + éxito del registro). Bombear hasta que no quede ninguno visible.
Future<void> _pumpPastSnackBars(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    if (find.byType(SnackBar).evaluate().isEmpty) break;
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

void main() {
  group('SetupFlowPage (flujo /setup)', () {
    testWidgets(
      '6 páginas: swipe avanza/retrocede y el ticket preview vive en 1-4 '
      '(con printer+filament registrados — gate abierto)',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinterAndFilament(container);
        await tester.pumpAndSettle();
        expect(find.byType(SetupFlowPage), findsOneWidget);
        expect(find.byType(ProgressPills), findsOneWidget);
        expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);
        // Paso 0: sin ticket preview.
        expect(find.byType(TicketPreviewCard), findsNothing);

        // Avanza las 5 páginas restantes (1..5); el tagline vive solo en 0.
        // Nota: el drag es ~1.1 páginas para que el snap avance exactamente
        // una página (un drag de 1.5 páginas saltaría de golpe a la 2).
        for (var i = 1; i <= 5; i++) {
          await _swipePage(tester, -900);
          await tester.pumpAndSettle();
          expect(
            find.text(EsBO.setupWelcomeTagline),
            findsNothing,
            reason: 'el tagline no debe estar en la página $i',
          );
          // Ticket preview solo en las páginas 1-4 (no en el cierre).
          expect(
            find.byType(TicketPreviewCard),
            i <= 4 ? findsOneWidget : findsNothing,
            reason: 'ticket preview en la iteración $i',
          );
        }
        // Cierre (página 5): las 5 pills están completadas con check.
        expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));
        // Un swipe más no cambia nada (última página).
        await _swipePage(tester, -900);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));

        // Retrocede hasta el inicio.
        for (var i = 5; i >= 1; i--) {
          await _swipePage(tester, 900);
          await tester.pumpAndSettle();
        }
        expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);
        expect(find.byType(TicketPreviewCard), findsNothing);
      },
    );

    testWidgets(
      'gate: swipe/pill HACIA ATRÁS siempre permitido (incluso sin printer)',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());
        await _swipePage(tester, -900); // 0 → 1
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[1]);

        await _swipePage(tester, -900); // 1 → 2 (paso impresora, sin gate)
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);

        // Retroceso sin restricciones: 2 → 1 → 0.
        await _swipePage(tester, 900);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[1]);
        await _swipePage(tester, 900);
        await tester.pumpAndSettle();
        expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);
      },
    );

    testWidgets(
      'gate: swipe adelante bloqueado sin impresora ⇒ snap-back + SnackBar '
      'setupNeedPrinter',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());
        await _swipePage(tester, -900); // 0 → 1
        await _swipePage(tester, -900); // 1 → 2 (paso impresora)
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);

        // Swipe 2 → 3 sin printer default: rebotado + hint.
        await _swipePage(tester, -900);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        expect(find.text(EsBO.setupNeedPrinter), findsOneWidget);
        expect(find.text(EsBO.setupFilamentTitle), findsNothing);

        // Pill al paso 3 (filamento) también bloqueada.
        await tester.tap(find.byKey(const ValueKey('setup-progress-pill-3')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        expect(find.text(EsBO.setupNeedPrinter), findsWidgets);
      },
    );

    testWidgets(
      'gate: swipe/pill adelante bloqueado sin filamento (con printer) ⇒ '
      'snap-back + SnackBar setupNeedFilament',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        // Solo printer: el gate de filamento sigue cerrado.
        await container
            .read(printersNotifierProvider.notifier)
            .create(
              name: 'P1S',
              brand: 'Bambu Lab',
              averageWatts: 105,
              asDefault: true,
            );
        await tester.pumpAndSettle();

        await _swipePage(tester, -900); // 0 → 1
        await _swipePage(tester, -900); // 1 → 2 (impresora, saved)
        await _swipePage(tester, -900); // 2 → 3 (permitido: printer OK)
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);

        // Swipe 3 → 4 sin filamento: rebotado + hint.
        await _swipePage(tester, -900);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(find.text(EsBO.setupNeedFilament), findsOneWidget);
        expect(find.text(EsBO.setupProfitTitle), findsNothing);

        // Pill al paso 4 (ganancia) también bloqueada.
        await tester.tap(find.byKey(const ValueKey('setup-progress-pill-4')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(find.text(EsBO.setupNeedFilament), findsWidgets);
      },
    );

    testWidgets('back del sistema: en paso >0 retrocede de página y NO sale; '
        'en el paso 0 sí permite pop', (tester) async {
      final router = _buildTestRouter(initialLocation: '/');
      await _pumpSetup(tester, router: router);
      unawaited(router.push('/setup'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupFlowPage), findsOneWidget);

      // Paso 1: el back retrocede al paso 0 sin salir del flujo.
      await _swipePage(tester, -900);
      await tester.pumpAndSettle();
      expect(find.text(EsBO.setupWelcomeTagline), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byType(SetupFlowPage),
        findsOneWidget,
        reason: 'el back en paso >0 no debe sacar del flujo',
      );
      expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);

      // Paso 0: el pop se permite (sale al home del router de prueba).
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SetupFlowPage), findsNothing);
      expect(find.text('home-marker'), findsOneWidget);
    });

    testWidgets('tap en pill navega al paso correspondiente (con printer '
        'registrada para el gate)', (tester) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      await container
          .read(printersNotifierProvider.notifier)
          .create(
            name: 'P1S',
            brand: 'Bambu Lab',
            averageWatts: 105,
            asDefault: true,
          );
      await tester.pumpAndSettle();

      // Tap en la pill 3 → página 3 (filamento; el gate de printer pasa).
      await tester.tap(find.byKey(const ValueKey('setup-progress-pill-3')));
      await tester.pumpAndSettle();
      expect(find.text(EsBO.setupWelcomeTagline), findsNothing);
      // Pills 0-2 completadas (check); pill 3 es la actual (sin check).
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));

      // Tap en la pill 0 → vuelve al inicio.
      await tester.tap(find.byKey(const ValueKey('setup-progress-pill-0')));
      await tester.pumpAndSettle();
      expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('tap en idioma cambia strings al instante y persiste en '
        'SharedPreferences', (tester) async {
      await _pumpSetup(tester, router: _buildTestRouter());
      expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('setup-language-en')));
      await tester.pumpAndSettle();

      // Locale persistido (clave 'locale' del LocaleNotifier).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'en');

      // Strings en inglés al instante (mismo mecanismo setImpl que app.dart).
      expect(find.text('Set up your calculator in seconds'), findsOneWidget);
      // La card English muestra el check de seleccionada.
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('idioma por defecto: español seleccionado y la pref locale '
        'NO persiste hasta tocar', (tester) async {
      await _pumpSetup(tester, router: _buildTestRouter());
      expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);

      // Default de fábrica: español activo sin escribir la pref 'locale'.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), isNull);

      // La tarjeta Español queda marcada como seleccionada (check único).
      expect(find.byKey(const ValueKey('setup-language-es')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('pills: contador a11y (configStepCounter) refleja la página '
        'actual', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpSetup(tester, router: _buildTestRouter());

      // Contador "Paso 1 de 5" del container de pills y de la pill actual.
      expect(find.bySemanticsLabel('Paso 1 de 5'), findsAtLeastNWidgets(1));

      await _swipePage(tester, -900);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Paso 2 de 5'), findsAtLeastNWidgets(1));
      semantics.dispose();
    });

    testWidgets(
      'gradiente animado por paso (400 ms) + sin "Guardar" (AC-07; cambio '
      '2026-10-11: "Siguiente"/"Atrás" discretos en barra inferior)',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());

        final gradient0 = _gradientContainer(tester);
        expect(gradient0.duration, const Duration(milliseconds: 400));
        final deco0 = gradient0.decoration! as BoxDecoration;
        expect(deco0.gradient, isA<LinearGradient>());
        expect(
          (deco0.gradient! as LinearGradient).colors.first,
          AppTheme.onboardingSlideColors[0],
        );

        // AC-07: en todo el flujo no existe "Guardar". Paso 0: solo
        // "Siguiente" (sin "Atrás").
        expect(find.text('Guardar'), findsNothing);
        expect(find.text('Siguiente'), findsOneWidget);
        expect(find.text('Atrás'), findsNothing);

        // Cambia de paso: el gradiente muta al color mapeado de la página 1.
        await _swipePage(tester, -900);
        await tester.pumpAndSettle();
        final gradient1 = _gradientContainer(tester);
        final deco1 = gradient1.decoration! as BoxDecoration;
        expect(deco1.gradient, isA<LinearGradient>());
        expect(
          (deco1.gradient! as LinearGradient).colors.first,
          AppTheme.onboardingSlideColors[1],
        );
        expect(find.text('Guardar'), findsNothing);
        expect(find.text('Siguiente'), findsOneWidget);
        expect(find.text('Atrás'), findsOneWidget);
      },
    );

    testWidgets(
      'barra nav: "Siguiente" navega, "Atrás" retrocede; sin "Atrás" en el '
      'paso 0 ni barra en el cierre',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());

        // Paso 0: solo "Siguiente" (sin "Atrás").
        expect(find.byKey(const ValueKey('setup-nav-next')), findsOneWidget);
        expect(find.byKey(const ValueKey('setup-nav-back')), findsNothing);
        expect(find.text('Atrás'), findsNothing);

        // "Siguiente" navega al paso 1.
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[1]);

        // Paso 1: "Atrás" retrocede al paso 0.
        expect(find.byKey(const ValueKey('setup-nav-back')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('setup-nav-back')));
        await tester.pumpAndSettle();
        expect(find.text(EsBO.setupWelcomeTagline), findsOneWidget);
        expect(find.byKey(const ValueKey('setup-nav-back')), findsNothing);
      },
    );

    testWidgets(
      'barra nav: "Siguiente" bloqueado con hint sin impresora (paso 2) y sin '
      'filamento (página 3 con printer) — sin cambio de página',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());

        // Paso 2 sin printer: "Siguiente" muestra hint y no cambia de página.
        await _swipePage(tester, -900); // 0 → 1
        await _swipePage(tester, -900); // 1 → 2 (paso impresora)
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        expect(find.text(EsBO.setupNeedPrinter), findsOneWidget);
        expect(find.text(EsBO.setupFilamentTitle), findsNothing);

        // Con printer: "Siguiente" llega al paso 3; sin filamento ⇒ hint.
        await container
            .read(printersNotifierProvider.notifier)
            .create(
              name: 'P1S',
              brand: 'Bambu Lab',
              averageWatts: 105,
              asDefault: true,
            );
        await tester.pumpAndSettle();
        // El hint del gate anterior (2 s) tapa la barra: esperar su salida.
        await _pumpPastSnackBars(tester);
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);

        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(find.text(EsBO.setupNeedFilament), findsOneWidget);
        expect(find.text(EsBO.setupProfitTitle), findsNothing);
      },
    );

    testWidgets(
      'barra nav: "Siguiente" en impresora/filamento con registro hecho '
      'avanza (pasos 2→3→4); cierre sin barra',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _swipePage(tester, -900); // 0 → 1
        await _swipePage(tester, -900); // 1 → 2 (paso impresora)
        await tester.pumpAndSettle();

        // El preset llena el form (commit-on-navigate): el SnackBar del
        // guard aparece DURANTE el tap de "Siguiente", que hace el commit
        // (create) y recién entonces avanza al paso 3.
        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-P1S')),
        );
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await _pumpPastSnackBars(tester);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);

        // Filamento: mismo patrón — "Siguiente" persiste el borrador y
        // avanza a ganancia.
        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('setup-filament-price')),
          '125',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await _pumpUntilText(tester, EsBO.configFilamentSaved);
        await _pumpPastSnackBars(tester);
        await tester.pumpAndSettle();
        // Página 4 (ganancia) ⇒ índice de color 0 (4 % 4).
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[0]);
        expect(find.text(EsBO.setupProfitTitle), findsOneWidget);

        // Cierre (página 5): sin barra de navegación (ni Siguiente ni Atrás).
        await _swipePage(tester, -900);
        await tester.pumpAndSettle();
        expect(find.text(EsBO.setupDoneTitle), findsOneWidget);
        expect(find.byKey(const ValueKey('setup-nav-next')), findsNothing);
        expect(find.byKey(const ValueKey('setup-nav-back')), findsNothing);
        expect(find.text('Siguiente'), findsNothing);
        expect(find.text('Atrás'), findsNothing);
        expect(container.read(printersNotifierProvider).value, hasLength(1));
      },
    );

    testWidgets('MED-5: commit por swipe — el form completo persiste vía '
        'NotificationListener y el gate deja avanzar (sin snap-back; MED-3 '
        'espera el commit antes de evaluar)', (tester) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      await _swipePage(tester, -900); // 0 → 1
      await _swipePage(tester, -900); // 1 → 2 (paso impresora)
      await tester.pumpAndSettle();
      expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);

      // Form completo vía preset, SIN tocar "Guardar": el swipe debe
      // disparar el commit fire-and-forget (ScrollStartNotification) y
      // el gate debe esperarlo antes de decidir (MED-3).
      await tester.tap(
        find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-P1S')),
      );
      await tester.pumpAndSettle();

      await _swipePage(tester, -900); // 2 → 3 (commit al arrancar el gesto)
      await _pumpUntilText(tester, EsBO.configPrinterSaved);
      await _pumpPastSnackBars(tester);
      await tester.pumpAndSettle();

      // Sin snap-back: el gate evaluó contra el provider YA actualizado.
      expect(
        _gradientColor(tester),
        AppTheme.onboardingSlideColors[3],
        reason: 'el swipe con form completo debe avanzar a filamento',
      );
      expect(find.text(EsBO.setupFilamentTitle), findsOneWidget);
      expect(container.read(printersNotifierProvider).value, hasLength(1));
    });
  });
}
