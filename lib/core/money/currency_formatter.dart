/// Formateo de moneda segun la moneda seleccionada.
///
/// No hace conversion de montos. Solo muestra el simbolo de la moneda
/// seleccionada + el numero formateado con formato es_BO.
///
/// Formato: `$ 1.234,56` o `Bs. 1.234,56`
library;

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'currency.dart';

/// Formatea un [Decimal] como moneda segun la moneda seleccionada.
///
/// Ejemplos:
///   1234.56, USD -> "$ 1.234,56"
///   1234.56, BOB -> "Bs. 1.234,56"
///   0            -> "$ 0,00"
String formatCurrency(Decimal amount, WorldCurrency currency) {
  final formatter = NumberFormat('#,##0.00', 'es_BO');
  return '${currency.symbol} ${formatter.format(amount.toDouble())}';
}

/// Formatea un [Decimal] como numero sin el simbolo de moneda.
///
/// Ejemplo: `1234.56` -> `"1.234,56"`
String formatCurrencyNumber(Decimal amount, WorldCurrency currency) {
  final formatter = NumberFormat('#,##0.00', 'es_BO');
  return formatter.format(amount.toDouble());
}

// ─── Backwards compat (mantener hasta migrar ultimos callers) ───

/// @deprecated Usar [formatCurrency] con WorldCurrency.
String formatBob(Decimal amount) {
  return formatCurrency(amount, WorldCurrency.bob);
}

/// @deprecated Usar [formatCurrencyNumber] con WorldCurrency.
String formatBobNumber(Decimal amount) {
  return formatCurrencyNumber(amount, WorldCurrency.bob);
}

// ─── Funciones independientes de moneda ────────────

/// Formatea un [Decimal] como porcentaje.
///
/// Ejemplos:
///   200.0  -> "200%"
///   12.5   -> "12,5%"
String formatPercentage(Decimal value) {
  final formatted =
      NumberFormat.decimalPattern('es_BO').format(value.toDouble());
  return '$formatted%';
}

/// Formatea horas decimales como `Hh Mm`.
///
/// Ejemplos:
///   2.5   -> "2h 30m"
///   0.25  -> "0h 15m"
///   10.0  -> "10h 0m"
String formatHours(Decimal hours) {
  if (hours < Decimal.zero) {
    return '0h 0m';
  }
  final totalMinutes = (hours * Decimal.fromInt(60)).toBigInt();
  final h = totalMinutes ~/ BigInt.from(60);
  final m = totalMinutes.remainder(BigInt.from(60));
  return '${h.toInt()}h ${m.toInt()}m';
}
