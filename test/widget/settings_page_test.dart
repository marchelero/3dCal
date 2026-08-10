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
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';

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

/// Helper: monta [SettingsPage] en estado Free (isPro=false) SIN router.
/// Para tests que solo verifican el renderizado (badge, readOnly) sin
/// navegar a /paywall.
Future<ProviderContainer> _pumpPageFree(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
    isProProvider.overrideWith((ref) => false),
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

/// Helper: monta [SettingsPage] en estado Free CON GoRouter (incluye
/// `/paywall` stub). Para tests que ejercitan la accion "Go Pro" del
/// SnackBar y verifican la navegacion.
Future<({ProviderContainer container, GoRouter router})> _pumpPageFreeWithRouter(
  WidgetTester tester,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('PAYWALL_STUB_T12')),
        ),
      ),
    ],
  );
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
    isProProvider.overrideWith((ref) => false),
  ]);
  addTearDown(() async {
    router.dispose();
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, router: router);
}

/// Helper: monta [SettingsPage] en estado Pro (isPro=true). Para tests
/// que verifican que el comportamiento gated se mantiene libre.
Future<ProviderContainer> _pumpPagePro(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
    isProProvider.overrideWith((ref) => true),
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
      expect(find.text('3dCalc'), findsWidgets); // header + company name field default
      expect(find.text('PARÁMETROS GLOBALES'), findsOneWidget); // _SettingsSection usa toUpperCase
      expect(find.text('EMPRESA'), findsOneWidget); // _SettingsSection usa toUpperCase
      expect(find.text('Nombre de la empresa'), findsOneWidget);
      expect(find.text('Filamentos'), findsOneWidget);
      expect(find.text('Impresoras'), findsOneWidget);
      expect(find.textContaining('Privacidad:'), findsAtLeast(1));
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

  // ─────────────────────────────────────────────────────────────
  // T12 — Branding gate (companyName + companyLogo)
  //
  // Free user: companyName readOnly, logo pick/remove gated, ambos
  //   disparan SnackBar con body + accion "Go Pro" que navega a
  //   /paywall. El "Pro" badge aparece en la seccion Empresa.
  // Pro user: comportamiento actual (editable + pick enabled).
  // ─────────────────────────────────────────────────────────────

  group('T12 — Branding gate l10n', () {
    test('EsBO.settingsBrandingLockedBody esta definido y no vacio', () {
      expect(EsBO.settingsBrandingLockedBody, isNotEmpty);
    });

    test('EsBO.settingsGoProAction esta definido y no vacio', () {
      expect(EsBO.settingsGoProAction, isNotEmpty);
    });

    test('EsBO.proBadgeLabel esta definido y no vacio', () {
      expect(EsBO.proBadgeLabel, isNotEmpty);
    });

    test('EnImpl expone las 3 keys del branding gate con texto no vacio', () {
      EsBO.setImpl(const EnImpl());
      expect(EsBO.settingsBrandingLockedBody, isNotEmpty);
      expect(EsBO.settingsGoProAction, isNotEmpty);
      expect(EsBO.proBadgeLabel, isNotEmpty);
    });
  });

  group('T12 — Branding gate en Free', () {
    testWidgets(
      'campo companyName es readOnly (no editable) cuando isPro=false',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPageFree(tester);

        // El TextField del companyName (label "Nombre de la empresa") debe
        // estar rendered con readOnly=true.
        final nameField = find.widgetWithText(TextField, '3dCalc');
        expect(nameField, findsOneWidget);

        final textField = tester.widget<TextField>(nameField);
        expect(textField.readOnly, isTrue,
            reason: 'Free: companyName TextField debe ser readOnly.');
      },
    );

    testWidgets(
      'tap en companyName muestra SnackBar con body + accion Go Pro',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPageFree(tester);

        await tester.tap(find.widgetWithText(TextField, '3dCalc'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // SnackBar visible con el body del gate.
        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason: 'Free: tap companyName debe disparar SnackBar del gate.',
        );
        expect(find.text(EsBO.settingsBrandingLockedBody), findsOneWidget,
            reason: 'Body del SnackBar debe ser settingsBrandingLockedBody.');
        expect(find.text(EsBO.settingsGoProAction), findsOneWidget,
            reason: 'Action del SnackBar debe ser settingsGoProAction.');
      },
    );

    testWidgets(
      'tap en accion "Go Pro" del SnackBar navega a /paywall',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPageFreeWithRouter(tester);

        await tester.tap(find.widgetWithText(TextField, '3dCalc'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final goPro = find.text(EsBO.settingsGoProAction);
        expect(goPro, findsOneWidget);
        await tester.tap(goPro);
        await tester.pumpAndSettle();

        // El stub del paywall debe estar visible.
        expect(find.text('PAYWALL_STUB_T12'), findsOneWidget,
            reason: 'Action "Go Pro" debe navegar a /paywall.');
      },
    );

    testWidgets(
      'muestra badge "Pro" en la seccion Empresa cuando isPro=false',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPageFree(tester);

        // El badge "PRO" debe estar visible (en o cerca de la seccion
        // Empresa). Buscamos por el texto.
        expect(find.text(EsBO.proBadgeLabel), findsAtLeast(1),
            reason: 'Free: debe mostrarse el badge "PRO" en la UI.');
      },
    );

    testWidgets(
      'tap en "Seleccionar imagen" muestra SnackBar del gate',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPageFree(tester);

        // El boton de pick logo tiene el label "Seleccionar imagen".
        await tester.tap(find.text(EsBO.settingsCompanyLogoPick));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(SnackBar), findsOneWidget,
            reason: 'Free: tap en pick logo debe disparar SnackBar del gate.');
        expect(find.text(EsBO.settingsBrandingLockedBody), findsOneWidget);
        expect(find.text(EsBO.settingsGoProAction), findsOneWidget);
      },
    );
  });

  group('T12 — Branding gate en Pro', () {
    testWidgets(
      'campo companyName es editable cuando isPro=true (texto se puede cambiar)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = await _pumpPagePro(tester);

        final nameField = find.widgetWithText(TextField, '3dCalc');
        expect(nameField, findsOneWidget);

        final textField = tester.widget<TextField>(nameField);
        expect(textField.readOnly, isFalse,
            reason: 'Pro: companyName TextField debe ser editable.');

        // El usuario puede escribir un nuevo nombre y persistirlo via
        // onTapOutside. Para dispararlo en test, hacemos tap fuera del
        // field (esquina superior izquierda, fuera del TextField).
        await tester.enterText(nameField, 'Acme 3D Studio');
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        final notifier = container.read(settingsNotifierProvider);
        expect(notifier.valueOrNull!.companyName, 'Acme 3D Studio',
            reason: 'Pro: companyName nuevo debe persistir.');
      },
    );

    testWidgets(
      'tap en companyName NO dispara SnackBar del gate cuando isPro=true',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPagePro(tester);

        await tester.tap(find.widgetWithText(TextField, '3dCalc'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Pro: NO debe aparecer el SnackBar del gate.
        expect(find.text(EsBO.settingsBrandingLockedBody), findsNothing,
            reason: 'Pro: gate del companyName NO debe dispararse.');
        expect(find.text(EsBO.settingsGoProAction), findsNothing,
            reason: 'Pro: no debe ofrecer "Go Pro" en companyName.');
      },
    );

    testWidgets(
      'tap en "Seleccionar imagen" NO dispara SnackBar del gate cuando isPro=true',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPagePro(tester);

        // Pro: tap en pick logo NO dispara el gate. (El image_picker
        // platform channel va a throw MissingPluginException, pero
        // eso ocurre DESPUES de pasar el gate. El assert relevante
        // es que el SnackBar del gate NO aparece.)
        try {
          await tester.tap(find.text(EsBO.settingsCompanyLogoPick));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
        } catch (_) {
          // Ignoramos MissingPluginException del image_picker channel.
        }

        expect(find.text(EsBO.settingsBrandingLockedBody), findsNothing,
            reason: 'Pro: gate del logo NO debe dispararse.');
        expect(find.text(EsBO.settingsGoProAction), findsNothing);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────
  // T11 — Restore purchases button
  // ─────────────────────────────────────────────────────────────

  group('T11 — Restore button', () {
    // Mocks minimos para que el notifier real funcione.
    late _FakePaymentService _payment;
    late _FakeRepo _repo;

    setUp(() {
      _payment = _FakePaymentService();
      _repo = _FakeRepo();
    });

    Future<ProviderContainer> _pumpForRestore(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
      });
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        entitlementRepositoryProvider.overrideWithValue(_repo),
        paymentServiceProvider.overrideWithValue(_payment),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('boton Restaurar compras visible en settings', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpForRestore(tester);

      expect(
        find.byType(FilledButton),
        findsAtLeast(1),
        reason: 'Restore FilledButton debe estar visible.',
      );
    });

    testWidgets(
      'tap en boton Restaurar compras invoca PaymentService.restore',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpForRestore(tester);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(_payment.restoreCalls, 1,
            reason:
                'Tap en boton Restaurar debe llamar PaymentService.restore().');
      },
    );
  });
}

class _FakePaymentService implements PaymentService {
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> configure() async {}

  @override
  Future<RestoreResult> restore() async {
    restoreCalls++;
    return const RestoreEmpty();
  }

  @override
  Future<PaymentResult> purchase({required String productId}) async {
    purchaseCalls++;
    return const PaymentCancelled();
  }

  @override
  Stream<PaymentResult> get purchaseStream =>
      const Stream<PaymentResult>.empty();
}

class _FakeRepo implements EntitlementRepository {
  @override
  Future<Entitlement?> getActive() async => null;

  @override
  Future<int> save(EntitlementsCompanion entry) async => 1;

  @override
  Future<int> clear() async => 0;

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}
