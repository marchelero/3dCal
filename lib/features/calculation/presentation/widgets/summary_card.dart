// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../domain/entities/calculation_output.dart';
import '../state/calculator_state.dart' show CalculatorMode, CalculatorState, MaterialCostBreakdown;

/// Tarjeta resumen de la cotizacion.
///
/// Vive en su propio archivo (extraido de calculator_page.dart) para que
/// pueda ser reusada por [ResultSheet] sin tener que importar el page
/// completo ni exponer miembros privados.
///
/// **Meta info (Fix #2)**: opcionalmente muestra una fila con gramos usados
/// + tiempo de impresion debajo del precio hero. Si [metaGrams] y [metaTime]
/// son ambos null, la fila no se renderiza.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.output,
    required this.label,
    required this.discountPct,
    required this.showDetail,
    required this.onToggleDetail,
    required this.detailMaterialBreakdown,
    required this.detailElectricCost,
    required this.detailBaseCost,
    required this.detailProfitAmount,
    required this.detailTotalFinal,
    required this.metaGrams,
    required this.metaTime,
    super.key,
  });

  final CalculationOutput output;
  final String label;
  final String discountPct;
  final bool showDetail;
  final VoidCallback onToggleDetail;
  final List<MaterialCostBreakdown> detailMaterialBreakdown;
  final Decimal? detailElectricCost;
  final Decimal? detailBaseCost;
  final Decimal? detailProfitAmount;
  final Decimal? detailTotalFinal;

  /// Texto formateado de gramos usados (ej: "100 g"). Si null, no se renderiza.
  final String? metaGrams;

  /// Texto formateado de tiempo de impresion (ej: "5h 30m"). Si null, no se
  /// renderiza.
  final String? metaTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final hasLabel = label.trim().isNotEmpty;
    final hasDiscount = output.discountAmount > Decimal.zero;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primaryContainer,
            color.primaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xxxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label
          if (hasLabel) ...[
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          // Date
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.onPrimaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.xxxl),
            ),
            child: Text(
              DateFormat('dd MMM yyyy HH:mm').format(now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onPrimaryContainer.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Big price - HERO display. Usa estilo del tema + tabularFigures
          // para digitos monoespaciados. Sin GoogleFonts para evitar FOUT.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatBob(output.totalPrice),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Meta: gramos usados + tiempo de impresion (Fix #2).
          // Aparece justo debajo del precio hero, antes del subtitulo, para
          // que el usuario vea de un vistazo la "porcion" que esta pagando.
          if (metaGrams != null || metaTime != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                ?metaGrams,
                ?metaTime,
              ].join(EsBO.calcMetaSeparator),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.onPrimaryContainer.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Subtitle
          Text(
            'Total ${hasDiscount ? 'con descuento' : 'final'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          // Discount breakdown: subtotal → descuento → total
          if (hasDiscount) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: color.errorContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(
                children: [
                  _discountRow(
                    'Sin descuento',
                    formatBob(output.totalPrice + output.discountAmount),
                    theme,
                    color.onErrorContainer,
                  ),
                  const SizedBox(height: 6),
                  _discountRow(
                    'Descuento $discountPct%',
                    '-${formatBob(output.discountAmount)}',
                    theme,
                    color.onErrorContainer,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(
                      height: 1,
                      color: color.onErrorContainer.withValues(alpha: 0.3),
                    ),
                  ),
                  _discountRow(
                    'Total con descuento',
                    formatBob(output.totalPrice),
                    theme,
                    color.onErrorContainer,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],

          // Toggle detail
          const SizedBox(height: AppSpacing.lg),
          Align(
            child: TextButton.icon(
              icon: Icon(
                showDetail
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
                color: color.onPrimaryContainer,
              ),
              label: Text(
                showDetail ? EsBO.calcToggleHideDetail : EsBO.calcToggleShowDetail,
                style: TextStyle(color: color.onPrimaryContainer),
              ),
              onPressed: onToggleDetail,
            ),
          ),

          // Detail breakdown
          if (showDetail) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(
              height: 1,
              color: color.onPrimaryContainer.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.sm),
            DetailSection(
              materialCost: output.materialCost,
              materialBreakdown: detailMaterialBreakdown,
              electricCost: detailElectricCost ?? Decimal.zero,
              baseCost: detailBaseCost ?? Decimal.zero,
              profitAmount: detailProfitAmount ?? Decimal.zero,
              totalFinal: detailTotalFinal ?? Decimal.zero,
              textColor: color.onPrimaryContainer,
            ),
          ],
        ],
      ),
    );
  }
}

