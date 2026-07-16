/// Tile de estadistica compacta: icono + valor grande + label.
///
/// Usado en dashboard y home para KPIs (cotizado, vendido, conversion).
/// `[color]` actua como acento para el icono y su fondo translucido.
///
/// Sigue el diseno de [Card] del theme (M3 industrial). El valor usa
/// `FontFeature.tabularFigures()` para alinear cifras en columnas.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.semanticLabel,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Etiqueta semantica opcional. Si se da, el screen reader lee este
  /// string en vez de anunciar `label` y `value` por separado. Util para
  /// agregar contexto (ej: "Ventas hoy: 1500 BOB") o para evitar
  /// duplicacion cuando el padre ya provee contexto.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              // M2: KPI numerico usa JetBrains Mono + tabular para
              // alineacion perfecta en columnas de dashboard/home.
              style: GoogleFonts.jetBrainsMono(
                textStyle: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    if (semanticLabel == null) return tile;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: tile,
    );
  }
}
