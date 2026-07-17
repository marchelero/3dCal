/// LineChart de tendencia mensual (cotizado vs vendido).
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../calculation/domain/monthly_totals.dart';

class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({
    required this.data,
    super.key,
  });

  final List<MonthlyTotal> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Sin datos mensuales',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxVal = data.fold<double>(0, (max, m) => m.quoted > max ? m.quoted : max);
    final ceiling = maxVal == 0 ? 100.0 : (maxVal * 1.2);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ceiling / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: color.outlineVariant.withAlpha(80),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) => Text(
                  _formatAxis(value),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _labelInterval(),
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  final label = data[idx].yearMonth;
                  // Show only MMM
                  final parts = label.split('-');
                  final short = parts.length == 2 ? _monthAbbr(int.parse(parts[1])) : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      short,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Cotizado (linea azul)
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.quoted)).toList(),
              isCurved: true,
              color: color.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.primary.withAlpha(40),
              ),
            ),
            // Vendido (linea verde)
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sold)).toList(),
              isCurved: true,
              color: color.tertiary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.tertiary.withAlpha(40),
              ),
            ),
          ],
          minY: 0,
          maxY: ceiling,
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  double _labelInterval() {
    if (data.length <= 6) return 1;
    if (data.length <= 12) return 2;
    return 3;
  }

  String _formatAxis(double value) {
    if (value >= 1000) {
      return 'Bs. ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Bs. ${value.toStringAsFixed(0)}';
  }

  String _monthAbbr(int m) {
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return m >= 1 && m <= 12 ? months[m] : '?';
  }
}
