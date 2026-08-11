// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, no_leading_underscores_for_local_identifiers
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculations_list_page.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/features/settings/presentation/pages/settings_page.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests del gate visual de items Pro-bloqueados (UX).
///
/// **Scope**: verificar que los controles gateados se ven NOTORIAMENTE
/// deshabilitados para users free (badge "PRO" + opacidad / candado) y
/// normales para users pro. NO se testea el SnackBar gate aca (ya
/// cubierto en `paywall_navigation_test.dart` y
/// `calculations_list_page_test.dart`).
///
/// **Call sites cubiertos**:
/// 1. `calculator_page.dart` — modo advanced free: badge "PRO" + Opacity
///    0.6 en el segmento (badge a opacidad completa). Pro: sin badge,
///    normal.
/// 2. `calculations_list_page.dart` — CSV export free: icono candado +
///    Opacity 0.6 + tooltip locked ([EsBO.csvExportTooltipLocked]).
///    Pro: icono descarga normal.
/// 3. `calculations_list_page.dart` — contador "x/$kFreeHistoryCap" para
///    free (oculto en Pro, con filtros/busqueda activos y durante
///    loading/error via `async.hasValue`).
/// 4. `settings_page.dart` — branding free: badge + campo empresa y
///    botones de logo atenuados. Pro: normal.
/// 5. **Guard `!ent.isLoading`** en los 3 call sites: mientras el
///    entitlement carga (fake con [Completer] nunca resuelto) NO se
///    muestra badge ni Opacity (evita falso "locked" en cold start).
///
/// **Fakes**: `_FakeEntitlementRepository` + `_FakePaymentService`
/// (in-memory, patron de `paywall_navigation_test.dart`). `isProProvider`
/// real via notifier (cache SP vacio → Free, o seed en DB → Pro).

class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;
  int saveCalls = 0;
  int clearCalls = 0;

  void seedActive(Entitlement? e) => _active = e;

  @override
  Future<Entitlement?> getActive() async => _active;

  @override
  Future<int> save(EntitlementsCompanion entry) async {
    saveCalls++;
    return 1;
  }

  @override
  Future<int> clear() async {
    clearCalls++;
    return 0;
  }

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}

/// Fake de repo que NUNCA resuelve `getActive` (Completer sin completar).
///
/// Mantiene el [EntitlementNotifier] en `isLoading` para poder testear
/// el guard `!ent.isLoading` del gate visual (falso "locked" en cold
/// start para un Pro real).
class _DelayedEntitlementRepository implements EntitlementRepository {
  final Completer<Entitlement?> completer = Completer<Entitlement?>();

  @override
  Future<Entitlement?> getActive() => completer.future;

  @override
  Future<int> save(EntitlementsCompanion entry) async => 1;

  @override
  Future<int> clear() async => 0;

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}

class _FakePaymentService implements PaymentService {
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  PaymentResult purchaseResult = const PaymentCancelled();
  RestoreResult restoreResult = const RestoreEmpty();

  void seedPurchase(PaymentResult r) => purchaseResult = r;
  void seedRestore(RestoreResult r) => restoreResult = r;

  @override
  Future<void> configure() async {
    configureCalls++;
  }

  @override
  Future<PaymentResult> purchase({required String productId}) async {
    purchaseCalls++;
    return purchaseResult;
  }

  @override
  Future<RestoreResult> restore() async {
    restoreCalls++;
    return restoreResult;
  }

  @override
  Stream<PaymentResult> get purchaseStream => const Stream.empty();
}

/// Inserta [count] cotizaciones via repo real (DB in-memory).
Future<void> _seedCalculations(ProviderContainer container, int count) async {
  final repo = container.read(calculationRepositoryProvider);
  for (var i = 0; i < count; i++) {
    await repo.create(
      CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA',
            weightGrams: Decimal.parse('100'),
            pricePerBobbin: Decimal.parse('120'),
            gramsPerBobbin: Decimal.parse('1000'),
          ),
        ],
        totalHours: Decimal.parse('5'),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.parse('12'),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.parse('36'),
        ),
        pieceName: 'Seed #$i',
      ),
    );
  }
}

/// Monta un container con fakes. [seedPro] hidrata la DB con un
/// entitlement activo (→ EntitlementPro); si no, cache vacio → Free.
/// Siempre fuerza la resolucion del [EntitlementNotifier] ANTES del
/// pumpWidget para que el gate visual lea el estado resuelto (evita
/// la ventana de loading en el primer frame).
Future<ProviderContainer> _makeContainer({
  required bool seedPro,
  required AppDatabase db,
  required SharedPreferences prefs,
}) async {
  final repo = _FakeEntitlementRepository();
  final payment = _FakePaymentService();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementRepositoryProvider.overrideWithValue(repo),
      paymentServiceProvider.overrideWithValue(payment),
    ],
  );
  if (seedPro) {
    repo.seedActive(
      Entitlement(
        id: 1,
        source: kSourceLifetimePurchase,
        productId: kProProductId,
        purchasedAt: DateTime.utc(2026, 1, 1),
        validatedAt: DateTime.utc(2026, 1, 1),
        isActive: true,
      ),
    );
  }
  await container.read(entitlementNotifierProvider.future);
  return container;
}

