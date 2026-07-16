// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/calculation_output.dart';

/// Modo del calculator.
enum CalculatorMode {
  /// Single material, campos top-level (weight, filamentPrice, filamentGrams).
  /// Default MVP, back-compat con Sprint 3.
  express,

  /// Multi-material. La lista `materials` es la fuente de verdad; los campos
  /// top-level de filamento se ignoran.
  advanced,
}

/// Fila de material en el calculator (modo advanced).
///
/// Strings raw, parsing en [parseDecimal]. Inmutable.
@immutable
class MaterialRow {
  const MaterialRow({
    this.label = '',
    this.weight = '',
    this.pricePerBobbin = '',
    this.gramsPerBobbin = '',
  });

  final String label;
  final String weight; // gramos de ESTE material en la pieza
  final String pricePerBobbin;
  final String gramsPerBobbin;

  bool get isValid {
    final w = CalculatorState.parseDecimal(weight);
    final p = CalculatorState.parseDecimal(pricePerBobbin);
    final g = CalculatorState.parseDecimal(gramsPerBobbin);
    return w != null && w > Decimal.zero && p != null && p > Decimal.zero &&
        g != null && g > Decimal.zero;
  }

  MaterialRow copyWith({
    String? label,
    String? weight,
    String? pricePerBobbin,
    String? gramsPerBobbin,
  }) =>
      MaterialRow(
        label: label ?? this.label,
        weight: weight ?? this.weight,
        pricePerBobbin: pricePerBobbin ?? this.pricePerBobbin,
        gramsPerBobbin: gramsPerBobbin ?? this.gramsPerBobbin,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialRow &&
          other.label == label &&
          other.weight == weight &&
          other.pricePerBobbin == pricePerBobbin &&
          other.gramsPerBobbin == gramsPerBobbin);

  @override
  int get hashCode =>
      Object.hash(label, weight, pricePerBobbin, gramsPerBobbin);
}

/// Estado del formulario de cotizacion.
///
/// **Inmutable**. Cada cambio genera un nuevo state via [copyWith].
/// El campo [output] se computa lazy en el notifier cuando el form es valido.
///
/// **Modos**:
/// - [CalculatorMode.express]: single material, usa `weight/filamentPrice/filamentGrams`.
/// - [CalculatorMode.advanced]: multi-material, usa `materials` (lista).
///
/// Formula: totalPrice = materialCost - discountAmount
///   Sin electricidad, sin profit. Solo costo de materiales - descuento.
@immutable
class CalculatorState {
  const CalculatorState({
    required this.mode,
    required this.printHours,
    required this.printMinutes,
    required this.discountPct,
    required this.weight,
    required this.filamentPrice,
    required this.filamentGrams,
    required this.label,
    required this.materials,
    required this.output,
    this.showDetail = false,
    this.detailElectricCost,
    this.detailBaseCost,
    this.detailProfitAmount,
    this.detailTotalFinal,
    this.detailDiscountPct,
    this.computeVersion = 0,
  });

  /// Estado inicial (modo express, sin materiales).
  factory CalculatorState.initial() => const CalculatorState(
        mode: CalculatorMode.express,
        printHours: '',
        printMinutes: '',
        discountPct: '0',
        weight: '',
        filamentPrice: '',
        filamentGrams: '',
        label: '',
        materials: <MaterialRow>[],
        output: null,
      );

  final CalculatorMode mode;

  // === Comunes (ambos modos) ===
  /// Horas de impresion (informacional).
  final String printHours;

  /// Minutos de impresion (informacional, 0-59).
  final String printMinutes;

  /// Descuento comercial (%).
  final String discountPct;

  /// Etiqueta opcional de la cotizacion (ej: "Soporte pared").
  final String label;

  // === Modo express (single material) ===
  final String weight;
  final String filamentPrice;
  final String filamentGrams;

  // === Modo advanced (multi-material) ===
  final List<MaterialRow> materials;

  // === Computed ===
  final CalculationOutput? output;

  // === Detail (ojito toggle) ===
  final bool showDetail;
  final Decimal? detailElectricCost;
  final Decimal? detailBaseCost;
  final Decimal? detailProfitAmount;
  final Decimal? detailTotalFinal;

  /// Porcentaje de descuento real aplicado (el ingresado ×2).
  final Decimal? detailDiscountPct;

  /// Numero de version que incrementa en cada recomputo.
  /// Usado por la UI para animar "calculando..." cuando cambia el output.
  final int computeVersion;

