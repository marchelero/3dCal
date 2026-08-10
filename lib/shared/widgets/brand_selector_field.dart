// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../../l10n/app_locale.dart';
import '../../../l10n/es_bo.dart';
import 'k3d_brands.dart';

/// Valor sentinela del item "Otro..." del dropdown.
const String _kOtherOption = '__brand_other__';

/// Selector de marca con autocompletado, parametrizado por [BrandDomain]:
/// la lista base y el notifier observado dependen del dominio.
///
/// - [BrandDomain.filament] -> observa `filamentsNotifierProvider`,
///   base = `kKnownFilamentBrands`.
/// - [BrandDomain.printer] -> observa `printersNotifierProvider`,
///   base = `kKnownPrinterBrands`.
///
/// En ambos casos se unen las marcas que el usuario ya registro en el
/// dominio correspondiente (no cross-domain) y se ordenan. La opcion
/// "Otro..." activa un campo de texto manual para marca custom.
///
/// El valor SIEMPRE vive en [controller] (igual que un TextFormField)
/// para no tocar la logica de guardado de los forms que lo usan.
///
/// Reglas de modo:
/// - Sin valor -> dropdown con hint.
/// - Valor que esta en las opciones -> dropdown con esa marca seleccionada.
/// - Valor que NO esta en las opciones (ej. marca custom en edicion) o el
///   usuario eligio "Otro..." -> campo de texto manual.
class BrandSelectorField extends ConsumerStatefulWidget {
  const BrandSelectorField({
    super.key,
    required this.domain,
    required this.controller,
    this.validator,
    this.label,
    this.helperText,
    this.enabled = true,
  });

  /// Dominio del selector (filamento o impresora). Determina la lista
  /// base de marcas y que notifier se observa.
  final BrandDomain domain;

  final TextEditingController controller;

  /// Validador opcional del form padre (ej. limite de 100 chars).
  final String? Function(String?)? validator;

  /// Label del campo. Default: [EsBO.filamentBrand].
  final String? label;

  /// Helper mostrado en el campo manual. Default:
  /// [EsBO.brandSelectorManualHelper].
  final String? helperText;

  final bool enabled;

  @override
  ConsumerState<BrandSelectorField> createState() => _BrandSelectorFieldState();
}

class _BrandSelectorFieldState extends ConsumerState<BrandSelectorField> {
  /// true cuando el usuario eligio "Otro..." (ingreso manual explicito).
  bool _forceOther = false;

  /// Marcas registradas en la app para ESTE dominio (no cross-domain).
  Set<String> _registeredBrands(WidgetRef ref) {
    final brands = <String>{};
    switch (widget.domain) {
      case BrandDomain.filament:
        final filaments = ref.watch(filamentsNotifierProvider).value;
        for (final f in filaments ?? const <Filament>[]) {
          final b = f.brand;
          if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
        }
        break;
      case BrandDomain.printer:
        final printers = ref.watch(printersNotifierProvider).value;
        for (final p in printers ?? const <PrinterProfile>[]) {
          final b = p.brand;
          if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
        }
        break;
    }
    return brands;
  }

  /// Opciones ordenadas: conocidas del dominio + registradas del dominio.
  List<String> _options(WidgetRef ref) {
    final known = widget.domain == BrandDomain.filament
        ? kKnownFilamentBrands
        : kKnownPrinterBrands;
    final all = <String>{...known, ..._registeredBrands(ref)};
    return all.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final label = widget.label ?? EsBO.filamentBrand;
    final current = widget.controller.text.trim();
    final options = _options(ref);
    final isKnown = options.contains(current);
    final showManual = _forceOther || (current.isNotEmpty && !isKnown);

    // === Modo manual (Otro... o marca custom existente en edicion) ===
    if (showManual) {
      return TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: label,
          helperText: widget.helperText ?? EsBO.brandSelectorManualHelper,
        ),
        textInputAction: TextInputAction.next,
        validator: widget.validator,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: isKnown && current.isNotEmpty ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: widget.helperText,
      ),
      hint: Text(EsBO.brandSelectorHint),
      items: [
        for (final b in options) DropdownMenuItem(value: b, child: Text(b)),
        DropdownMenuItem(
          value: _kOtherOption,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(EsBO.brandSelectorOther),
            ],
          ),
        ),
      ],
      onChanged: widget.enabled
          ? (String? v) {
              if (v == _kOtherOption) {
                setState(() {
                  _forceOther = true;
                  widget.controller.clear();
                });
              } else if (v != null) {
                setState(() {
                  _forceOther = false;
                  widget.controller.text = v;
                });
              }
            }
          : null,
      validator: widget.validator,
    );
  }
}