/// Monta un container con el entitlement BLOQUEADO en loading (repo con
/// [Completer] nunca resuelto). NO fuerza la resolucion del notifier:
/// los tests de loading ejercitan el guard `!ent.isLoading` del gate.
Future<ProviderContainer> _makeLoadingContainer({
  required AppDatabase db,
  required SharedPreferences prefs,
}) async {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementRepositoryProvider.overrideWithValue(
        _DelayedEntitlementRepository(),
      ),
      paymentServiceProvider.overrideWithValue(_FakePaymentService()),
    ],
  );
}

/// Pumpea una [Widget] dentro de un [UncontrolledProviderScope] con el
/// container dado y un par de `pump()` (NO `pumpAndSettle`: mientras el
/// entitlement esta pendiente el skeleton puede animar en loop).
Future<void> _pumpRaw(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: child),
  );
  await tester.pump();
  await tester.pump();
}

/// Monta [CalculatorPage] con entitlement en loading (no resuelto).
Future<ProviderContainer> _pumpCalculatorLoading(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    await db.close();
  });
  final container = await _makeLoadingContainer(db: db, prefs: prefs);
  addTearDown(container.dispose);
  await _pumpRaw(tester, container, const MaterialApp(home: CalculatorPage()));
  return container;
}

/// Monta [CalculationsListPage] con entitlement en loading (no resuelto).
Future<ProviderContainer> _pumpHistoryLoading(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    await db.close();
  });
  final container = await _makeLoadingContainer(db: db, prefs: prefs);
  addTearDown(container.dispose);
  await _pumpRaw(
    tester,
    container,
    const MaterialApp(home: CalculationsListPage()),
  );
  return container;
}

/// Monta [SettingsPage] con entitlement resuelto (free o pro).
Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  bool seedPro = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    await db.close();
  });
  final container = await _makeContainer(
    seedPro: seedPro,
    db: db,
    prefs: prefs,
  );
  addTearDown(container.dispose);
  await _pumpRaw(tester, container, const MaterialApp(home: SettingsPage()));
  await tester.pumpAndSettle();
  return container;
}

/// Monta [SettingsPage] con entitlement en loading (no resuelto).
Future<ProviderContainer> _pumpSettingsLoading(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    await db.close();
  });
  final container = await _makeLoadingContainer(db: db, prefs: prefs);
  addTearDown(container.dispose);
  await _pumpRaw(tester, container, const MaterialApp(home: SettingsPage()));
  return container;
}

