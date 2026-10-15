// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';

/// Tarjeta táctil de preset de impresora (paso 2 del setup).
///
/// Muestra marca + modelo + watts con estado seleccionado (check) cuando ya
/// es la impresora por defecto. El tap crea la impresora con los datos del
/// catálogo vía [onTap] (el notifier hace la persistencia).
class PrinterPresetCard extends StatelessWidget {
  const PrinterPresetCard({
    required this.brand,
    required this.model,
    required this.watts,
    required this.selected,
    required this.onTap,
    this.width = 220,
    super.key,
  });

  final String brand;
  final String model;
  final int watts;

  /// Ancho de la tarjeta. Lo calcula el paso segun el espacio disponible
  /// para mantener 2 columnas en ventanas delgadas (1 sola solo en extremo).
  final double width;

  /// true cuando este modelo ya es la impresora por defecto.
  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppRadii.xl);

    return Semantics(
      button: true,
      selected: selected,
      label: '$brand $model',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: width,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: selected
                  ? color.primaryContainer
                  : color.surfaceContainerLow,
              border: Border.all(
                color: selected
                    ? color.primary
                    : color.outlineVariant.withValues(alpha: 0.6),
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    MdiIcons.printer3d,
                    size: 22,
                    color: color.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$brand · $watts W',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: color.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
