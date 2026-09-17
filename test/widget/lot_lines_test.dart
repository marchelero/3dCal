// ignore_for_file: public_member_api_docs, no_leading_underscores_for_local_identifiers
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/money/currency_formatter.dart';
import 'package:tresdcal/core/money/currency_settings_provider.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/entitlement/data/entitlement_repository.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';
import 'package:tresdcal/features/entitlement/presentation/providers/entitlement_providers.dart';
import 'package:tresdcal/features/settings/data/discount_tiers_repository.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Widget tests de las líneas de lote en [CalculatorPage] (feature A — Hito 1).
///
/// **Scope**: verificar que la barra de total refleja el LOTE (subtotal ×
/// cantidad con descuento mayorista cuando aplica escalón) y que las líneas
/// compactas "Descuento por cantidad (X %)" / "Descuento (Y %)" aparecen
/// SOLO cuando hay escalón aplicado:
/// 1. N=1 sin escalones → cero líneas nuevas; el total queda IDÉNTICO al
///    math de hoy (`output.totalPrice × N`); sin hint.
/// 2. N=10 con escalón 10 → 10 % + descuento manual 10 % → 2 líneas, hint
///    "10 % desde 10 u." presente y total == `lotTotal` del estado.
///
/// **Setup**: `CalculatorPage` con fakes de entitlement (seedPro).
/// Los escalones se siembran en la DB in-memory vía
/// [DiscountTiersRepository.upsert] (el notifier los escucha por stream).

class _FakeEntitlementRepository implements EntitlementRepository {
  Entitlement? _active;

  void seedActive(Entitlement? e) => _active = e;

  @override
  Future<Entitlement?> getActive() async => _active;

  @override
  Future<int> save(EntitlementsCompanion entry) async => 1;

  @override
  Future<int> clear() async => 0;

  @override
  Stream<Entitlement?> watchActive() => const Stream<Entitlement?>.empty();
}

class _FakePaymentService implements PaymentService {
  @override
  bool get isAvailable => true;

  @override
  Future<void> configure() async {}

  @override
  Future<PaymentResult> purchase({required String productId}) async =>
      const PaymentCancelled();

  @override
  Future<RestoreResult> restore() async => const RestoreEmpty();

  @override
  Future<String?> getProPriceString() async => null;

  @override
  Future<bool?> isProActiveOnStore() async => null;

  @override
  Stream<void> get proRevocationStream => const Stream.empty();
}

/// Container con fakes + entitlement Pro activo. Resuelve el notifier ANTES
/// del pump para que la sección cantidad esté desbloqueada desde el inicio.
Future<ProviderContainer> _makeContainer({
  required AppDatabase db,
  required SharedPreferences prefs,
}) async {
  final repo = _FakeEntitlementRepository();
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
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementRepositoryProvider.overrideWithValue(repo),
      paymentServiceProvider.overrideWithValue(_FakePaymentService()),
    ],
  );
  await container.read(entitlementNotifierProvider.future);
  return container;
}

