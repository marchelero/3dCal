// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/calculation_draft.dart' as storage;
import '../../../../features/settings/domain/settings.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../data/calculation_repository.dart';
import '../../domain/calculation_engine.dart';
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/material_input.dart';
import '../notifiers/calculations_notifier.dart';
import 'calculator_state.dart';

/// Notifier reactivo para el formulario de cotizacion.
///
/// **Modos**:
/// - `express`: 1 material via setters simples.
/// - `advanced`: lista de materiales con `addMaterial/removeMaterial/updateMaterial`.
///
/// Formula simplificada: totalPrice = materialCost - discountAmount.
/// Sin electricidad, sin profit, sin watts de impresora.
///
/// El output se recalcula en cada cambio, sincronamente (engine es pure).
/// Si el form no es valido, [CalculatorState.output] queda en `null`.
class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() => CalculatorState.initial();

  // === Mode ===

  void setMode(CalculatorMode mode) {
    state = _recompute(state.copyWith(mode: mode));
  }

  // === Setters express ===

  void setWeight(String value) {
    state = _recompute(state.copyWith(weight: value));
  }

  void setFilamentPrice(String value) {
    state = _recompute(state.copyWith(filamentPrice: value));
  }

  void setFilamentGrams(String value) {
    state = _recompute(state.copyWith(filamentGrams: value));
  }

  // === Setters comunes ===

  void setPrintHours(String value) {
    state = _recompute(state.copyWith(printHours: value));
  }

  void setPrintMinutes(String value) {
    state = _recompute(state.copyWith(printMinutes: value));
  }

  void setDiscountPct(String value) {
    state = _recompute(state.copyWith(discountPct: value));
  }

  void setLabel(String value) {
    state = state.copyWith(label: value);
  }

  // === OTROS (F1: extras por cotizacion) ===

  void setExtraLaborRate(String value) {
    state = _recompute(state.copyWith(extraLaborRate: value));
  }

  void setExtraPostProcessRate(String value) {
    state = _recompute(state.copyWith(extraPostProcessRate: value));
  }

  void setExtraFailureRate(String value) {
    state = _recompute(state.copyWith(extraFailureRate: value));
  }

  void setExtraMarkupOnMaterials(String value) {
    state = _recompute(state.copyWith(extraMarkupOnMaterials: value));
  }

  // === Express material label ===

  void setFilamentLabel(String value) {
    state = state.copyWith(filamentLabel: value);
  }

  // === Setters advanced (multi-material) ===

  void addMaterial() {
    final next = List<MaterialRow>.from(state.materials)
      ..add(const MaterialRow());
    state = _recompute(state.copyWith(materials: next));
  }

  void removeMaterial(int index) {
    if (index < 0 || index >= state.materials.length) return;
    final next = List<MaterialRow>.from(state.materials)..removeAt(index);
    state = _recompute(state.copyWith(materials: next));
  }

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
    updateMaterial(0,
        pricePerBobbin: pricePerBobbin, gramsPerBobbin: gramsPerBobbin);
  }

  /// Resetea el form a los defaults.
  void reset() {
    state = CalculatorState.initial();
  }

  /// Restaura el form desde un draft persistido.
  ///
  /// Llamado por [CalculatorPage.initState] al reabrir la app si habia un
  /// draft guardado. Aplica el modo (express/advanced), los campos comunes
  /// (horas, descuento, etiqueta) y los express (peso, precio, gramos).
  /// En advanced, reconstruye las filas de materiales desde [MaterialDraft]s.
  void restoreFromDraft(storage.CalculationDraft draft) {
    final mode =
        draft.isAdvanced ? CalculatorMode.advanced : CalculatorMode.express;
    state = _recompute(CalculatorState(
      mode: mode,
      printHours: draft.printHours,
      printMinutes: draft.printMinutes,
      discountPct: draft.discountPct,
      label: draft.label,
      filamentLabel: draft.filamentLabel,
      weight: draft.weight,
      filamentPrice: draft.filamentPrice,
      filamentGrams: draft.filamentGrams,
      materials: draft.materials
          .map((m) => MaterialRow(
                label: m.label,
                weight: m.weight,
                pricePerBobbin: m.pricePerBobbin,
                gramsPerBobbin: m.gramsPerBobbin,
              ))
          .toList(),
      output: null,
    ));
  }

  /// Alterna el detalle secreto (ojito) con desglose electrico/profit.
  /// Los valores detallados ya estan computados en _recompute().
  void toggleDetail() {
    state = state.copyWith(showDetail: !state.showDetail);
  }

  /// Carga el state desde una cotizacion guardada (para "Reusar").
  Future<void> loadFromCalculation(Calculation calc) async {
    final repo = ref.read(calculationRepositoryProvider);
    final mats = await repo.materialsOf(calc.id);
    final mode =
        mats.length > 1 ? CalculatorMode.advanced : CalculatorMode.express;
    final total = CalculatorState.parseDecimal(
          calc.totalHours.toStringAsFixed(2),
        ) ??
        Decimal.zero;

    // Recuperar el split h/m.
    // - Nuevos: printMinutes esta persistido (v4+).
    // - Viejos (v3): printMinutes=0 default. Si total tiene parte fraccional,
    //   derivamos (best-effort: 1.55h -> 1h 33min).
    //
    // Estrategia: convertir total a minutos totales, separar.
    final totalMinutesInt =
        (total * Decimal.fromInt(60)).toBigInt().toInt();
    int minutes;
    Decimal hours;
    if (calc.printMinutes > 0) {
      // Trust the stored value: take it from the DB.
      minutes = calc.printMinutes;
      final hoursAsMinutes = totalMinutesInt - minutes;
      hours = Decimal.fromInt(hoursAsMinutes ~/ 60);
    } else {
      // Backfill: derive from total.
      minutes = totalMinutesInt % 60;
      hours = Decimal.fromInt(totalMinutesInt ~/ 60);
    }

    final discount = CalculatorState.parseDecimal(
          calc.discountPercentage.toStringAsFixed(2),
        ) ??
        Decimal.zero;

    if (mode == CalculatorMode.express) {
      final m = mats.isEmpty ? null : mats.first;
      state = _recompute(
        CalculatorState(
          mode: CalculatorMode.express,
          printHours: hours.toString(),
          printMinutes: minutes > 0 ? minutes.toString() : '',
          discountPct: discount.toString(),
          label: calc.pieceName ?? '',
          filamentLabel: m == null ? '' : m.label,
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
        printMinutes: minutes > 0 ? minutes.toString() : '',
        discountPct: discount.toString(),
        label: calc.pieceName ?? '',
        weight: '',
        filamentPrice: '',
        filamentGrams: '',
        materials: rows,
        output: null,
      ),
    );
  }

  /// Guarda la cotizacion actual en la DB.
  Future<int?> save({String? pieceName, String? clientName}) async {
    if (!state.isValid || state.output == null) return null;
    final input = _buildInput(state);
    final draft = CalculationDraft(
      materials: input.materials,
      totalHours: input.totalHours,
      printMinutes: CalculatorState.parseDecimal(state.printMinutes)?.toBigInt().toInt() ?? 0,
      discountPercentage: input.discountPercentage,
      output: state.output!,
      filamentLabel: state.filamentLabel,
      pieceName: (state.label.trim().isNotEmpty)
          ? state.label.trim()
          : (pieceName == null || pieceName.trim().isEmpty
              ? null
              : pieceName.trim()),
      clientName: (clientName == null || clientName.trim().isEmpty)
          ? null
          : clientName.trim(),
    );
    final repo = ref.read(calculationRepositoryProvider);
    final id = await repo.create(draft);
    ref.invalidate(calculationsNotifierProvider);
    return id;
  }

  /// Recalcula el output si el form es valido usando el engine completo (F1).
  ///
  /// El engine recibe todos los parametros de settings (printerWatts, kwhRate,
  /// profitBase, laborRate, etc.) via [CalculationInput]. No hay calculo
  /// secundario — el output del engine es la unica fuente de verdad.
  CalculatorState _recompute(CalculatorState next) {
    final version = next.computeVersion + 1;
    if (!next.isValid) {
      return next.copyWith(
        clearOutput: true,
        clearDetail: true,
        computeVersion: version,
      );
    }
    final input = _buildInput(next);
    final output = CalculationEngine.compute(input);

    // Desglose de costo por material
    final breakdown = input.materials
        .map((m) => MaterialCostBreakdown(
              label: m.label,
              cost: m.cost,
            ))
        .toList();

    final discountPct =
        CalculatorState.parseDecimal(next.discountPct) ?? Decimal.zero;

    return next.copyWith(
      output: output,
      detailMaterialBreakdown: breakdown,
      detailElectricCost: output.electricCost,
      detailLaborCost: output.laborCost,
      detailPostProcessCost: output.postProcessCost,
      detailBaseCost: output.baseCost,
      detailFailureCost: output.failureCost,
      detailMarkupCost: output.markupCost,
      detailProfitAmount: output.profitAmount,
      detailTotalFinal: output.totalFinal,
      detailDiscountPct: discountPct,
      computeVersion: version,
    );
  }

  /// Construye [CalculationInput] desde el state + settings + printer.
  ///
  /// Lee [Settings] y [defaultPrinter] de los providers para pasar watts,
  /// kwhRate, profitBase y los 5 nuevos parametros F1 al engine.
  CalculationInput _buildInput(CalculatorState s) {
    final asyncSettings =
        ref.read<AsyncValue<Settings>>(settingsNotifierProvider);
    final settings = asyncSettings.valueOrNull ?? Settings.defaults;
    final printer = ref.read(defaultPrinterProvider);

    final materials = <MaterialInput>[];
    if (s.mode == CalculatorMode.express) {
      final matLabel =
          s.filamentLabel.isNotEmpty ? s.filamentLabel : 'Filamento';
      materials.add(MaterialInput(
        label: matLabel,
        weightGrams: CalculatorState.parseDecimal(s.weight)!,
        pricePerBobbin: CalculatorState.parseDecimal(s.filamentPrice)!,
        gramsPerBobbin: CalculatorState.parseDecimal(s.filamentGrams) ??
            Decimal.fromInt(1000),
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
      totalHours: s.totalHoursDecimal ?? Decimal.zero,
      discountPercentage:
          CalculatorState.parseDecimal(s.discountPct) ?? Decimal.zero,
      printerWatts: printer?.averageWatts ?? 0,
      kwhRate: settings.kwhRate,
      profitBase: settings.profitBase,
      laborRate: CalculatorState.parseDecimal(s.extraLaborRate) ?? Decimal.zero,
      postProcessRate:
          CalculatorState.parseDecimal(s.extraPostProcessRate) ?? Decimal.zero,
      failureRate:
          CalculatorState.parseDecimal(s.extraFailureRate) ?? Decimal.zero,
      markupOnMaterials: CalculatorState.parseDecimal(s.extraMarkupOnMaterials) ??
          Decimal.zero,
    );
  }
}

/// Provider del [CalculatorNotifier]. Standalone (no depende de DB).
final calculatorNotifierProvider =
    NotifierProvider<CalculatorNotifier, CalculatorState>(
  CalculatorNotifier.new,
);
