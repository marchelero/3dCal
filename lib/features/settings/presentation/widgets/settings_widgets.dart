// ignore_for_file: public_member_api_docs
/// Widgets compartidos entre SettingsPage y PrintSettingsPage.
///
/// Extraidos de los widgets privados originales en settings_page.dart
/// para reutilizar sin duplicar codigo.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/numeric_input_field.dart';

/// Etiqueta de grupo que subdivide el menu de ajustes.
///
/// Titulo en MAYUSCULAS con tracking + icono en caja tintada + trailing
/// opcional (ej: badge PRO). Una regla corta de acento cierra el titulo,
/// como la linea pautada de un formulario.
class GroupLabel extends StatelessWidget {
  const GroupLabel({
    required this.icon,
    required this.title,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = title;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 16, color: color.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: color.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Icono de badge reutilizable para filas (leading de ListTile).
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}

/// Divisor horizontal de una card.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      color: color.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

/// Card contenedora de un grupo de ajustes.
///
/// Card limpia y redondeada con contenido separado por hairlines
/// ([CardDivider]) si `divider` es true.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    required this.accentColor,
    required this.children,
    this.divider = false,
    super.key,
  });

  final Color accentColor;
  final List<Widget> children;

  /// Aplica un borde superior de acento y separa los hijos con hairlines.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (divider) Container(height: 3, color: accentColor),
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// StatParamTile — tarjeta de parametro estilo "stat"
// ─────────────────────────────────────────────────

/// Tarjeta editable presentada igual que los KPIs de la home: icono en caja
/// tintada + titulo arriba y un valor numerico grande en mono tabular debajo.
/// Auto-save on blur.
///
/// Internamente usa [NumericInputField] para mantener el filtrado numerico,
/// la validacion y el comportamiento de [TextField].
class StatParamTile extends StatefulWidget {
  const StatParamTile({
    required this.icon,
    required this.title,
    required this.helper,
    required this.accent,
    required this.initialValue,
    required this.validator,
    required this.onSave,
    required this.allowDecimals,
    required this.sliderMin,
    required this.sliderMax,
    required this.sliderDivisions,
    this.suffix = '',
    this.sliderLeadingIcon,
    this.sliderTrailingIcon,
    this.showProfitPreview = false,
    this.infoTooltip,
    super.key,
  });

  final IconData icon;
  final String title;
  final String helper;
  final Color accent;
  final String initialValue;
  final FormFieldValidator<String> validator;
  final ValueChanged<Decimal> onSave;
  final bool allowDecimals;
  final double sliderMin;
  final double sliderMax;
  final int sliderDivisions;
  final String suffix;
  final IconData? sliderLeadingIcon;
  final IconData? sliderTrailingIcon;
  final bool showProfitPreview;

  /// Tooltip de ayuda con icono de informacion junto al titulo.
  /// Null = no se muestra el icono.
  final String? infoTooltip;

  @override
  State<StatParamTile> createState() => _StatParamTileState();
}

class _StatParamTileState extends State<StatParamTile> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant StatParamTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBlur(String raw) {
    final err = widget.validator(raw);
    if (err != null) return;
    final cleaned = raw.trim().replaceAll(',', '.');
    final parsed = Decimal.tryParse(cleaned);
    if (parsed == null) return;
    widget.onSave(parsed);
  }

  double get _current {
    return double.tryParse(_ctrl.text.trim().replaceAll(',', '.')) ??
        widget.sliderMin;
  }

  void _onSliderChange(double v) {
    setState(() {
      _ctrl.text = widget.allowDecimals
          ? v.toStringAsFixed(2)
          : v.round().toString();
    });
  }

  void _onSliderEnd(double v) {
    if (!widget.allowDecimals) {
      widget.onSave(Decimal.fromInt(v.round()));
    } else {
      widget.onSave(Decimal.parse(v.toStringAsFixed(2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final raw = _current;
    final value = raw < widget.sliderMin
        ? widget.sliderMin
        : (raw > widget.sliderMax ? widget.sliderMax : raw);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barra de acento izquierda ──
          Container(width: 4, color: widget.accent),
          // ── Contenido ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon chip + titulo
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.infoTooltip != null) ...[
                        Tooltip(
                          message: widget.infoTooltip,
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Helper — solo se muestra si NO hay infoTooltip
                  // (cuando hay tooltip, la info detallada vive ahi).
                  if (widget.infoTooltip == null)
                    Text(
                      widget.helper,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  // Slider con iconos de tendencia
                  Row(
                    children: [
                      if (widget.sliderLeadingIcon != null) ...[
                        Icon(
                          widget.sliderLeadingIcon,
                          size: 16,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            activeTrackColor: widget.accent,
                            inactiveTrackColor: widget.accent.withValues(
                              alpha: 0.25,
                            ),
                            thumbColor: widget.accent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                            ),
                            overlayColor: widget.accent.withValues(alpha: 0.15),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 20,
                            ),
                          ),
                          child: Slider(
                            value: value,
                            min: widget.sliderMin,
                            max: widget.sliderMax,
                            divisions: widget.sliderDivisions,
                            label: widget.allowDecimals
                                ? value.toStringAsFixed(2)
                                : value.round().toString(),
                            onChanged: _onSliderChange,
                            onChangeEnd: _onSliderEnd,
                          ),
                        ),
                      ),
                      if (widget.sliderTrailingIcon != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          widget.sliderTrailingIcon,
                          size: 16,
                          color: color.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Valor + input (con preview si aplica)
                  if (widget.showProfitPreview)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: NumericInputField(
                            label: widget.title,
                            controller: _ctrl,
                            allowDecimals: widget.allowDecimals,
                            suffix: widget.suffix,
                            validator: widget.validator,
                            onBlur: _handleBlur,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: GainPreview(
                            value: _current,
                            accent: widget.accent,
                          ),
                        ),
                      ],
                    )
                  else
                    NumericInputField(
                      label: widget.title,
                      controller: _ctrl,
                      allowDecimals: widget.allowDecimals,
                      suffix: widget.suffix,
                      validator: widget.validator,
                      onBlur: _handleBlur,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview visual del porcentaje de ganancia: muestra cuanto se multiplica
/// sobre el costo.
class GainPreview extends StatelessWidget {
  const GainPreview({required this.value, required this.accent, super.key});

  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multiplier = 1 + (value / 100);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'x${multiplier.toStringAsFixed(1)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          Text(
            EsBO.settingsGainMultiplierSuffix,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
