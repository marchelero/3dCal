// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers.dart';
import '../presentation/notifiers/calculations_notifier.dart';
import 'monthly_totals.dart';

/// Stats agregadas del historial de cotizaciones.
///
/// **Uso**: dashboard / home page. Muestra totales y counts en un solo
/// read derivado. Se invalida cuando [calculationsNotifierProvider]
/// cambia (al guardar / eliminar / toggle sold).
class DashboardStats {
  DashboardStats({
    required this.totalQuoted,
    required this.totalSold,
    required this.countAll,
    required this.countSold,
    Decimal? profitQuoted,
    Decimal? profitSold,
    this.monthlyTotals = const [],
    this.topMaterials = const [],
    this.topClients = const [],
    this.printHours = 0,
    Decimal? filamentGrams,
    this.since,
  }) : profitQuoted = profitQuoted ?? Decimal.zero,
       profitSold = profitSold ?? Decimal.zero,
       filamentGrams = filamentGrams ?? Decimal.zero;

  final Decimal totalQuoted;
  final Decimal totalSold;
  final int countAll;
  final int countSold;

  /// Ganancia estimada de todas las cotizaciones (suma
  /// profit_amount_snapshot).
  ///
  /// NOTA (legacy): los registros historicos guardan profit 0 → este
  /// valor puede subestimar con datos viejos. Ver BUG-003/BUG-011 (Decimal
  /// obligatorio en dinero).
  final Decimal profitQuoted;

  /// Ganancia estimada de cotizaciones vendidas.
  final Decimal profitSold;

  /// Totales mensuales para trend chart.
  final List<MonthlyTotal> monthlyTotals;

  /// Top 5 materiales mas usados.
  final List<TopMaterial> topMaterials;

  /// Top clientes por total cotizado (Pro analytics).
  final List<TopClient> topClients;

  /// Horas totales de impresion. No es dinero → double permitido.
  final double printHours;

  /// Gramos totales de filamento cotizado (Decimal por consistencia con el
  /// resto del motor; se formatea g→kg en la UI).
  final Decimal filamentGrams;

  /// Filtro de rango aplicado (created_at >= since). `null` = todo.
  final DateTime? since;

  /// Porcentaje de cotizaciones vendidas (0.0 - 100.0).
  ///
  /// Retorna `null` si `countAll == 0` (aun no hay cotizaciones): "no
  /// aplica" es semanticamente distinto de "0%". La UI debe mostrar "—".
  /// (BUG-023 fix)
  ///
  /// NOTA (BUG-011): es un ratio no monetario, por eso se permite `double`
  /// aca — excepcion documentada al non-negotiable "no doubles en dinero".
  double? get conversionPct {
    if (countAll == 0) return null;
    return (countSold / countAll) * 100;
  }

  /// Margen promedio: ganancia cotizada / total cotizado * 100.
  ///
  /// Retorna `null` si `totalQuoted == 0` ("no aplica", la UI muestra "—").
  /// Decimal: es dinero implicito, respeta el non-negotiable.
  ///
  /// NOTA: `Decimal / Decimal` devuelve `Rational` (precision extendida),
  /// asi que se convierte a Decimal y se redondea a 2 decimales.
  Decimal? get marginPct {
    if (totalQuoted == Decimal.zero) return null;
    // Multiplicar antes de dividir: Decimal*Decimal → Decimal; solo la
    // division produce Rational (ver NOTA arriba).
    final pct = (profitQuoted * Decimal.fromInt(100)) / totalQuoted;
    return pct.toDecimal(scaleOnInfinitePrecision: 4).round(scale: 2);
  }

  /// Ticket promedio de una cotizacion cotizada (totalQuoted / countAll).
  ///
  /// `null` si `countAll == 0`. Derivado de totales existentes, sin query
  /// nueva.
  Decimal? get avgTicketQuoted {
    if (countAll == 0) return null;
    final ratio = totalQuoted / Decimal.fromInt(countAll);
    return ratio.toDecimal(scaleOnInfinitePrecision: 2);
  }

  /// Ticket promedio de una cotizacion vendida (totalSold / countSold).
  ///
  /// `null` si `countSold == 0`. Derivado de totales existentes.
  Decimal? get avgTicketSold {
    if (countSold == 0) return null;
    final ratio = totalSold / Decimal.fromInt(countSold);
    return ratio.toDecimal(scaleOnInfinitePrecision: 2);
  }
}

/// Rango de fechas activo del dashboard Pro. `null` = "Todo" (sin filtro).
///
/// Los ChoiceChips del dashboard lo setean; [dashboardStatsProvider] se
/// re-ejecuta al cambiar (families autoDispose re-corren con el nuevo arg).
final dashboardRangeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider derivado: queries agregadas + monthly + top materials + top
/// clientes + metricas operativas.
/// Se re-corre cuando [calculationsNotifierProvider] emite nuevo state o
/// cuando [dashboardRangeProvider] cambia (family con el rango como arg).
final dashboardStatsProvider = FutureProvider.autoDispose
    .family<DashboardStats, DateTime?>((ref, since) async {
      ref.watch(calculationsNotifierProvider);
      final repo = ref.watch(calculationRepositoryProvider);
      // Las 11 queries son independientes entre si: se disparan todas
      // primero y se esperan despues, para no encadenar sus latencias.
      final quotedF = repo.totalQuoted(since: since);
      final soldF = repo.totalSold(since: since);
      final countAllF = repo.countAll(since: since);
      final countSoldF = repo.countSold(since: since);
      final profitQuotedF = repo.totalProfitQuoted(since: since);
      final profitSoldF = repo.totalProfitSold(since: since);
      final monthlyF = repo.monthlyTotals(since: since);
      final materialsF = repo.topMaterials(since: since);
      final clientsF = repo.topClients(since: since);
      final hoursF = repo.totalPrintHours(since: since);
      final gramsF = repo.totalFilamentGrams(since: since);
      return DashboardStats(
        totalQuoted: await quotedF,
        totalSold: await soldF,
        countAll: await countAllF,
        countSold: await countSoldF,
        profitQuoted: await profitQuotedF,
        profitSold: await profitSoldF,
        monthlyTotals: await monthlyF,
        topMaterials: await materialsF,
        topClients: await clientsF,
        printHours: await hoursF,
        filamentGrams: await gramsF,
        since: since,
      );
    });