/// Monta [CalculatorPage] con el container dado y un pump que deja
/// asentarse el stream de escalones y el draft restore.
Future<ProviderContainer> _pumpCalculator(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CalculatorPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Llena el form Express (modo inicial) con un caso válido y controlable:
/// 100 g a $120/kg (1000 g), 5 h, sin descuento.
void _fillExpress(CalculatorNotifier n) {
  n
    ..setWeight('100')
    ..setFilamentPrice('120')
    ..setFilamentGrams('1000')
    ..setPrintHours('5')
    ..setPrintMinutes('0');
}

/// Finder de textos de pasos OCULTOS del wizard (IndexedStack): los widgets
/// de los pasos no visibles quedan montados pero offstage — estos asserts
/// verifican contenido/derivación del estado, no la pintura.
Finder offStep(String text) => find.text(text, skipOffstage: false);

Finder offStepContaining(String text) =>
    find.textContaining(text, skipOffstage: false);

void main() {
  setUp(() {
    EsBO.setImpl(const EsImpl());
  });

  Future<ProviderContainer> _setup(
    WidgetTester tester, {
    bool seedTier = false,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
    });
    final container = await _makeContainer(db: db, prefs: prefs);
    addTearDown(container.dispose);
    if (seedTier) {
      await container
          .read(discountTiersRepositoryProvider)
          .upsert(
            DiscountTier.create(minQty: 10, percent: Decimal.fromInt(10)),
          );
    }
    await _pumpCalculator(tester, container);
    return container;
  }

  group('Líneas de lote (feature A — Hito 1)', () {
    testWidgets('N=1 sin escalones: cero líneas nuevas y total de hoy', (
      tester,
    ) async {
      final container = await _setup(tester);

      _fillExpress(container.read(calculatorNotifierProvider.notifier));
      await tester.pumpAndSettle();

      final st = container.read(calculatorNotifierProvider);
      final currency = container.read(selectedCurrencyProvider);

      expect(
        st.showsBatchLine,
        isFalse,
        reason: 'Sin tier no hay línea batch.',
      );
      expect(st.batchAppliedPercent, isNull);
      // Regla 95 %: N=1 sin escalón → lotTotal == el math de hoy.
      expect(
        st.lotTotal,
        st.output!.totalPrice * Decimal.fromInt(st.quantity),
        reason: 'N=1 debe reproducir el total actual exacto.',
      );
      // Cero líneas nuevas (batch ni manual) — ni siquiera montadas
      // (offstage incluido: el paso resultado también está construido).
      expect(offStepContaining('Descuento por cantidad'), findsNothing);
      expect(offStepContaining('Descuento ('), findsNothing);
      expect(offStep('10 % desde 10 u.'), findsNothing);
      // El total mostrado es idéntico al de hoy.
      expect(
        find.text(formatCurrency(st.lotTotal, currency)),
        findsWidgets,
        reason: 'AppBar + bottom bar muestran el mismo total.',
      );
    });

    testWidgets(
      'N=10 con escalón 10→10 % + manual 10 %: 2 líneas + hint + lotTotal',
      (tester) async {
        final container = await _setup(tester, seedTier: true);

        final n = container.read(calculatorNotifierProvider.notifier);
        _fillExpress(n);
        n
          ..setQuantity(10)
          ..setDiscountPct('10');
        await tester.pumpAndSettle();

        final st = container.read(calculatorNotifierProvider);
        final currency = container.read(selectedCurrencyProvider);

        expect(st.showsBatchLine, isTrue, reason: 'Escalón 10→10 % aplica.');
        expect(st.batchAppliedPercent, Decimal.fromInt(10));
        expect(st.batchAppliedMinQty, 10);
        expect(
          st.batchDiscountAmount,
          greaterThan(Decimal.zero),
          reason: 'El lote de 10 descuenta el 10 % del subtotal.',
        );
        expect(
          st.lotTotal,
          lessThan(st.output!.totalPrice * Decimal.fromInt(st.quantity)),
          reason: 'El lotTotal ya incluye el desc. mayorista.',
        );

        // Línea batch ("Descuento por cantidad (10 %)") — paso Resultado,
        // montada pero offstage (el test ejercita el estado, no la pintura).
        expect(offStep('Descuento por cantidad (10%)'), findsOneWidget);
        // Línea manual ("Descuento manual (10%)").
        expect(offStep('Descuento manual (10%)'), findsOneWidget);
        // Hint del umbral activo (paso Ajustes).
        expect(offStep('10 % desde 10 u.'), findsOneWidget);
        // Total = lotTotal (AppBar + bottom bar).
        expect(find.text(formatCurrency(st.lotTotal, currency)), findsWidgets);
      },
    );

    testWidgets('N bajo el primer escalón: sin líneas ni hint', (tester) async {
      final container = await _setup(tester, seedTier: true);

      final n = container.read(calculatorNotifierProvider.notifier);
      _fillExpress(n);
      n.setQuantity(5);
      await tester.pumpAndSettle();

      final st = container.read(calculatorNotifierProvider);
      expect(st.showsBatchLine, isFalse, reason: 'N=5 < min_qty 10.');
      expect(st.batchAppliedPercent, isNull);
      expect(offStepContaining('Descuento por cantidad'), findsNothing);
      expect(offStep('10 % desde 10 u.'), findsNothing);
      // Total del lote sin descuento mayorista (igual al math de hoy).
      expect(st.lotTotal, st.output!.totalPrice * Decimal.fromInt(st.quantity));
    });
  });
}
