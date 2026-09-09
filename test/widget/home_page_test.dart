// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/presentation/notifiers/calculations_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/pages/home_page.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/quote_guide_dialog.dart';
import 'package:tresdcal/features/settings/domain/settings.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Fake de settings: devuelve defaults sin tocar drift/SP.
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => Settings.defaults;
}

/// Fake de la lista de cotizaciones: devuelve [items] fijos sin DB.
class _FakeCalculationsNotifier extends CalculationsNotifier {
  _FakeCalculationsNotifier(this.items);

  final List<CalculationListItem> items;

  @override
  Future<List<CalculationListItem>> build() async => items;
}

CalculationListItem _item({
  required int id,
  required DateTime createdAt,
  String? pieceName,
  String? clientName,
  bool isSold = false,
  double total = 100.0,
}) =>
    CalculationListItem(
      id: id,
      createdAt: createdAt,
      pieceName: pieceName,
      clientName: clientName,
      quantity: 1,
      totalHours: 2,
      discountPercentage: 0,
      isSold: isSold,
      materialCostSnapshot: 50,
      electricCostSnapshot: 10,
      profitAmountSnapshot: 40,
      totalPriceSnapshot: total,
      hasImage: false,
    );

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
    GoRoute(
      path: '/calculator',
      builder: (_, _) => const Scaffold(body: Text('CALC_PAGE')),
    ),
    GoRoute(
      path: '/history/:id',
      builder: (_, _) => const Scaffold(body: Text('DETAIL_PAGE')),
    ),
  ],
);

Future<void> _pumpHome(
  WidgetTester tester, {
  required List<CalculationListItem> items,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsNotifierProvider.overrideWith(_FakeSettingsNotifier.new),
        calculationsNotifierProvider.overrideWith(
          () => _FakeCalculationsNotifier(items),
        ),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final now = DateTime(2026, 9, 9, 12);
  final items4 = [
    _item(
      id: 1,
      createdAt: now.subtract(const Duration(days: 1)),
      pieceName: 'Vaso',
      clientName: 'Ana',
      total: 150,
    ),
    _item(
      id: 2,
      createdAt: now.subtract(const Duration(days: 3)),
      pieceName: 'Engranaje',
      total: 80,
    ),
    _item(
      id: 3,
      createdAt: now.subtract(const Duration(days: 5)),
      pieceName: 'Figura',
      clientName: 'Luis',
      total: 200,
    ),
    _item(
      id: 4,
      createdAt: now.subtract(const Duration(days: 7)),
      pieceName: 'Soporte',
      total: 40,
    ),
  ];

  group('HomePage — dedup Home/Dashboard', () {
    testWidgets(
      'AC-001: no muestra las stats duplicadas del Dashboard',
      (tester) async {
        await _pumpHome(tester, items: items4);

        expect(find.text('Cotizaciones'), findsNothing);
        expect(find.text('Vendidas'), findsNothing);
        expect(find.text('Conversión'), findsNothing);
        expect(find.text('Últimas cotizaciones'), findsOneWidget);
      },
    );

    testWidgets(
      'AC-002: muestra solo las 3 mas recientes en orden desc',
      (tester) async {
        await _pumpHome(tester, items: items4);

        expect(find.text('Vaso'), findsOneWidget);
        expect(find.text('Engranaje'), findsOneWidget);
        expect(find.text('Figura'), findsOneWidget);
        // La mas vieja queda fuera (solo 3).
        expect(find.text('Soporte'), findsNothing);

        final dyVaso = tester.getTopLeft(find.text('Vaso')).dy;
        final dyEng = tester.getTopLeft(find.text('Engranaje')).dy;
        final dyFig = tester.getTopLeft(find.text('Figura')).dy;
        expect(dyVaso < dyEng && dyEng < dyFig, isTrue,
            reason: 'La mas nueva (Vaso) debe estar arriba de las otras.');
      },
    );

    testWidgets('AC-002: tap en una cotizacion navega al detalle', (
      tester,
    ) async {
      await _pumpHome(tester, items: items4);

      await tester.ensureVisible(find.text('Vaso'));
      await tester.tap(find.text('Vaso'));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL_PAGE'), findsOneWidget);
    });

    testWidgets(
      'AC-003: sin cotizaciones muestra CTA "Nueva cotización"',
      (tester) async {
        await _pumpHome(tester, items: []);

        expect(find.text(EsBO.homeEmptyQuotations), findsOneWidget);
        final cta = find.widgetWithText(FilledButton, EsBO.homeEmptyCta);
        expect(cta, findsOneWidget);

        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.text('CALC_PAGE'), findsOneWidget);
      },
    );

    testWidgets('AC-004: con 1 cotizacion la muestra sin romper', (
      tester,
    ) async {
      await _pumpHome(tester, items: [items4[3]]);

      expect(find.text('Soporte'), findsOneWidget);
      expect(find.text('Últimas cotizaciones'), findsOneWidget);
    });

    testWidgets('AC-006: la guia de cotizacion abre desde la Home', (
      tester,
    ) async {
      await _pumpHome(tester, items: []);

      await tester.ensureVisible(find.text(EsBO.quoteGuideTitle));
      await tester.tap(find.text(EsBO.quoteGuideTitle));
      await tester.pumpAndSettle();

      expect(find.byType(QuoteGuideDialog), findsOneWidget);
    });
  });
}