/// Monta [CalculatorPage] con entitlement resuelto (free o pro).
Future<ProviderContainer> _pumpCalculator(
  WidgetTester tester, {
  bool seedPro = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    await db.close();
  });
  final container = await _makeContainer(
    seedPro: seedPro,
    db: db,
    prefs: prefs,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CalculatorPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Monta [CalculationsListPage] con entitlement resuelto + N cotizaciones.
Future<ProviderContainer> _pumpHistory(
  WidgetTester tester, {
  int seedCalculations = 0,
  bool seedPro = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    await db.close();
  });
  final container = await _makeContainer(
    seedPro: seedPro,
    db: db,
    prefs: prefs,
  );
  addTearDown(container.dispose);
  if (seedCalculations > 0) {
    await _seedCalculations(container, seedCalculations);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CalculationsListPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Finder de widgets `Opacity` con [kLockedOpacity].
Finder _dimmed() =>
    find.byWidgetPredicate((w) => w is Opacity && w.opacity == kLockedOpacity);

void main() {
  setUp(() {
    EsBO.setImpl(const EsImpl());
  });

  // ─────────────────────────────────────────────────────────────
  // l10n (keys nuevas del gate visual)
  // ─────────────────────────────────────────────────────────────

  group('Pro locked visuals l10n', () {
    test('EsBO.proBadgeLabel es "PRO"', () {
      expect(EsBO.proBadgeLabel, 'PRO');
    });

    test('EsBO.proLockedTooltip esta definido y no vacio', () {
      expect(EsBO.proLockedTooltip, isNotEmpty);
    });

    test('EsBO.csvExportTooltipLocked indica que la accion es Pro', () {
      expect(EsBO.csvExportTooltipLocked, 'Exportar CSV (Pro)');
    });

    test('EsBO.historyUsageCounter formatea en es', () {
      expect(
        EsBO.historyUsageCounter(5, kFreeHistoryCap),
        '5/$kFreeHistoryCap cotizaciones',
      );
      expect(
        EsBO.historyUsageCounter(1, kFreeHistoryCap),
        '1/$kFreeHistoryCap cotización',
      );
    });

    test('EnImpl expone las keys nuevas', () {
      EsBO.setImpl(const EnImpl());
      expect(EsBO.proBadgeLabel, 'PRO');
      expect(EsBO.proLockedTooltip, isNotEmpty);
      expect(EsBO.csvExportTooltipLocked, 'Export CSV (Pro)');
      expect(
        EsBO.historyUsageCounter(5, kFreeHistoryCap),
        '5/$kFreeHistoryCap quotes',
      );
      expect(
        EsBO.historyUsageCounter(1, kFreeHistoryCap),
        '1/$kFreeHistoryCap quote',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Calculator — modo advanced free: badge + atenuado
  // ─────────────────────────────────────────────────────────────

  group('Calculator — modo advanced gate visual', () {
    testWidgets('free: segmento Advanced muestra badge "PRO" + Opacity 0.6', (
      tester,
    ) async {
      await _pumpCalculator(tester);

      // El badge puede aparecer en varios lugares (modo Advanced + seccion
      // Otros) — se verifica al menos uno.
      expect(
        find.text(EsBO.proBadgeLabel),
        findsAtLeastNWidgets(1),
        reason: 'Free: debe mostrarse al menos un badge "PRO".',
      );
      expect(
        find.byIcon(Icons.lock_rounded),
        findsAtLeastNWidgets(1),
        reason: 'Free: el badge debe incluir el icono de candado.',
      );
      expect(
        _dimmed(),
        findsAtLeastNWidgets(1),
        reason: 'Free: el segmento advanced debe estar atenuado (0.6).',
      );
      // El texto "Advanced" sigue presente (el gate de tap no cambia).
      expect(find.text(EsBO.calcModeAdvanced), findsOneWidget);
    });

    testWidgets('pro: segmento Advanced normal, sin badge ni opacidad', (
      tester,
    ) async {
      await _pumpCalculator(tester, seedPro: true);

      expect(
        find.text(EsBO.proBadgeLabel),
        findsNothing,
        reason: 'Pro: no debe mostrarse el badge "PRO".',
      );
      expect(
        _dimmed(),
        findsNothing,
        reason: 'Pro: el modo advanced no debe estar atenuado.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // History — CSV export: candado en free, normal en pro
  // ─────────────────────────────────────────────────────────────

  group('History — CSV export gate visual', () {
    testWidgets('free: el boton CSV muestra icono candado atenuado', (
      tester,
    ) async {
      await _pumpHistory(tester, seedCalculations: 1);

      expect(
        find.byIcon(Icons.lock_rounded),
        findsOneWidget,
        reason: 'Free: el boton CSV debe mostrar el icono de candado.',
      );
      expect(
        find.byIcon(Icons.file_download_outlined),
        findsNothing,
        reason: 'Free: el icono de descarga no debe verse.',
      );
      expect(
        _dimmed(),
        findsAtLeastNWidgets(1),
        reason: 'Free: el boton CSV debe estar atenuado (0.6).',
      );
      // El tooltip locked describe la accion como Pro (no la habilita).
      expect(
        find.byTooltip(EsBO.csvExportTooltipLocked),
        findsOneWidget,
        reason: 'Free: el tooltip debe indicar que el CSV es Pro.',
      );
      expect(
        find.byTooltip('Exportar CSV'),
        findsNothing,
        reason: 'Free: el tooltip no debe describir la accion habilitada.',
      );
    });

    testWidgets('pro: el boton CSV mantiene el icono de descarga', (
      tester,
    ) async {
      await _pumpHistory(tester, seedCalculations: 1, seedPro: true);

      expect(
        find.byIcon(Icons.file_download_outlined),
        findsOneWidget,
        reason: 'Pro: el boton CSV debe mostrar el icono de descarga.',
      );
      expect(
        find.byIcon(Icons.lock_rounded),
        findsNothing,
        reason: 'Pro: no debe verse el candado en el export CSV.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // History — contador "x/$kFreeHistoryCap"
  // ─────────────────────────────────────────────────────────────

  group('History — contador de uso free', () {
    testWidgets('free con N cotizaciones muestra "N/$kFreeHistoryCap"', (
      tester,
    ) async {
      const n = 3;
      await _pumpHistory(tester, seedCalculations: n);

      expect(
        find.text(EsBO.historyUsageCounter(n, kFreeHistoryCap)),
        findsOneWidget,
        reason:
            'Free: el contador de historial debe mostrar "$n/$kFreeHistoryCap".',
      );
    });

    testWidgets('free sin cotizaciones muestra "0/$kFreeHistoryCap"', (
      tester,
    ) async {
      await _pumpHistory(tester, seedCalculations: 0);

      expect(
        find.text(EsBO.historyUsageCounter(0, kFreeHistoryCap)),
        findsOneWidget,
        reason:
            'Free: sin cotizaciones el contador muestra 0/$kFreeHistoryCap.',
      );
      // El EmptyView sigue intacto (no rompe el flujo de lista vacia).
      expect(find.text(EsBO.historyEmpty), findsOneWidget);
    });

    testWidgets('free: el contador se oculta con busqueda activa', (
      tester,
    ) async {
      const n = 3;
      await _pumpHistory(tester, seedCalculations: n);

      expect(
        find.text(EsBO.historyUsageCounter(n, kFreeHistoryCap)),
        findsOneWidget,
        reason: 'Free: sin filtros el contador se ve.',
      );

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(
        find.text(EsBO.historyUsageCounter(n, kFreeHistoryCap)),
        findsNothing,
        reason:
            'Free: con busqueda activa el contador se oculta '
            '(el count del state no representa el historial total).',
      );
    });

    testWidgets('pro: el contador no se muestra (historial ilimitado)', (
      tester,
    ) async {
      const n = 3;
      await _pumpHistory(tester, seedCalculations: n, seedPro: true);

      expect(
        find.text(EsBO.historyUsageCounter(n, kFreeHistoryCap)),
        findsNothing,
        reason: 'Pro: no debe mostrarse el contador x/$kFreeHistoryCap.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Settings — branding: badge + atenuacion de campo/botones
  // ─────────────────────────────────────────────────────────────

  group('Settings — branding gate visual', () {
    testWidgets('free: badge PRO + campo empresa y botones logo atenuados', (
      tester,
    ) async {
      await _pumpSettings(tester);

      expect(
        find.text(EsBO.proBadgeLabel),
        findsOneWidget,
        reason: 'Free: el badge "PRO" debe verse en la seccion Empresa.',
      );
      // Campo empresa (1) + botones de logo (1) = 2 Opacity 0.6.
      expect(
        _dimmed(),
        findsAtLeastNWidgets(2),
        reason: 'Free: campo empresa y botones de logo atenuados (0.6).',
      );
    });

    testWidgets('pro: sin badge ni atenuacion en branding', (tester) async {
      await _pumpSettings(tester, seedPro: true);

      expect(
        find.text(EsBO.proBadgeLabel),
        findsNothing,
        reason: 'Pro: no debe mostrarse el badge "PRO".',
      );
      expect(_dimmed(), findsNothing, reason: 'Pro: branding sin atenuar.');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Loading state — guard !ent.isLoading (falso locked en cold start)
  // ─────────────────────────────────────────────────────────────

  group('Loading state — gate visual cerrado', () {
    testWidgets('calculator: sin badge ni Opacity mientras carga', (
      tester,
    ) async {
      await _pumpCalculatorLoading(tester);

      expect(
        find.text(EsBO.proBadgeLabel),
        findsNothing,
        reason: 'Loading: no debe verse el badge "PRO" (falso locked).',
      );
      expect(
        _dimmed(),
        findsNothing,
        reason: 'Loading: el segmento advanced no debe atenuarse.',
      );
    });

    testWidgets('history CSV: boton normal mientras carga', (tester) async {
      await _pumpHistoryLoading(tester);

      expect(
        find.byIcon(Icons.lock_rounded),
        findsNothing,
        reason: 'Loading: no debe verse el candado del CSV.',
      );
      expect(
        find.byIcon(Icons.file_download_outlined),
        findsOneWidget,
        reason: 'Loading: el boton CSV se ve normal (sin gate).',
      );
      expect(
        _dimmed(),
        findsNothing,
        reason: 'Loading: el boton CSV no debe atenuarse.',
      );
      expect(
        find.text(EsBO.historyUsageCounter(0, kFreeHistoryCap)),
        findsNothing,
        reason: 'Loading: no debe mostrarse "0/10" antes de resolver.',
      );
    });

    testWidgets('settings: sin badge ni Opacity en branding', (tester) async {
      await _pumpSettingsLoading(tester);

      expect(
        find.text(EsBO.proBadgeLabel),
        findsNothing,
        reason: 'Loading: no debe verse el badge "PRO".',
      );
      expect(
        _dimmed(),
        findsNothing,
        reason: 'Loading: campo empresa y botones de logo sin atenuar.',
      );
    });
  });
}
