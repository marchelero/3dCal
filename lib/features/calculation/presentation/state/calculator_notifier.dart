// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/export/pdf_rate_audit.dart';
import '../../../../core/export/quote_report_variant.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/calculation_draft.dart' as storage;
import '../../../../features/settings/domain/settings.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../catalog/printers/data/printer_repository.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../../../settings/domain/discount_tier.dart';
import '../../data/calculation_repository.dart';
import '../../domain/batch_discount_resolver.dart';
import '../../domain/batch_lot_composer.dart';
import '../../domain/calculation_engine.dart';
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/calculation_output.dart';
import '../../domain/entities/material_input.dart';
import '../notifiers/calculations_notifier.dart';
import 'calculator_state.dart';

export '../notifiers/calculations_notifier.dart'
    show HistoryCapReachedException;

/// Thrown when [CalculatorNotifier.save] is called but the form is not valid
/// (missing required fields or no computed output). The caller cannot
/// distinguish "invalid form" from "history cap reached" via the nullable
/// return value, so this typed exception provides an explicit signal.
class FormIncompleteException implements Exception {
  const FormIncompleteException();

  @override
  String toString() =>
      'FormIncompleteException: el formulario no está completo.';
}

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
  /// Últimos escalones de descuento leídos del repo (feature A). Se mantiene
  /// sincronizado con la DB vía [discountTiersProvider]; cada cambio dispara
  /// un recompute para que el lotTotal refleje el escalón aplicado.
  List<DiscountTier> _tiers = const <DiscountTier>[];

  @override
  CalculatorState build() {
    // Recalcula cuando cambia la impresora activa (elegida en el selector,
    // creada desde el CTA, o restaurada desde prefs) para que el costo de
    // energia se actualice sin que el usuario tenga que tocar un campo.
    ref.listen(activePrinterProvider, (_, _) {
      if (state.isValid) {
        state = _recompute(state);
      }
    });
    // Idem para settings globales (kwhRate, profitBase, labor, etc.): si el
    // usuario cambia un parametro en Ajustes, el total se recalcula al vuelo
    // en vez de quedar con el valor anterior hasta tocar un campo.
    ref.listen(settingsNotifierProvider, (_, _) {
      if (state.isValid) {
        state = _recompute(state);
      }
    });
    // Los escalones de descuento (feature A) NO se escuchan acá: el stream de
    // la DB vive en la página (ref.listen en build) para que los unit tests
    // sin widget no sostengan una suscripción drift abierta (haría colgar
    // `db.close()` en tearDown). La página llama [updateTiers] al cambiar la
    // lista, que por acá recalcula el lote si el form es válido.
    return CalculatorState.initial();
  }

  /// Carga la última lista de escalones de descuento vigentes (feature A).
  /// Llamado por la UI cuando [discountTiersProvider] emite. Recalcula el
  /// lote si el form es válido para reflejar el escalón aplicado.
  void updateTiers(List<DiscountTier> tiers) {
    _tiers = tiers;
    if (state.isValid) {
      state = _recompute(state);
    }
  }

  /// Fuerza un recalculo del form actual si es valido. Idempotente.
  ///
  /// La pagina lo llama **despues del prefill** ("Editar"/"Reusar") para
  /// garantizar que el total quede calculado ni bien se entra, sin esperar a
  /// que el usuario toque un campo.
  void recompute() {
    if (state.isValid) {
      state = _recompute(state);
    }
  }

  // === Mode ===

  void setMode(CalculatorMode mode) {
    if (state.mode == mode) return;
    // El selector solo ofrece 2 variantes por modo. Al cambiar de express a
    // avanzado (o al reves) hay que arrastrar la eleccion al eje nuevo: si no,
    // quedaria seleccionada una variante que la UI ya no muestra y el usuario
    // creeria estar viendo otra cosa.
    state = _recompute(
      state.copyWith(
        mode: mode,
        reportVariant: state.reportVariant.forMode(
          isAdvanced: mode == CalculatorMode.advanced,
        ),
      ),
    );
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
    // BUG-013 fix: clamp defensivo 0..kMaxDiscountPercentage en el punto
    // unico de entrada. La UI ya clampa, pero draft-restore/loadFromCalc
    // pueden traer valores fuera de rango que producian total negativo.
    final parsed = CalculatorState.parseDecimal(value);
    if (parsed == null) {
      state = _recompute(state.copyWith(discountPct: value));
      return;
    }
    final clamped = parsed.clamp(
      Decimal.zero,
      Decimal.fromInt(kMaxDiscountPercentage),
    );
    state = _recompute(state.copyWith(discountPct: clamped.toString()));
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

  // === v17: setters de los 3 campos de servicio con modo % / fijo ===

  /// Cambia el modo del campo "Modelado y diseño" (`pct` | `fixed`).
  void setModelingMode(String mode) {
    state = _recompute(
      state.copyWith(modelingMode: _normalizeServiceMode(mode)),
    );
  }

  /// Cambia el valor del modelado. Se interpreta segun el modo activo.
  void setModelingValue(String value) {
    state = _recompute(state.copyWith(modelingValue: value));
  }

  /// Cambia el modo del campo "Postprocesado" (`pct` | `fixed`).
  void setPostprocMode(String mode) {
    state = _recompute(
      state.copyWith(postprocMode: _normalizeServiceMode(mode)),
    );
  }

  /// Cambia el valor del postprocesado.
  void setPostprocValue(String value) {
    state = _recompute(state.copyWith(postprocValue: value));
  }

  /// Cambia el modo del campo "Extras" (`pct` | `fixed`).
  void setExtraCostMode(String mode) {
    state = _recompute(
      state.copyWith(extraCostMode: _normalizeServiceMode(mode)),
    );
  }

  /// Cambia el valor de los extras.
  void setExtraCostValue(String value) {
    state = _recompute(state.copyWith(extraCostValue: value));
  }

  /// Cambia la descripcion libre de los extras (argollas, pegamento, etc.).
  void setExtraCostLabel(String label) {
    state = state.copyWith(extraCostLabel: label);
  }

  /// Actualiza la cantidad de unidades del lote (>= 1).
  ///
  /// El engine produce precios UNITARIOS; el total efectivo
  /// (`unitario x quantity`) se calcula en la capa de presentacion
  /// (`calculator_page`, `quote_image_template`) y al agregar queries.
  void setQuantity(int value) {
    if (value < 1) return;
    state = _recompute(state.copyWith(quantity: value));
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
    bool? useOwnTime,
    String? materialHours,
    String? materialMinutes,
  }) {
    if (index < 0 || index >= state.materials.length) return;
    final updated = state.materials[index].copyWith(
      label: label,
      weight: weight,
      pricePerBobbin: pricePerBobbin,
      gramsPerBobbin: gramsPerBobbin,
      useOwnTime: useOwnTime,
      materialHours: materialHours,
      materialMinutes: materialMinutes,
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
      state = _recompute(
        state.copyWith(
          filamentPrice: pricePerBobbin,
          filamentGrams: gramsPerBobbin,
        ),
      );
      return;
    }
    if (state.materials.isEmpty) return;
    updateMaterial(
      0,
      pricePerBobbin: pricePerBobbin,
      gramsPerBobbin: gramsPerBobbin,
    );
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
    final mode = draft.isAdvanced
        ? CalculatorMode.advanced
        : CalculatorMode.express;
    debugPrint(
      '[restoreFromDraft] mode=$mode weight=${draft.weight} '
      'hours=${draft.printHours} price=${draft.filamentPrice} '
      'label=${draft.label} filament=${draft.filamentLabel}',
    );
    state = _recompute(
      CalculatorState(
        mode: mode,
        printHours: draft.printHours,
        printMinutes: draft.printMinutes,
        discountPct: draft.discountPct,
        label: draft.label,
        filamentLabel: draft.filamentLabel,
        weight: draft.weight,
        filamentPrice: draft.filamentPrice,
        filamentGrams: draft.filamentGrams,
        // MED-07 fix (auditoría 2026-10-04): la cantidad del lote también
        // sobrevive al cierre de la app. Con el default 1, un lote de 12 u
        // volvía a cotizar como 1 u sin aviso.
        quantity: draft.quantity < 1 ? 1 : draft.quantity,
        materials: draft.materials
            .map(
              (m) => MaterialRow(
                label: m.label,
                weight: m.weight,
                pricePerBobbin: m.pricePerBobbin,
                gramsPerBobbin: m.gramsPerBobbin,
                useOwnTime: m.useOwnTime,
                materialHours: m.materialHours,
                materialMinutes: m.materialMinutes,
              ),
            )
            .toList(),
        output: null,
        extraLaborRate: draft.extraLaborRate,
        extraPostProcessRate: draft.extraPostProcessRate,
        extraFailureRate: draft.extraFailureRate,
        extraMarkupOnMaterials: draft.extraMarkupOnMaterials,
        // v17: los 3 costos de servicio sobreviven al cierre de la app.
        modelingMode: _normalizeServiceMode(draft.modelingMode),
        modelingValue: _hoursText(draft.modelingValue),
        postprocMode: _normalizeServiceMode(draft.postprocMode),
        postprocValue: _hoursText(draft.postprocValue),
        extraCostMode: _normalizeServiceMode(draft.extraCostMode),
        extraCostValue: _hoursText(draft.extraCostValue),
        extraCostLabel: draft.extraCostLabel,
      ),
    );
  }

  /// Fija la variante del reporte (pantalla, PDF, PNG e impresion).
  ///
  /// Rechaza una variante que no pertenece al modo actual: el selector solo
  /// ofrece 2, y aceptar la otra dejaria el estado en un valor invisible para
  /// el usuario.
  void setReportVariant(QuoteReportVariant variant) {
    final allowed = QuoteReportVariant.optionsForMode(
      isAdvanced: state.mode == CalculatorMode.advanced,
    );
    if (!allowed.contains(variant) || state.reportVariant == variant) return;
    state = state.copyWith(reportVariant: variant);
  }

  /// Avanza a la siguiente variante del eje actual (cliente <-> detalle).
  void cycleReportVariant() {
    final allowed = QuoteReportVariant.optionsForMode(
      isAdvanced: state.mode == CalculatorMode.advanced,
    );
    setReportVariant(
      allowed[(allowed.indexOf(state.reportVariant) + 1) % allowed.length],
    );
  }

  /// Carga el state desde una cotizacion guardada (para "Reusar").
  Future<void> loadFromCalculation(Calculation calc) async {
    final repo = ref.read(calculationRepositoryProvider);
    final mats = await repo.materialsOf(calc.id);
    // v16+: el flag `is_advanced` es la fuente de verdad. Antes se usaba
    // `mats.length > 1` como fallback, pero eso rompia cotizaciones Express
    // cuyo guardado rapido habia persistido el material implicito (1 fila) y,
    // combinado con filas previas, forzaba Advanced: el form quedaba en
    // multi-material y el total no aparecia. Las filas pre-v16 con varios
    // materiales ya quedaron marcadas por la migracion v16 (data migration).
    final mode = calc.isAdvanced
        ? CalculatorMode.advanced
        : CalculatorMode.express;
    final total =
        CalculatorState.parseDecimal(calc.totalHours.toStringAsFixed(2)) ??
        Decimal.zero;

    // Recuperar el split h/m.
    // - Nuevos: printMinutes esta persistido (v4+).
    // - Viejos (v3): printMinutes=0 default. Si total tiene parte fraccional,
    //   derivamos (best-effort: 1.55h -> 1h 33min).
    //
    // Estrategia: convertir total a minutos totales, separar.
    final totalMinutesInt = CalculatorState.decimalHoursToMinutes(total);
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

    final discount =
        CalculatorState.parseDecimal(
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
          filamentPrice: m == null
              ? ''
              : m.pricePerBobbinSnapshot.toStringAsFixed(2),
          filamentGrams: m == null
              ? ''
              : m.gramsPerBobbinSnapshot.toStringAsFixed(0),
          materials: const <MaterialRow>[],
          output: null,
          quantity: calc.quantity < 1 ? 1 : calc.quantity,
          // v17: restaurar los 3 costos de servicio. Filas pre-v17 (y las
          // guardadas con el modo "Auto" que se elimino) caen a `fixed`.
          modelingMode: _normalizeServiceMode(calc.modelingMode),
          modelingValue: _hoursText(calc.modelingValue),
          postprocMode: _normalizeServiceMode(calc.postprocMode),
          postprocValue: _hoursText(calc.postprocValue),
          extraCostMode: _normalizeServiceMode(calc.extraMode),
          extraCostValue: _hoursText(calc.extraValue),
          extraCostLabel: calc.extraLabel,
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
            // v15: restaurar el desglose de tiempo propio por material.
            useOwnTime: m.useOwnTime ?? false,
            materialHours: m.materialHours == null
                ? ''
                : _hoursText(m.materialHours!),
            materialMinutes: m.materialMinutes == null
                ? ''
                : _minutesText(m.materialMinutes!),
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
        quantity: calc.quantity < 1 ? 1 : calc.quantity,
        modelingMode: _normalizeServiceMode(calc.modelingMode),
        modelingValue: _hoursText(calc.modelingValue),
        postprocMode: _normalizeServiceMode(calc.postprocMode),
        postprocValue: _hoursText(calc.postprocValue),
        extraCostMode: _normalizeServiceMode(calc.extraMode),
        extraCostValue: _hoursText(calc.extraValue),
        extraCostLabel: calc.extraLabel,
      ),
    );
  }

  /// Guarda la cotizacion actual en la DB.
  ///
  /// **Cap gate (T15)**: si el user no es Pro y la DB ya tiene
  /// [kFreeHistoryCap] cotizaciones, lanza [HistoryCapReachedException]
  /// y NO inserta nada. Los items existentes quedan intactos.
  /// Pro users: sin cap.
  /// Al guardar, suma las horas impresas al `currentHours` de la impresora.
  ///
  /// **Editar** ([updateId] no null): actualiza la fila existente en vez de
  /// crear una nueva. Tres diferencias deliberadas con el alta:
  /// - NO hay cap gate (no crece el historial).
  /// - NO se suman horas a la impresora: son horas ya contadas al crear la
  ///   cotizacion; sumarlas de nuevo inflaria la depreciacion.
  /// - Se conservan `id`, `createdAt` e `isSold`.
  /// Devuelve `false` si la cotizacion ya no existe (borrada mientras
  /// editaba); el caller muestra el error generico.
  Future<int?> save({
    String? pieceName,
    String? clientName,
    String? notes,
    String? conditions,
    Uint8List? pieceImageBytes,
    int? updateId,
    bool markDefinitive = false,
  }) async {
    if (!state.isValid || state.output == null) {
      throw const FormIncompleteException();
    }
    final repo = ref.read(calculationRepositoryProvider);
    final printerRepo = ref.read(printerRepositoryProvider);
    // F2: downscale antes de persistir (max 1200px lado mayor, JPEG q85).
    final downscale = ref.read(pieceImageDownscalerProvider);
    final pieceImage = await downscale(pieceImageBytes);

    if (updateId != null) {
      // Convertir un borrador en definitiva SUMA al historial real (los
      // borradores no cuentan). Validar el cap Free antes para no dejar al
      // usuario con una "cotizacion" que excede el limite.
      if (markDefinitive) {
        final isPro = await resolveIsPro(ref);
        if (!isPro) {
          final count = await repo.countAll();
          if (count >= kFreeHistoryCap) {
            throw HistoryCapReachedException(
              cap: kFreeHistoryCap,
              currentCount: count,
            );
          }
        }
        // Sumar horas a la impresora solo al convertir (una vez). Editar una
        // cotizacion existente NO re-suma (son horas ya contadas).
        await _addHoursToPrinter(printerRepo);
      }
      final ok = await repo.updateCalculation(
        updateId,
        _buildDraft(
          pieceName: pieceName,
          clientName: clientName,
          notes: notes,
          conditions: conditions,
          pieceImageBytes: pieceImage,
        ),
        markDefinitive: markDefinitive,
      );
      // El historial se refresca solo via drift watchItems().
      return ok ? updateId : null;
    }

    final isPro = await resolveIsPro(ref);
    // El repositorio hace conteo + insercion en una sola transaccion.
    if (!isPro) {
      final id = await repo.createIfWithinLimit(
        _buildDraft(
          pieceName: pieceName,
          clientName: clientName,
          notes: notes,
          conditions: conditions,
          pieceImageBytes: pieceImage,
        ),
        limit: kFreeHistoryCap,
      );
      if (id == null) {
        final currentCount = await repo.countAll();
        throw HistoryCapReachedException(
          cap: kFreeHistoryCap,
          currentCount: currentCount,
        );
      }
      // Sumar horas impresas a la impresora activa.
      await _addHoursToPrinter(printerRepo);
      // El historial se refresca solo via drift watchItems().
      return id;
    }
    final id = await repo.create(
      _buildDraft(
        pieceName: pieceName,
        clientName: clientName,
        notes: notes,
        conditions: conditions,
        pieceImageBytes: pieceImage,
      ),
    );
    // Sumar horas impresas a la impresora activa.
    await _addHoursToPrinter(printerRepo);
    // El historial se refresca solo via drift watchItems().
    return id;
  }

  /// Suma las horas estimadas de la cotizacion al `currentHours` de la
  /// impresora activa (para estadisticas de depreciacion).
  Future<void> _addHoursToPrinter(PrinterRepository printerRepo) async {
    final printer = ref.read(activePrinterProvider);
    if (printer == null) return;
    final totalHours = state.totalHoursDecimal;
    if (totalHours == null || totalHours <= Decimal.zero) return;
    await printerRepo.addHours(printer.id, totalHours.toDouble());
  }

  CalculationDraft _buildDraft({
    String? pieceName,
    String? clientName,
    String? notes,
    String? conditions,
    Uint8List? pieceImageBytes,
  }) {
    final input = _buildInput(state);
    final printer = ref.read(activePrinterProvider);
    return CalculationDraft(
      materials: input.materials,
      totalHours: input.totalHours,
      printMinutes:
          CalculatorState.parseDecimal(
            state.printMinutes,
          )?.toBigInt().toInt() ??
          0,
      discountPercentage: input.discountPercentage,
      output: state.output!,
      filamentLabel: state.filamentLabel,
      isAdvanced: state.mode == CalculatorMode.advanced,
      quantity: state.quantity,
      // F2 fix (auditoría 2026-10-04): persistir las tasas REALES que el
      // motor usó (antes se escribían 0 y `resolveRates` caía siempre a los
      // Settings actuales: cambiar Ajustes reescribía el desglose de
      // cotizaciones viejas sin tocar el Total).
      kwhRate: input.kwhRate,
      profitBase: input.profitBase,
      laborRate: input.laborRate,
      postProcessRate: input.postProcessRate,
      failureRate: input.failureRate,
      markupOnMaterials: input.markupOnMaterials,
      minimumCharge: input.minimumCharge,
      printerId: printer?.id,
      printerName: printer?.name,
      printerWatts: printer?.averageWatts,
      pieceName: (state.label.trim().isNotEmpty)
          ? state.label.trim()
          : (pieceName == null || pieceName.trim().isEmpty
                ? null
                : pieceName.trim()),
      clientName: (clientName == null || clientName.trim().isEmpty)
          ? null
          : clientName.trim(),
      notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      conditions: (conditions == null || conditions.trim().isEmpty)
          ? null
          : conditions.trim(),
      pieceImageBytes: pieceImageBytes,
      batchDiscountPercent: state.batchAppliedPercent,
      batchDiscountAmount: state.batchDiscountAmount,
      // v17: modo + valor de los 3 costos de servicio. Sin esto el guardado
      // escribe los defaults de columna y el usuario pierde lo que configuro.
      modelingMode: _normalizeServiceMode(state.modelingMode),
      modelingValue: _textToDouble(state.modelingValue),
      postprocMode: _normalizeServiceMode(state.postprocMode),
      postprocValue: _textToDouble(state.postprocValue),
      extraCostMode: _normalizeServiceMode(state.extraCostMode),
      extraCostValue: _textToDouble(state.extraCostValue),
      extraCostLabel: state.extraCostLabel,
    );
  }

  /// Guarda el form actual como plantilla de trabajo frecuente.
  ///
  /// A diferencia de [save], las plantillas NO cuentan contra el cap free
  /// (T15): se excluyen del historial y del dashboard. Reusan la misma
  /// fila de `calculations` con `isTemplate = true`.
  Future<int?> saveAsTemplate({String? pieceName, String? clientName}) async {
    if (!state.isValid || state.output == null) return null;
    final repo = ref.read(calculationRepositoryProvider);
    final input = _buildInput(state);
    final printer = ref.read(activePrinterProvider);
    final draft = CalculationDraft(
      materials: input.materials,
      totalHours: input.totalHours,
      printMinutes:
          CalculatorState.parseDecimal(
            state.printMinutes,
          )?.toBigInt().toInt() ??
          0,
      discountPercentage: input.discountPercentage,
      output: state.output!,
      filamentLabel: state.filamentLabel,
      isAdvanced: state.mode == CalculatorMode.advanced,
      quantity: state.quantity,
      // F2: las plantillas también snapshotan sus tasas reales.
      kwhRate: input.kwhRate,
      profitBase: input.profitBase,
      laborRate: input.laborRate,
      postProcessRate: input.postProcessRate,
      failureRate: input.failureRate,
      markupOnMaterials: input.markupOnMaterials,
      minimumCharge: input.minimumCharge,
      printerId: printer?.id,
      printerName: printer?.name,
      printerWatts: printer?.averageWatts,
      pieceName: (state.label.trim().isNotEmpty)
          ? state.label.trim()
          : (pieceName == null || pieceName.trim().isEmpty
                ? null
                : pieceName.trim()),
      clientName: (clientName == null || clientName.trim().isEmpty)
          ? null
          : clientName.trim(),
      isTemplate: true,
      batchDiscountPercent: state.batchAppliedPercent,
      batchDiscountAmount: state.batchDiscountAmount,
      // v17: sin estos campos la plantilla se guardaba con los defaults del
      // draft (mode 'fixed' / valor 0) y al reusarla el usuario perdia el
      // modo % / fijo de modelado, postprocesado y extras que habia
      // configurado. El guardado normal (stateToPartialDto) ya los incluye.
      modelingMode: _normalizeServiceMode(state.modelingMode),
      modelingValue: _textToDouble(state.modelingValue),
      postprocMode: _normalizeServiceMode(state.postprocMode),
      postprocValue: _textToDouble(state.postprocValue),
      extraCostMode: _normalizeServiceMode(state.extraCostMode),
      extraCostValue: _textToDouble(state.extraCostValue),
      extraCostLabel: state.extraCostLabel,
    );
    final id = await repo.createTemplate(draft);
    // Plantillas no viven en el historial (isTemplate=true); el stream de
    // watchItems no emite por ellas, pero invalidar es barato y cubre el
    // cap/contadores que sí dependen de calculations.
    ref.invalidate(calculationsNotifierProvider);
    return id;
  }

  /// Elimina una plantilla por id. Devuelve true si existia.
  Future<bool> deleteTemplate(int id) async {
    final repo = ref.read(calculationRepositoryProvider);
    final removed = await repo.delete(id);
    ref.invalidate(calculationsNotifierProvider);
    return removed > 0;
  }

  /// Lista las plantillas guardadas, mas recientes primero.
  Future<List<Calculation>> templates() {
    return ref.read(calculationRepositoryProvider).listTemplates();
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
        clearBatch: true,
        computeVersion: version,
      );
    }
    try {
      final input = _buildInput(next);
      final output = CalculationEngine.compute(input);

      // Desglose de costo por material (unitario, sin cantidad).
      final breakdown = input.materials
          .map((m) => MaterialCostBreakdown(label: m.label, cost: m.cost))
          .toList();

      final discountPct =
          CalculatorState.parseDecimal(next.discountPct) ?? Decimal.zero;

      // Lote mayorista (feature A — Hito 1): el motor NO se toca, solo se
      // consume su OUTPUT. Sin escalón (o N=1) el resultado es `output.totalPrice
      // × N` — idéntico al math actual (regla 95 %).
      final batch = _composeBatch(
        output: output,
        quantity: next.quantity,
        manualDiscountPct: discountPct,
        minimumCharge: input.minimumCharge,
      );

      // Parametros de calculo para el reporte interno. Se derivan del input YA
      // resuelto (snapshot -> fallback), que es la misma fuente que usa el
      // engine: asi la tabla de auditoria no puede desincronizarse del
      // desglose que imprime al lado.
      final rates = ResolvedRates(
        kwhRate: input.kwhRate,
        printerWatts: input.printerWatts,
        laborRate: input.laborRate,
        postProcessRate: input.postProcessRate,
        failureRate: input.failureRate,
        markupOnMaterials: input.markupOnMaterials,
        profitBase: input.profitBase,
        // El contrato de [ResolvedRates.amortizationCost] es el costo
        // ACUMULADO (Bs), no la tarifa por hora. Antes se pasaba
        // `input.amortizationPerHour` (Bs/h) y [PdfRateAudit.fromRates] volvia
        // a dividir por `totalHours` para mostrar "Bs/h": la fila de
        // amortizacion del PDF/PNG quedaba dividida por horas de mas.
        amortizationCost: output.amortizationCost,
      );

      return next.copyWith(
        output: output,
        detailMaterialBreakdown: breakdown,
        detailElectricCost: output.electricCost,
        detailAmortizationCost: output.amortizationCost,
        detailLaborCost: output.laborCost,
        detailPostProcessCost: output.postProcessCost,
        // v17: extras en su propio slot. El reporte (PDF/PNG) lo lee
        // directo y muestra la fila solo si > 0.
        detailExtrasCost: output.extrasCost,
        detailBaseCost: output.baseCost,
        detailFailureCost: output.failureCost,
        detailMarkupCost: output.markupCost,
        detailProfitAmount: output.profitAmount,
        detailTotalFinal: output.totalFinal,
        detailDiscountPct: discountPct,
        batchAppliedPercent: batch.appliedTier?.percent,
        batchAppliedMinQty: batch.appliedTier?.minQty,
        batchDiscountAmount: batch.batchDiscountAmount,
        manualDiscountAmount: batch.manualDiscountAmount,
        subtotalImpression: batch.subtotalImpression,
        lotTotal: batch.lotTotal,
        rateAudit: PdfRateAudit.fromRates(
          rates: rates,
          profitAmount: output.profitAmount,
          baseCost: output.baseCost,
          totalFinal: output.totalFinal,
          totalHours: input.totalHours,
        ),
        showsBatchLine: batch.appliedTier != null,
        computeVersion: version,
      );
    } catch (e, st) {
      debugPrint('[Recompute] ERROR: $e\n$st');
      return next.copyWith(
        clearOutput: true,
        clearDetail: true,
        clearBatch: true,
        computeVersion: version,
      );
    }
  }

  /// Resuelve el escalón aplicado (mayor `min_qty <= quantity`) y compone el
  /// lote. Nunca devuelve null: sin escalón, `lotTotal` == el math actual
  /// escalado y las líneas de lote quedan en cero.
  BatchLotResult _composeBatch({
    required CalculationOutput output,
    required int quantity,
    required Decimal manualDiscountPct,
    required Decimal minimumCharge,
  }) {
    final tier = BatchDiscountResolver.resolve(
      quantity: quantity,
      tiers: _tiers,
    );
    return BatchLotComposer.compose(
      output: output,
      quantity: quantity,
      minimumCharge: minimumCharge,
      tier: tier,
      manualDiscountPct: manualDiscountPct,
    );
  }

  /// Construye [CalculationInput] desde el state + settings + printer.
  ///
  /// Lee [Settings] y la impresora ACTIVA de los providers para pasar watts,
  /// kwhRate, profitBase y los 5 nuevos parametros F1 al engine. Se usa la
  /// activa (no la default) para que el calculo coincida con la UI.
  ///
  /// BUG-007 (NOTA): si settings esta en loading (cold start con DB lenta),
  /// se usan [Settings.defaults] como fallback transitorio. El listener de
  /// `settingsNotifierProvider` en build() (linea ~48) re-dispara _recompute
  /// cuando los settings reales cargan, corrigiendo el total al vuelo.
  /// No se retorna null aca: rompe save()/plantillas cuando settings no
  /// cargaron a tiempo (caso tests + cold start rapido).
  CalculationInput _buildInput(CalculatorState s) {
    final asyncSettings = ref.read<AsyncValue<Settings>>(
      settingsNotifierProvider,
    );
    final settings = asyncSettings.value ?? Settings.defaults;
    final printer = ref.read(activePrinterProvider);

    // F5: amortizacion de la impresora (costo fijo por hora). Null si la
    // impresora no tiene costo/vida util configurados → linea ausente.
    final amortizationPerHour = printer == null
        ? null
        : CalculationEngine.amortizationPerHour(
            purchaseCost: _toDecimal(printer.purchaseCost) ?? Decimal.zero,
            usefulLifeHours: printer.usefulLifeHours ?? 0,
          );

    final materials = <MaterialInput>[];
    if (s.mode == CalculatorMode.express) {
      final matLabel = s.filamentLabel.isNotEmpty
          ? s.filamentLabel
          : 'Filamento';
      materials.add(
        MaterialInput(
          label: matLabel,
          weightGrams: CalculatorState.parseDecimal(s.weight)!,
          pricePerBobbin: CalculatorState.parseDecimal(s.filamentPrice)!,
          // MED-08 fix (auditoría 2026-10-04): "0" o negativos se tratan
          // como "sin dato" -> default 1000 g. Antes `?? 1000` no cubría
          // Decimal(0): el assert de MaterialInput reventaba en debug (y el
          // catch de _recompute lo silenciaba) o, en release, el guard del
          // motor dejaba el costo de material en 0 = cotización regalada.
          gramsPerBobbin: _positiveOr(
            CalculatorState.parseDecimal(s.filamentGrams),
            Decimal.fromInt(1000),
          ),
        ),
      );
    } else {
      for (final row in s.materials) {
        if (!row.isValid) continue;
        materials.add(
          MaterialInput(
            label: row.label.isEmpty ? 'Material' : row.label,
            weightGrams: CalculatorState.parseDecimal(row.weight)!,
            pricePerBobbin: CalculatorState.parseDecimal(row.pricePerBobbin)!,
            gramsPerBobbin: CalculatorState.parseDecimal(row.gramsPerBobbin)!,
            // Snapshot del desglose por material (schema v15). No afecta el
            // costo: el tiempo total ya viene resuelto en totalHoursDecimal.
            useOwnTime: row.useOwnTime,
            ownTimeHours: row.ownTimeHoursDecimal,
            ownTimeMinutes: row.ownTimeMinutesDecimal,
          ),
        );
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
      markupOnMaterials:
          CalculatorState.parseDecimal(s.extraMarkupOnMaterials) ??
          Decimal.zero,
      minimumCharge: settings.minimumCharge,
      amortizationPerHour: amortizationPerHour,
      // === v17: 3 campos de servicio con modo % / fijo ===
      // Default `auto` replica la formula legacy; `off` no cobra. El valor
      // en `modelingValue` se interpreta segun el modo (pct o monto fijo).
      modelingMode: ServiceCostMode.parse(s.modelingMode),
      modelingPct:
          CalculatorState.parseDecimal(s.modelingValue) ?? Decimal.zero,
      modelingFixed:
          CalculatorState.parseDecimal(s.modelingValue) ?? Decimal.zero,
      postprocMode: ServiceCostMode.parse(s.postprocMode),
      postprocPct:
          CalculatorState.parseDecimal(s.postprocValue) ?? Decimal.zero,
      postprocFixed:
          CalculatorState.parseDecimal(s.postprocValue) ?? Decimal.zero,
      extraCostMode: ServiceCostMode.parse(s.extraCostMode),
      extraCostPct:
          CalculatorState.parseDecimal(s.extraCostValue) ?? Decimal.zero,
      extraCostFixed:
          CalculatorState.parseDecimal(s.extraCostValue) ?? Decimal.zero,
    );
  }

  /// Convierte el state actual a un `CalculationsCompanion` parcial para upsert.
  ///
  /// Solo incluye campos que [CalculatorState] tiene valores para.
  /// `pieceName`/`clientName` se escriben SOLO si el form los tiene (state.label);
  /// si estan vacios van ausentes y NO pisan lo que ya tenga la fila en DB.
  /// Antes iban siempre `Value('')` y borraban el nombre al editar un
  /// borrador que ya tenia pieza asignada.
  /// DTO del autoguardado parcial con las TASAS REALES del momento.
  ///
  /// Llamado por la página cuando `ref` sigue vivo. Si el form no está
  /// completo (input no construible) o la lectura falla, degrada al dto
  /// legacy (tasas 0 = fallback Settings al recomprar), igual que antes.
  CalculationsCompanion buildPartialDto(CalculatorState s) {
    CalculationInput? input;
    if (s.isValid && s.output != null) {
      try {
        input = _buildInput(s);
      } catch (_) {
        input = null;
      }
    }
    final printer = ref.read(activePrinterProvider);
    return stateToPartialDto(
      s,
      input: input,
      printerId: printer?.id,
      printerName: printer?.name,
      printerWatts: printer?.averageWatts,
    );
  }

  static CalculationsCompanion stateToPartialDto(
    CalculatorState state, {
    CalculationInput? input,
    int? printerId,
    String? printerName,
    int? printerWatts,
  }) {
    final o = state.output;
    final label = state.label.trim();
    // F2 fix (auditoría 2026-10-04): el parcial persiste las tasas reales que
    // se leyeron de Settings/impresora (si el caller las pasó).
    // LOW-16 fix (auditoría 2026-10-05): si NO hay input resuelto (form
    // inválido o dispose), las tasas van `absent` en vez de Value(0):
    //  - en UPDATE conservan las tasas reales que el borrador ya tenía
    //    (antes el autosave de salida las pisaba con 0 y al reabrir el
    //    form cargaba 0 en vez de las tasas de Settings);
    //  - en INSERT caen al default de columna (0) — migraión v2→v3 añadió
    //    DEFAULT 0 a las 11 columnas F1 (LOW-17), así que NOT NULL no truena.
    // Con input != null el valor null de un campo concreto sí persiste 0
    // (significa "setting sin configurar").
    double rd(Decimal? d) => (d ?? Decimal.zero).toDouble();
    Value<double> rateSnap(Decimal? v) =>
        input == null ? const Value.absent() : Value(rd(v));
    return CalculationsCompanion(
      createdAt: Value(DateTime.now()),
      pieceName: label.isNotEmpty ? Value(label) : const Value.absent(),
      clientName: const Value.absent(),
      notes: const Value.absent(),
      conditions: const Value.absent(),
      // Sin impresora resuelta = `absent` (no borrar la que ya tenía la fila
      // del parcial en una pasada anterior).
      printerId: printerId == null ? const Value.absent() : Value(printerId),
      printerNameSnapshot: printerName == null
          ? const Value.absent()
          : Value(printerName),
      printerWattsSnapshot: printerWatts == null
          ? const Value.absent()
          : Value(printerWatts.toDouble()),
      totalHours: Value(state.totalHoursDecimal?.toDouble() ?? 0),
      printMinutes: Value(
        CalculatorState.parseDecimal(state.printMinutes)?.toBigInt().toInt() ??
            0,
      ),
      discountPercentage: Value(
        CalculatorState.parseDecimal(state.discountPct)?.toDouble() ?? 0,
      ),
      kwhRateSnapshot: rateSnap(input?.kwhRate),
      profitBaseSnapshot: rateSnap(input?.profitBase),
      quantity: Value(state.quantity),
      isSold: const Value(false),
      isTemplate: const Value(false),
      isPartial: const Value(true),
      isAdvanced: Value(state.mode == CalculatorMode.advanced),
      materialCostSnapshot: Value(o?.materialCost.toDouble() ?? 0),
      electricCostSnapshot: Value(o?.electricCost.toDouble() ?? 0),
      amortizationCostSnapshot: Value(o?.amortizationCost.toDouble() ?? 0),
      laborCostSnapshot: Value(o?.laborCost.toDouble() ?? 0),
      postProcessCostSnapshot: Value(o?.postProcessCost.toDouble() ?? 0),
      baseCostSnapshot: Value(o?.baseCost.toDouble() ?? 0),
      failureCostSnapshot: Value(o?.failureCost.toDouble() ?? 0),
      markupCostSnapshot: Value(o?.markupCost.toDouble() ?? 0),
      profitAmountSnapshot: Value(o?.profitAmount.toDouble() ?? 0),
      minimumChargeAppliedSnapshot: Value(
        input != null &&
            o != null &&
            input.minimumCharge > Decimal.zero &&
            (o.totalFinal - o.discountAmount) < input.minimumCharge
        ? 1
        : 0,
      ),
      effectiveTotalSnapshot: Value(o?.totalFinal.toDouble() ?? 0),
      totalPriceSnapshot: Value(o?.totalPrice.toDouble() ?? 0),
      laborRateSnapshot: rateSnap(input?.laborRate),
      postProcessRateSnapshot: rateSnap(input?.postProcessRate),
      failureRateSnapshot: rateSnap(input?.failureRate),
      minimumChargeSnapshot: rateSnap(input?.minimumCharge),
      markupOnMaterialsSnapshot: rateSnap(input?.markupOnMaterials),
      pieceImageBlob: const Value.absent(),
      // MED-05 (auditoría 2026-10-04): el escalón mayorista se guardaba en
      // `save()` pero NO en el autoguardado — un borrador con N>1 aparecía
      // en lista/Home/Continuar y en el dashboard como unit×N sin descuento.
      // `batchDiscountAmount` es no-nullable en el state (0 = sin escalón),
      // igual que en `save()` → Value('0') es correcto; el percent va null
      // explícito cuando no hay tier (misma semántica que `_insert`).
      batchDiscountPercent: Value(state.batchAppliedPercent?.toString()),
      batchDiscountAmount: Value(state.batchDiscountAmount.toString()),
      // === v17: persistir los 3 overrides per-cotizacion ===
      modelingMode: Value(state.modelingMode),
      modelingValue: Value(
        CalculatorState.parseDecimal(state.modelingValue)?.toDouble() ?? 0,
      ),
      postprocMode: Value(state.postprocMode),
      postprocValue: Value(
        CalculatorState.parseDecimal(state.postprocValue)?.toDouble() ?? 0,
      ),
      extraMode: Value(state.extraCostMode),
      extraValue: Value(
        CalculatorState.parseDecimal(state.extraCostValue)?.toDouble() ?? 0,
      ),
      extraLabel: Value(state.extraCostLabel),
    );
  }

  /// Convierte el `double?` de drift (REAL) al `Decimal?` del dominio.
  static Decimal? _toDecimal(double? v) =>
      v == null ? null : Decimal.parse(v.toString());

  /// Formatea un REAL de drift a texto para un controller, sin notacion
  /// cientifica ni ceros de relleno. `1.0` -> "1", `0.5` -> "0.5".
  static String _hoursText(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  static String _minutesText(double v) => _hoursText(v);

  /// Convierte el texto de un controller de costo a REAL para persistir.
  /// Texto vacio, invalido o con coma decimal -> 0.
  static double _textToDouble(String v) =>
      double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  /// MED-08 fix: null O <= 0 -> [fallback]. `parseDecimal` devuelve Decimal(0)
  /// (no null) para "0", y el `??` de la version anterior no lo capturaba.
  static Decimal _positiveOr(Decimal? v, Decimal fallback) =>
      (v == null || v <= Decimal.zero) ? fallback : v;

  /// Deja el modo en una de las 2 opciones que el switch expone.
  ///
  /// El motor todavia acepta los modos legacy `auto` / `off` (las filas
  /// guardadas antes de quitar el "Auto" los tienen persistidos y deben seguir
  /// dando los mismos numeros en el historial), pero la UI no puede
  /// representarlos: si llegaran aqui se cairian a `fixed`.
  static String _normalizeServiceMode(String mode) =>
      (mode == 'pct' || mode == 'fixed') ? mode : 'fixed';
}

/// True cuando el form tiene output calculado (form valido).
final isValidProvider = Provider<bool>((ref) {
  return ref.watch(calculatorNotifierProvider.select((s) => s.output != null));
});

/// Provider del [CalculatorNotifier]. Standalone (no depende de DB).
final calculatorNotifierProvider =
    NotifierProvider<CalculatorNotifier, CalculatorState>(
      CalculatorNotifier.new,
    );
