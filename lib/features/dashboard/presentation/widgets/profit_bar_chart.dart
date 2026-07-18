// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../l10n/es_bo.dart';

/// Bar chart 2 barras: Cotizado vs Ganado (PRD AC-8.1/AC-8.2).
///
/// **Uso**: dashboard. Las barras se renderizan desde 0 hasta
/// `max(valueTotalQuoted, valueTotalSold) * 1.2` para dejar headroom
/// visual. Eje Y formatea con sufijo "K" si el valor supera 1000 BOB.
///
/// **Por que recibe `Decimal`**: el resto de la app trabaja en Decimal
/// para evitar floating point errors (NFR-2). fl_chart internamente usa
/// double, asi que el `toDouble()` es el unico lugar donde se pierde
/// precision (los valores de las cotizaciones ya estan redondeados a 2
/// decimales al guardarse).
class ProfitBarChart extends StatelessWidget {
  /// Construye el bar chart con los totales agregados.
  const ProfitBarChart({
    required this.totalQuoted,
    required this.totalSold,
    required this.currency,
    super.key,
  });

  /// Suma de `totalPriceSnapshot` de TODAS las cotizaciones.
  final Decimal totalQuoted;

  /// Suma de `totalPriceSnapshot` de las cotizaciones con `isSold=true`.
  final Decimal totalSold;

  /// Configuracion monetaria activa para formateo.
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quotedColor = theme.colorScheme.primary;
    final soldColor = theme.colorScheme.tertiary;
    final quotedValue = totalQuoted.toDouble();
    final soldValue = totalSold.toDouble();
    // maxY: 20% headroom sobre el max de las 2 barras. Floor 100 BOB
    // para que charts con valores chicos no se vean ridiculos.
    final maxValue = quotedValue > soldValue ? quotedValue : soldValue;
    final maxY = (maxValue * 1.2).clamp(100.0, double.infinity);

    return Semantics(
      label: '${EsBO.dashboardChartQuoted} ${formatCurrency(totalQuoted, currency)}, '
          '${EsBO.dashboardChartSold} ${formatCurrency(totalSold, currency)}',
      child: AspectRatio(
        aspectRatio: 1.5,
        child: BarChart(
        // fl_chart 0.68 auto-anima en rebuilds con datos nuevos
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: quotedValue,
                  color: quotedColor,
                  gradient: LinearGradient(
                    colors: [
                      quotedColor.withValues(alpha: 0.4),
                      quotedColor,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: soldValue,
                  color: soldColor,
                  gradient: LinearGradient(
                    colors: [
                      soldColor.withValues(alpha: 0.4),
                      soldColor,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(
                      _formatYLabel(value, currency.symbol),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final label =
                      value == 0 ? EsBO.dashboardChartQuoted : EsBO.dashboardChartSold;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label =
                    group.x == 0 ? EsBO.dashboardChartQuoted : EsBO.dashboardChartSold;
                return BarTooltipItem(
                  '$label\n${currency.symbol} ${rod.toY.toStringAsFixed(2)}',
                  theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// Formato corto del eje Y: "{symbol} 0" / "{symbol} 1.5K" / "{symbol} 12.3K".
  static String _formatYLabel(double value, String symbol) {
    if (value == 0) return '$symbol 0';
    if (value < 1000) return '$symbol ${value.toStringAsFixed(0)}';
    final k = value / 1000;
    return '$symbol ${k.toStringAsFixed(1)}K';
  }
}
