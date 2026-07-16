// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/dashboard_stats.dart';
import 'package:tresdcal/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:tresdcal/features/dashboard/presentation/widgets/profit_bar_chart.dart';

/// Helper: monta [DashboardPage] dentro de un [ProviderScope] con
/// [dashboardStatsProvider] overriden a un [DashboardStats] fijo.
Future<void> _pumpPage(
  WidgetTester tester, {
  required DashboardStats stats,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardStatsProvider.overrideWith(
          (ref) => Future<DashboardStats>.value(stats),
        ),
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
      'con datos: muestra 3 stat cards (Cotizaciones / Vendidas / Conversion)',
      (tester) async {
        await _pumpPage(
          tester,
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
        expect(find.text('10'), findsOneWidget); // countAll
        expect(find.text('6'), findsOneWidget); // countSold
        // 6/10 = 60%
        expect(find.text('60%'), findsOneWidget);
        // chart presente
        expect(find.byType(BarChart), findsOneWidget);
        // labels eje X
        expect(find.text('Cotizado'), findsOneWidget);
        expect(find.text('Ganado'), findsOneWidget);
      },
    );

    testWidgets(
      'conversion 100% cuando todas las cotizaciones estan vendidas',
      (tester) async {
        await _pumpPage(
          tester,
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
            ),
          ),
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}
