// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/notifiers/calculations_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculations_list_page.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests del gate "Exportar CSV" (T16 del plan de monetizacion).
///
/// **Scope**:
/// - **Free**: tap en "Exportar CSV" muestra SnackBar con
///   [EsBO.csvExportLockedBody] + action [EsBO.csvGoProAction].
///   El action navega a `/paywall`. El export NO ocurre (no se invoca
///   `Share.shareXFiles`).
/// - **Pro**: tap en "Exportar CSV" NO muestra el gate SnackBar. Procede
///   al export (que en el test fallara con MissingPluginException — el
///   aserto relevante es "no se mostro el SnackBar de gate").
/// - **l10n**: las 2 keys nuevas existen en es_bo y en_us.
///
/// **Mocking**: `_FakeEntitlementRepository` + `_FakePaymentService`
/// (in-memory, sin SDK nativo). El `isProProvider` real se evalua
/// contra los fakes via el [entitlementNotifierProvider] real — asi
/// se ejercita la cadena completa (cache SP → repo → notifier →
/// isProProvider → gate).

class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;
  int saveCalls = 0;
  int clearCalls = 0;

  // ignore: use_setters_to_change_properties
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

class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;
  int configureCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  PaymentResult purchaseResult = const PaymentCancelled();
  RestoreResult restoreResult = const RestoreEmpty();

  // ignore: use_setters_to_change_properties
  void seedPurchase(PaymentResult r) => purchaseResult = r;
  // ignore: use_setters_to_change_properties
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
  Future<String?> getProPriceString() async => null;

  @override
  Future<bool?> isProActiveOnStore() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

