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
    final cs = theme.colorScheme;
    final color = accentColor ?? cs.primary;
    // Padding vertical compacto (sm en vez de md) para que el header no
    // visualmente "flote" mas alto que el resto del contenido de la card.
    // Antes: vertical=md (12) + textMedium + border = bloque mas grueso que
    // el resto. Ahora: vertical=sm (8) + textSmall alineado al mismo ritmo
    // que los inputs y filas de la card.
    final rowChildren = <Widget>[
      Icon(icon, size: 18, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onPrimaryContainer,
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
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: row,
        ),
      );
    }

    // Header con gradiente azul (primaryContainer) identico al hero de home.
    // Antes era un fill gris apagado (surfaceContainerHighest) que contrastaba
    // poco con la card; ahora tiene identidad visual y se integra con la
    // paleta "Industrial 3D".
    final container = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withValues(alpha: 0.7),
            cs.primaryContainer.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
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
