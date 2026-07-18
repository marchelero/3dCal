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

/// Header de seccion: icono + titulo en una fila, con trailing opcional.
///
/// Usado como intro visual de bloques en pages (settings, calculator,
/// dashboard). Soporta [onTap] para hacerlo tappable (ej: collapsable) y
/// [trailing] para un widget al final de la fila.
class SectionHeader extends StatelessWidget {
  /// Crea un header de seccion con icono, titulo y trailing opcional.
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.accentColor,
    this.semanticLabel,
    this.onTap,
    this.trailing,
  });

  /// Icono decorativo a la izquierda del titulo.
  final IconData icon;

  /// Texto del titulo de la seccion.
  final String title;

  /// Color de acento para el icono. Por defecto usa `colorScheme.primary`.
  final Color? accentColor;

  /// Etiqueta semantica opcional. Si se da, se anuncia como `header`
  /// semantico (signaling inicio de seccion). Si es `null`, el screen
  /// reader anuncia el `title` normal.
  final String? semanticLabel;

  /// Callback opcional para hacer la seccion tappable (ej: collapsable).
  /// Cuando se provee, el header entero es sensitivo al tap.
  final VoidCallback? onTap;

  /// Widget opcional al final de la fila (ej: icono expand_more animado).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final rowChildren = <Widget>[
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
      ?trailing,
    ];

    Widget row = Row(children: rowChildren);

    if (onTap != null) {
      row = InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      );
    }

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
      child: row,
    );

    if (semanticLabel == null) return container;
    return Semantics(
      header: true,
      label: semanticLabel,
      child: container,
    );
  }
}
