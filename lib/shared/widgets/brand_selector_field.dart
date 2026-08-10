// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../../l10n/app_locale.dart';
import '../../../l10n/es_bo.dart';

/// Marcas conocidas del ecosistema 3D (impresoras y filamentos).
///
/// Base del selector de marca. Se unen con las marcas que el usuario ya
/// registro en la app (filamentos + impresoras) y se ordenan.
const List<String> kKnown3dBrands = [
  'Anycubic',
  'Artillery',
  'Bambu Lab',
  'Creality',
  'Elegoo',
  'Eryone',
  'eSun',
  'Flashforge',
  'Geeetech',
  'Hatchbox',
  'Overture',
  'Polymaker',
  'Prusa',
  'Prusament',
  'Qidi',
  'Raise3D',
  'Sovol',
  'Sunlu',
  'Ultimaker',
  'Voxelab',
  'Voron',
];

/// Valor sentinela del item "Otro..." del dropdown.
const String _kOtherOption = '__brand_other__';

/// Selector de marca con autocompletado: marcas conocidas del mundo 3D +
/// las ya registradas en la app, con la opcion "Otro..." que activa un
/// campo de texto para ingresar la marca manualmente.
///
/// El valor SIEMPRE vive en [controller] (igual que un TextFormField)
/// para no tocar la logica de guardado de los forms que lo usan.
///
/// Reglas de modo:
/// - Sin valor → dropdown con hint.
/// - Valor que esta en las opciones → dropdown con esa marca seleccionada.
/// - Valor que NO esta en las opciones (ej. marca custom en edicion) o el
///   usuario eligio "Otro..." → campo de texto manual.
class BrandSelectorField extends ConsumerStatefulWidget {
  const BrandSelectorField({
    super.key,
    required this.controller,
    this.validator,
    this.label,
    this.helperText,
    this.enabled = true,
  });

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
  ConsumerState<BrandSelectorField> createState() =>
      _BrandSelectorFieldState();
}

class _BrandSelectorFieldState extends ConsumerState<BrandSelectorField> {
  /// true cuando el usuario eligio "Otro..." (ingreso manual explicito).
  bool _forceOther = false;

  /// Marcas registradas en la app (filamentos + impresoras), unicas.
  Set<String> _registeredBrands(WidgetRef ref) {
    final filaments = ref.watch(filamentsNotifierProvider).value;
    final printers = ref.watch(printersNotifierProvider).value;
    final brands = <String>{};
    for (final f in filaments ?? const <Filament>[]) {
      final b = f.brand;
      if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
    }
    for (final p in printers ?? const <PrinterProfile>[]) {
      final b = p.brand;
      if (b != null && b.trim().isNotEmpty) brands.add(b.trim());
    }
    return brands;
  }

  /// Opciones ordenadas: conocidas + registradas (sin duplicados).
  List<String> _options(WidgetRef ref) {
    final all = <String>{
      ...kKnown3dBrands,
      ..._registeredBrands(ref),
    };
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
        for (final b in options)
          DropdownMenuItem(value: b, child: Text(b)),
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
