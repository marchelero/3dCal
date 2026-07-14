import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

import '../state/calculator_state.dart';

/// TextField especializado para inputs numericos `Decimal`.
///
/// - Acepta `.` o `,` como separador decimal (boliviano/europeo).
/// - El teclado es numerico con punto decimal (`TextInputType.number`).
/// - Validacion en vivo: borde rojo si el valor es invalido (no parseable).
/// - No muestra error hasta que el user haya editado el campo (`_hasInteracted`).
///
/// **No** maneja el submit ni el estado global. El parent debe:
/// 1. pasar `controller`, `onChanged`.
/// 2. mantener un `TextEditingController` con el texto raw.
class DecimalInputField extends StatefulWidget {
  const DecimalInputField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffix,
    this.helperText,
    this.autofocus = false,
    super.key,
  });

  /// Etiqueta visible del field.
  final String label;

  /// Controller que mantiene el texto crudo. El parent debe manejar su ciclo
  /// de vida (`dispose()`).
  final TextEditingController controller;

  /// Callback invocado en cada cambio de texto. Recibe el string raw.
  final ValueChanged<String> onChanged;

  /// Sufijo opcional (ej: `g`, `h`, `BOB/kWh`, `%`).
  final String? suffix;

  /// Texto de ayuda debajo del field (gris, no error).
  final String? helperText;

  /// Si true, autofocus al montar.
  final bool autofocus;

  @override
  State<DecimalInputField> createState() => _DecimalInputFieldState();
}

class _DecimalInputFieldState extends State<DecimalInputField> {
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Re-evaluar la validez cuando el texto cambia desde fuera (ej: reset).
    setState(() {});
  }

  /// Si el campo no esta vacio y el texto no parsea, retorna mensaje de error.
  String? _validate() {
    if (!_hasInteracted && widget.controller.text.isEmpty) {
      return null;
    }
    final raw = widget.controller.text;
    if (raw.isEmpty) return null; // vacio no es "invalido", solo "no lleno"
    if (CalculatorState.parseDecimal(raw) == null) {
      return 'Numero invalido';
    }
    return null;
  }

  void _handleChange(String value) {
    if (!_hasInteracted) {
      setState(() => _hasInteracted = true);
    }
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final error = _validate();
    final hasError = error != null;
    return TextField(
      controller: widget.controller,
      onChanged: _handleChange,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: hasError ? null : widget.helperText,
        errorText: hasError ? error : null,
        suffixText: widget.suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
