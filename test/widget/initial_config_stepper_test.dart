// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/money/currency_settings_provider.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import 'package:tresdcal/features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import 'package:tresdcal/features/onboarding/presentation/pages/initial_config_page.dart';

Future<ProviderContainer> _pumpStepper(
  WidgetTester tester, {
  GoRouter? router,
}) async {
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
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: router != null
          ? MaterialApp.router(routerConfig: router)
          : const MaterialApp(home: InitialConfigPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('InitialConfigPage stepper', () {
    testWidgets('paso 1 muestra idioma + moneda', (tester) async {
      await _pumpStepper(tester);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Moneda'), findsOneWidget);
      // Boton Continuar habilitado (paso 1 siempre permite avanzar).
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuar'),
      );
      expect(btn.onPressed != null, isTrue);
    });

    testWidgets(
      'paso 2: Continuar deshabilitado sin impresora, se habilita al guardar',
      (tester) async {
        final container = await _pumpStepper(tester);
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Paso 2: titulo de secciones impresora/filamento visibles.
        expect(find.text('Impresora (requerida)'), findsOneWidget);
        expect(find.text('Filamento (opcional)'), findsOneWidget);
        // Sin impresora guardada el boton Continuar esta deshabilitado.
        final btn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continuar'),
        );
        expect(btn.onPressed == null, isTrue);

        // Completo el formulario de impresora y guardo.
        await tester.enterText(
          find.widgetWithText(TextField, 'Modelo'),
          'Ender 3',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Consumo promedio (W)'),
          '180',
        );
        await tester.pump();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Guardar').first,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
        await tester.pumpAndSettle();

        // Impresora persistida en el notifier.
        final printers = await container.read(printersNotifierProvider.future);
        expect(printers, hasLength(1));
        expect(printers.first.name, 'Ender 3');
        expect(printers.first.averageWatts, 180);

        // Continuar habilitado de nuevo.
        final btn2 = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continuar'),
        );
        expect(btn2.onPressed != null, isTrue);
      },
    );

    testWidgets(
      'paso 2: filamento opcional se puede saltear con "Lo agrego después"',
      (tester) async {
        final container = await _pumpStepper(tester);
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Guardo impresora para habilitar Continuar.
        await tester.enterText(
          find.widgetWithText(TextField, 'Modelo'),
          'Ender 3',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Consumo promedio (W)'),
          '180',
        );
        await tester.pump();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Guardar').first,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
        await tester.pumpAndSettle();

        // Salto el filamento.
        await tester.ensureVisible(find.text('Lo agrego después'));
        await tester.tap(find.text('Lo agrego después'));
        await tester.pumpAndSettle();
        expect(find.text('Filamento (opcional)'), findsOneWidget);

        // Continuar → paso 3.
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('Ganancia base (%)'), findsWidgets);

        // Sin filamento creado.
        final filaments = await container.read(
          filamentsNotifierProvider.future,
        );
        expect(filaments, isEmpty);
      },
    );

    testWidgets('paso 2: filamento se puede agregar en el momento', (
      tester,
    ) async {
      final container = await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Modelo'),
        'Ender 3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '180',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Guardar').first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(TextField, 'Nombre'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'PLA Pro',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Precio filamento (\$)'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Precio filamento (\$)'),
        '120',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Gramos por rollo'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Gramos por rollo'),
        '1000',
      );
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      final filaments = await container.read(filamentsNotifierProvider.future);
      expect(filaments, hasLength(1));
      expect(filaments.first.name, 'PLA Pro');
    });

    testWidgets('paso 3: ganancia y energia precargadas con defaults', (
      tester,
    ) async {
      final container = await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      // Impresora requerida para avanzar al paso 3.
      await tester.enterText(
        find.widgetWithText(TextField, 'Modelo'),
        'Ender 3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '180',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Guardar').first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Ganancia base (%)'), findsWidgets);
      final currency = container.read(selectedCurrencyProvider);
      expect(
        find.text('Tarifa electrica (${currency.symbol}/kWh)'),
        findsWidgets,
      );
      // Defaults 200% y 0.70 en los inputs.
      expect(find.widgetWithText(TextField, '200'), findsOneWidget);
      expect(find.widgetWithText(TextField, '0.7'), findsOneWidget);
    });

    testWidgets('paso 2: dropdown impresora muestra marcas de impresoras y NO '
        'marcas exclusivas de filamentos', (tester) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // En el paso 2, la sub-seccion impresora tiene un
      // BrandSelectorField (domain: printer).
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsWidgets);

      // Abre el dropdown de impresora (el primero).
      await tester.tap(dropdown.first);
      await tester.pumpAndSettle();

      // Marcas de impresoras visibles en el slice del menu: presentes.
      // (default skipOffstage=true → solo items onstage del menu abierto).
      expect(find.text('Anycubic', skipOffstage: true), findsWidgets);
      expect(find.text('Creality', skipOffstage: true), findsWidgets);
      expect(find.text('Bambu Lab', skipOffstage: true), findsWidgets);
      expect(find.text('Elegoo', skipOffstage: true), findsWidgets);

      // Marcas exclusivas de filamentos: ausentes (el dropdown de filamento
      // cerrado tiene sus items offstage → skiped por skipOffstage default).
      expect(find.text('Hatchbox'), findsNothing);
      expect(find.text('Polymaker'), findsNothing);
      expect(find.text('Prusament'), findsNothing);
      expect(find.text('Sunlu'), findsNothing);
      expect(find.text('Eryone'), findsNothing);
      expect(find.text('Kingroon'), findsNothing);
      expect(find.text('eSun'), findsNothing);
      expect(find.text('Amolen'), findsNothing);
    });

    testWidgets('paso 2: dropdown filamento muestra marcas de filamentos y NO '
        'marcas exclusivas de impresoras', (tester) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Sub-seccion filamento: agregar en el momento para ver su dropdown.
      // La sub-seccion filament aparece debajo de la de impresora con su
      // propio BrandSelectorField (domain: filament).
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(
        dropdowns,
        findsNWidgets(2),
        reason: 'Impresora y filamento tienen cada uno su dropdown',
      );

      // Abre el segundo dropdown (el de filamento).
      await tester.ensureVisible(dropdowns.last);
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      // Marcas de filamentos visibles en el slice del menu: presentes.
      // (con 23 items el slice cubre el inicio del listado alfabetico).
      expect(find.text('Amolen', skipOffstage: true), findsWidgets);
      expect(find.text('Anycubic', skipOffstage: true), findsWidgets);
      expect(find.text('Bambu Lab', skipOffstage: true), findsWidgets);
      expect(find.text('Creality', skipOffstage: true), findsWidgets);

      // Marcas exclusivas de impresoras: ausentes (dropdown de impresora
      // cerrado tiene sus items offstage → skiped por skipOffstage default).
      // Nota: solo printer-only; los duales (Creality, Anycubic, Geeetech,
      // Bambu Lab...) SI estan en filament.
      expect(find.text('Voron'), findsNothing);
      expect(find.text('Artillery'), findsNothing);
      expect(find.text('MakerBot'), findsNothing);
      expect(find.text('FLSun'), findsNothing);
      expect(find.text('Ultimaker'), findsNothing);
    });

    testWidgets('paso 1: contador + LinearProgressIndicator en 1/3', (
      tester,
    ) async {
      await _pumpStepper(tester);

      // Contador "Paso X de 3" y barra de progreso con valor 1/3.
      expect(find.text('Paso 1 de 3'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(1 / 3, 0.001));
    });

    testWidgets('paso 1: microcopy helper de idioma y moneda visibles', (
      tester,
    ) async {
      await _pumpStepper(tester);
      expect(
        find.text('Elegí el idioma de la app. Podés cambiarlo después.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Moneda en que se muestran precios y cotizaciones. No convierte '
          'valores.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('paso 3: chip "Típico" con defaults y desaparece al cambiar', (
      tester,
    ) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Modelo'),
        'Ender 3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '180',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Guardar').first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Defaults 200% y 0.7 → ambos chips "Típico" visibles.
      expect(find.text('Típico'), findsNWidgets(2));

      // Cambio ganancia → desaparece su chip, queda el de kWh.
      await tester.enterText(find.widgetWithText(TextField, '200'), '150');
      await tester.pump();
      expect(find.text('Típico'), findsOneWidget);
    });

    testWidgets('paso 3: bloque Resumen muestra los 6 valores y botón final', (
      tester,
    ) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Modelo'),
        'Ender 3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '180',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Guardar').first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
      await tester.pumpAndSettle();

      // Agrego filamento en el momento para que aparezca en el resumen.
      await tester.ensureVisible(find.widgetWithText(TextField, 'Nombre'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'PLA Pro',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Precio filamento (\$)'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Precio filamento (\$)'),
        '120',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Gramos por rollo'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Gramos por rollo'),
        '1000',
      );
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Resumen: título, imprint y filas (labels = keys i18n exactas).
      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Tu próxima cotización:'), findsOneWidget);
      expect(find.text('Impresora (requerida)'), findsWidgets);
      expect(find.text('Filamento (opcional)'), findsWidgets);
      expect(find.text('Ender 3'), findsWidgets);
      expect(find.text('PLA Pro'), findsWidgets);

      // Botón final (configStartButton).
      expect(find.text('Empezar a cotizar'), findsOneWidget);
    });

    testWidgets('paso 3: finalizar persiste onboarding_done y navega a '
        '/onboarding', (tester) async {
      final router = GoRouter(
        initialLocation: '/config',
        routes: [
          GoRoute(
            path: '/config',
            builder: (_, _) => const InitialConfigPage(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const Scaffold(body: Text('onboarding')),
          ),
        ],
      );
      await _pumpStepper(tester, router: router);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Modelo'),
        'Ender 3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Consumo promedio (W)'),
        '180',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Guardar').first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Paso 3: botón final → persiste onboarding_done y navega a /onboarding.
      await tester.ensureVisible(find.text('Empezar a cotizar'));
      await tester.tap(find.text('Empezar a cotizar'));
      await tester.pumpAndSettle();

      expect(find.text('onboarding'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);
    });
  });
}
