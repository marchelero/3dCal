/// Datos agregados por mes para el dashboard.
library;
// ignore_for_file: public_member_api_docs

/// Totals de un mes especifico.
class MonthlyTotal {
  const MonthlyTotal({
    required this.yearMonth,
    required this.quoted,
    required this.sold,
  });

  /// "YYYY-MM"
  final String yearMonth;

  /// Suma totalPriceSnapshot del mes (BOB).
  final double quoted;

  /// Suma totalPriceSnapshot del mes donde isSold=true (BOB).
  final double sold;
}

/// Material mas usado (top N para dashboard).
class TopMaterial {
  const TopMaterial({
    required this.label,
    required this.count,
    required this.totalWeightGrams,
  });

  final String label;
  final int count;
  final double totalWeightGrams;
}
