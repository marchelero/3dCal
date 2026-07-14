// ignore_for_file: public_member_api_docs

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/calculation_engine.dart';
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/material_input.dart';
import 'calculator_state.dart';

/// Notifier reactivo para el formulario de cotizacion.
///
/// **Reglas**:
/// - Single material: la cotizacion usa 1 filamento a la vez (Sprint 3).
/// - El output se recalcula en cada cambio, sincronamente (engine es pure).
/// - Si el form no es valido, [CalculatorState.output] queda en `null`.
/// - `profitBasePercentage` se mantiene como esta; el engine clampea a 0
///   el `profitAmount` si `effProfit < 0` (no se vende a perdida).
class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() => CalculatorState.initial();

  /// Etiqueta visible del material en el motor. Cambia si el user edita
  /// el filamento seleccionado (placeholder en Sprint 3, dinamico en
  /// Sprint 4 cuando se conecte al repositorio de filamentos).
  static const _materialLabel = 'Filamento';

  // === Setters (uno por field) ===

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

  /// Resetea el form a los defaults (limpia output y campos numericos user-input).
  void reset() {
    state = CalculatorState.initial();
  }

  /// Aplica defaults desde un filamento (precio y gramos por bobina).
  ///
  /// Usado en Sprint 4 cuando se conecte con el repositorio. En Sprint 3
  /// se llama manualmente desde el test o desde un selector placeholder.
  void loadFilamentDefaults({
    required String pricePerBobbin,
    required String gramsPerBobbin,
  }) {
    state = _recompute(state.copyWith(
      filamentPrice: pricePerBobbin,
      filamentGrams: gramsPerBobbin,
    ));
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
    final material = MaterialInput(
      label: _materialLabel,
      weightGrams: CalculatorState.parseDecimal(s.weight)!,
      pricePerBobbin: CalculatorState.parseDecimal(s.filamentPrice)!,
      gramsPerBobbin: CalculatorState.parseDecimal(s.filamentGrams)!,
    );
    return CalculationInput(
      materials: [material],
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
