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
  // Viewport mas alto para acomodar el form de filamento que ahora incluye
  // el campo color (RF1-2 del PRD 2026-09-08); el default 800x600 deja el
  // boton "Guardar" fuera de pantalla en algunos tests.
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

/// Selecciona marca + modelo del catalogo en el sub-form de impresora del
/// paso 2 (via los dropdowns del PrinterCatalogSelector).
Future<void> _selectPrinter(
  WidgetTester tester,
  String brand,
  String model,
) async {
  await tester.tap(find.byKey(const ValueKey('catalog-brand-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(brand).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('catalog-model-dropdown-$brand')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(model).last);
  await tester.pumpAndSettle();
}

void main() {
  group('InitialConfigPage stepper', () {
    testWidgets('paso 1 muestra tema (claro/oscuro) + moneda', (tester) async {
      await _pumpStepper(tester);
      // Tema: solo las dos opciones, sin "Sistema" en el setup.
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Sistema'), findsNothing);
      // Moneda debajo del tema.
      expect(find.text('Moneda'), findsOneWidget);
      // El idioma ya no se configura acá: vive en su propia pantalla previa.
      expect(find.text('Idioma'), findsNothing);
      // Boton Continuar habilitado (paso 1 siempre permite avanzar).
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuar'),
      );
      expect(btn.onPressed != null, isTrue);
    });

    testWidgets('paso 1: tocar la tarjeta Oscuro persiste theme_mode', (
      tester,
    ) async {
      await _pumpStepper(tester);

      // Sin preferencia previa → Claro seleccionado por defecto (2026-09).
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      // La tarjeta seleccionada muestra el check.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('paso 2: Continuar deshabilitado sin impresora ni filamento, '
        'se habilita al guardar ambos', (tester) async {
      final container = await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Paso 2: titulo de secciones impresora/filamento visibles.
      expect(find.text('Impresora (requerida)'), findsOneWidget);
      expect(find.text('Filamento (requerido)'), findsOneWidget);
      // Sin impresora ni filamento guardados el boton Continuar esta
      // deshabilitado.
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuar'),
      );
      expect(btn.onPressed == null, isTrue);

      // Completo el formulario de impresora y guardo.
      await _selectPrinter(tester, 'Creality', 'Ender-3');
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
      expect(printers.first.name, 'Ender-3');
      expect(printers.first.averageWatts, 180);

      // Solo impresora NO habilita Continuar: el filamento es requerido.
      final btnAfterPrinter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuar'),
      );
      expect(btnAfterPrinter.onPressed == null, isTrue);

      // Completo el formulario de filamento y guardo.
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

      // Filamento persistido.
      final filaments = await container.read(filamentsNotifierProvider.future);
      expect(filaments, hasLength(1));
      expect(filaments.first.name, 'PLA Pro');

      // Continuar habilitado de nuevo.
      final btn2 = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuar'),
      );
      expect(btn2.onPressed != null, isTrue);
    });

    testWidgets(
      'paso 2: error "Requerido" desaparece al llenar el input (BUG-017)',
      (tester) async {
        await _pumpStepper(tester);
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Intento guardar la impresora con campos vacíos → muestra errores.
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Guardar').first,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
        await tester.pumpAndSettle();
        expect(find.text('Requerido'), findsAtLeastNWidgets(1));

        // Completo marca/modelo + watts → los errores se limpian solos.
        await _selectPrinter(tester, 'Creality', 'Ender-3');
        await tester.enterText(
          find.widgetWithText(TextField, 'Consumo promedio (W)'),
          '180',
        );
        await tester.pumpAndSettle();
        expect(find.text('Requerido'), findsNothing);
      },
    );

    testWidgets(
      'paso 2: filamento es REQUERIDO (sin boton "Lo agrego después")',
      (tester) async {
        final container = await _pumpStepper(tester);
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // El titulo refleja que el filamento ya no es opcional.
        expect(find.text('Filamento (requerido)'), findsOneWidget);

        // Guardo impresora para habilitar Continuar.
        await _selectPrinter(tester, 'Creality', 'Ender-3');
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

        // Sin filamento, Continuar sigue deshabilitado (requerido).
        final btn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continuar'),
        );
        expect(btn.onPressed == null, isTrue);

        // El skip "Lo agrego después" fue eliminado del flujo.
        expect(find.text('Lo agrego después'), findsNothing);
        expect(find.text('Lo agrego despu�s'), findsNothing);

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

      await _selectPrinter(tester, 'Creality', 'Ender-3');
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

    testWidgets('paso 3: ganancia y energia VACIAS por default (0 = sin '
        'configurar)', (tester) async {
      final container = await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      // Impresora requerida para avanzar al paso 3.
      await _selectPrinter(tester, 'Creality', 'Ender-3');
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
      // Filamento requerido para avanzar al paso 3.
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

      expect(find.text('Ganancia base (%)'), findsWidgets);
      final currency = container.read(selectedCurrencyProvider);
      expect(
        find.text('Tarifa electrica (${currency.symbol}/kWh)'),
        findsWidgets,
      );
      // Defaults 0 → campos VACIOS (el usuario los define en Ajustes).
      expect(find.text('200'), findsNothing);
      expect(find.text('0.7'), findsNothing);
      // Los inputs de ganancia y tarifa estan vacios.
      expect(
        find.widgetWithText(TextField, 'Ganancia base (%)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          TextField,
          'Tarifa electrica (${currency.symbol}/kWh)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('paso 2: dropdown impresora muestra marcas de impresoras y NO '
        'marcas exclusivas de filamentos', (tester) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // En el paso 2, la sub-seccion impresora usa el PrinterCatalogSelector
      // cuyo dropdown de marca lista el catalogo de impresoras.
      final dropdown = find.byKey(const ValueKey('catalog-brand-dropdown'));
      expect(dropdown, findsWidgets);

      // Abre el dropdown de marca de impresora.
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
      // Nota: 'Kingroon' y 'Longer' ahora SI estan en el catalogo de
      // impresoras (ya no son exclusivas de filamento).
      expect(find.text('Hatchbox'), findsNothing);
      expect(find.text('Polymaker'), findsNothing);
      expect(find.text('Prusament'), findsNothing);
      expect(find.text('Sunlu'), findsNothing);
      expect(find.text('Eryone'), findsNothing);
      expect(find.text('Overture'), findsNothing);
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
      // propio BrandSelectorField (domain: filament). En total hay 3
      // dropdowns: marca de impresora, modelo (deshabilitado) y marca de
      // filamento.
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(
        dropdowns,
        findsNWidgets(3),
        reason: 'Marca/modelo de impresora + marca de filamento',
      );

      // Abre el ultimo dropdown (el de filamento).
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

    testWidgets('paso 1: microcopy helper de moneda visible', (tester) async {
      await _pumpStepper(tester);
      expect(
        find.text(
          'Moneda en que se muestran precios y cotizaciones. No convierte '
          'valores.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('paso 3: sin chip "Típico" (vive solo en Ajustes)', (
      tester,
    ) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await _selectPrinter(tester, 'Creality', 'Ender-3');
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
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // El onboarding NO ofrece el chip "Típico" (el usuario define sus
      // valores); el chip de valores sugeridos vive en Ajustes.
      expect(find.text('Típico'), findsNothing);
      expect(find.text('Tipico'), findsNothing);
    });

    testWidgets('paso 3: bloque Resumen muestra los 6 valores y botón final', (
      tester,
    ) async {
      await _pumpStepper(tester);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await _selectPrinter(tester, 'Creality', 'Ender-3');
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
      expect(find.text('Filamento (requerido)'), findsWidgets);
      expect(find.text('Ender-3'), findsWidgets);
      expect(find.text('PLA Pro'), findsWidgets);

      // Botón final (configStartButton).
      expect(find.text('Empezar a cotizar'), findsOneWidget);
    });

    testWidgets('paso 3: finalizar persiste onboarding_done y abre el '
        'calculador encima del home', (tester) async {
      final router = GoRouter(
        initialLocation: '/config',
        routes: [
          GoRoute(
            path: '/config',
            builder: (_, _) => const InitialConfigPage(),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(appBar: AppBar(), body: const Text('home')),
          ),
          GoRoute(
            path: '/calculator',
            builder: (_, _) =>
                Scaffold(appBar: AppBar(), body: const Text('calculator')),
          ),
        ],
      );
      await _pumpStepper(tester, router: router);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await _selectPrinter(tester, 'Creality', 'Ender-3');
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
      // Filamento requerido para habilitar Continuar.
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

      // Paso 3: botón final → persiste onboarding_done y abre el calculador
      // encima de Home (stack limpio, sin /initial-config vivo).
      await tester.ensureVisible(find.text('Empezar a cotizar'));
      await tester.tap(find.text('Empezar a cotizar'));
      await tester.pumpAndSettle();

      expect(find.text('calculator'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsKeys.onboardingDone), isTrue);

      // Back desde el calculador → Home (nunca la config).
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(find.byType(InitialConfigPage), findsNothing);
    });
  });
}
