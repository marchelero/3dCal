// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../state/calculator_state.dart' show MaterialCostBreakdown;

/// Seccion de detalle expandible: costo material, energia, mano de obra,
/// post-procesado, base, falla, markup, ganancia, cargo minimo y total final.
///
/// Extraido de [SummaryCard] para ser compartido con [QuoteImageTemplate].
class DetailSection extends StatelessWidget {
  DetailSection({
    required this.materialCost,
    required this.materialBreakdown,
    required this.electricCost,
    required this.laborCost,
    required this.postProcessCost,
    required this.baseCost,
    required this.failureCost,
    required this.markupCost,
    required this.profitAmount,
    required this.totalFinal,
    Decimal? amortizationCost,
    // v17: Extras (argollas, pegamento, etc.). Aparece solo si > 0.
    Decimal? extrasCost,
    // v17: descripcion libre del extra ("2 argollas M3"). Si esta vacia o el
    // monto es 0, no aparece en la fila.
    this.extraLabel = '',
    this.currency = WorldCurrency.bob,
    this.textColor,
    super.key,
  }) : amortizationCost = amortizationCost ?? Decimal.zero,
       extrasCost = extrasCost ?? Decimal.zero;

  final Decimal materialCost;
  final List<MaterialCostBreakdown> materialBreakdown;
  final Decimal electricCost;

  /// Amortizacion de la impresora (F5). Se conserva el campo por
  /// compatibilidad, pero NO se muestra: la amortizacion queda fuera del
  /// costo y de todos los reportes (expreso y avanzado).
  final Decimal amortizationCost;

  final Decimal laborCost;
  final Decimal postProcessCost;
  final Decimal baseCost;
  final Decimal failureCost;
  final Decimal markupCost;

  /// v17: Extras. `Decimal.zero` si no se cobra o no se seteo.
  final Decimal extrasCost;

  /// v17: descripcion libre del extra ("2 argollas M3"). Cadena vacia por
  /// default: en ese caso la fila Extras solo muestra el monto.
  final String extraLabel;

  final Decimal profitAmount;
  final Decimal totalFinal;

  /// Moneda activa para formatear las filas del desglose.
  final WorldCurrency currency;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = textColor ?? theme.colorScheme.onSurface;
    final s = theme.textTheme.bodySmall?.copyWith(
      color: tc.withValues(alpha: 0.8),
    );
    final hasExtras =
        laborCost > Decimal.zero ||
        postProcessCost > Decimal.zero ||
        failureCost > Decimal.zero ||
        markupCost > Decimal.zero ||
        extrasCost > Decimal.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Per-material breakdown (si hay mas de 1 material)
        if (materialBreakdown.length > 1) ...[
          ...materialBreakdown.map((m) => _materialRow(m, theme, tc)),
          const SizedBox(height: AppSpacing.sm),
        ],
        _dr(
          EsBO.calcDetailMaterial,
          formatCurrency(materialCost, currency),
          s,
          tc: tc,
        ),
        _dr(
          EsBO.calcDetailEnergy,
          formatCurrency(electricCost, currency),
          s,
          tc: tc,
        ),
        // F5: sin fila de amortizacion — la amortizacion de la impresora no
        // entra en el costo ni en el desglose (expreso y avanzado).
        if (laborCost > Decimal.zero)
          _dr(
            EsBO.calcDetailModeling,
            formatCurrency(laborCost, currency),
            s,
            tc: tc,
          ),
        if (postProcessCost > Decimal.zero)
          _dr(
            EsBO.calcDetailPostProcess,
            formatCurrency(postProcessCost, currency),
            s,
            tc: tc,
          ),
        // v17: Extras con label opcional. Si el usuario ingreso descripcion
        // (ej: "2 argollas M3"), se muestra adyacente al titulo para que
        // el reporte explique que es ese cobro extra.
        if (extrasCost > Decimal.zero)
          _dr(
            extraLabel.isNotEmpty
                ? '${EsBO.calcExtraExtras} ($extraLabel)'
                : EsBO.calcExtraExtras,
            formatCurrency(extrasCost, currency),
            s,
            tc: tc,
          ),
        _dr(
          EsBO.calcDetailBase,
          formatCurrency(baseCost, currency),
          s,
          tc: tc,
          isSubtotal: hasExtras,
        ),
        if (failureCost > Decimal.zero)
          _dr(
            EsBO.calcDetailFailure,
            formatCurrency(failureCost, currency),
            s,
            tc: tc,
          ),
        if (markupCost > Decimal.zero)
          _dr(
            EsBO.calcDetailMarkup,
            formatCurrency(markupCost, currency),
            s,
            tc: tc,
          ),
        _dr(
          EsBO.calcDetailProfit,
          formatCurrency(profitAmount, currency),
          s,
          tc: theme.colorScheme.primary,
          isProfit: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(
          height: 1,
          color: (textColor ?? theme.colorScheme.onSurface).withValues(
            alpha: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _dr(
          EsBO.calcDetailTotal,
          formatCurrency(totalFinal, currency),
          s,
          tc: tc,
          isTotal: true,
        ),
      ],
    );
  }

  /// Fila individual de costo por material en el desglose.
  Widget _materialRow(MaterialCostBreakdown m, ThemeData theme, Color tc) {
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
            formatCurrency(m.cost, currency),
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
    bool isSubtotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: style?.copyWith(
              fontWeight: isTotal
                  ? FontWeight.w600
                  : isSubtotal
                  ? FontWeight.w600
                  : null,
              color: tc?.withValues(
                alpha: isTotal
                    ? 1.0
                    : isSubtotal
                    ? 1.0
                    : 0.8,
              ),
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
                  : isSubtotal
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: isProfit
                  ? tc
                  : isTotal
                  ? tc
                  : isSubtotal
                  ? tc
                  : tc?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
