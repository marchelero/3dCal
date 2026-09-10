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
  return '${currency.symbol} ${formatCurrencyNumber(amount)}';
}

/// Formatea un [Decimal] como numero sin el simbolo de moneda.
///
/// Ejemplo: `1234.56` -> `"1.234,56"`
///
/// El formato numerico no depende de la moneda (siempre es_BO); el simbolo
/// lo agrega [formatCurrency].
String formatCurrencyNumber(Decimal amount) {
  final formatter = NumberFormat('#,##0.00', 'es_BO');
  return formatter.format(_toFormattableDouble(amount));
}

/// Convierte [amount] a `double` para [NumberFormat.format].
///
/// `intl` solo acepta `num` (internamente opera con `double`), asi que este es
/// el UNICO punto del pipeline monetario que toca `double`. Para no perder
/// precision, primero se redondea a centavos con aritmetica [Decimal] exacta:
/// el `double` resultante es exacto mientras los centavos quepan en 2^53.
double _toFormattableDouble(Decimal amount, {int scale = 2}) =>
    amount.round(scale: scale).toDouble();

// ─── Backwards compat (mantener hasta migrar ultimos callers) ───

/// @deprecated Usar [formatCurrency] con WorldCurrency.
String formatBob(Decimal amount) {
  return formatCurrency(amount, WorldCurrency.bob);
}

/// @deprecated Usar [formatCurrencyNumber] sin simbolo.
String formatBobNumber(Decimal amount) {
  return formatCurrencyNumber(amount);
}

// ─── Funciones independientes de moneda ────────────

/// Formatea un [Decimal] como porcentaje.
///
/// Ejemplos:
///   200.0  -> "200%"
///   12.5   -> "12,5%"
String formatPercentage(Decimal value) {
  final formatted = NumberFormat.decimalPattern(
    'es_BO',
  ).format(_toFormattableDouble(value, scale: 3));
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
