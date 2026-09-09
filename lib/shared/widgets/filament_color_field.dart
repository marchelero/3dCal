// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/es_bo.dart';
import 'filament_color_palette.dart';
import 'filament_color_picker_dialog.dart';

/// Campo de seleccion de color del filamento.
///
/// **RF1-2 del PRD 2026-09-08**: widget reutilizable para form de settings y
/// onboarding. Compone:
///
/// - Label + helper
/// - Fila 1: paleta rapida (17 swatches en scroll horizontal), tap = selecciona
/// - Fila 2: tile "Personalizado" que abre [FilamentColorPickerDialog]
/// - Boton "Quitar color" visible solo si hay color seleccionado
///
/// **Estado externo**: el padre mantiene `String?` (hex canonico
/// `#RRGGBB` o `null`) y lo pasa a [value]. El widget es puro (sin estado
/// propio salvo para ripple), todas las mutaciones se notifican via [onChanged].
class FilamentColorField extends StatelessWidget {
  const FilamentColorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.helperText,
  });

  /// Hex canonico `#RRGGBB` o `null` si no hay color.
  final String? value;

  /// Notifica al padre el nuevo hex (o `null` cuando se quita).
  final ValueChanged<String?> onChanged;

  /// Label del campo (default: [EsBO.filamentColorLabel]).
  final String? label;

  /// Helper del campo (default: [EsBO.filamentColorHelper]).
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedColor = colorFromHex(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──
        Text(
          label ?? EsBO.filamentColorLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        if ((helperText ?? EsBO.filamentColorHelper).isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            helperText ?? EsBO.filamentColorHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // ── Paleta rapida ──
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: kFilamentPalette.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final entry = kFilamentPalette[i];
              final entryHex = hexFromColor(entry.color);
              final isSelected = entryHex == value;
              return _ColorSwatch(
                color: entry.color,
                isSelected: isSelected,
                semanticLabel: _nameForKey(entry.nameKey),
                onTap: () => onChanged(entryHex),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Personalizado ──
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () async {
            final result = await showFilamentColorPickerDialog(
              context,
              initialHex: value,
            );
            if (result != null) onChanged(result);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.colorize_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    EsBO.filamentColorCustom,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (selectedColor != null && !isPaletteHex(value))
                  _ColorDot(
                    color: selectedColor,
                    size: 20,
                    borderColor: cs.outlineVariant,
                  ),
              ],
            ),
          ),
        ),
        // ── Quitar color ──
        if (value != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: Text(EsBO.filamentColorClear),
              onPressed: () => onChanged(null),
            ),
          ),
        ],
      ],
    );
  }

  /// Resuelve la clave i18n (`red`, `orange`, ...) al nombre legible del
  /// locale activo. Si la clave no existe en el locale, devuelve la clave
  /// misma (fallback explicito).
  String _nameForKey(String key) {
    switch (key) {
      case 'red':
        return EsBO.colorNameRed;
      case 'orange':
        return EsBO.colorNameOrange;
      case 'amber':
        return EsBO.colorNameAmber;
      case 'yellow':
        return EsBO.colorNameYellow;
      case 'lime':
        return EsBO.colorNameLime;
      case 'green':
        return EsBO.colorNameGreen;
      case 'teal':
        return EsBO.colorNameTeal;
      case 'cyan':
        return EsBO.colorNameCyan;
      case 'blue':
        return EsBO.colorNameBlue;
      case 'indigo':
        return EsBO.colorNameIndigo;
      case 'purple':
        return EsBO.colorNamePurple;
      case 'magenta':
        return EsBO.colorNameMagenta;
      case 'pink':
        return EsBO.colorNamePink;
      case 'brown':
        return EsBO.colorNameBrown;
      case 'gray':
        return EsBO.colorNameGray;
      case 'black':
        return EsBO.colorNameBlack;
      case 'white':
        return EsBO.colorNameWhite;
      default:
        return key;
    }
  }
}

/// Swatch individual de la paleta. Circulo 28×28 dp con borde cuando esta
/// seleccionado.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Borde oscuro en blanco para que se vea contra fondos claros.
    final isWhite = color.toARGB32() == 0xFFFFFFFF;
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : (isWhite ? cs.outline : cs.outlineVariant),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: isWhite
              ? Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Dot pequeno usado en el subtitulo del tile "Personalizado" cuando hay un
/// color no-paleta seleccionado.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.size,
    required this.borderColor,
  });

  final Color color;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      ),
    );
  }
}

