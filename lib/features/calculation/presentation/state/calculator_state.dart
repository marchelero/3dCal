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
@immutable
class CalculatorState {
  const CalculatorState({
    required this.mode,
    required this.printHours,
    required this.printerWatts,
    required this.kwhRate,
    required this.profitPct,
    required this.discountPct,
    required this.weight,
    required this.filamentPrice,
    required this.filamentGrams,
    required this.materials,
    required this.output,
  });

  /// Estado inicial con defaults MVP (modo express, sin materiales).
  factory CalculatorState.initial() => const CalculatorState(
        mode: CalculatorMode.express,
        printHours: '',
        printerWatts: '200',
        kwhRate: '0.70',
        profitPct: '200',
        discountPct: '0',
        weight: '',
        filamentPrice: '',
        filamentGrams: '',
        materials: <MaterialRow>[],
        output: null,
      );

  final CalculatorMode mode;

  // === Comunes (ambos modos) ===
  final String printHours;
  final String printerWatts;
  final String kwhRate;
  final String profitPct;
  final String discountPct;

  // === Modo express (single material) ===
  final String weight;
  final String filamentPrice;
  final String filamentGrams;

  // === Modo advanced (multi-material) ===
  final List<MaterialRow> materials;

  // === Computed ===
  final CalculationOutput? output;

  CalculatorState copyWith({
    CalculatorMode? mode,
    String? printHours,
    String? printerWatts,
    String? kwhRate,
    String? profitPct,
    String? discountPct,
    String? weight,
    String? filamentPrice,
    String? filamentGrams,
    List<MaterialRow>? materials,
    CalculationOutput? output,
    bool clearOutput = false,
  }) =>
      CalculatorState(
        mode: mode ?? this.mode,
        printHours: printHours ?? this.printHours,
        printerWatts: printerWatts ?? this.printerWatts,
        kwhRate: kwhRate ?? this.kwhRate,
        profitPct: profitPct ?? this.profitPct,
        discountPct: discountPct ?? this.discountPct,
        weight: weight ?? this.weight,
        filamentPrice: filamentPrice ?? this.filamentPrice,
        filamentGrams: filamentGrams ?? this.filamentGrams,
        materials: materials ?? this.materials,
        output: clearOutput ? null : (output ?? this.output),
      );

  /// True si el form completo es valido y se puede calcular output.
  bool get isValid {
    final commonValid = _parseNonNeg(printHours) != null &&
        _parseNonNeg(printerWatts) != null &&
        _parsePos(kwhRate) != null &&
        _parseNonNeg(profitPct) != null &&
        _parseNonNeg(discountPct) != null;
    if (!commonValid) return false;
    if (mode == CalculatorMode.express) {
      return _parsePos(weight) != null &&
          _parsePos(filamentPrice) != null &&
          _parsePos(filamentGrams) != null;
    }
    // Advanced: al menos 1 material valido.
    return materials.any((m) => m.isValid);
  }

  Decimal? _parsePos(String raw) {
    final d = parseDecimal(raw);
    if (d == null || d <= Decimal.zero) return null;
    return d;
  }

  Decimal? _parseNonNeg(String raw) {
    final d = parseDecimal(raw);
    if (d == null || d < Decimal.zero) return null;
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
        printerWatts == other.printerWatts &&
        kwhRate == other.kwhRate &&
        profitPct == other.profitPct &&
        discountPct == other.discountPct &&
        weight == other.weight &&
        filamentPrice == other.filamentPrice &&
        filamentGrams == other.filamentGrams &&
        _listEq(materials, other.materials) &&
        output == other.output;
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
        printerWatts,
        kwhRate,
        profitPct,
        discountPct,
        weight,
        filamentPrice,
        filamentGrams,
        Object.hashAll(materials),
        output,
      );
}
