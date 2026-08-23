/// Datos agregados por mes para el dashboard.
library;
// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Totals de un mes especifico.
@immutable
class MonthlyTotal {
  const MonthlyTotal({
    required this.yearMonth,
    required this.quoted,
    required this.sold,
  });

  /// "YYYY-MM"
  final String yearMonth;

  /// Suma totalPriceSnapshot del mes (BOB).
  // BUG-003 fix: Decimal para respetar el non-negotiable "no doubles en
  // dinero". La precision agregada importa con 50+ cotizaciones grandes.
  final Decimal quoted;

  /// Suma totalPriceSnapshot del mes donde isSold=true (BOB).
  final Decimal sold;
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

  /// Decimal para mantener precision consistente con el resto del motor.
  final Decimal totalWeightGrams;
}
