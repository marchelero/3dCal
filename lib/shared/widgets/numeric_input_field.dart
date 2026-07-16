import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore_for_file: public_member_api_docs

/// Input especializado para valores numericos.
///
/// - Teclado numerico con o sin punto decimal segun [allowDecimals].
/// - Filtro automatico: descarta caracteres no numericos (o no decimales).
/// - Validacion en vivo: error si el texto no parsea como numero (o entero,
///   si [allowDecimals] es `false`). Solo se muestra despues de la primera
///   interaccion.
/// - Si [validator] se provee, se integra como [FormField] (validacion en
///   submit del `Form` padre). Si no, el field se renderiza como [TextField]
///   independiente (util para auto-save on blur, draft, etc).
/// - [onBlur] se invoca al perder foco con el string raw (util para
///   auto-save en settings).
///
/// **Importante**: el parent debe manejar el ciclo de vida del [controller]
/// (crearlo en `initState`, llamar `dispose()` en `dispose`).
///
/// Ejemplo standalone (no Form):
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
/// Ejemplo en un Form (entero, validado):
/// ```dart
/// Form(
///   key: _formKey,
///   child: NumericInputField(
///     label: 'Gramos por bobina',
///     controller: _gramsCtrl,
///     allowDecimals: false,
///     validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
///   ),
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
    this.validator,
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

  /// Validador opcional. Si se provee, el widget se monta como [FormField]
  /// para integrarse con un `Form` padre (validacion en submit).
  final FormFieldValidator<String>? validator;

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
    if (mounted) setState(() {});
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

  /// Validador interno: rechaza strings que no parsean como numero.
  /// Retorna `null` si la validacion interna pasa.
  String? _internalValidator(String? value) {
    if (!_hasInteracted) return null;
    final raw = (value ?? widget.controller.text).trim();
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(',', '.');
    final n = num.tryParse(cleaned);
    if (n == null) return 'Numero invalido';
    if (!widget.allowDecimals) {
      if (cleaned.contains('.') || cleaned.contains(',')) {
        return 'Numero invalido';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Combinar validador interno + externo si validator fue provisto.
    final combined = widget.validator == null
        ? null
        : (String? value) {
            final internal = _internalValidator(value);
            if (internal != null) return internal;
            return widget.validator!(value);
          };

    final textField = TextFormField(
      controller: widget.controller,
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
        suffixText: widget.suffix,
      ),
      // Si no hay validator, manejamos errorText en vivo via _onTextChanged.
      onChanged: _handleChange,
      validator: combined,
    );

    if (widget.validator != null) {
      // TextFormField ya es FormField; no necesitamos wrapper extra.
      return textField;
    }

    // Sin validator: usar ValueListenableBuilder para mostrar el errorText
    // interno en vivo sin requerir un FormField wrapper.
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final error = _internalValidator(widget.controller.text);
        // No podemos reutilizar textField porque ya cambio el decoration
        // arriba. Construimos un TextField equivalente aqui.
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
            helperText: error == null ? widget.helperText : null,
            errorText: error,
            suffixText: widget.suffix,
          ),
        );
      },
    );
  }
}
