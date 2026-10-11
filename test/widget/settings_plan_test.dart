import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/entitlement/presentation/notifiers/entitlement_notifier.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/shared/widgets/page_header_card.dart';

/// Detalle del plan desde Settings (PRD
/// `docs/prds/2026-10-10_2313-settings-plan-view.prd.md`, v2).
///
/// La sección "Plan" fue eliminada de Settings (2026-10-11): el badge
/// PRO/FREE de la cabecera (`PlanTierBadge`) es el único punto de entrada
/// al bottom sheet comparador (badge de estado, lista Gratis y subsección
/// Pro "Todo lo de Gratis, y además:"). CTA "→ /paywall" solo si es free.
const _sheetKey = ValueKey('settingsPlanSheet');
const _statusBadgeKey = ValueKey('settingsPlanStatusBadge');
const _unlockCtaKey = ValueKey('settingsPlanUnlockCta');

/// Notifier que queda en `loading` para siempre (patrón de
/// `paywall_page_test.dart`). Permite verificar el estado de boot.
class _LoadingNotifier extends EntitlementNotifier {
  @override
  Future<EntitlementState> build() async {
    state = const AsyncValue<EntitlementState>.loading();
    return Completer<EntitlementState>().future;
  }
}

/// Monta [SettingsPage] con DB in-memory + prefs mock.
///
/// - `isPro != null` → override de [isProProvider] (render sin IAP).
/// - `loading = true` → override de [entitlementNotifierProvider] a loading.
/// - `router != null` → monta `MaterialApp.router` para navegación.
Future<void> _pump(
  WidgetTester tester, {
  bool? isPro,
  bool loading = false,
  GoRouter? router,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final overrides = [
    appDatabaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
  if (loading) {
    overrides.add(
      entitlementNotifierProvider.overrideWith(_LoadingNotifier.new),
    );
  } else if (isPro != null) {
    overrides.add(isProProvider.overrideWith((ref) => isPro));
  }
  final container = ProviderContainer(overrides: overrides);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: router == null
          ? const MaterialApp(home: SettingsPage())
          : MaterialApp.router(routerConfig: router),
    ),
  );
  if (!loading) {
    await tester.pumpAndSettle();
  } else {
    // Deja resolverse settings (Drift) sin settle (entitlement colgado).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('SettingsPage — detalle del plan desde el badge de cabecera', () {
    testWidgets('free: badge FREE abre sheet con estado, CTA y listas '
        '(AC-001/002/003/004)', (tester) async {
      await _pump(tester, isPro: false);

      // El badge de cabecera está presente y el sheet cerrado.
      expect(find.byType(PlanTierBadge), findsOneWidget);
      expect(find.byKey(_sheetKey), findsNothing);

      // Tocar el badge abre el sheet.
      await tester.tap(find.byType(PlanTierBadge));
      await tester.pumpAndSettle();
      expect(find.byKey(_sheetKey), findsOneWidget);

      // Badge de estado = Gratis (dentro del sheet).
      final badge = find.byKey(_statusBadgeKey);
      expect(badge, findsOneWidget);
      expect(
        find.descendant(
          of: badge,
          matching: find.text(EsBO.settingsPlanStatusFree),
        ),
        findsOneWidget,
      );

      // CTA visible para free.
      expect(find.byKey(_unlockCtaKey), findsOneWidget);

      // Encabezado Pro "Todo lo de Gratis, y además:".
      expect(find.text(EsBO.settingsPlanProIncludes), findsOneWidget);

      // Listas con al menos una feature cada una.
      expect(find.text(EsBO.settingsPlanFreeFeatures.first), findsWidgets);
      expect(find.text(EsBO.settingsPlanProFeatures.first), findsWidgets);
    });

    testWidgets(
      'pro: sheet con estado Pro, sin CTA y con "ya tienes PRO" '
      '(AC-002/003)',
      (tester) async {
        await _pump(tester, isPro: true);

        expect(find.byType(PlanTierBadge), findsOneWidget);
        await tester.tap(find.byType(PlanTierBadge));
        await tester.pumpAndSettle();

        final badge = find.byKey(_statusBadgeKey);
        expect(badge, findsOneWidget);
        expect(
          find.descendant(
            of: badge,
            matching: find.text(EsBO.settingsPlanStatusPro),
          ),
          findsOneWidget,
        );

        // Sin CTA de desbloqueo; en su lugar, mensaje de ya-Pro.
        expect(find.byKey(_unlockCtaKey), findsNothing);
        expect(find.text(EsBO.settingsPlanAlreadyPro), findsOneWidget);
      },
    );

    testWidgets('loading: sin badge visible (no falso "FREE") (AC-007)', (
      tester,
    ) async {
      await _pump(tester, loading: true);

      // Settings renderiza, pero el badge se auto-oculta en loading:
      // ningún estado de plan se muestra ni es tocable.
      expect(find.byKey(_sheetKey), findsNothing);
      expect(find.text(EsBO.proBadgeLabelFree), findsNothing);
      expect(find.text(EsBO.proBadgeLabel), findsNothing);
      expect(find.byKey(_statusBadgeKey), findsNothing);
      expect(find.byKey(_unlockCtaKey), findsNothing);
    });

    testWidgets('el badge vive en la cabecera, arriba de Empresa (AC-001)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, isPro: false);

      final badgeY = tester.getTopLeft(find.byType(PlanTierBadge)).dy;
      final companyY = tester
          .getTopLeft(find.text(EsBO.settingsCompany.toUpperCase()))
          .dy;
      expect(badgeY, lessThan(companyY));
    });

    testWidgets('CTA del sheet navega a /paywall (AC-003)', (tester) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(
            path: '/paywall',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('PAYWALL_STUB_PLAN'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pump(tester, isPro: false, router: router);

      // Abre el sheet desde el badge y toca el CTA.
      await tester.tap(find.byType(PlanTierBadge));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(_unlockCtaKey));
      await tester.tap(find.byKey(_unlockCtaKey));
      await tester.pumpAndSettle();

      expect(find.text('PAYWALL_STUB_PLAN'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        '/paywall',
      );
    });
  });
}
