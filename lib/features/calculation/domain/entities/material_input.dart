import 'package:decimal/decimal.dart';

/// Material individual en una cotizacion.
///
/// **Pure Dart, NO Flutter.** Esta clase se usa en el motor de calculo
/// y se testea sin WidgetTester.
class MaterialInput {
  /// Construye un material con sus parametros de calculo. Todos los campos
  /// son requeridos; [weightGrams], [pricePerBobbin] y [gramsPerBobbin] deben
  /// ser > 0 (validado en el motor, no aca).
  const MaterialInput({
    required this.label,
    required this.weightGrams,
    required this.pricePerBobbin,
    required this.gramsPerBobbin,
  });

  /// Etiqueta visible: "PLA Negro", "Genérico", "PETG transparente".
  final String label;

  /// Peso del material en la pieza (gramos). Debe ser > 0.
  final Decimal weightGrams;

  /// Precio de la bobina (BOB). Debe ser > 0.
  final Decimal pricePerBobbin;

  /// Gramos por bobina. Debe ser > 0.
  final Decimal gramsPerBobbin;

  /// Precio por gramo derivado (BOB/g).
  Decimal get pricePerGram => (pricePerBobbin / gramsPerBobbin).toDecimal();

  /// Costo de este material (BOB) = weight * pricePerGram.
  Decimal get cost => weightGrams * pricePerGram;
}
