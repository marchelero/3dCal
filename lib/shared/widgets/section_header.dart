/// Header de seccion: icono + titulo en una fila con regla de cota.
///
/// Usado como rubrica impresa en pages (settings, calculator, dashboard).
/// El titulo se muestra en MAYUSCULAS con tracking (voz de documento
/// plano) y una regla de cota de 1.5px lo cierra por abajo, como la
/// linea pautada de un formulario. El icono usa [accentColor] (default:
/// `colorScheme.primary`).
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Header de seccion: icono + titulo en una fila, con trailing opcional.
///
/// Usado como rubrica impresa en pages (settings, calculator, dashboard).
/// Soporta [onTap] para hacerlo tappable (ej: collapsable) y [trailing]
/// para un widget al final de la fila.
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

  /// Texto del titulo de la seccion (se muestra en MAYUSCULAS).
  final String title;

  /// Color de acento para el icono y la regla. Por defecto `colorScheme.primary`.
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

    final rowChildren = <Widget>[
      Icon(icon, size: 18, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: cs.onSurface,
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

    // Rubrica de plano: regla de cota de 1.5px bajo el titulo en caps.
    // Sin caja ni gradiente: la linea es la voz del formulario impreso.
    final container = Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color, width: 1.5),
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
