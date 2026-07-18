// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/currency_formatter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../state/calculator_state.dart'
    show CalculatorMode, CalculatorState, MaterialCostBreakdown;

/// Seccion de detalle expandible: costo material, energia, mano de obra,
/// post-procesado, base, falla, markup, ganancia, cargo minimo y total final.
///
/// Extraido de [SummaryCard] para ser compartido con [QuoteImageTemplate].
class DetailSection extends StatelessWidget {
  const DetailSection({
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
    this.textColor,
    super.key,
  });

  final Decimal materialCost;
  final List<MaterialCostBreakdown> materialBreakdown;
  final Decimal electricCost;
  final Decimal laborCost;
  final Decimal postProcessCost;
  final Decimal baseCost;
  final Decimal failureCost;
  final Decimal markupCost;
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
    final hasExtras = laborCost > Decimal.zero ||
        postProcessCost > Decimal.zero ||
        failureCost > Decimal.zero ||
        markupCost > Decimal.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Per-material breakdown (si hay mas de 1 material)
        if (materialBreakdown.length > 1) ...[
          ...materialBreakdown.map((m) => _materialRow(m, theme, tc)),
          const SizedBox(height: AppSpacing.sm),
        ],
        _dr(EsBO.calcDetailMaterial, formatBob(materialCost), s, tc: tc),
        _dr(EsBO.calcDetailEnergy, formatBob(electricCost), s, tc: tc),
        if (laborCost > Decimal.zero)
          _dr(EsBO.calcDetailLabor, formatBob(laborCost), s, tc: tc),
        if (postProcessCost > Decimal.zero)
          _dr(
              EsBO.calcDetailPostProcess, formatBob(postProcessCost), s,
              tc: tc),
        _dr(EsBO.calcDetailBase, formatBob(baseCost), s, tc: tc,
            isSubtotal: hasExtras),
        if (failureCost > Decimal.zero)
          _dr(EsBO.calcDetailFailure, formatBob(failureCost), s, tc: tc),
        if (markupCost > Decimal.zero)
          _dr(EsBO.calcDetailMarkup, formatBob(markupCost), s, tc: tc),
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
                  alpha: isTotal ? 1.0 : isSubtotal ? 1.0 : 0.8),
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
