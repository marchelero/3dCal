// ignore_for_file: public_member_api_docs

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/calculation_engine.dart';
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/material_input.dart';
import 'calculator_state.dart';

/// Notifier reactivo para el formulario de cotizacion.
///
/// **Modos**:
/// - `express`: 1 material via setters simples (Sprint 3).
/// - `advanced`: lista de materiales con `addMaterial/removeMaterial/updateMaterial`.
///
/// El output se recalcula en cada cambio, sincronamente (engine es pure).
/// Si el form no es valido, [CalculatorState.output] queda en `null`.
class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() => CalculatorState.initial();

  /// Etiqueta visible del material en el motor. Cambia si el user edita
  /// el filamento seleccionado (placeholder en Sprint 3, dinamico en
  /// Sprint 4 cuando se conecte al repositorio de filamentos).
  static const _materialLabel = 'Filamento';

  // === Mode ===

  void setMode(CalculatorMode mode) {
    state = _recompute(state.copyWith(mode: mode));
  }

  // === Setters express (single material) ===

  void setWeight(String value) {
    state = _recompute(state.copyWith(weight: value));
  }

  void setPrintHours(String value) {
    state = _recompute(state.copyWith(printHours: value));
  }

  void setPrinterWatts(String value) {
    state = _recompute(state.copyWith(printerWatts: value));
  }

  void setKwhRate(String value) {
    state = _recompute(state.copyWith(kwhRate: value));
  }

  void setProfitPct(String value) {
    state = _recompute(state.copyWith(profitPct: value));
  }

  void setDiscountPct(String value) {
    state = _recompute(state.copyWith(discountPct: value));
  }

  void setFilamentPrice(String value) {
    state = _recompute(state.copyWith(filamentPrice: value));
  }

  void setFilamentGrams(String value) {
    state = _recompute(state.copyWith(filamentGrams: value));
  }

  // === Setters advanced (multi-material) ===

  /// Agrega una fila vacia al final de la lista de materiales.
  void addMaterial() {
    final next = List<MaterialRow>.from(state.materials)
      ..add(const MaterialRow());
    state = _recompute(state.copyWith(materials: next));
  }

  /// Quita la fila en [index]. No hace nada si index fuera de rango.
  void removeMaterial(int index) {
    if (index < 0 || index >= state.materials.length) return;
    final next = List<MaterialRow>.from(state.materials)..removeAt(index);
    state = _recompute(state.copyWith(materials: next));
  }

  /// Actualiza un campo de la fila en [index]. Crea la fila si no existe
  /// (cuando el user edita un item recien agregado que por algun motivo no
  /// esta en la lista).
  void updateMaterial(
    int index, {
    String? label,
    String? weight,
    String? pricePerBobbin,
    String? gramsPerBobbin,
  }) {
    if (index < 0 || index >= state.materials.length) return;
    final updated = state.materials[index].copyWith(
      label: label,
      weight: weight,
      pricePerBobbin: pricePerBobbin,
      gramsPerBobbin: gramsPerBobbin,
    );
    final next = List<MaterialRow>.from(state.materials);
    next[index] = updated;
    state = _recompute(state.copyWith(materials: next));
  }

  /// Aplica defaults desde un filamento (precio y gramos por bobina).
  ///
  /// En modo express: actualiza los campos top-level.
  /// En modo advanced: actualiza la primera fila si existe, sino no hace nada.
  void loadFilamentDefaults({
    required String pricePerBobbin,
    required String gramsPerBobbin,
  }) {
    if (state.mode == CalculatorMode.express) {
      state = _recompute(state.copyWith(
        filamentPrice: pricePerBobbin,
        filamentGrams: gramsPerBobbin,
      ));
      return;
    }
    if (state.materials.isEmpty) return;
    updateMaterial(0, pricePerBobbin: pricePerBobbin, gramsPerBobbin: gramsPerBobbin);
  }

  /// Resetea el form a los defaults (limpia output y campos numericos user-input).
  void reset() {
    state = CalculatorState.initial();
  }

  /// Recalcula el output si el form es valido, si no limpia el output.
  CalculatorState _recompute(CalculatorState next) {
    if (!next.isValid) {
      return next.copyWith(clearOutput: true);
    }
    final input = _buildInput(next);
    final output = CalculationEngine.compute(input);
    return next.copyWith(output: output);
  }

  /// Construye el [CalculationInput] desde el state. Asume [CalculatorState.isValid].
  CalculationInput _buildInput(CalculatorState s) {
    final materials = <MaterialInput>[];
    if (s.mode == CalculatorMode.express) {
      materials.add(MaterialInput(
        label: _materialLabel,
        weightGrams: CalculatorState.parseDecimal(s.weight)!,
        pricePerBobbin: CalculatorState.parseDecimal(s.filamentPrice)!,
        gramsPerBobbin: CalculatorState.parseDecimal(s.filamentGrams)!,
      ));
    } else {
      for (final row in s.materials) {
        if (!row.isValid) continue;
        materials.add(MaterialInput(
          label: row.label.isEmpty ? 'Material' : row.label,
          weightGrams: CalculatorState.parseDecimal(row.weight)!,
          pricePerBobbin: CalculatorState.parseDecimal(row.pricePerBobbin)!,
          gramsPerBobbin: CalculatorState.parseDecimal(row.gramsPerBobbin)!,
        ));
      }
    }
    return CalculationInput(
      materials: materials,
      totalHours: CalculatorState.parseDecimal(s.printHours)!,
      printerWatts: CalculatorState.parseDecimal(s.printerWatts)!,
      kwhRate: CalculatorState.parseDecimal(s.kwhRate)!,
      profitBasePercentage: CalculatorState.parseDecimal(s.profitPct)!,
      discountPercentage: CalculatorState.parseDecimal(s.discountPct)!,
    );
  }
}

/// Provider del [CalculatorNotifier]. Standalone (no depende de DB).
final calculatorNotifierProvider =
    NotifierProvider<CalculatorNotifier, CalculatorState>(
  CalculatorNotifier.new,
);
