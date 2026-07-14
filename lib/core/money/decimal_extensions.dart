/// Extensiones y helpers para trabajar con [Decimal] en tresdcal.
///
/// Regla de oro: **prohibido `double` en motor de calculo**. Toda la aritmetica
/// financiera pasa por `Decimal` del paquete `decimal`. Esta libreria provee
/// extension methods para hacer el uso ergonomico.
library;

import 'package:decimal/decimal.dart';

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
    final normalized = value.replaceAll(',', '.');
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
