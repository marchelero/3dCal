import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore_for_file: public_member_api_docs

/// TextField especializado para inputs numericos.
///
/// Acepta `.` o `,` como separador decimal (cuando [allowDecimals] es `true`).
/// El teclado es numerico con o sin punto decimal segun [allowDecimals].
/// Validacion en vivo: borde rojo si el valor es invalido (no parseable) — solo
/// para inputs no vacios. No muestra error hasta que el user haya editado el campo.
///
/// **No** maneja el submit ni el estado global. El parent debe:
/// 1. pasar `controller`, `onChanged` y/u `onBlur`.
/// 2. mantener un `TextEditingController` con el texto raw.
///
/// Ejemplo basico (con decimales):
/// ```dart
/// NumericInputField(
///   label: 'Peso de la pieza',
///   controller: _weightCtrl,
///   onChanged: notifier.setWeight,
///   suffix: 'g',
///   helperText: 'Gramos del modelo',
/// )
/// ```
///
/// Ejemplo entero (solo digitos):
/// ```dart
/// NumericInputField(
///   label: 'Consumo promedio (W)',
///   controller: _wattsCtrl,
///   allowDecimals: false,
///   onBlur: (v) => notifier.updateWatts(int.parse(v)),
///   textInputAction: TextInputAction.done,
/// )
/// ```
class NumericInputField extends StatefulWidget {
  const NumericInputField({
    required this.label,
    required this.controller,
    this.allowDecimals = true,
    this.suffix,
    this.helperText,
    this.onChanged,
    this.onBlur,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  /// Etiqueta visible del field.
  final String label;

  /// Controller que mantiene el texto crudo. El parent debe manejar su ciclo
  /// de vida (`dispose()`).
  final TextEditingController controller;

  /// Si `true`, acepta punto/coma decimal y usa teclado numerico-decimal.
  /// Si `false`, solo digitos.
  final bool allowDecimals;

  /// Sufijo opcional (ej: `g`, `h`, `BOB/kWh`, `%`).
  final String? suffix;

  /// Texto de ayuda debajo del field (gris, no error).
  final String? helperText;

  /// Callback invocado en cada cambio de texto. Recibe el string raw.
  final ValueChanged<String>? onChanged;

  /// Callback invocado cuando el field pierde foco. Recibe el string raw.
  /// Util para auto-save on blur (settings, draft).
  final ValueChanged<String>? onBlur;

  /// Si true, autofocus al montar.
  final bool autofocus;

  /// Accion de teclado (default: `next`).
  final TextInputAction textInputAction;

  @override
  State<NumericInputField> createState() => _NumericInputFieldState();
}

class _NumericInputFieldState extends State<NumericInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Re-evaluar la validez cuando el texto cambia desde fuera (ej: reset).
    setState(() {});
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;
    widget.onBlur?.call(widget.controller.text);
  }

  void _handleChange(String value) {
    if (!_hasInteracted) {
      setState(() => _hasInteracted = true);
    }
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _hasError();
    return TextField(
      controller: widget.controller,
      onChanged: _handleChange,
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.allowDecimals,
      ),
      textInputAction: widget.textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          widget.allowDecimals ? RegExp('[0-9.,]') : RegExp('[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: hasError ? null : widget.helperText,
        errorText: hasError ? 'Numero invalido' : null,
        suffixText: widget.suffix,
      ),
    );
  }

  /// Muestra error solo si: user interactuo y texto no vacio no parsea como
  /// numero (entero si !allowDecimals).
  bool _hasError() {
    if (!_hasInteracted) return false;
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) return false;
    final cleaned = raw.replaceAll(',', '.');
    final n = num.tryParse(cleaned);
    if (n == null) return true;
    if (!widget.allowDecimals) {
      // No aceptar "1.0" o "1,0" si !allowDecimals
      if (cleaned.contains('.') || cleaned.contains(',')) return true;
    }
    return false;
  }
}
