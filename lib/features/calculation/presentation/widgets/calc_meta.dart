// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../state/calculator_state.dart' show CalculatorMode, CalculatorState;

/// Computa los strings de meta info (gramos usados + tiempo de impresion)
/// para mostrarlos en [SummaryCard] debajo del precio hero.
///
/// - Express: usa `state.weight` directo.
/// - Advanced: suma `state.materials[].weight`.
/// - Tiempo: combina `printHours` + `printMinutes` en formato "Xh Ym".
///
/// Si todos los valores son 0 retorna nulls (oculta la fila meta).
({String? grams, String? time}) computeMeta(CalculatorState state) {
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
  final h = parseOrZero(state.printHours);
  final m = parseOrZero(state.printMinutes);
  // Para evitar el tipo Rational (resultado de Decimal/Decimal), trabajamos
  // directo en minutos (BigInt) y reconstruimos el string Xh Ym. El
  // formato final es siempre entero, asi que no perdemos precision.
  final totalMinutes = (h * Decimal.fromInt(60) + m).toBigInt();
  String? timeStr;
  if (totalMinutes > BigInt.zero) {
    final hh = totalMinutes ~/ BigInt.from(60);
    final mm = totalMinutes.remainder(BigInt.from(60));
    timeStr = '${hh.toInt()}h ${mm.toInt()}m';
  }

  final gramsStr = gramsDec > Decimal.zero
      ? '${NumberFormat.decimalPattern('es_BO').format(gramsDec.toDouble())} g'
      : null;
  return (grams: gramsStr, time: timeStr);
}
