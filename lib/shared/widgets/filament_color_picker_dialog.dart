// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorFromHex;

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/es_bo.dart';
import 'filament_color_palette.dart';

/// Dialog modal para elegir un color con la **rueda de color redonda**
/// (HSV) de `flutter_colorpicker` + hex editable (dos-way via
/// `hexInputController`).
///
/// **UX** (RF1-2 del PRD 2026-09-08): wheel redonda estándar de la comunidad,
/// sin slider de matiz manual. Retorna el hex normalizado `#RRGGBB` al
/// aceptar; `null` si el usuario cancela.
class FilamentColorPickerDialog extends StatefulWidget {
  const FilamentColorPickerDialog({super.key, this.initialHex});

  /// Hex inicial (preseleccion al abrir). Si es null, empieza en rojo.
  final String? initialHex;

  @override
  State<FilamentColorPickerDialog> createState() =>
      _FilamentColorPickerDialogState();
}

class _FilamentColorPickerDialogState extends State<FilamentColorPickerDialog> {
  late Color _currentColor;
  late TextEditingController _hexCtrl;

  @override
  void initState() {
    super.initState();
    final initial = colorFromHex(widget.initialHex) ?? const Color(0xFFE53935);
    _currentColor = initial;
    // `hexInputController` (dos-way) del paquete maneja el valor del hex y
    // lo mantiene sincronizado con la rueda.
    _hexCtrl = TextEditingController(text: hexFromColor(initial));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(hexFromColor(_currentColor));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      title: Text(EsBO.filamentColorPickerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Rueda de color redonda (HSV) ──
            ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) => setState(() => _currentColor = color),
              hexInputController: _hexCtrl,
              enableAlpha: false,
              displayThumbColor: true,
              colorPickerWidth: 300,
              pickerAreaHeightPercent: 0.75,
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Preview grande ──
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: cs.outlineVariant, width: 1),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // ── Hex editable (sincronizado con la rueda) ──
            TextField(
              controller: _hexCtrl,
              decoration: InputDecoration(
                labelText: EsBO.filamentColorHexLabel,
                helperText: EsBO.filamentColorHexHelper,
                prefixIcon: const Icon(Icons.tag, size: 18),
                isDense: true,
              ),
              onSubmitted: (_) => _apply(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(EsBO.commonCancel),
        ),
        FilledButton(onPressed: _apply, child: Text(EsBO.commonApply)),
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
