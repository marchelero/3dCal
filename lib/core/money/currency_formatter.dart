/// Formateo de moneda BOB segun convencion boliviana.
///
/// Formato: `Bs. 1.234,56` (punto como miles, coma como decimal).
library;

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formateador unico para montos BOB.
/// Pattern explicito con 2 decimales forzados.
final NumberFormat _bobFormatter = NumberFormat('#,##0.00', 'es_BO');

/// Formatea un [Decimal] como BOB legible.
///
/// **Convención boliviana**: simbolo "Bs." antes del monto.
///   1234.56  -> "Bs. 1.234,56"
///   0        -> "Bs. 0,00"
///   1000000  -> "Bs. 1.000.000,00"
///
/// Usamos pattern custom en lugar de `NumberFormat.currency` porque intl
/// pone el simbolo DESPUES en locales `es*`. Bolivia usa "Bs. X" antes
/// (convencion de recibos y facturacion local).
String formatBob(Decimal amount) {
  return '$kCurrencySymbol ${_bobFormatter.format(amount.toDouble())}';
}

/// Formatea un [Decimal] como BOB sin el simbolo.
String formatBobNumber(Decimal amount) {
  return _bobFormatter.format(amount.toDouble());
}

/// Formatea un [Decimal] como porcentaje.
///
/// Ejemplos:
///   200.0  -> "200%"
///   12.5   -> "12,5%"
String formatPercentage(Decimal value) {
  final formatted = NumberFormat.decimalPattern('es_BO').format(value.toDouble());
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