/// Seccion de detalle expandible: costo material, energia, base, ganancia,
/// total final. Renderizada dentro de [SummaryCard] cuando `showDetail`.
class DetailSection extends StatelessWidget {
  const DetailSection({
    required this.materialCost,
    required this.materialBreakdown,
    required this.electricCost,
    required this.baseCost,
    required this.profitAmount,
    required this.totalFinal,
    this.textColor,
    super.key,
  });

  final Decimal materialCost;
  final List<MaterialCostBreakdown> materialBreakdown;
  final Decimal electricCost;
  final Decimal baseCost;
  final Decimal profitAmount;
  final Decimal totalFinal;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = textColor ?? theme.colorScheme.onSurface;
    final s = theme.textTheme.bodySmall?.copyWith(
      color: tc.withValues(alpha: 0.8),
    );
    return Column(
      children: [
        // Per-material breakdown (si hay mas de 1 material)
        if (materialBreakdown.length > 1) ...[
          ...materialBreakdown.map((m) => _materialRow(m, theme, tc)),
          const SizedBox(height: AppSpacing.sm),
        ],
        _dr(EsBO.calcDetailMaterial, formatBob(materialCost), s, tc: tc),
        _dr(EsBO.calcDetailEnergy, formatBob(electricCost), s, tc: tc),
        _dr(EsBO.calcDetailBase, formatBob(baseCost), s, tc: tc),
        _dr(
          EsBO.calcDetailProfit,
          formatBob(profitAmount),
          s,
          tc: theme.colorScheme.primary,
          isProfit: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(
          height: 1,
          color: (textColor ?? theme.colorScheme.onSurface)
              .withValues(alpha: 0.2),
        ),
        const SizedBox(height: AppSpacing.md),
        _dr(
          EsBO.calcDetailTotal,
          formatBob(totalFinal),
          s,
          tc: tc,
          isTotal: true,
        ),
      ],
    );
  }

  /// Fila individual de costo por material en el desglose.
  Widget _materialRow(
    MaterialCostBreakdown m,
    ThemeData theme,
    Color tc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Text(
              m.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tc.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Text(
            formatBob(m.cost),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: tc.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dr(
    String label,
    String value,
    TextStyle? style, {
    Color? tc,
    bool isProfit = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: style?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : null,
              color: tc?.withValues(alpha: isTotal ? 1.0 : 0.8),
            ),
          ),
          Text(
            value,
            style: style?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: isTotal
                  ? FontWeight.bold
                  : isProfit
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: isProfit
                  ? tc
                  : isTotal
                  ? tc
                  : tc?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper: fila de breakdown de descuento (label | valor).
Widget _discountRow(
  String label,
  String value,
  ThemeData theme,
  Color color, {
  bool bold = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

/// Computa los strings de meta info (gramos usados + tiempo de impresion)
/// para mostrarlos en [SummaryCard] debajo del precio hero.
///
/// - Express: usa `state.weight` directo.
/// - Advanced: suma `state.materials[].weight`.
/// - Tiempo: combina `printHours` + `printMinutes` en formato "Xh Ym".
///
/// Si todos los valores son 0 retorna nulls (oculta la fila meta).
({String? grams, String? time}) computeMeta(CalculatorState state) {
  Decimal parseOrZero(String s) =>
      Decimal.tryParse(s.replaceAll(',', '.')) ?? Decimal.zero;

  final Decimal gramsDec;
  if (state.mode == CalculatorMode.express) {
    gramsDec = parseOrZero(state.weight);
  } else {
    gramsDec = state.materials.fold(
      Decimal.zero,
      (sum, m) => sum + parseOrZero(m.weight),
    );
  }
  final h = parseOrZero(state.printHours);
  final m = parseOrZero(state.printMinutes);
  // Para evitar el tipo Rational (resultado de Decimal/Decimal), trabajamos
  // directo en minutos (BigInt) y reconstruimos el string Xh Ym. El
  // formato final es siempre entero, asi que no perdemos precision.
  final totalMinutes = (h * Decimal.fromInt(60) + m).toBigInt();
  String? timeStr;
  if (totalMinutes > BigInt.zero) {
    final hh = totalMinutes ~/ BigInt.from(60);
    final mm = totalMinutes.remainder(BigInt.from(60));
    timeStr = '${hh.toInt()}h ${mm.toInt()}m';
  }

  final gramsStr = gramsDec > Decimal.zero
      ? '${NumberFormat.decimalPattern('es_BO').format(gramsDec.toDouble())} g'
      : null;
  return (grams: gramsStr, time: timeStr);
}