/// Stub para destinos de navegacion (solo necesitamos el titulo para
/// verificar que la navegacion llego a la ruta correcta).
class _ScaffoldWithText extends StatelessWidget {
  const _ScaffoldWithText({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}

/// Helper: inserta una cotizacion "dummy" via el [CalculationRepository]
/// real (contra DB in-memory). Asi el page no se renderiza en empty state
/// y el export button es visible.
Future<void> _seedOneCalculation(
  ProviderContainer container, {
  Uint8List? pieceImageBytes,
}) async {
  final repo = container.read(calculationRepositoryProvider);
  await repo.create(
    CalculationDraft(
      materials: [
        MaterialInput(
          label: 'PLA Test',
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
        totalPrice: Decimal.parse('12'),
      ),
      pieceName: 'Test piece',
      clientName: 'Test client',
      pieceImageBytes: pieceImageBytes,
    ),
  );
}

/// Helper: inserta una cotizacion con control de fecha, cliente, material,
/// precio, cantidad y estado vendida (PRD historial avanzado 2026-09-11).
Future<void> _seed(
  ProviderContainer container, {
  required String piece,
  String? clientName,
  String materialLabel = 'PLA',
  Decimal? price,
  int quantity = 1,
  DateTime? createdAtUtc,
  bool sold = false,
}) async {
  final repo = container.read(calculationRepositoryProvider);
  final db = container.read(appDatabaseProvider);
  final id = await repo.create(
    CalculationDraft(
      materials: [
        MaterialInput(
          label: materialLabel,
          weightGrams: Decimal.parse('100'),
          pricePerBobbin: Decimal.parse('120'),
          gramsPerBobbin: Decimal.parse('1000'),
        ),
      ],
      totalHours: Decimal.parse('2'),
      discountPercentage: Decimal.zero,
      output: CalculationOutput.simple(
        materialCost: Decimal.parse('10'),
        discountAmount: Decimal.zero,
        totalPrice: price ?? Decimal.parse('10'),
      ),
      pieceName: piece,
      clientName: clientName,
      quantity: quantity,
    ),
  );
  if (createdAtUtc != null || sold) {
    await (db.update(db.calculations)..where((c) => c.id.equals(id))).write(
      CalculationsCompanion(
        createdAt: createdAtUtc != null
            ? Value(createdAtUtc)
            : const Value.absent(),
        isSold: sold ? const Value(true) : const Value.absent(),
      ),
    );
  }
}

/// Helper: construye un [ProviderContainer] con DB in-memory + fakes de
/// entitlement (mismos fakes que [_pumpPageFree]). Con [pro]=true pre-puebla
/// el cache de SharedPreferences y fuerza la resolucion del
/// [EntitlementNotifier] a Pro antes de devolver.
Future<({ProviderContainer container, AppDatabase db})> _buildFreeContainer({
  bool pro = false,
}) async {
  if (pro) {
    final validated = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues(<String, Object>{
      kIsProKey: true,
      kEntitlementSourceKey: kSourceLifetimePurchase,
      kEntitlementValidatedAtKey: validated.toIso8601String(),
    });
  } else {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
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
  addTearDown(container.dispose);
  addTearDown(() async {
    await db.close();
  });
  if (pro) {
    await container.read(entitlementNotifierProvider.future);
  }
  return (container: container, db: db);
}

/// Helper: monta [CalculationsListPage] (con el GoRouter minimal que incluye
/// `/paywall`) sobre un container ya construido.
Future<void> _pumpContainer(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = _buildRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Helper: monta [CalculationsListPage] en estado FREE sobre el container de
/// [_buildFreeContainer]. Inserta [seedCount] cotizaciones "dummy".
Future<({ProviderContainer container, AppDatabase db})> _pumpPageFree(
  WidgetTester tester, {
  int seedCount = 1,
  Uint8List? pieceImageBytes,
}) async {
  final res = await _buildFreeContainer();
  for (var i = 0; i < seedCount; i++) {
    await _seedOneCalculation(res.container, pieceImageBytes: pieceImageBytes);
  }
  await _pumpContainer(tester, res.container);
  return res;
}

/// Helper: monta [CalculationsListPage] en estado PRO (via cache SP
/// pre-poblada, sin tocar DB). Igual GoRouter que [_pumpPageFree].
Future<({ProviderContainer container, AppDatabase db})> _pumpPagePro(
  WidgetTester tester,
) async {
  final res = await _buildFreeContainer(pro: true);
  await _seedOneCalculation(res.container);
  await _pumpContainer(tester, res.container);
  return res;
}

/// GoRouter minimal con la lista + el destino /paywall. Se reutiliza
/// entre los pumps Free y Pro.
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (_, _) => const CalculationsListPage(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, _) => const _ScaffoldWithText(title: 'Paywall stub'),
      ),
    ],
  );
}

void main() {
  setUp(() {
    EsBO.setImpl(const EsImpl());
  });

  // ─────────────────────────────────────────────────────────────
  // l10n (las 2 keys nuevas del gate)
  // ─────────────────────────────────────────────────────────────

  group('CSV gate l10n (T16)', () {
    test('EsBO.csvExportLockedBody esta definido y no vacio', () {
      expect(EsBO.csvExportLockedBody, isNotEmpty);
    });

    test('EsBO.csvGoProAction esta definido y no vacio', () {
      expect(EsBO.csvGoProAction, isNotEmpty);
    });

    test('EnImpl expone las 2 keys del CSV gate con texto no vacio', () {
      EsBO.setImpl(const EnImpl());
      expect(EsBO.csvExportLockedBody, isNotEmpty);
      expect(EsBO.csvGoProAction, isNotEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Gate behavior (Free + tap CSV)
  // ─────────────────────────────────────────────────────────────

  group('CalculationsListPage — CSV export gate en Free', () {
    testWidgets('duplicar al alcanzar el cap muestra el gate de historial', (
      tester,
    ) async {
      await _pumpPageFree(tester, seedCount: kFreeHistoryCap);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.calcDuplicateAction).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(EsBO.historyCapReachedBody), findsOneWidget);
      expect(find.text(EsBO.calculatorGoProAction), findsOneWidget);
    });

    testWidgets('muestra el IconButton "Exportar CSV" en la AppBar', (
      tester,
    ) async {
      await _pumpPageFree(tester);
      expect(
        find.byTooltip(EsBO.csvExportTooltipLocked),
        findsOneWidget,
        reason: 'Free: el boton de export CSV (tooltip locked) en la AppBar.',
      );
    });

    testWidgets(
      'tap en "Exportar CSV" muestra SnackBar con body + action "Go Pro"',
      (tester) async {
        await _pumpPageFree(tester);

        await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
        await tester.pump(); // Schedule SnackBar.
        await tester.pump(const Duration(milliseconds: 100)); // Anima SnackBar.

        // El SnackBar del gate debe estar visible.
        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason: 'Free debe ver SnackBar del gate.',
        );
        // Body del gate.
        expect(
          find.text(EsBO.csvExportLockedBody),
          findsOneWidget,
          reason: 'Body del SnackBar debe ser csvExportLockedBody.',
        );
        // Action label.
        expect(
          find.text(EsBO.csvGoProAction),
          findsOneWidget,
          reason: 'Action del SnackBar debe ser csvGoProAction.',
        );
      },
    );

    testWidgets(
      'NO muestra el SnackBar de "no hay cotizaciones" cuando hay datos',
      (tester) async {
        // La lista tiene 1 cotizacion seeded → el codigo del export debe
        // entrar al gate (no al branch de lista vacia).
        await _pumpPageFree(tester);

        await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // El texto del branch "lista vacia" no debe aparecer.
        expect(
          find.text('No hay cotizaciones para exportar'),
          findsNothing,
          reason:
              'Lista no vacia: el gate debe dispararse, no el branch empty.',
        );
        // El body del gate SI debe aparecer.
        expect(find.text(EsBO.csvExportLockedBody), findsOneWidget);
      },
    );

    testWidgets('tap en action "Go Pro" navega a /paywall', (tester) async {
      await _pumpPageFree(tester);

      await tester.tap(find.byTooltip(EsBO.csvExportTooltipLocked));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // El action "Go Pro" del SnackBar debe estar visible.
      final goProAction = find.text(EsBO.csvGoProAction);
      expect(goProAction, findsOneWidget);

      // Tap en el action. Usamos ensureVisible por si quedo fuera del
      // viewport en viewports chicos.
      await tester.ensureVisible(goProAction);
      await tester.tap(goProAction);
      await tester.pumpAndSettle();

      // La pagina paywall (stub) debe estar visible.
      expect(
        find.text('Paywall stub'),
        findsOneWidget,
        reason: 'Action "Go Pro" debe navegar a /paywall.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Gate behavior (Pro + tap CSV) — export debe proceder, no gate
  // ─────────────────────────────────────────────────────────────

  group('CalculationsListPage — CSV export en Pro', () {
    testWidgets('tap en "Exportar CSV" NO muestra SnackBar del gate', (
      tester,
    ) async {
      final res = await _pumpPagePro(tester);

      // Sanity check: isProProvider debe ser true antes del tap. El
      // `_pumpPagePro` fuerza la resolucion del notifier via
      // `container.read(future)`, asi que esto es un guard redundante
      // para que un cambio futuro no haga el test silenciosamente
      // invalido.
      expect(
        res.container.read(isProProvider),
        isTrue,
        reason: 'Pro setup: el notifier debe haber resuelto a Pro.',
      );

      await tester.tap(find.byTooltip('Exportar CSV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // El body del gate NO debe aparecer.
      expect(
        find.text(EsBO.csvExportLockedBody),
        findsNothing,
        reason: 'Pro: el gate no debe dispararse.',
      );
      // El action "Go Pro" tampoco.
      expect(
        find.text(EsBO.csvGoProAction),
        findsNothing,
        reason: 'Pro: no debe ofrecer "Go Pro" en el export.',
      );
      // Y no debe aparecer el branch de lista vacia tampoco.
      expect(
        find.text('No hay cotizaciones para exportar'),
        findsNothing,
        reason: 'Lista no vacia: no debe disparar branch empty.',
      );
      // El share va a throw MissingPluginException (no hay platform
      // channel en test), pero eso no rompe el assert: lo que importa
      // es que el gate NO se disparo.
    });
  });

  // ─────────────────────────────────────────────────────────────
  // F2 — thumbnail de la foto persistida en cada card del historial
  // ─────────────────────────────────────────────────────────────

  group('CalculationsListPage — thumbnail de foto persistida (F2)', () {
    // 1x1 PNG transparente valido (mismo asset de result_sheet_test).
    const tinyPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=';
    Uint8List tinyPng() => base64Decode(tinyPngBase64);

    testWidgets('con foto: muestra un thumbnail Image.memory 44x44', (
      tester,
    ) async {
      // runAsync: el engine real de decode necesita el event loop real.
      await tester.runAsync(() async {
        await _pumpPageFree(tester, pieceImageBytes: tinyPng());
        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        expect(
          imageFinder,
          findsOneWidget,
          reason: 'Con foto persistida debe renderizar un thumbnail.',
        );
        final image = tester.widget<Image>(imageFinder);
        expect(image.width, 44);
        expect(image.height, 44);
        expect(image.fit, BoxFit.cover);
      });
    });

    testWidgets('sin foto: NO renderiza Image, mantiene el icono', (
      tester,
    ) async {
      await _pumpPageFree(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(
        find.byIcon(Icons.receipt_long_rounded),
        findsOneWidget,
        reason: 'Sin foto el card mantiene el leading icono de siempre.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Historial avanzado (PRD 2026-09-11): filtros de fecha, cliente,
  // material, orden y barra de resumen
  // ─────────────────────────────────────────────────────────────

  group('CalculationsListPage — historial avanzado (PRD 2026-09-11)', () {
    double dy(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('preset "7 días" filtra por fecha y el chip muestra "7 d"', (
      tester,
    ) async {
      final res = await _buildFreeContainer();
      final now = DateTime.now();
      await _seed(res.container, piece: 'Reciente', clientName: 'Ana');
      await _seed(
        res.container,
        piece: 'Vieja',
        clientName: 'Ana',
        createdAtUtc: now.toUtc().subtract(const Duration(days: 10)),
      );
      await _pumpContainer(tester, res.container);

      // Chip "Fechas" → sheet → preset "7 días".
      await tester.tap(find.text(EsBO.historyFilterDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.historyDatePreset7d));
      await tester.pumpAndSettle();

      expect(find.text('Reciente'), findsOneWidget);
      expect(find.text('Vieja'), findsNothing);
      expect(find.text('7 d'), findsOneWidget);

      // Con dateRange activo el contador free queda oculto y aparece la
      // barra de resumen ("· $" solo existe en ella).
      expect(find.textContaining('· \$', findRichText: true), findsOneWidget);
    });

    testWidgets('resumen visible SOLO con filtro activo', (tester) async {
      final res = await _buildFreeContainer();
      await _seed(res.container, piece: 'Sola', clientName: 'Ana');
      await _pumpContainer(tester, res.container);

      // Sin filtros no hay barra de resumen.
      expect(find.textContaining('· \$', findRichText: true), findsNothing);

      // Tap en el cliente filtra → aparece la barra.
      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();

      expect(find.textContaining('· \$', findRichText: true), findsOneWidget);
    });

    testWidgets('tap en el cliente filtra y el × del chip limpia', (
      tester,
    ) async {
      final res = await _buildFreeContainer();
      await _seed(res.container, piece: 'De Ana', clientName: 'Ana');
      await _seed(res.container, piece: 'De Beto', clientName: 'Beto');
      await _pumpContainer(tester, res.container);

      await tester.tap(find.text('Beto'));
      await tester.pumpAndSettle();

      expect(find.text(EsBO.historyClientFilterChip('Beto')), findsOneWidget);
      expect(find.text('De Beto'), findsOneWidget);
      expect(find.text('De Ana'), findsNothing);

      // × del chip limpia el filtro de cliente.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text(EsBO.historyClientFilterChip('Beto')), findsNothing);
      expect(find.text('De Ana'), findsOneWidget);
    });

    testWidgets('menú de orden: "Precio mayor" reordena por total efectivo', (
      tester,
    ) async {
      final res = await _buildFreeContainer();
      final now = DateTime.now();
      // Totales efectivos: A=100, B=60x3=180, C=50.
      await _seed(
        res.container,
        piece: 'A',
        price: Decimal.parse('100'),
        quantity: 1,
        createdAtUtc: now.toUtc().subtract(const Duration(days: 3)),
      );
      await _seed(
        res.container,
        piece: 'B',
        price: Decimal.parse('60'),
        quantity: 3,
        createdAtUtc: now.toUtc().subtract(const Duration(days: 2)),
      );
      await _seed(
        res.container,
        piece: 'C',
        price: Decimal.parse('50'),
        quantity: 1,
        createdAtUtc: now.toUtc().subtract(const Duration(days: 1)),
      );
      await _pumpContainer(tester, res.container);

      // Default: fecha reciente → C (arriba) < B < A.
      expect(dy(tester, 'C') < dy(tester, 'B'), isTrue);
      expect(dy(tester, 'B') < dy(tester, 'A'), isTrue);

      // AppBar actions → orden → "Precio mayor".
      await tester.tap(find.byTooltip(EsBO.historySortTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(EsBO.historySortPriceHigh));
      await tester.pumpAndSettle();

      // Precio mayor → B (180) < A (100) < C (50).
      expect(dy(tester, 'B') < dy(tester, 'A'), isTrue);
      expect(dy(tester, 'A') < dy(tester, 'C'), isTrue);
    });

    testWidgets('búsqueda encuentra por label de material', (tester) async {
      final res = await _buildFreeContainer();
      await _seed(
        res.container,
        piece: 'Engranaje',
        clientName: 'Ana',
        materialLabel: 'PLA+',
      );
      await _seed(
        res.container,
        piece: 'Soporte',
        clientName: 'Ana',
        materialLabel: 'PETG',
      );
      await _pumpContainer(tester, res.container);

      await tester.enterText(find.byType(TextField), 'pla+');
      await tester.pumpAndSettle();

      expect(find.text('Engranaje'), findsOneWidget);
      expect(find.text('Soporte'), findsNothing);
    });

    testWidgets('320dp: fila de chips extendida sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final res = await _buildFreeContainer();
      final now = DateTime.now();
      await _seed(res.container, piece: 'A', clientName: 'Cliente Largo');
      await _seed(
        res.container,
        piece: 'B',
        clientName: 'Cliente Largo',
        sold: true,
      );
      await _pumpContainer(tester, res.container);

      // Filtros activos via notifier (el canal de estado real del page).
      final notifier = res.container.read(
        calculationsNotifierProvider.notifier,
      );
      notifier.setClientFilter('Cliente Largo');
      notifier.setDateRange(
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InputChip), findsWidgets);
    });
  });
}
