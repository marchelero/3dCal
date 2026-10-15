// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/money/currency.dart';
import 'package:tresdcal/core/money/currency_settings_provider.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/core/theme/app_theme.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import 'package:tresdcal/features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import 'package:tresdcal/features/onboarding/presentation/pages/setup_flow_page.dart';
import 'package:tresdcal/features/onboarding/presentation/widgets/setup_chip.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/settings_notifier.dart';
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

/// Harness: patrón de setup_flow_test / initial_config_stepper_test (prefs
/// mock + drift memory + UncontrolledProviderScope + viewport 800x2000).
Future<ProviderContainer> _pumpSetup(
  WidgetTester tester, {
  required GoRouter router,
  Size viewport = const Size(800, 2000),
}) async {
  tester.view.physicalSize = viewport;
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

/// Navega a la página [page] del PageView tocando la pill de progreso.
Future<void> _goToPage(WidgetTester tester, int page) async {
  await tester.tap(find.byKey(ValueKey('setup-progress-pill-$page')));
  await tester.pumpAndSettle();
}

/// Color de gradiente de la página actual (mapeo `onboardingSlideColors`).
Color _gradientColor(WidgetTester tester) {
  final gradient = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.byType(PageView),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  final deco = gradient.decoration! as BoxDecoration;
  return (deco.gradient! as LinearGradient).colors.first;
}

/// Registra una impresora default vía el notifier (reanudación AC-13 /
/// superar el gate de obligatoriedad del flujo).
Future<void> _registerPrinter(ProviderContainer container) async {
  await container
      .read(printersNotifierProvider.notifier)
      .create(
        name: 'P1S',
        brand: 'Bambu Lab',
        averageWatts: 105,
        usefulLifeHours: 8000,
        asDefault: true,
      );
}

/// Registra un filamento default vía el notifier.
Future<void> _registerFilament(ProviderContainer container) async {
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

/// Selecciona marca + modelo del catálogo en el selector "Personalizada"
/// (mismo patrón que _selectPrinter del initial_config_stepper_test).
Future<void> _selectCatalogPrinter(
  WidgetTester tester,
  String brand,
  String model,
) async {
  final brandDropdown = find.byKey(const ValueKey('catalog-brand-dropdown'));
  await tester.ensureVisible(brandDropdown);
  await tester.tap(brandDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(brand).last);
  await tester.pumpAndSettle();
  final modelDropdown = find.byKey(ValueKey('catalog-model-dropdown-$brand'));
  await tester.ensureVisible(modelDropdown);
  await tester.tap(modelDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(model).last);
  await tester.pumpAndSettle();
}

/// Toca el botón "Guardar" del borrador de impresora (commit-on-navigate:
/// el preset/Personalizada llena el form y la persistencia es explícita).
Future<void> _tapPrinterSave(WidgetTester tester) async {
  final save = find.byKey(const ValueKey('setup-printer-save'));
  await tester.ensureVisible(save);
  await tester.tap(save);
}

/// Toca el botón "Guardar" del borrador de filamento.
Future<void> _tapFilamentSave(WidgetTester tester) async {
  final save = find.byKey(const ValueKey('setup-filament-save'));
  await tester.ensureVisible(save);
  await tester.tap(save);
}

/// Código de moneda persistido (espera el AsyncValue del notifier).
Future<String> _currencyCode(ProviderContainer container) async {
  final settings = await container.read(settingsNotifierProvider.future);
  return settings.currencyCode;
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
  group('Setup steps Fase 2', () {
    testWidgets('tema: tap "Oscuro" persiste themeMode en SharedPreferences', (
      tester,
    ) async {
      await _pumpSetup(tester, router: _buildTestRouter());
      await _goToPage(tester, 1);

      expect(find.text('Oscuro'), findsOneWidget);
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      expect(
        tester
            .widgetList(
              find.ancestor(
                of: find.text('Oscuro'),
                matching: find.byType(Semantics),
              ),
            )
            .where((w) => (w as Semantics).properties.selected == true),
        isNotEmpty,
        reason: 'la tarjeta Oscuro queda marcada como seleccionada',
      );
    });

    testWidgets(
      'moneda: locale es + factory default ⇒ BOB auto-persistida al entrar '
      'a paso 1',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        // Default de fábrica antes del paso 1.
        expect(await _currencyCode(container), 'USD');

        await _goToPage(tester, 1);
        await tester.pumpAndSettle();

        expect(await _currencyCode(container), 'BOB');
        expect(container.read(selectedCurrencyProvider).code, 'BOB');
        // Microcopy "por qué" de la moneda visible en el paso.
        expect(find.text(EsBO.configCurrencyHelper), findsOneWidget);
      },
    );

    testWidgets('moneda: tap USD ⇒ persiste USD y NO es pisada por el locale', (
      tester,
    ) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      await _goToPage(tester, 1);
      await tester.pumpAndSettle();
      expect(
        await _currencyCode(container),
        'BOB',
        reason: 'la pre-selección por locale aplica BOB primero',
      );

      // El chip USD muestra símbolo + código ('$ USD').
      final usdChip = find.text(r'$ USD');
      await tester.ensureVisible(usdChip);
      await tester.tap(usdChip);
      await tester.pumpAndSettle();

      expect(await _currencyCode(container), 'USD');
      // Un rebuild extra no lo pisa (flag _userTouchedCurrency).
      await tester.pumpAndSettle();
      expect(await _currencyCode(container), 'USD');
      expect(container.read(selectedCurrencyProvider).code, 'USD');
    });

    testWidgets(
      'moneda: "Ver más" abre sheet con WorldCurrency.all y la selección '
      'persiste',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 1);

        await tester.tap(find.byKey(const ValueKey('setup-currency-see-all')));
        await tester.pumpAndSettle();

        // La hoja lista TODAS las monedas del catálogo.
        expect(find.byType(BottomSheet), findsOneWidget);
        for (final currency in WorldCurrency.all) {
          expect(
            find.text('${currency.code} — ${currency.name}'),
            findsOneWidget,
            reason: 'falta ${currency.code} en la hoja',
          );
        }

        await tester.tap(
          find.byKey(const ValueKey('setup-currency-option-GBP')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
        expect(await _currencyCode(container), 'GBP');
        expect(container.read(selectedCurrencyProvider).code, 'GBP');

        // Bug F2: la moneda elegida desde la hoja (no sugerida ni común)
        // aparece como chip en la lista y queda reflejada como seleccionada.
        final gbpChip = find.text('${WorldCurrency.gbp.symbol} GBP');
        expect(gbpChip, findsOneWidget, reason: 'chip GBP tras elegir en hoja');
        expect(
          tester
              .widgetList(
                find.ancestor(of: gbpChip, matching: find.byType(Semantics)),
              )
              .where((w) => (w as Semantics).properties.selected == true),
          isNotEmpty,
          reason: 'el chip GBP queda selected=true tras elegirlo en la hoja',
        );
      },
    );

    testWidgets('badge "para tu idioma" (moneda sugerida por locale) '
        'eliminado', (tester) async {
      await _pumpSetup(tester, router: _buildTestRouter());
      await _goToPage(tester, 1);

      expect(find.text('para tu idioma'), findsNothing);
      expect(find.text('for your language'), findsNothing);
    });

    testWidgets(
      'ticket preview: colapsado compacto, tap expande, cambiar de página '
      'recolapsa',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 1);
        await tester.pumpAndSettle();

        final cardFinder = find.byKey(const ValueKey('setup-ticket-card'));
        expect(cardFinder, findsOneWidget);

        // Colapsado: una sola fila tipo ticket (~50 px), sin filas completas.
        final collapsedHeight = tester.getSize(cardFinder).height;
        expect(
          collapsedHeight,
          lessThan(100),
          reason: 'modo compacto debe ser una barra delgada (~50 px)',
        );
        expect(find.text(EsBO.printerTitle), findsNothing);
        final summary = tester.widget<Text>(
          find.byKey(const ValueKey('setup-ticket-summary')),
        );
        expect(summary.data, contains('BOB'), reason: 'moneda ya configurada');
        expect(summary.data, contains('+4 ${EsBO.setupTicketPending}'));

        // Tap expande a la vista completa con todas las filas.
        await tester.tap(find.byKey(const ValueKey('setup-ticket-toggle')));
        await tester.pumpAndSettle();

        expect(find.text(EsBO.printerTitle), findsOneWidget);
        expect(find.text(EsBO.filamentTitle), findsOneWidget);
        expect(find.text(EsBO.settingsProfitBase), findsOneWidget);
        final expandedHeight = tester.getSize(cardFinder).height;
        expect(expandedHeight, greaterThan(collapsedHeight));

        // Cambiar de página re-monta el ticket (key por página) ⇒ colapsado.
        await _goToPage(tester, 2);
        await _goToPage(tester, 1);
        expect(find.text(EsBO.printerTitle), findsNothing);
      },
    );

    testWidgets(
      'impresora: tap preset llena el form y "Guardar" crea default con '
      'watts/vida útil del catálogo SIN auto-avance; "Siguiente" avanza al '
      'paso filamento',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // Preset P1S (Bambu Lab): 105 W / 8000 h según kPrinterCatalog. El
        // tap LLENA el form (commit-on-navigate): persistir requiere
        // "Guardar" (o navegar).
        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-P1S')),
        );
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await tester.pumpAndSettle();

        // Sin auto-avance (cambio 2026-10-11): el flujo queda en la página
        // 2 con la tarjeta saved.
        expect(
          _gradientColor(tester),
          AppTheme.onboardingSlideColors[2],
          reason: 'registrar la impresora NO debe auto-avanzar',
        );
        expect(find.text('P1S'), findsWidgets);
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );

        // DB row via notifier state (no solo prefs).
        final printers = container.read(printersNotifierProvider).value;
        expect(printers, hasLength(1));
        final printer = printers!.single;
        expect(printer.name, 'P1S');
        expect(printer.brand, 'Bambu Lab');
        expect(printer.averageWatts, 105);
        expect(printer.usefulLifeHours, 8000);
        expect(printer.isDefault, isTrue);

        // "Siguiente" (barra inferior) avanza al paso filamento. El
        // SnackBar de éxito (2 s) tapa la barra: esperar su salida.
        await _pumpPastSnackBars(tester);
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(find.text(EsBO.setupFilamentTitle), findsOneWidget);

        // Volver a la página 2 muestra el estado saved (nombre + editar).
        await _goToPage(tester, 2);
        expect(find.text('P1S'), findsWidgets);
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );
      },
    );

    testWidgets('impresora: "Personalizada" completa + "Guardar" ⇒ create SIN '
        'auto-avance', (tester) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      await _goToPage(tester, 2);

      await tester.tap(find.byKey(const ValueKey('setup-printer-custom')));
      await tester.pumpAndSettle();
      await _selectCatalogPrinter(tester, 'Elegoo', 'Neptune 4 Pro');
      // Watts se auto-llena del catálogo (120 W); sin auto-guard: el
      // borrador se persiste al tocar "Guardar" (o al navegar).
      await _tapPrinterSave(tester);
      await _pumpUntilText(tester, EsBO.configPrinterSaved);
      await tester.pumpAndSettle();

      // Sin auto-avance (cambio 2026-10-11): el flujo queda en la página 2.
      expect(
        _gradientColor(tester),
        AppTheme.onboardingSlideColors[2],
        reason: 'el auto-create de Personalizada NO debe auto-avanzar',
      );
      final printers = container.read(printersNotifierProvider).value;
      expect(printers, hasLength(1));
      final printer = printers!.single;
      expect(printer.name, 'Neptune 4 Pro');
      expect(printer.brand, 'Elegoo');
      expect(printer.averageWatts, 120);
      // Vida útil default del form (7500): el catálogo solo la aplica al
      // elegir un PRESET, no en el selector "Personalizada".
      expect(printer.usefulLifeHours, 7500);
      expect(printer.isDefault, isTrue);

      // "Siguiente" avanza al paso filamento (esperar salida del SnackBar
      // de éxito, que tapa la barra).
      await _pumpPastSnackBars(tester);
      await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
      await tester.pumpAndSettle();
      expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
    });

    testWidgets(
      'impresora: gate — avanzar sin printer está BLOQUEADO (snap-back + '
      'hint); con printer registrado "Siguiente" avanza',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // Swipe adelante sin printer ⇒ rebota a la página 2 + hint.
        await tester.drag(find.byType(PageView), const Offset(-900, 0));
        await tester.pumpAndSettle();
        expect(
          _gradientColor(tester),
          AppTheme.onboardingSlideColors[2],
          reason: 'el avance sin impresora debe hacer snap-back',
        );
        expect(find.text(EsBO.setupNeedPrinter), findsOneWidget);
        expect(find.text(EsBO.setupFilamentTitle), findsNothing);

        // Con el preset elegido, "Siguiente" hace commit (create) y pasa
        // al paso filamento.
        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-P1S')),
        );
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        // El hint del gate anterior (2 s) tapa la barra: esperar su salida
        // antes del tap.
        await _pumpPastSnackBars(tester);
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        // El commit-on-navigate persiste y recién entonces pasa el gate.
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await _pumpPastSnackBars(tester);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(container.read(printersNotifierProvider).value, hasLength(1));
      },
    );

    testWidgets(
      'impresora: sin default el avance queda bloqueado (gate) — el enlace '
      '"lo agrego después" ya no existe',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // El enlace de skip fue eliminado del flujo nuevo.
        expect(find.text('Lo agrego después'), findsNothing);
        expect(
          find.byKey(const ValueKey('setup-printer-add-later')),
          findsNothing,
        );

        // Swipe adelante sin printer ⇒ snap-back a la página 2 + hint.
        await tester.drag(find.byType(PageView), const Offset(-900, 0));
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        expect(find.text(EsBO.setupNeedPrinter), findsOneWidget);
        expect(container.read(printersNotifierProvider).value, isEmpty);
      },
    );

    testWidgets(
      'impresora: re-entrar con default existente ⇒ estado saved (AC-13)',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-A1')),
        );
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await tester.pumpAndSettle();
        // Sin auto-avance (cambio 2026-10-11): el paso queda en la página 2
        // en estado saved.
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);
        expect(find.text('A1'), findsWidgets);
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );
        // Sin formulario: el estado guardado reemplaza al grid.
        expect(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-A1')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'impresora: segundo preset con default existente ⇒ UPDATE (una sola '
      'printer) + SnackBar setupPrinterUpdated + vuelta a tarjeta saved',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // Primera elección: preset P1S llena el form; "Guardar" crea la
        // default SIN auto-avance (queda en la página 2 con la tarjeta
        // saved).
        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-P1S')),
        );
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await tester.pumpAndSettle();

        // Tocar "editar" para reabrir el grid.
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('setup-printer-edit')));
        await tester.pumpAndSettle();
        // El colapsable "Impresoras populares" quedó plegado tras la primera
        // elección: reabrirlo para elegir otro preset.
        if (find
            .byKey(const ValueKey('setup-printer-preset-Bambu Lab-A1'))
            .evaluate()
            .isEmpty) {
          await tester.tap(find.text(EsBO.setupPrinterPopular));
          await tester.pumpAndSettle();
        }
        // Toca OTRO preset (A1) y "Guardar" ⇒ UPDATE SIN auto-avance
        // (colapsa a saved en la misma página 2).
        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-A1')),
        );
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.setupPrinterUpdated);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);

        // SnackBar de actualización + vuelta a la tarjeta saved.
        expect(find.text(EsBO.setupPrinterUpdated), findsOneWidget);
        await _goToPage(tester, 2);
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );
        expect(find.text('A1'), findsWidgets);

        // Una sola printer en DB, actualizada con el nuevo preset.
        final printers = container.read(printersNotifierProvider).value;
        expect(printers, hasLength(1));
        final printer = printers!.single;
        expect(printer.name, 'A1');
        expect(printer.brand, 'Bambu Lab');
        expect(printer.isDefault, isTrue);
      },
    );

    testWidgets(
      'impresora: edición custom con dropdown válido ⇒ updatePrinter + '
      'SnackBar setupPrinterUpdated + colapso a tarjeta saved',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // "Personalizada" completa + "Guardar" ⇒ create SIN auto-avance.
        await tester.tap(find.byKey(const ValueKey('setup-printer-custom')));
        await tester.pumpAndSettle();
        await _selectCatalogPrinter(tester, 'Elegoo', 'Neptune 4 Pro');
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);

        // El watch de defaultPrinterProvider reconstruye el paso en estado
        // saved en el lugar (sin auto-avance).
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('setup-printer-edit')));
        await tester.pumpAndSettle();
        await _selectCatalogPrinter(tester, 'Bambu Lab', 'A1');
        // Editar el form deja el borrador sucio; "Guardar" persiste el
        // update.
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.setupPrinterUpdated);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[2]);

        // Colapsa a la tarjeta saved con el nombre nuevo + SnackBar.
        expect(find.text(EsBO.setupPrinterUpdated), findsOneWidget);
        await _goToPage(tester, 2);
        expect(
          find.byKey(const ValueKey('setup-printer-edit')),
          findsOneWidget,
        );
        expect(find.text('A1'), findsWidgets);

        final printers = container.read(printersNotifierProvider).value;
        expect(printers, hasLength(1));
        final printer = printers!.single;
        expect(printer.name, 'A1');
        expect(printer.brand, 'Bambu Lab');
        expect(printer.isDefault, isTrue);
      },
    );

    testWidgets(
      'impresora: HIGH-1 — editar SOLO el costo de compra hace update '
      '(antes se descartaba) y vaciarlo limpia la amortización',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // Registro inicial con costo (preset + "Otros datos").
        await tester.tap(
          find.byKey(const ValueKey('setup-printer-preset-Bambu Lab-P1S')),
        );
        await tester.pumpAndSettle();
        final extra = find.byKey(const ValueKey('setup-printer-extra'));
        await tester.ensureVisible(extra);
        await tester.tap(extra);
        await tester.pumpAndSettle();
        final costField = find.byKey(
          const ValueKey('setup-printer-custom-cost'),
        );
        await tester.ensureVisible(costField);
        await tester.enterText(costField, '200');
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.configPrinterSaved);
        await tester.pumpAndSettle();
        expect(
          container.read(printersNotifierProvider).value!.single.purchaseCost,
          closeTo(200.0, 0.0001),
        );

        // Editar SOLO el costo: sin el fix (purchaseCost ausente del check
        // `changed`) no había update ni SnackBar.
        await _pumpPastSnackBars(tester);
        await tester.tap(find.byKey(const ValueKey('setup-printer-edit')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(extra);
        await tester.tap(extra);
        await tester.pumpAndSettle();
        await tester.ensureVisible(costField);
        await tester.enterText(costField, '350');
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.setupPrinterUpdated);
        await tester.pumpAndSettle();
        expect(find.text(EsBO.setupPrinterUpdated), findsOneWidget);
        expect(container.read(printersNotifierProvider).value, hasLength(1));
        expect(
          container.read(printersNotifierProvider).value!.single.purchaseCost,
          closeTo(350.0, 0.0001),
          reason: 'el cambio SOLO de costo debe persistir (HIGH-1)',
        );

        // Vaciar el costo limpia la amortización (clearAmortization).
        await _pumpPastSnackBars(tester);
        await tester.tap(find.byKey(const ValueKey('setup-printer-edit')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(extra);
        await tester.tap(extra);
        await tester.pumpAndSettle();
        await tester.ensureVisible(costField);
        await tester.enterText(costField, '');
        await tester.pumpAndSettle();
        await _tapPrinterSave(tester);
        await _pumpUntilText(tester, EsBO.setupPrinterUpdated);
        await tester.pumpAndSettle();
        expect(
          container.read(printersNotifierProvider).value!.single.purchaseCost,
          isNull,
          reason: 'vaciar el costo debe poder (clearAmortization)',
        );
      },
    );

    testWidgets(
      'impresora: MED-2 — el borrador del form sobrevive a re-montar el '
      'step (app "matada" a mitad de escritura)',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _goToPage(tester, 2);

        // Escribe en el form SIN completarlo (sin marca/modelo ⇒ el commit
        // al navegar es no-op y no se crea la impresora).
        await tester.tap(find.byKey(const ValueKey('setup-printer-custom')));
        await tester.pumpAndSettle();
        final wattsField = find.byKey(
          const ValueKey('setup-printer-custom-watts'),
        );
        await tester.ensureVisible(wattsField);
        await tester.enterText(wattsField, '555');
        await tester.pumpAndSettle();

        // Navega away y vuelve: el PageView desmonta/remonta el step y el
        // form debe restaurarse desde el borrador persistido en prefs.
        await _goToPage(tester, 1);
        await tester.pumpAndSettle();
        expect(container.read(printersNotifierProvider).value, isEmpty);
        await _goToPage(tester, 2);
        await tester.pumpAndSettle();

        final restoredWatts = find.descendant(
          of: wattsField,
          matching: find.byType(TextField),
        );
        expect(
          tester.widget<TextField>(restoredWatts).controller!.text,
          '555',
          reason: 'el borrador debe restaurar lo tipeado al re-montar',
        );
      },
    );

    testWidgets(
      'flujo sin "Guardar" (AC-07); "Siguiente"/"Atrás" discretos en pasos '
      '1-2 (cambio 2026-10-11)',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());

        for (final page in [1, 2]) {
          await _goToPage(tester, page);
          expect(
            find.text('Guardar'),
            findsNothing,
            reason: 'no debe haber "Guardar" en la página $page',
          );
          expect(
            find.text('Siguiente'),
            findsOneWidget,
            reason: '"Siguiente" discreto en la barra inferior ($page)',
          );
          expect(
            find.text('Atrás'),
            findsOneWidget,
            reason: '"Atrás" discreto en la barra inferior ($page)',
          );
        }
      },
    );
    testWidgets(
      'grid de presets adaptivo: ventana delgada (360) ⇒ 2 columnas con '
      'tarjetas a media anchura',
      (tester) async {
        await _pumpSetup(
          tester,
          router: _buildTestRouter(),
          viewport: const Size(360, 2000),
        );
        await _goToPage(tester, 2);

        // Contenido = 360 − 2×24 (padding xxl) − 2×16 (childrenPadding del
        // colapsable) = 280; 2 columnas con gap 12 → cada tarjeta
        // (280 − 12) / 2 = 134 de ancho.
        final card = find.byKey(
          const ValueKey('setup-printer-preset-Bambu Lab-A1'),
        );
        expect(tester.getSize(card).width, 134);
        // Las dos primeras de la fila comparten el mismo top (2 columnas).
        final combo = find.byKey(
          const ValueKey('setup-printer-preset-Bambu Lab-A1 Combo'),
        );
        expect(
          tester.getTopLeft(card).dy,
          tester.getTopLeft(combo).dy,
          reason: 'A1 y A1 Combo deben estar en la misma fila',
        );
      },
    );

    testWidgets(
      'grid de presets adaptivo: ventana extrema (320) ⇒ 1 columna a ancho '
      'completo',
      (tester) async {
        await _pumpSetup(
          tester,
          router: _buildTestRouter(),
          viewport: const Size(320, 2000),
        );
        await _goToPage(tester, 2);

        // Contenido = 320 − 48 (padding xxl) − 32 (childrenPadding del
        // colapsable) = 240 (< 280) → 1 sola columna, ancho total.
        final card = find.byKey(
          const ValueKey('setup-printer-preset-Bambu Lab-A1'),
        );
        expect(tester.getSize(card).width, 240);
        final combo = find.byKey(
          const ValueKey('setup-printer-preset-Bambu Lab-A1 Combo'),
        );
        expect(
          tester.getTopLeft(combo).dy,
          greaterThan(tester.getBottomRight(card).dy),
          reason: 'A1 Combo debe ir debajo de A1 (1 columna)',
        );
      },
    );
  });

  group('Setup steps Fase 3', () {
    /// Navega al cierre (página 5): no hay pill para el cierre (solo 5
    /// pills, índices 0–4), se llega con un swipe hacia adelante desde la
    /// página 4. Requiere printer+filament registrados (gate de
    /// obligatoriedad).
    Future<void> swipeToClosing(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await _registerPrinter(container);
      await _registerFilament(container);
      await tester.pumpAndSettle();
      await _goToPage(tester, 4);
      await tester.drag(find.byType(PageView), const Offset(-900, 0));
      await tester.pumpAndSettle();
    }

    /// Arrastra el slider [finder] desde el pulgar (value actual) la
    /// cantidad de divisiones [divisions]. El tap del tester sobre la pista
    /// salta el valor a la posición tocada; arrancar desde el pulgar (en el
    /// borde izquierdo) mantiene el cálculo determinista. El dx tiene que
    /// superar el kTouchSlop (~18 px) del DragGestureRecognizer o el
    /// gesto degrada a tap y el valor no se mueve.
    Future<void> dragSlider(
      WidgetTester tester,
      Finder finder,
      double divisions, {
      double totalDivisions = 50,
    }) async {
      final topLeft = tester.getTopLeft(finder);
      final size = tester.getSize(finder);
      // El pulgar (thumbRadius 12) recorre [left+12, right-12].
      await tester.dragFrom(
        topLeft + Offset(12, size.height / 2),
        Offset((size.width - 24) * divisions / totalDivisions, 0),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('filamento: marca + precio + color ⇒ auto-create default '
        '(nombre auto "Sunlu 1000g" — alias vacío NO se mezcla con la marca, '
        'grams 1000) SIN auto-avance; "Siguiente" avanza a ganancia', (
      tester,
    ) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      // El gate exige printer para llegar al paso filamento.
      await _registerPrinter(container);
      await tester.pumpAndSettle();
      await _goToPage(tester, 3);

      await tester.tap(
        find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('setup-filament-price')),
        '125',
      );
      final redSwatch = find.bySemanticsLabel(EsBO.colorNameRed);
      await tester.ensureVisible(redSwatch);
      await tester.tap(redSwatch);
      await tester.pumpAndSettle();
      // Sin auto-guard: el borrador se persiste al tocar "Guardar" (o al
      // navegar).
      await _tapFilamentSave(tester);
      await _pumpUntilText(tester, EsBO.configFilamentSaved);
      await tester.pumpAndSettle();

      // Sin auto-avance (cambio 2026-10-11): el flujo queda en la página 3
      // con la tarjeta saved.
      expect(
        _gradientColor(tester),
        AppTheme.onboardingSlideColors[3],
        reason: 'registrar el filamento NO debe auto-avanzar',
      );
      // Alias vacío ⇒ auto-generado "${marca} ${gramos}g" (el alias NO se
      // precarga con la marca: bug 2026-10-11). Tarjeta saved: header con
      // el nombre auto + fila de marca 'Sunlu'.
      expect(find.text('Sunlu 1000g'), findsOneWidget);
      expect(find.text('Sunlu'), findsOneWidget);
      expect(find.byKey(const ValueKey('setup-filament-edit')), findsOneWidget);

      // DB row via notifier state (no solo prefs).
      final filaments = container.read(filamentsNotifierProvider).value;
      expect(filaments, hasLength(1));
      final filament = filaments!.single;
      expect(filament.name, 'Sunlu 1000g');
      expect(filament.brand, 'Sunlu');
      expect(filament.pricePerBobbin, 125);
      expect(filament.gramsPerBobbin, 1000);
      expect(filament.isDefault, isTrue);
      expect(filament.color, isNotNull, reason: 'color elegido persistido');

      // "Siguiente" avanza al paso ganancia (página 4 ⇒ índice de color 0).
      // El SnackBar de éxito (2 s) tapa la barra: esperar su salida.
      await _pumpPastSnackBars(tester);
      await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
      await tester.pumpAndSettle();
      expect(_gradientColor(tester), AppTheme.onboardingSlideColors[0]);
      expect(find.text(EsBO.setupProfitTitle), findsOneWidget);

      // Volver al paso filamento ⇒ estado saved (check + nombre + editar).
      await _goToPage(tester, 3);
      expect(find.text('Sunlu 1000g'), findsOneWidget);
      expect(find.text('Sunlu'), findsOneWidget);
      expect(find.byKey(const ValueKey('setup-filament-edit')), findsOneWidget);
    });

    testWidgets(
      'filamento: re-entrar con default existente ⇒ estado saved (AC-13)',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        // Default pre-existente (reanudación: kill+reopen).
        await _registerFilament(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        expect(find.text('Sunlu 1000g'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('setup-filament-edit')),
          findsOneWidget,
        );
        // Sin formulario: el estado guardado reemplaza al form.
        expect(
          find.byKey(const ValueKey('setup-filament-price')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'filamento: chip "Otro..." limpia la marca, resalta el chip y enfoca '
      'el campo manual (bug 2026-10-11: "no hacía nada")',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        // Selecciona un chip known primero (escenario del bug: el campo
        // manual aparecía con esa marca adentro, idéntico a la vista previa).
        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-other')),
        );
        await tester.pumpAndSettle();

        // Campo visible, vacío y con el foco (teclado abierto).
        final manual = find.byKey(const ValueKey('setup-filament-brand-field'));
        expect(manual, findsOneWidget);
        final field = tester.widget<TextField>(manual);
        expect(field.controller!.text, isEmpty);
        expect(
          field.focusNode?.hasFocus,
          isTrue,
          reason: 'el campo manual debe tener el foco tras tocar "Otro..."',
        );

        // El chip "Otro..." queda resaltado (modo manual activo) y el chip
        // known pierde la selección.
        final other = tester.widget<SetupChip>(
          find.byKey(const ValueKey('setup-filament-brand-other')),
        );
        expect(other.selected, isTrue);
        expect(
          tester
              .widget<SetupChip>(
                find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
              )
              .selected,
          isFalse,
        );

        // Escribir la marca manual + alias + precio y guardar persiste los
        // DOS campos (marca "Marca Custom" ≠ alias "PLA Negro"; pedido del
        // usuario 2026-10-11: son 2 campos, no 1).
        await tester.enterText(manual, 'Creality');
        await tester.pumpAndSettle();
        // Alias vacío en modo manual ⇒ sin "Guardar" (ambos obligatorios).
        expect(find.byKey(const ValueKey('setup-filament-save')), findsNothing);
        await tester.enterText(
          find.byKey(const ValueKey('setup-filament-name')),
          'PLA Negro',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('setup-filament-price')),
          '90',
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('setup-filament-save')),
          findsOneWidget,
        );
        await _tapFilamentSave(tester);
        await _pumpUntilText(tester, EsBO.configFilamentSaved);

        final filaments = container.read(filamentsNotifierProvider).value;
        expect(filaments, hasLength(1));
        expect(filaments!.single.brand, 'Creality');
        expect(filaments.single.name, 'PLA Negro');
      },
    );

    testWidgets(
      'filamento: volver de "Otro..." a un chip known deja la marca en '
      'solo-lectura (los 2 campos siguen visibles)',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-other')),
        );
        await tester.pumpAndSettle();
        final brandField = find.byKey(
          const ValueKey('setup-filament-brand-field'),
        );
        expect(brandField, findsOneWidget);
        expect(tester.widget<TextField>(brandField).readOnly, isFalse);

        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();
        // El campo de marca SIGUE visible pero en solo-lectura (lo llena
        // el chip) — usuario 2026-10-11: marca y alias son 2 campos.
        expect(brandField, findsOneWidget);
        final field = tester.widget<TextField>(brandField);
        expect(field.readOnly, isTrue);
        expect(field.controller!.text, 'Sunlu');
        expect(
          tester
              .widget<SetupChip>(
                find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
              )
              .selected,
          isTrue,
        );
      },
    );

    testWidgets(
      'filamento: gate — avanzar sin filamento está BLOQUEADO (snap-back + '
      'hint); el enlace "lo agrego después" ya no existe',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        // El enlace de skip fue eliminado del flujo nuevo.
        expect(find.text('Lo agrego después'), findsNothing);
        expect(
          find.byKey(const ValueKey('setup-filament-add-later')),
          findsNothing,
        );

        // Swipe adelante sin filamento ⇒ snap-back a la página 3 + hint.
        // El drag arranca en zona no interactiva (arriba): la paleta de
        // colores del form gana el gesto horizontal en el centro.
        final area = find.byType(PageView);
        await tester.dragFrom(
          tester.getTopLeft(area) + Offset(tester.getSize(area).width / 2, 48),
          const Offset(-900, 0),
        );
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(find.text(EsBO.setupNeedFilament), findsOneWidget);
        expect(find.text(EsBO.setupProfitTitle), findsNothing);
        expect(container.read(filamentsNotifierProvider).value, isEmpty);

        // "Guardar" persiste el filamento SIN auto-avance: el paso queda en
        // la página 3 con la tarjeta saved; recién entonces "Siguiente"
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
        await _tapFilamentSave(tester);
        await _pumpUntilText(tester, EsBO.configFilamentSaved);
        await tester.pumpAndSettle();
        expect(_gradientColor(tester), AppTheme.onboardingSlideColors[3]);
        expect(find.text(EsBO.setupProfitTitle), findsNothing);
        // El SnackBar de éxito (2 s) tapa la barra: esperar su salida.
        await _pumpPastSnackBars(tester);
        await tester.tap(find.byKey(const ValueKey('setup-nav-next')));
        await tester.pumpAndSettle();
        expect(find.text(EsBO.setupProfitTitle), findsOneWidget);
      },
    );

    testWidgets(
      'filamento: "Guardar" solo aparece con marca+precio+gramos válidos',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        // Borrador vacío: sin "Guardar" y sin filamento en DB.
        expect(find.byKey(const ValueKey('setup-filament-save')), findsNothing);

        // Marca sola (sin precio) tampoco habilita el guardado.
        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('setup-filament-save')), findsNothing);

        // Precio válido ⇒ "Guardar" aparece (aún sin persistir).
        await tester.enterText(
          find.byKey(const ValueKey('setup-filament-price')),
          '125',
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('setup-filament-save')),
          findsOneWidget,
        );
        expect(container.read(filamentsNotifierProvider).value, isEmpty);
      },
    );

    testWidgets(
      'filamento: MED-2 — el borrador del form sobrevive a re-montar el '
      'step (marca restaurada en solo-lectura, alias sin mezclar)',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        // Chip de marca + alias vacío, SIN precio ⇒ incompleto (el
        // commit al navegar es no-op y no se crea el filamento).
        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();

        await _goToPage(tester, 2);
        await tester.pumpAndSettle();
        expect(container.read(filamentsNotifierProvider).value, isEmpty);
        await _goToPage(tester, 3);
        await tester.pumpAndSettle();

        // El chip de marca sigue seleccionado, el campo de marca restaura
        // "Sunlu" (solo-lectura) y el alias queda vacío — ya NO se
        // precarga con la marca (bug 2026-10-11: los 2 campos se veían
        // como 1).
        expect(
          tester
              .widget<SetupChip>(
                find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
              )
              .selected,
          isTrue,
          reason: 'el borrador debe restaurar la marca al re-montar',
        );
        final brandField = tester.widget<TextField>(
          find.byKey(const ValueKey('setup-filament-brand-field')),
        );
        expect(brandField.controller!.text, 'Sunlu');
        expect(brandField.readOnly, isTrue);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('setup-filament-name')),
              )
              .controller!
              .text,
          isEmpty,
          reason: 'el alias no se mezcla con la marca (queda vacío)',
        );
      },
    );

    testWidgets(
      'filamento: error de persistencia ⇒ SnackBar filamentErrorSave y sin '
      'fila en DB',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        // Trigger que rechaza el INSERT (patrón del viejo
        // initial_config_stepper_test: el error da feedback y no deja el
        // botón colgado).
        await container
            .read(appDatabaseProvider)
            .customStatement(
              'CREATE TRIGGER reject_filament BEFORE INSERT ON filaments '
              "BEGIN SELECT RAISE(ABORT, 'test persistence failure'); END",
            );

        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('setup-filament-price')),
          '125',
        );
        await tester.pumpAndSettle();
        await _tapFilamentSave(tester);
        await _pumpUntilText(tester, EsBO.filamentErrorSave);
        await tester.pumpAndSettle();

        expect(find.text(EsBO.filamentErrorSave), findsOneWidget);
        expect(container.read(filamentsNotifierProvider).value, isEmpty);
        // El botón "Guardar" vuelve a quedar habilitado (_saving reseteado
        // en el finally del commit).
        expect(
          find.byKey(const ValueKey('setup-filament-save')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ganancia: slider persiste en settings + input numérico sincronizado',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await _registerFilament(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 4);
        await tester.pumpAndSettle();

        // Primer arranque: el paso siembra valores de ejemplo (ganancia
        // 200 %) y los persiste como punto de partida.
        expect(
          container.read(settingsNotifierProvider).value!.profitBase,
          Decimal.fromInt(200),
        );
        // El chip "Típico" vive solo en Ajustes (no en el setup).
        expect(find.text('Típico'), findsNothing);

        // Ambas cards (ganancia y kWh) están expandidas por defecto ⇒ dos
        // sliders; el de ganancia es el primero.
        expect(find.byType(Slider), findsNWidgets(2));
        final profitSlider = find.byType(Slider).first;
        // +5 divisiones (dx > kTouchSlop para que sea drag, no tap). El
        // kTouchSlop se come un poco de precisión, así que el valor
        // esperado se deriva del slider resultante y se valida la
        // persistencia 1:1 contra settings.
        await dragSlider(tester, profitSlider, 5);

        final sliderValue = tester.widget<Slider>(profitSlider).value;
        expect(sliderValue, greaterThan(0), reason: 'el slider se movió');
        final settings = container.read(settingsNotifierProvider).value!;
        expect(settings.profitBase, Decimal.fromInt(sliderValue.round()));

        // Campo numérico sincronizado: 40 ⇒ settings + slider.
        await tester.enterText(
          find.byKey(const ValueKey('setup-profit-input')),
          '40',
        );
        // Tap fuera del field dispara onBlur (persiste + sincroniza slider).
        await tester.tap(find.text(EsBO.setupProfitTitle));
        await tester.pumpAndSettle();

        expect(
          container.read(settingsNotifierProvider).value!.profitBase,
          Decimal.fromInt(40),
        );
        expect(tester.widget<Slider>(profitSlider).value, 40);
      },
    );

    testWidgets('ganancia: reanudación (AC-13) lee settings persistidos', (
      tester,
    ) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      await _registerPrinter(container);
      await _registerFilament(container);
      // Esperar el build del notifier ANTES de mutar: sin este await, la
      // race build-vs-update pisaría el valor recién escrito.
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .updateProfitBase(Decimal.fromInt(30));
      await tester.pumpAndSettle();

      await _goToPage(tester, 4);
      await tester.pumpAndSettle();

      expect(
        tester.widget<Slider>(find.byType(Slider).first).value,
        30,
        reason: 'el slider se inicializa desde settings, no desde 0',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('setup-profit-input')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '30',
      );
    });

    testWidgets(
      'kWh: sección expandida por defecto; colapsar/expandir y cambiar '
      'persiste',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await _registerFilament(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 4);
        await tester.pumpAndSettle();

        // Expandido por defecto (usuario 2026-10-11): sliders de ganancia
        // y kWh construidos.
        expect(find.byType(Slider), findsNWidgets(2));

        // Colapsar oculta su slider; expandir lo vuelve a construir (el
        // valor vive en el state del step, no en el slider). El tap va al
        // header (icono): el centro del ExpansionTile expandido cae sobre
        // el slider y lo movería.
        final kwhHeader = find.descendant(
          of: find.byKey(const ValueKey('setup-kwh-section')),
          matching: find.byIcon(Icons.bolt_rounded),
        );
        await tester.tap(kwhHeader);
        await tester.pumpAndSettle();
        expect(find.byType(Slider), findsOneWidget);
        await tester.tap(kwhHeader);
        await tester.pumpAndSettle();
        expect(find.byType(Slider), findsNWidgets(2));

        // +25 divisiones sobre 0–5 ⇒ ~2.5 (la persistencia es 1:1 con el
        // valor final del slider; ver nota de kTouchSlop arriba).
        await dragSlider(tester, find.byType(Slider).last, 25);
        final kwhValue = tester.widget<Slider>(find.byType(Slider).last).value;
        expect(kwhValue, greaterThan(0), reason: 'el slider kWh se movió');
        expect(
          container.read(settingsNotifierProvider).value!.kwhRate,
          Decimal.parse(kwhValue.toStringAsFixed(2)),
        );
      },
    );

    testWidgets('cierre: resumen muestra lo configurado (ganancia/kWh con '
        'valores de ejemplo, sin pendientes)', (tester) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      // Con el gate, printer+filament siempre están registrados para
      // llegar al cierre; solo ganancia y kWh quedan pendientes.
      await swipeToClosing(tester, container);

      expect(find.text(EsBO.setupDoneTitle), findsOneWidget);
      expect(find.text('Sunlu 1000g'), findsOneWidget, reason: 'filamento');
      expect(find.text('P1S'), findsOneWidget, reason: 'impresora');
      // Sin "pendientes": el gate obliga a printer/filamento y el paso de
      // ganancia siembra valores de ejemplo (200 % / 1.00) al primer
      // arranque. La moneda sigue en el default USD (el paso 1 no se
      // visitó: la pill salta directo al paso 4).
      expect(find.text(EsBO.setupTicketPending), findsNothing);
      expect(find.text('200 %'), findsOneWidget, reason: 'ganancia ejemplo');
      expect(
        find.text(r'1 $/kWh'),
        findsOneWidget,
        reason: 'kWh ejemplo con moneda USD',
      );
    });

    testWidgets(
      'cierre: tap CTA ⇒ onboardingDone=true + Home + calculador (stack '
      'limpio)',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await swipeToClosing(tester, container);

        await tester.tap(find.byKey(const ValueKey('setup-finish-button')));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);
        // Calculador abierto encima del Home.
        expect(find.text('calculator-marker'), findsOneWidget);

        // Back del sistema desde el calculador → Home (nunca el setup).
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('home-marker'), findsOneWidget);
        expect(find.byType(SetupFlowPage), findsNothing);
      },
    );

    testWidgets('flujo sin "Guardar" (AC-07); barra nav en pasos 3-4 y '
        'sin barra en el cierre (cambio 2026-10-11)', (tester) async {
      final container = await _pumpSetup(tester, router: _buildTestRouter());
      await _registerPrinter(container);
      await _registerFilament(container);
      await tester.pumpAndSettle();

      for (final page in [3, 4]) {
        await _goToPage(tester, page);
        expect(
          find.text('Guardar'),
          findsNothing,
          reason: 'no debe haber "Guardar" en la página $page',
        );
        expect(
          find.text('Siguiente'),
          findsOneWidget,
          reason: '"Siguiente" discreto en la barra inferior ($page)',
        );
        expect(
          find.text('Atrás'),
          findsOneWidget,
          reason: '"Atrás" discreto en la barra inferior ($page)',
        );
      }
      // El cierre (página 5) se alcanza por swipe (sin pill propia) y no
      // muestra la barra (ni "Siguiente" ni "Atrás"): su CTA es el final.
      await _goToPage(tester, 4);
      await tester.drag(find.byType(PageView), const Offset(-900, 0));
      await tester.pumpAndSettle();
      expect(find.text(EsBO.setupDoneTitle), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
      expect(find.text('Siguiente'), findsNothing);
      expect(find.text('Atrás'), findsNothing);
    });
  });

  group('Setup steps contraste (validación 2026-10-11)', () {
    testWidgets(
      'chips de marca del filamento: texto onSurface opaco (no blanco) sobre '
      'fondo opaco — AA sobre el gradiente',
      (tester) async {
        final container = await _pumpSetup(tester, router: _buildTestRouter());
        await _registerPrinter(container);
        await tester.pumpAndSettle();
        await _goToPage(tester, 3);

        // Chip no seleccionado: label usa colorScheme.onSurface (opaco),
        // nunca blanco puro sobre fondo translúcido (bug reportado).
        final chipText = tester.widget<Text>(find.text('Sunlu'));
        final onSurface = Theme.of(
          tester.element(find.text('Sunlu')),
        ).colorScheme.onSurface;
        expect(chipText.style?.color, onSurface);
        expect(chipText.style?.color, isNot(Colors.white));

        // Seleccionado: label onPrimaryContainer (fondo primaryContainer).
        // El nombre opcional se pre-carga con la marca: acotar el finder al
        // Text del chip (find.text también matchea el contenido del
        // TextField).
        await tester.tap(
          find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
        );
        await tester.pumpAndSettle();
        final selectedChipText = find.descendant(
          of: find.byKey(const ValueKey('setup-filament-brand-Sunlu')),
          matching: find.text('Sunlu'),
        );
        final selectedText = tester.widget<Text>(selectedChipText);
        final onPrimaryContainer = Theme.of(
          tester.element(selectedChipText),
        ).colorScheme.onPrimaryContainer;
        expect(selectedText.style?.color, onPrimaryContainer);
      },
    );

    testWidgets(
      'chips de moneda: texto onSurface opaco en el chip no seleccionado',
      (tester) async {
        await _pumpSetup(tester, router: _buildTestRouter());
        // Moneda sugerida para es = BOB; USD queda no seleccionado.
        await _goToPage(tester, 1);

        final usdText = tester.widget<Text>(find.text(r'$ USD'));
        final onSurface = Theme.of(
          tester.element(find.text(r'$ USD')),
        ).colorScheme.onSurface;
        expect(usdText.style?.color, onSurface);
        expect(usdText.style?.color, isNot(Colors.white));

        // Seleccionado (BOB auto-por-locale): texto onPrimaryContainer.
        final bobChip = find.text('${WorldCurrency.bob.symbol} BOB');
        final bobText = tester.widget<Text>(bobChip);
        final onPrimaryContainer = Theme.of(
          tester.element(bobChip),
        ).colorScheme.onPrimaryContainer;
        expect(bobText.style?.color, onPrimaryContainer);
      },
    );
  });
}
