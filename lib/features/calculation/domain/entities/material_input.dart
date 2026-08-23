import 'package:decimal/decimal.dart';

/// Material individual en una cotizacion.
///
/// **Pure Dart, NO Flutter.** Esta clase se usa en el motor de calculo
/// y se testea sin WidgetTester.
class MaterialInput {
  /// Construye un material con sus parametros de calculo. Todos los campos
  /// son requeridos; [weightGrams], [pricePerBobbin] y [gramsPerBobbin] deben
  /// ser > 0.
  ///
  /// BUG-021 fix: assert de debug para valores positivos. En release, el
  /// motor y los guards de display ya saltean valores <= 0.
  MaterialInput({
    required this.label,
    required this.weightGrams,
    required this.pricePerBobbin,
    required this.gramsPerBobbin,
  }) : assert(weightGrams > Decimal.zero, 'weightGrams debe ser > 0'),
       assert(pricePerBobbin > Decimal.zero, 'pricePerBobbin debe ser > 0'),
       assert(gramsPerBobbin > Decimal.zero, 'gramsPerBobbin debe ser > 0');

  /// Etiqueta visible: "PLA Negro", "Genérico", "PETG transparente".
  final String label;

  /// Peso del material en la pieza (gramos). Debe ser > 0.
  final Decimal weightGrams;

  /// Precio de la bobina (BOB). Debe ser > 0.
  final Decimal pricePerBobbin;

  /// Gramos por bobina. Debe ser > 0.
  final Decimal gramsPerBobbin;

  /// Precio por gramo derivado (BOB/g).
  ///
  /// BUG-021 fix: guard defensivo — si gramsPerBobbin <= 0 (solo posible
  /// via construccion no-assert o datos corruptos), retorna 0 en vez de
  /// Infinity.
  Decimal get pricePerGram {
    if (gramsPerBobbin <= Decimal.zero) return Decimal.zero;
    return (pricePerBobbin / gramsPerBobbin).toDecimal(
      scaleOnInfinitePrecision: 12,
    );
  }

  /// Costo de este material (BOB) = weight * pricePerGram.
  Decimal get cost => weightGrams * pricePerGram;
}
