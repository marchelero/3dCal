// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers.dart';
import '../../data/calculation_repository.dart';
import '../../domain/calculation_engine.dart';
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/material_input.dart';
import '../notifiers/calculations_notifier.dart';
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

  /// Carga el state desde una cotizacion guardada (para "Reusar").
  ///
  /// Lee los snapshots de [calc] + los materiales de la DB y reconstruye un
  /// [CalculatorState] valido. Si hay 1 material, va a modo `express`; si hay
  /// mas, va a `advanced`.
  Future<void> loadFromCalculation(Calculation calc) async {
    final repo = ref.read(calculationRepositoryProvider);
    final mats = await repo.materialsOf(calc.id);
    final mode = mats.length > 1
        ? CalculatorMode.advanced
        : CalculatorMode.express;
    final kwh = CalculatorState.parseDecimal(
          calc.kwhRateSnapshot.toStringAsFixed(2),
        ) ??
        Decimal.zero;
    final profit = CalculatorState.parseDecimal(
          calc.profitBaseSnapshot.toStringAsFixed(2),
        ) ??
        Decimal.zero;
    final discount = CalculatorState.parseDecimal(
          calc.discountPercentage.toStringAsFixed(2),
        ) ??
        Decimal.zero;
    final watts = CalculatorState.parseDecimal(
          calc.printerWattsSnapshot.toStringAsFixed(2),
        ) ??
        Decimal.zero;
    final hours = CalculatorState.parseDecimal(
          calc.totalHours.toStringAsFixed(2),
        ) ??
        Decimal.zero;
    if (mode == CalculatorMode.express) {
      final m = mats.isEmpty
          ? null
          : mats.first;
      state = _recompute(
        CalculatorState(
          mode: CalculatorMode.express,
          printHours: hours.toString(),
          printerWatts: watts.toString(),
          kwhRate: kwh.toString(),
          profitPct: profit.toString(),
          discountPct: discount.toString(),
          weight: m == null ? '' : m.weightGrams.toStringAsFixed(0),
          filamentPrice:
              m == null ? '' : m.pricePerBobbinSnapshot.toStringAsFixed(2),
          filamentGrams:
              m == null ? '' : m.gramsPerBobbinSnapshot.toStringAsFixed(0),
          materials: const <MaterialRow>[],
          output: null,
        ),
      );
      return;
    }
    // Advanced: una fila por material.
    final rows = mats
        .map(
          (m) => MaterialRow(
            label: m.label,
            weight: m.weightGrams.toStringAsFixed(0),
            pricePerBobbin: m.pricePerBobbinSnapshot.toStringAsFixed(2),
            gramsPerBobbin: m.gramsPerBobbinSnapshot.toStringAsFixed(0),
          ),
        )
        .toList();
    state = _recompute(
      CalculatorState(
        mode: CalculatorMode.advanced,
        printHours: hours.toString(),
        printerWatts: watts.toString(),
        kwhRate: kwh.toString(),
        profitPct: profit.toString(),
        discountPct: discount.toString(),
        weight: '',
        filamentPrice: '',
        filamentGrams: '',
        materials: rows,
        output: null,
      ),
    );
  }

  /// Guarda la cotizacion actual en la DB. Devuelve el id, o `null` si el
  /// form no es valido. Lanza si la DB falla.
  ///
  /// **Snapshots**: precio kWh, profit base, watts de impresora y descuento
  /// se copian del state al momento de guardar. Cambios futuros en catalogos
  /// NO afectan cotizaciones historicas.
  ///
  /// **Active printer**: si el user eligio una impresora en el AppBar, sus
  /// snapshots se incluyen. Si no, `printerId` queda `null` (proforma rapida).
  Future<int?> save({String? pieceName, String? clientName}) async {
    if (!state.isValid || state.output == null) return null;
    final input = _buildInput(state);
    final printer = ref.read(activePrinterProvider);
    final draft = CalculationDraft(
      materials: input.materials,
      totalHours: input.totalHours,
      printerId: printer?.id,
      printerNameSnapshot: printer?.name,
      printerWattsSnapshot: input.printerWatts,
      discountPercentage: input.discountPercentage,
      kwhRateSnapshot: input.kwhRate,
      profitBaseSnapshot: input.profitBasePercentage,
      output: state.output!,
      pieceName: (pieceName == null || pieceName.trim().isEmpty)
          ? null
          : pieceName.trim(),
      clientName: (clientName == null || clientName.trim().isEmpty)
          ? null
          : clientName.trim(),
    );
    final repo = ref.read(calculationRepositoryProvider);
    final id = await repo.create(draft);
    // Invalida el notifier del historial y dashboard para que refresquen
    // la proxima vez que se lean (al volver a Historial o Home).
    ref.invalidate(calculationsNotifierProvider);
    return id;
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
