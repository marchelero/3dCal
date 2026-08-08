// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/domain/dashboard_stats.dart';
import 'package:tresdcal/features/calculation/domain/monthly_totals.dart';
import 'package:tresdcal/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:tresdcal/core/money/currency.dart';
import 'package:tresdcal/features/dashboard/presentation/providers/dashboard_entitlement_provider.dart';
import 'package:tresdcal/features/dashboard/presentation/widgets/profit_bar_chart.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Helper: monta [DashboardPage] dentro de un [ProviderScope] con
/// [dashboardStatsProvider] overriden a un [DashboardStats] fijo.
Future<void> _pumpPage(
  WidgetTester tester, {
  required DashboardStats stats,
  bool isPro = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardStatsProvider.overrideWith(
          (ref) => Future<DashboardStats>.value(stats),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        dashboardIsProProvider.overrideWithValue(isPro),
      ],
      child: const MaterialApp(home: DashboardPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final emptyStats = DashboardStats(
    totalQuoted: Decimal.zero,
    totalSold: Decimal.zero,
    countAll: 0,
    countSold: 0,
  );

  group('DashboardPage', () {
    testWidgets('muestra appbar con titulo Dashboard', (tester) async {
      await _pumpPage(tester, stats: emptyStats);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets(
      'empty state: muestra CTA "Ir a Home" cuando no hay cotizaciones',
      (tester) async {
        await _pumpPage(tester, stats: emptyStats);
        expect(find.textContaining('Aun no cotizaste nada'), findsOneWidget);
        expect(find.textContaining('Crea tu primera cotizacion desde el inicio'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Ir a Home'),
          findsOneWidget,
        );
        // No hay stat cards ni chart en empty state.
        expect(find.byType(BarChart), findsNothing);
      },
    );

    testWidgets(
      'con datos (Pro): muestra 3 stat cards + BarChart + labels eje X',
      (tester) async {
        await _pumpPage(
          tester,
          isPro: true,
          stats: DashboardStats(
            totalQuoted: Decimal.fromInt(50000),
            totalSold: Decimal.fromInt(30000),
            countAll: 10,
            countSold: 6,
          ),
        );
        expect(find.text('Cotizaciones'), findsOneWidget);
        expect(find.text('Vendidas'), findsOneWidget);
        expect(find.text('Conversion'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
        expect(find.byType(BarChart), findsOneWidget);
        expect(find.text('Cotizado'), findsOneWidget);
        expect(find.text('Ganado'), findsOneWidget);
      },
    );

    testWidgets(
      'conversion 100% cuando todas las cotizaciones estan vendidas',
      (tester) async {
        await _pumpPage(
          tester,
          isPro: true,
          stats: DashboardStats(
            totalQuoted: Decimal.fromInt(40000),
            totalSold: Decimal.fromInt(40000),
            countAll: 4,
            countSold: 4,
          ),
        );
        expect(find.text('100%'), findsOneWidget);
      },
    );

    testWidgets(
      'conversion 0% cuando ninguna cotizacion esta vendida',
      (tester) async {
        await _pumpPage(
          tester,
          isPro: true,
          stats: DashboardStats(
            totalQuoted: Decimal.fromInt(40000),
            totalSold: Decimal.zero,
            countAll: 4,
            countSold: 0,
          ),
        );
        expect(find.text('0%'), findsOneWidget);
      },
    );
  });

  group('ProfitBarChart', () {
    testWidgets('renderiza 2 barras (BarChartGroupData x=0 y x=1)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitBarChart(
              totalQuoted: Decimal.fromInt(1000),
              totalSold: Decimal.fromInt(500),
              currency: WorldCurrency.usd,
            ),
          ),
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('con ambos en cero: renderiza sin crashear', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitBarChart(
              totalQuoted: Decimal.zero,
              totalSold: Decimal.zero,
              currency: WorldCurrency.usd,
            ),
          ),
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
    });
  });

  group('DashboardPage — Pro gate (T17)', () {
    final richStats = DashboardStats(
      totalQuoted: Decimal.fromInt(50000),
      totalSold: Decimal.fromInt(30000),
      countAll: 10,
      countSold: 6,
      monthlyTotals: const [
        MonthlyTotal(yearMonth: '2026-05', quoted: 10000, sold: 6000),
        MonthlyTotal(yearMonth: '2026-06', quoted: 20000, sold: 12000),
        MonthlyTotal(yearMonth: '2026-07', quoted: 20000, sold: 12000),
      ],
      topMaterials: const [
        TopMaterial(label: 'PLA Negro', count: 5, totalWeightGrams: 800),
        TopMaterial(label: 'PETG', count: 3, totalWeightGrams: 500),
      ],
    );

    testWidgets(
      'free: muestra stats + totals + Pro teaser; oculta chart sections',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPage(tester, stats: richStats, isPro: false);

        expect(find.text('Cotizaciones'), findsOneWidget);
        expect(find.text('Vendidas'), findsOneWidget);
        expect(find.text('Conversion'), findsOneWidget);
        expect(find.text(EsBO.dashboardTotalQuoted), findsOneWidget);
        expect(find.text(EsBO.dashboardTotalSold), findsOneWidget);

        expect(find.text(EsBO.dashboardProTeaserTitle), findsOneWidget);
        expect(find.text(EsBO.dashboardProTeaserBody), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, EsBO.dashboardGoProAction),
          findsOneWidget,
          reason: 'Free user debe ver el boton "Go Pro" en el teaser.',
        );

        expect(find.text(EsBO.dashboardChartTitle), findsNothing,
            reason: 'Free: ProfitBarChart card oculto.');
        expect(find.text('Tendencia mensual'), findsNothing,
            reason: 'Free: MonthlyTrendChart card oculto.');
        expect(find.text('Materiales mas usados'), findsNothing,
            reason: 'Free: TopMaterials card oculto.');

        expect(find.byType(BarChart), findsNothing);
        expect(find.byType(LineChart), findsNothing);
      },
    );

    testWidgets(
      'pro: muestra todas las chart sections; oculta Pro teaser',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpPage(tester, stats: richStats, isPro: true);

        expect(find.text('Cotizaciones'), findsOneWidget);
        expect(find.text(EsBO.dashboardTotalQuoted), findsOneWidget);

        expect(find.text(EsBO.dashboardChartTitle), findsOneWidget,
            reason: 'Pro: ProfitBarChart card visible.');
        expect(find.byType(BarChart), findsOneWidget,
            reason: 'Pro: BarChart renderizado.');
        expect(find.text('Tendencia mensual'), findsOneWidget,
            reason: 'Pro: MonthlyTrendChart card visible.');
        expect(find.byType(LineChart), findsOneWidget,
            reason: 'Pro: LineChart renderizado.');
        expect(find.text('Materiales mas usados'), findsOneWidget,
            reason: 'Pro: TopMaterials card visible.');

        expect(find.text(EsBO.dashboardProTeaserTitle), findsNothing);
        expect(find.text(EsBO.dashboardProTeaserBody), findsNothing);
        expect(
          find.widgetWithText(FilledButton, EsBO.dashboardGoProAction),
          findsNothing,
          reason: 'Pro: no debe haber boton "Go Pro" en el dashboard.',
        );
      },
    );

    testWidgets(
      'free: empty-state no muestra Pro teaser (gate no rompe empty path)',
      (tester) async {
        await _pumpPage(tester, stats: emptyStats, isPro: false);

        expect(find.textContaining('Aun no cotizaste nada'), findsOneWidget);
        expect(find.text(EsBO.dashboardProTeaserTitle), findsNothing);
        expect(
          find.widgetWithText(FilledButton, EsBO.dashboardGoProAction),
          findsNothing,
        );
      },
    );
  });
}
