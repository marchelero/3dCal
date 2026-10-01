import 'package:flutter/material.dart';

import '../../../../core/export/quote_report_variant.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// Selector de variante del reporte, compartido por la calculadora y el
/// historial.
///
/// Reemplaza al toggle binario "ver detalle": antes solo se podia elegir entre
/// dos estados, y el estado "detalle" mezclaba informacion publica con costos
/// internos. Ahora son 2 ejes explicitos y el usuario ve de antemano si lo que
/// va a compartir es seguro para el cliente.
///
/// Solo muestra 2 opciones, no 4. Las 4 variantes existen, pero el modo de
/// calculo ya decidio una de las dos dimensiones:
///
/// - express -> [QuoteReportVariant.clientSimple] / [QuoteReportVariant.internalDetail]
/// - advanced -> [QuoteReportVariant.clientAdvanced] / [QuoteReportVariant.internalAdvanced]
///
/// Los labels son siempre "Cliente" / "Detalle": marcar "Av." en el nombre
/// confunde mas de lo que ayuda, porque lo que el usuario quiere saber es a
/// QUIEN se lo manda, no cuanta informacion lleva. Que haya mas o menos detalle
/// se descubre en el contenido.
class ReportVariantSelector extends StatelessWidget {
  const ReportVariantSelector({
    super.key,
    required this.selected,
    required this.isAdvanced,
    required this.onChanged,
  });

  final QuoteReportVariant selected;

  /// Si la calculacion esta en modo advanced (multi-material).
  final bool isAdvanced;

  final ValueChanged<QuoteReportVariant> onChanged;

  /// Label de la variante, resuelto desde l10n.
  static String labelOf(QuoteReportVariant v) =>
      v.isClientFacing ? EsBO.reportVariantClient : EsBO.reportVariantInternal;

  /// Icono de la variante. El candado marca que la interna NO se puede mandar
  /// al cliente tal cual.
  static IconData iconOf(QuoteReportVariant v) =>
      v.isClientFacing ? Icons.public_rounded : Icons.lock_rounded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordered = QuoteReportVariant.optionsForMode(isAdvanced: isAdvanced);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.reportVariantSelectorTitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final v in ordered) ...[
                _VariantChip(
                  label: labelOf(v),
                  icon: iconOf(v),
                  isClientFacing: v.isClientFacing,
                  selected: v == selected,
                  onTap: () => onChanged(v),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        // Aviso de confidencialidad: solo cuando la variante elegida es
        // interna. Es la unica proteccion real contra compartir el reporte
        // equivocado, y es barata.
        if (!selected.isClientFacing)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    EsBO.reportVariantInternalWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.label,
    required this.icon,
    required this.isClientFacing,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isClientFacing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = selected
        ? (isClientFacing ? scheme.primaryContainer : scheme.errorContainer)
        : scheme.surfaceContainerHighest;
    final fg = selected
        ? (isClientFacing ? scheme.onPrimaryContainer : scheme.onErrorContainer)
        : scheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
