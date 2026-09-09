// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/es_bo.dart';
import 'filament_color_palette.dart';

/// Dialog modal para elegir un color HSV + hex editable.
///
/// **UX simple** (RF1-2 del PRD 2026-09-08): un slider de matiz (H, 0-360°)
/// + saturacion/brillo al maximo por defecto (colores vivos como el material
/// design). Campo hex editable como atajo para usuarios que conocen el valor.
///
/// Retorna el hex normalizado `#RRGGBB` al aceptar; `null` si el usuario
/// cancela.
class FilamentColorPickerDialog extends StatefulWidget {
  const FilamentColorPickerDialog({super.key, this.initialHex});

  /// Hex inicial (preseleccion al abrir). Si es null, empieza en rojo.
  final String? initialHex;

  @override
  State<FilamentColorPickerDialog> createState() =>
      _FilamentColorPickerDialogState();
}

class _FilamentColorPickerDialogState
    extends State<FilamentColorPickerDialog> {
  late HSVColor _hsv;
  late TextEditingController _hexCtrl;
  String? _hexError;

  @override
  void initState() {
    super.initState();
    final initial = colorFromHex(widget.initialHex) ?? const Color(0xFFE53935);
    _hsv = HSVColor.fromColor(initial);
    _hexCtrl = TextEditingController(text: hexFromColor(initial));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _currentColor {
    // S y V al maximo (1.0) por UX simple: el slider solo controla el matiz.
    // El hex editable SI permite cualquier combinacion S/V porque escribe
    // directo el color.
    return _hsv.toColor();
  }

  void _onHueChanged(double hue) {
    setState(() {
      // `fromAHSV(alpha, hue, saturation, value)`: alpha=1, S=V=1 para
      // colores vivos por UX simple (RF1-2 del PRD 2026-09-08).
      _hsv = HSVColor.fromAHSV(1, hue, 1, 1);
      _hexError = null;
      _hexCtrl.text = hexFromColor(_currentColor);
    });
  }

  void _onHexChanged(String value) {
    final parsed = colorFromHex(value);
    if (parsed == null) {
      setState(() => _hexError = EsBO.filamentColorInvalid);
      return;
    }
    setState(() {
      _hexError = null;
      _hsv = HSVColor.fromColor(parsed);
    });
  }

  void _apply() {
    if (_hexError != null) return;
    Navigator.of(context).pop(hexFromColor(_currentColor));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final previewColor = _currentColor;

    return AlertDialog(
      title: Text(EsBO.filamentColorPickerTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Preview grande ──
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: cs.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Slider H ──
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'H',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _hsv.hue,
                    min: 0,
                    max: 360,
                    divisions: 360,
                    onChanged: _onHueChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // ── Hex editable ──
            TextField(
              controller: _hexCtrl,
              decoration: InputDecoration(
                labelText: EsBO.filamentColorHexLabel,
                helperText: EsBO.filamentColorHexHelper,
                errorText: _hexError,
                prefixIcon: const Icon(Icons.tag, size: 18),
                isDense: true,
              ),
              onChanged: _onHexChanged,
              onSubmitted: (_) {
                if (_hexError == null) _apply();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(EsBO.commonCancel),
        ),
        FilledButton(
          onPressed: _hexError == null ? _apply : null,
          child: Text(EsBO.commonApply),
        ),
      ],
    );
  }
}

/// Helper para abrir el dialog y devolver el hex elegido.
Future<String?> showFilamentColorPickerDialog(
  BuildContext context, {
  String? initialHex,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => FilamentColorPickerDialog(initialHex: initialHex),
  );
}

