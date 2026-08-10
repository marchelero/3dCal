// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/es_bo.dart';
import '../../domain/entities/calculation_output.dart';
import '../state/calculator_state.dart' show MaterialCostBreakdown;
import 'detail_section.dart';

/// Template visual para la imagen compartida de la cotizacion.
///
/// **Diferencia con [SummaryCard]**:
/// - Diseño tipo hoja de plano (fondo papel, bloque de titulo, caja de total).
/// - Sin elementos interactivos (no tiene toggle detail button).
/// - Con pie de pagina "Generado con 3dCalc".
/// - Usado exclusivamente dentro del [RepaintBoundary] para captura PNG.
///
/// No debe contener botones, TextButton, ni widgets clickeables.
class QuoteImageTemplate extends StatelessWidget {
  const QuoteImageTemplate({
    required this.output,
    required this.label,
    required this.discountPct,
    required this.showDetail,
    required this.detailMaterialBreakdown,
    required this.detailElectricCost,
    required this.detailLaborCost,
    required this.detailPostProcessCost,
    required this.detailBaseCost,
    required this.detailFailureCost,
    required this.detailMarkupCost,
    required this.detailProfitAmount,
    required this.detailTotalFinal,
    required this.metaGrams,
    required this.metaTime,
    required this.companyName,
    this.companyLogoBase64,
    required this.currency,
    super.key,
  });

  final CalculationOutput output;
  final String label;
  final String discountPct;
  final bool showDetail;
  final List<MaterialCostBreakdown> detailMaterialBreakdown;
  final Decimal? detailElectricCost;
  final Decimal? detailLaborCost;
  final Decimal? detailPostProcessCost;
  final Decimal? detailBaseCost;
  final Decimal? detailFailureCost;
  final Decimal? detailMarkupCost;
  final Decimal? detailProfitAmount;
  final Decimal? detailTotalFinal;
  final String? metaGrams;
  final String? metaTime;

  /// Nombre de la empresa. Si es null, usa "3dCalc".
  final String? companyName;

  /// Logo de la empresa en base64. Si es null, muestra icono default.
  final String? companyLogoBase64;

  /// Configuracion monetaria activa para formateo.
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final hasLabel = label.trim().isNotEmpty;
    final hasDiscount = output.discountAmount > Decimal.zero;
    final now = DateTime.now();

    return Container(
      width: 400, // ancho fijo para consistencia en la imagen
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxxl),
        border: Border.all(color: color.outlineVariant, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Membrete: logo + branding + folio/fecha ──
          _buildMembrete(theme, color, now),
          const SizedBox(height: AppSpacing.xs),

          // Separator
          _divider(color),
          const SizedBox(height: AppSpacing.lg),

          // ── Label (optional) ──
          if (hasLabel) ...[
            Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Big price: caja de total de doble regla ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color.onSurface, width: 2),
                bottom: BorderSide(color: color.onSurface, width: 2),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color.onSurface, width: 1),
                  bottom: BorderSide(color: color.onSurface, width: 1),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCurrency(output.totalPrice, currency),
                  style: AppTheme.num(
                    theme.textTheme.displayMedium ??
                        const TextStyle(fontSize: 28),
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                  ).copyWith(letterSpacing: -1),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Subtitle
          Center(
            child: Text(
              hasDiscount
                  ? EsBO.calcTotalWithDiscount
                  : EsBO.calcTotalFinal,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Meta info (grams + time): linea mono, sin pildora ──
          if (metaGrams != null || metaTime != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                [
                  ?metaGrams,
                  ?metaTime,
                ].join(EsBO.calcMetaSeparator),
                style: AppTheme.num(
                  theme.textTheme.bodySmall ?? const TextStyle(),
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // ── Discount breakdown: correccion de recibo ──
          if (hasDiscount) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: color.error, width: 1),
              ),
              child: Column(
                children: [
                  _discountRow(
                    EsBO.quoteNoDiscount,
                    formatCurrency(output.totalPrice + output.discountAmount, currency),
                    theme,
                    color.onSurface,
                  ),
                  const SizedBox(height: 6),
                  _discountRow(
                    EsBO.quoteDiscountPct(int.parse(discountPct)),
                    '-${formatCurrency(output.discountAmount, currency)}',
                    theme,
                    color.error,
                    bold: true,
                    strikeThrough: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(
                      height: 1,
                      color: color.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                  _discountRow(
                    EsBO.calcTotalWithDiscount,
                    formatCurrency(output.totalPrice, currency),
                    theme,
                    color.onSurface,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],

          // ── Detail section (optional) ──
          if (showDetail) ...[
            const SizedBox(height: AppSpacing.lg),
            _divider(color),
            const SizedBox(height: AppSpacing.sm),

            // "Detalle" header
            Center(
              child: Text(
                EsBO.quoteDetail.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            DetailSection(
              materialCost: output.materialCost,
              materialBreakdown: detailMaterialBreakdown,
              electricCost: detailElectricCost ?? Decimal.zero,
              laborCost: detailLaborCost ?? Decimal.zero,
              postProcessCost: detailPostProcessCost ?? Decimal.zero,
              baseCost: detailBaseCost ?? Decimal.zero,
              failureCost: detailFailureCost ?? Decimal.zero,
              markupCost: detailMarkupCost ?? Decimal.zero,
              profitAmount: detailProfitAmount ?? Decimal.zero,
              totalFinal: detailTotalFinal ?? Decimal.zero,
              textColor: color.onSurface,
            ),
          ],

          // ── Footer ──
          const SizedBox(height: AppSpacing.xxl),
          _divider(color),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/3dlogo.png',
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                Text(
                  EsBO.quoteGeneratedWith,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembrete(ThemeData theme, ColorScheme color, DateTime now) {
    final displayName = companyName ?? '3dCalc';
    final hasLogo = companyLogoBase64 != null && companyLogoBase64!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo o icono default
        hasLogo
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Image.memory(
                  _base64ToBytes(companyLogoBase64!),
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _defaultLogoIcon(color),
                ),
              )
            : _defaultLogoIcon(color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                EsBO.calcSheetTitle.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('dd MMM yyyy HH:mm').format(now),
              style: AppTheme.num(
                theme.textTheme.bodySmall ?? const TextStyle(),
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _defaultLogoIcon(ColorScheme color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Image.asset(
        'assets/images/3dlogo.png',
        width: 22,
        height: 22,
        fit: BoxFit.contain,
      ),
    );
  }

  Uint8List _base64ToBytes(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Widget _divider(ColorScheme color) {
    return Divider(
      height: 1,
      color: color.outlineVariant.withValues(alpha: 0.5),
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
  bool strikeThrough = false,
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
        style: AppTheme.num(
          theme.textTheme.bodyMedium ?? const TextStyle(),
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        ).copyWith(
          decoration: strikeThrough ? TextDecoration.lineThrough : null,
          decorationColor: color,
        ),
      ),
    ],
  );
}
