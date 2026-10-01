// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../state/calculator_state.dart' show CalculatorMode, CalculatorState;

/// Resultado de computeMeta con desglose por material.
class MetaResult {
  const MetaResult({this.grams, this.time, this.materialBreakdown = const []});

  /// Total de gramos (string formateado).
  final String? grams;

  /// Tiempo total (string "Xh Ym").
  final String? time;

  /// Desglose por material: (label, weightGrams, timeStr).
  final List<MaterialMetaItem> materialBreakdown;
}

class MaterialMetaItem {
  const MaterialMetaItem({
    required this.label,
    required this.weightGrams,
    this.timeStr,
  });
  final String label;
  final String weightGrams;
  final String? timeStr;
}

/// Computa los strings de meta info (gramos usados + tiempo de impresion)
/// para mostrarlos en [SummaryCard] debajo del precio hero.
///
/// - Express: usa `state.weight` directo.
/// - Advanced: suma `state.materials[].weight`.
/// - Tiempo: si algún material tiene `useOwnTime`, suma los tiempos
///   individuales; si no, usa el tiempo global.
///
/// Retorna [MetaResult] con desglose por material.
MetaResult computeMeta(CalculatorState state) {
  Decimal parseOrZero(String s) =>
      Decimal.tryParse(s.replaceAll(',', '.')) ?? Decimal.zero;

  final Decimal gramsDec;
  if (state.mode == CalculatorMode.express) {
    gramsDec = parseOrZero(state.weight);
  } else {
    gramsDec = state.materials.fold(
      Decimal.zero,
      (sum, m) => sum + parseOrZero(m.weight),
    );
  }

  // Tiempo: verificar si algún material tiene tiempo propio.
  final hasOwnTime = state.materials.any((m) => m.useOwnTime);

  var totalMinutesAcc = BigInt.zero;
  final breakdown = <MaterialMetaItem>[];

  if (hasOwnTime && state.mode == CalculatorMode.advanced) {
    // Sumar tiempos individuales de materiales con useOwnTime.
    for (final m in state.materials) {
      final w = parseOrZero(m.weight);
      String? timeStr;
      if (m.useOwnTime) {
        final mh = parseOrZero(m.materialHours);
        final mm = parseOrZero(m.materialMinutes);
        final matMinutes = (mh * Decimal.fromInt(60) + mm).toBigInt();
        totalMinutesAcc += matMinutes;
        if (matMinutes > BigInt.zero) {
          final hh = matMinutes ~/ BigInt.from(60);
          final mm2 = matMinutes.remainder(BigInt.from(60));
          timeStr = '${hh.toInt()}h ${mm2.toInt()}m';
        }
      }
      breakdown.add(
        MaterialMetaItem(
          label: m.label.isNotEmpty ? m.label : 'Material',
          weightGrams: w > Decimal.zero
              ? '${NumberFormat.decimalPattern('es_BO').format(w.toDouble())} g'
              : '0 g',
          timeStr: timeStr,
        ),
      );
    }
  } else {
    // Tiempo global.
    final h = parseOrZero(state.printHours);
    final m = parseOrZero(state.printMinutes);
    totalMinutesAcc = (h * Decimal.fromInt(60) + m).toBigInt();
    for (final mat in state.materials) {
      final w = parseOrZero(mat.weight);
      breakdown.add(
        MaterialMetaItem(
          label: mat.label.isNotEmpty ? mat.label : 'Material',
          weightGrams: w > Decimal.zero
              ? '${NumberFormat.decimalPattern('es_BO').format(w.toDouble())} g'
              : '0 g',
        ),
      );
    }
  }

  // Formatear tiempo total.
  String? timeStr;
  if (totalMinutesAcc > BigInt.zero) {
    final hh = totalMinutesAcc ~/ BigInt.from(60);
    final mm = totalMinutesAcc.remainder(BigInt.from(60));
    timeStr = '${hh.toInt()}h ${mm.toInt()}m';
  }

  final gramsStr = gramsDec > Decimal.zero
      ? '${NumberFormat.decimalPattern('es_BO').format(gramsDec.toDouble())} g'
      : null;

  return MetaResult(
    grams: gramsStr,
    time: timeStr,
    materialBreakdown: breakdown,
  );
}
