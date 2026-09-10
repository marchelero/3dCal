/// Extensiones y helpers para trabajar con [Decimal] en tresdcal.
///
/// Regla de oro: **prohibido `double` en motor de calculo**. Toda la aritmetica
/// financiera pasa por `Decimal` del paquete `decimal`. Esta libreria provee
/// extension methods para hacer el uso ergonomico.
library;

import 'package:decimal/decimal.dart';

/// Normaliza un string numerico a formato con `.` como separador decimal,
/// quitando separadores de miles cuando corresponde.
///
/// Acepta tanto formato es_BO (`.` miles, `,` decimal) como en-US
/// (`,` miles, `.` decimal):
///   "1.234,56" -> "1234.56"
///   "1234.56"  -> "1234.56"
///   "1234,56"  -> "1234.56"
///   "1,234.56" -> "1234.56"
///
/// Strings sin separadores (p.ej. "1234") se devuelven sin cambios.
String normalizeDecimalString(String value) {
  final dot = value.lastIndexOf('.');
  final comma = value.lastIndexOf(',');
  if (dot >= 0 && comma >= 0) {
    // El ultimo separador es el decimal; el otro es de miles.
    return comma > dot
        ? value.replaceAll('.', '').replaceAll(',', '.') // es_BO
        : value.replaceAll(',', ''); // en-US
  }
  if (comma >= 0) {
    // Solo coma: se interpreta como separador decimal (comportamiento previo).
    return value.replaceAll(',', '.');
  }
  return value;
}

/// Helpers para construir Decimales desde inputs tipicos de formularios.
///
/// Flutter forms devuelven `String` o `num`. Esta clase provee conversiones
/// seguras que lanzan [FormatException] con mensaje claro.
class DecimalParse {
  const DecimalParse._();

  /// Parsea [String] a [Decimal]. Acepta tanto `,` como `.` como decimal.
  static Decimal fromString(String value) {
    if (value.isEmpty) {
      throw const FormatException('DecimalParse: string vacia');
    }
    final normalized = normalizeDecimalString(value);
    return Decimal.parse(normalized);
  }

  /// Parsea [String] a [Decimal?] sin lanzar. Devuelve null si vacio/invalido.
  static Decimal? tryFromString(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return fromString(value);
    } on FormatException {
      return null;
    }
  }

  /// Parsea [num] (int o double) a [Decimal]. Para doubles, pasa por string
  /// para evitar perdida de precision.
  static Decimal fromNum(num value) {
    if (value is int) {
      return Decimal.fromInt(value);
    }
    return Decimal.parse(value.toString());
  }
}