  CalculatorState copyWith({
    CalculatorMode? mode,
    String? printHours,
    String? printMinutes,
    String? discountPct,
    String? weight,
    String? filamentPrice,
    String? filamentGrams,
    String? label,
    List<MaterialRow>? materials,
    CalculationOutput? output,
    bool clearOutput = false,
    bool? showDetail,
    Decimal? detailElectricCost,
    Decimal? detailBaseCost,
    Decimal? detailProfitAmount,
    Decimal? detailTotalFinal,
    Decimal? detailDiscountPct,
    bool clearDetail = false,
    int? computeVersion,
  }) =>
      CalculatorState(
        mode: mode ?? this.mode,
        printHours: printHours ?? this.printHours,
        printMinutes: printMinutes ?? this.printMinutes,
        discountPct: discountPct ?? this.discountPct,
        weight: weight ?? this.weight,
        filamentPrice: filamentPrice ?? this.filamentPrice,
        filamentGrams: filamentGrams ?? this.filamentGrams,
        label: label ?? this.label,
        materials: materials ?? this.materials,
        output: clearOutput ? null : (output ?? this.output),
        showDetail: showDetail ?? this.showDetail,
        detailElectricCost: clearDetail
            ? null
            : (detailElectricCost ?? this.detailElectricCost),
        detailBaseCost:
            clearDetail ? null : (detailBaseCost ?? this.detailBaseCost),
        detailProfitAmount:
            clearDetail ? null : (detailProfitAmount ?? this.detailProfitAmount),
        detailTotalFinal:
            clearDetail ? null : (detailTotalFinal ?? this.detailTotalFinal),
        detailDiscountPct:
            clearDetail ? null : (detailDiscountPct ?? this.detailDiscountPct),
        computeVersion: computeVersion ?? this.computeVersion,
      );

  /// True si el form completo es valido y se puede calcular output.
  bool get isValid {
    final hasTime = _parsePos(printHours) != null ||
        _parsePos(printMinutes) != null;
    if (mode == CalculatorMode.express) {
      return _parsePos(weight) != null &&
          _parsePos(filamentPrice) != null &&
          hasTime;
      // filamentGrams optional — defaults to 1000 en notifier.
    }
    // Advanced: al menos 1 material valido + time requerido.
    return materials.any((m) => m.isValid) && hasTime;
  }

  /// Lista de campos requeridos que faltan (en orden del formulario, top-down).
  /// Usado por la UI para hint dinamico: "Completa X, Y y Z para ver la cotizacion".
  /// Lista vacia cuando [isValid] es true.
  ///
  /// Retorna keys (weight/price/time/material), no strings resueltos.
  /// Orden:
  ///   - express: weight, price, time (mismo orden visual en el form).
  ///   - advanced: material, time.
  List<String> get missingRequiredFields {
    if (isValid) return const <String>[];
    final missing = <String>[];
    final hasTime = _parsePos(printHours) != null ||
        _parsePos(printMinutes) != null;
    if (mode == CalculatorMode.express) {
      if (_parsePos(weight) == null) missing.add('weight');
      if (_parsePos(filamentPrice) == null) missing.add('price');
      if (!hasTime) missing.add('time');
    } else {
      if (!materials.any((m) => m.isValid)) missing.add('material');
      if (!hasTime) missing.add('time');
    }
    return missing;
  }

  /// Horas totales como Decimal (printHours + printMinutes/60).
  /// Retorna null si printHours no es parseable.
  Decimal? get totalHoursDecimal {
    final h = parseDecimal(printHours);
    final m = parseDecimal(printMinutes);
    if (h == null) return null;
    if (m == null || m <= Decimal.zero) return h;
    return h + (m / Decimal.fromInt(60)).toDecimal();
  }

  Decimal? _parsePos(String raw) {
    final d = parseDecimal(raw);
    if (d == null || d <= Decimal.zero) return null;
    return d;
  }

  /// Parsea un string como [Decimal]. Acepta `.` o `,` como separador decimal.
  /// Retorna `null` si vacio, whitespace, o no parseable.
  static Decimal? parseDecimal(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    try {
      return Decimal.parse(cleaned);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CalculatorState) return false;
    return mode == other.mode &&
        printHours == other.printHours &&
        printMinutes == other.printMinutes &&
        discountPct == other.discountPct &&
        label == other.label &&
        weight == other.weight &&
        filamentPrice == other.filamentPrice &&
        filamentGrams == other.filamentGrams &&
        _listEq(materials, other.materials) &&
        output == other.output &&
        showDetail == other.showDetail &&
        detailElectricCost == other.detailElectricCost &&
        detailBaseCost == other.detailBaseCost &&
        detailProfitAmount == other.detailProfitAmount &&
        detailTotalFinal == other.detailTotalFinal &&
        detailDiscountPct == other.detailDiscountPct &&
        computeVersion == other.computeVersion;
  }

  static bool _listEq(List<MaterialRow> a, List<MaterialRow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        printHours,
        printMinutes,
        discountPct,
        label,
        weight,
        filamentPrice,
        filamentGrams,
        Object.hashAll(materials),
        output,
        showDetail,
        detailElectricCost,
        detailBaseCost,
        detailProfitAmount,
        detailTotalFinal,
        detailDiscountPct,
        computeVersion,
      );
}
