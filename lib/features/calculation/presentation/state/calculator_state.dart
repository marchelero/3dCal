// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/calculation_output.dart';

/// Estado del formulario de cotizacion (modo express, single material).
///
/// **Inmutable**. Cada cambio al formulario genera un nuevo state via
/// [copyWith]. El campo [output] se computa lazy en el notifier cuando
/// todos los inputs son validos.
///
/// **Single material**: en Sprint 3 la cotizacion usa 1 filamento a la vez.
/// El modo multi-material (con `AnimatedList`) se hara en un sprint posterior.
@immutable
class CalculatorState {
  /// Crea un estado del calculator.
  ///
  /// Todos los strings son raw (lo que el user escribio en el TextField).
  /// El parsing y validacion se hace via [parseDecimal].
  const CalculatorState({
    required this.weight,
    required this.printHours,
    required this.printerWatts,
    required this.kwhRate,
    required this.profitPct,
    required this.discountPct,
    required this.filamentPrice,
    required this.filamentGrams,
    required this.output,
  });

  /// Estado inicial con defaults MVP.
  ///
  /// Defaults (del PRD / sprint 0):
  /// - `printerWatts = 200` (placeholder comun FDM)
  /// - `kwhRate = 0.70` BOB/kWh (promedio Bolivia)
  /// - `profitPct = 200` (2x markup, regla del 95% lo valida)
  /// - `discountPct = 0` (sin descuento inicial)
  /// - resto vacio (requeridos por el user)
  factory CalculatorState.initial() => const CalculatorState(
        weight: '',
        printHours: '',
        printerWatts: '200',
        kwhRate: '0.70',
        profitPct: '200',
        discountPct: '0',
        filamentPrice: '',
        filamentGrams: '',
        output: null,
      );

  /// Peso de la pieza en gramos. Texto crudo (admite `,` o `.`).
  final String weight;

  /// Tiempo de impresion en horas. Texto crudo.
  final String printHours;

  /// Consumo de la impresora en Watts. Texto crudo.
  final String printerWatts;

  /// Tarifa electrica BOB/kWh. Texto crudo.
  final String kwhRate;

  /// Margen de ganancia base (%). Texto crudo.
  final String profitPct;

  /// Descuento comercial (%). Texto crudo.
  final String discountPct;

  /// Precio de la bobina del filamento seleccionado (BOB). Texto crudo.
  final String filamentPrice;

  /// Gramos por bobina del filamento seleccionado. Texto crudo.
  final String filamentGrams;

  /// Resultado del motor. `null` si el form no es valido o no se lleno.
  final CalculationOutput? output;

  /// Crea una copia con los campos provistos reemplazados.
  CalculatorState copyWith({
    String? weight,
    String? printHours,
    String? printerWatts,
    String? kwhRate,
    String? profitPct,
    String? discountPct,
    String? filamentPrice,
    String? filamentGrams,
    CalculationOutput? output,
    bool clearOutput = false,
  }) {
    return CalculatorState(
      weight: weight ?? this.weight,
      printHours: printHours ?? this.printHours,
      printerWatts: printerWatts ?? this.printerWatts,
      kwhRate: kwhRate ?? this.kwhRate,
      profitPct: profitPct ?? this.profitPct,
      discountPct: discountPct ?? this.discountPct,
      filamentPrice: filamentPrice ?? this.filamentPrice,
      filamentGrams: filamentGrams ?? this.filamentGrams,
      output: clearOutput ? null : (output ?? this.output),
    );
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

  /// Valida que el form este completo y todos los inputs sean >= 0 (los
  /// `weight`, `kwhRate`, `filamentPrice`, `filamentGrams` deben ser > 0).
  bool get isValid {
    final w = parseDecimal(weight);
    final ph = parseDecimal(printHours);
    final pw = parseDecimal(printerWatts);
    final kr = parseDecimal(kwhRate);
    final pp = parseDecimal(profitPct);
    final dp = parseDecimal(discountPct);
    final fp = parseDecimal(filamentPrice);
    final fg = parseDecimal(filamentGrams);
    return w != null &&
        w > Decimal.zero &&
        ph != null &&
        ph >= Decimal.zero &&
        pw != null &&
        pw >= Decimal.zero &&
        kr != null &&
        kr > Decimal.zero &&
        pp != null &&
        pp >= Decimal.zero &&
        dp != null &&
        dp >= Decimal.zero &&
        fp != null &&
        fp > Decimal.zero &&
        fg != null &&
        fg > Decimal.zero;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculatorState &&
        other.weight == weight &&
        other.printHours == printHours &&
        other.printerWatts == printerWatts &&
        other.kwhRate == kwhRate &&
        other.profitPct == profitPct &&
        other.discountPct == discountPct &&
        other.filamentPrice == filamentPrice &&
        other.filamentGrams == filamentGrams &&
        other.output == output;
  }

  @override
  int get hashCode => Object.hash(
        weight,
        printHours,
        printerWatts,
        kwhRate,
        profitPct,
        discountPct,
        filamentPrice,
        filamentGrams,
        output,
      );
}
