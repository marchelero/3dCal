// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/dashboard_stats.dart';
import 'package:tresdcal/features/calculation/domain/monthly_totals.dart';

void main() {
  group('DashboardStats.marginPct', () {
    test('profit / total * 100, redondeado a 2 decimales', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.fromInt(1000),
        totalSold: Decimal.fromInt(600),
        countAll: 10,
        countSold: 6,
        profitQuoted: Decimal.fromInt(200),
      );
      expect(stats.marginPct, Decimal.parse('20'));
    });

    test('null cuando total cotizado es 0 (no aplica)', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.zero,
        totalSold: Decimal.zero,
        countAll: 0,
        countSold: 0,
      );
      expect(stats.marginPct, isNull);
    });

    test('1/3 -> 33.33', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.fromInt(300),
        totalSold: Decimal.fromInt(100),
        countAll: 3,
        countSold: 1,
        profitQuoted: Decimal.fromInt(100),
      );
      expect(stats.marginPct, Decimal.parse('33.33'));
    });
  });

  group('DashboardStats avgTicket', () {
    test('avgTicketQuoted = totalQuoted / countAll', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.fromInt(1000),
        totalSold: Decimal.fromInt(600),
        countAll: 10,
        countSold: 6,
      );
      expect(stats.avgTicketQuoted, Decimal.fromInt(100));
      expect(stats.avgTicketSold, Decimal.fromInt(100));
    });

    test('null cuando el count es 0', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.zero,
        totalSold: Decimal.zero,
        countAll: 0,
        countSold: 0,
      );
      expect(stats.avgTicketQuoted, isNull);
      expect(stats.avgTicketSold, isNull);
    });
  });

  group('DashboardStats.conversionPct (no regression)', () {
    test('mantiene el comportamiento BUG-023', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.fromInt(40000),
        totalSold: Decimal.fromInt(40000),
        countAll: 4,
        countSold: 4,
      );
      expect(stats.conversionPct, 100.0);
    });
  });

  group('DashboardStats monthly totals', () {
    test('existe el mejor mes para insights', () {
      final stats = DashboardStats(
        totalQuoted: Decimal.zero,
        totalSold: Decimal.zero,
        countAll: 0,
        countSold: 0,
        monthlyTotals: [
          MonthlyTotal(
            yearMonth: '2026-05',
            quoted: Decimal.fromInt(10000),
            sold: Decimal.fromInt(6000),
          ),
          MonthlyTotal(
            yearMonth: '2026-06',
            quoted: Decimal.fromInt(20000),
            sold: Decimal.fromInt(12000),
          ),
        ],
      );
      expect(stats.monthlyTotals, hasLength(2));
    });
  });
}
