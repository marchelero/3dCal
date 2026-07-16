/// Header de seccion: icono + titulo en una fila.
///
/// Usado como intro visual de bloques en pages (settings, calculator,
/// dashboard). El color del icono y del texto usan [accentColor] (default:
/// `colorScheme.primary`).
///
/// Sigue el tamano y peso del `textTheme.titleSmall` para consistencia con
/// la densidad M3.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.accentColor,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final Color? accentColor;

  /// Etiqueta semantica opcional. Si se da, se anuncia como `header`
  /// semantico (signaling inicio de seccion). Si es `null`, el screen
  /// reader anuncia el `title` normal.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final container = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) return container;
    return Semantics(
      header: true,
      label: semanticLabel,
      child: container,
    );
  }
}
