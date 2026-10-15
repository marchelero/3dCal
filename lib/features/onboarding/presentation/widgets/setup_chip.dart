// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';

/// Chip reutilizable del flujo de setup con contraste AA garantizado sobre
/// el gradiente.
///
/// Fondo opaco [ColorScheme.surfaceContainerLow] + texto
/// [ColorScheme.onSurface] (nunca blanco translúcido: el estilo previo de
/// chips blancos sobre los tonos claros del gradiente quedaba ilegible —
/// bug de validación 2026-10-11). Seleccionado: [ColorScheme.primaryContainer]
/// + borde [ColorScheme.primary] + check (patrón de [PrinterPresetCard]).
///
/// Lo usan los chips de moneda ([CurrencyChips]) y de marca del filamento
/// para que todos los pasos queden consistentes.
class SetupChip extends StatelessWidget {
  const SetupChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticsLabel,
    this.showCheck = true,
    this.icon,
    super.key,
  });

  /// Texto del chip (estilo aplicado por el chip; el color SIEMPRE resuelve
  /// contra su fondo opaco, no contra el gradiente).
  final String label;

  /// true cuando el chip está seleccionado (fondo primaryContainer + check).
  final bool selected;

  /// Tap del chip.
  final VoidCallback onTap;

  /// Label semántico opcional (ej: solo el código ISO de la moneda).
  final String? semanticsLabel;

  /// Muestra el check a la derecha cuando [selected] es true.
  final bool showCheck;

  /// Icono opcional antes del label (ej: expand_more del "Ver más").
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppRadii.xl);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? color.onPrimaryContainer
                        : color.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? color.onPrimaryContainer
                        : color.onSurface,
                  ),
                ),
                if (selected && showCheck) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.check_rounded, size: 16, color: color.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
