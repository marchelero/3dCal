import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_radii.dart';

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
    this.showValidation = false,
    this.isKey = false,
    this.keyHint,
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

  /// Si `true`, fuerza validacion visual incluso sin interaccion previa.
  /// Util para mostrar errores al intentar guardar con campos vacios.
  final bool showValidation;

  /// Si `true`, marca el field como critico para el calculo. Aplica:
  /// - Borde mas visible en color de acento (primary).
  /// - Fill levemente tintado para distinguirlo de los demas.
  /// - Prefijo con icono de "estrella" para senalar importancia.
  /// - [keyHint] como helper prioritario (si se provee).
  final bool isKey;

  /// Helper prioritario para campos clave. Si se provee, reemplaza
  /// [helperText] cuando [isKey] es `true`. Sirve para explicar al usuario
  /// por que el campo es indispensable (ej: "Sin este dato no se cotiza").
  final String? keyHint;

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
  /// Si [widget.showValidation] es true, tambien marca vacios como error.
  String? _internalValidator(String? value) {
    if (!_hasInteracted && !widget.showValidation) return null;
    final raw = (value ?? widget.controller.text).trim();
    if (raw.isEmpty) return widget.showValidation ? 'Requerido' : null;
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

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // === Estilos condicionales para campos clave (isKey) ===
    // Senalamos los inputs indispensables (ej: peso, tiempo) con un borde
    // de acento mas visible y un fill levemente tintado. Asi el usuario
    // entiende que sin esos datos la cotizacion no se puede generar.
    //
    // **Importante**: el helperText NO se renderiza abajo del field cuando
    // isKey=true. La razon: agrega una linea que rompe la alineacion
    // vertical con los demas inputs de la fila. En su lugar, la
    // explicacion (keyHint) se muestra como Tooltip del push_pin icon.
    // Asi el field mantiene exactamente la misma altura que sus vecinos.
    final isKey = widget.isKey;
    final keyFill = isKey
        ? cs.primaryContainer.withValues(alpha: 0.35)
        : null;
    final keyBorderColor = isKey ? cs.primary : cs.outlineVariant;
    final keyLabelColor = isKey ? cs.primary : cs.onSurfaceVariant;
    final keyIcon = Icon(
      Icons.push_pin_rounded,
      size: 18,
      color: cs.primary,
      semanticLabel: widget.keyHint,
    );
    final keyPrefixIcon = isKey
        ? (widget.keyHint != null
            ? Tooltip(
                message: widget.keyHint!,
                triggerMode: TooltipTriggerMode.tap,
                child: keyIcon,
              )
            : keyIcon)
        : null;

    // Cuando es key, suprimimos el helperText para que el field quede a
    // la misma altura que los inputs adyacentes. La info sigue accesible
    // via el Tooltip del push_pin icon (toque largo / hover).
    final effectiveHelper = isKey ? null : widget.helperText;

    final decoration = InputDecoration(
      labelText: widget.label,
      helperText: effectiveHelper,
      suffixText: widget.suffix,
      prefixIcon: keyPrefixIcon,
      filled: true,
      fillColor: keyFill,
      // Sobreescribimos bordes solo si es key: mas visible y en color de
      // acento. Si no, dejamos los del theme (OutlineInputBorder generico).
      enabledBorder: isKey
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(color: keyBorderColor, width: 1.5),
            )
          : null,
      focusedBorder: isKey
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(color: cs.primary, width: 2),
            )
          : null,
      labelStyle: TextStyle(
        color: keyLabelColor,
        fontWeight: isKey ? FontWeight.w600 : FontWeight.w500,
      ),
    );

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
      decoration: decoration,
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
        // Misma decoration, pero con errorText en vivo (no se puede pasar
        // via validator porque no hay FormField wrapper).
        final liveDecoration = decoration.copyWith(
          errorText: error,
          helperText: error == null ? effectiveHelper : null,
        );
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
          decoration: liveDecoration,
        );
      },
    );
  }
}
