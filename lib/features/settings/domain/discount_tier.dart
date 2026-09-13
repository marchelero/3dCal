// ignore_for_file: public_member_api_docs
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

/// Escalón de descuento por cantidad (feature A — Hito 1).
///
/// Un escalón define `(cantidad mínima → % de descuento)` para el descuento
/// mayorista automático. Se aplica el escalón con la mayor `min_qty <= N`.
///
/// **Inmutable**. El porcentaje es SIEMPRE [Decimal]; en la DB se persiste
/// como texto `decimal` en la columna `percent` (TEXT) — regla no negociable.
///
/// **Validación de dominio** (diseño PRD feature A):
/// - `min_qty >= 2` (la cantidad 1 es el flujo actual, nunca descuenta).
/// - `0 < percent <= 100`.
///
/// El id es texto tipo UUID (consistente con PRD v2). [create] genera un UUID
/// v4 fresco. El mapeo a/desde la fila drift vive en
/// `DiscountTiersRepository` (patrón del repo: las entidades de dominio no
/// dependen de drift).
class DiscountTier {
  const DiscountTier({
    required this.id,
    required this.minQty,
    required this.percent,
    required this.sortOrder,
  });

  /// Crea un escalón nuevo con id UUID v4 y `sortOrder = 0`. El repository
  /// re-secuencia los slots automáticamente al guardar (auto-sort), así que
  /// el caller no necesita calcular la posición.
  factory DiscountTier.create({
    required int minQty,
    required Decimal percent,
  }) {
    return DiscountTier(
      id: _uuidV4(),
      minQty: minQty,
      percent: percent,
      sortOrder: 0,
    );
  }

  /// Id texto tipo UUID (RFC 4122 v4).
  final String id;

  /// Cantidad mínima de unidades que dispara el escalón (>= 2).
  final int minQty;

  /// Porcentaje de descuento mayorista (0 < % <= 100).
  final Decimal percent;

  /// Posición en la lista. `sort_order` en DB; el repository lo re-secuencia
  /// (0..n-1) al guardar y al borrar.
  final int sortOrder;

  /// True si [minQty] cumple la regla de negocio (>= 2).
  static bool isValidMinQty(int minQty) => minQty >= 2;

  /// True si [percent] cumple la regla de negocio (0 < % <= 100).
  static bool isValidPercent(Decimal percent) {
    return percent > Decimal.zero && percent <= Decimal.fromInt(100);
  }

  /// True si el escalón completo es válido.
  bool get isValid => isValidMinQty(minQty) && isValidPercent(percent);

  DiscountTier copyWith({
    String? id,
    int? minQty,
    Decimal? percent,
    int? sortOrder,
  }) {
    return DiscountTier(
      id: id ?? this.id,
      minQty: minQty ?? this.minQty,
      percent: percent ?? this.percent,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Genera un UUID v4 válido (RFC 4122) sin dependencias externas.
///
/// Usa [math.Random.secure]. El repo no depende de `package:uuid`; mantener
/// el generador acá evita sumar una dependency solo para una columna de id.
String _uuidV4() {
  final rng = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  // Version 4 (bits 12-15 = 0100) y variant 10xx (bit 7).
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
