import 'package:decimal/decimal.dart';

import 'material_input.dart';

/// Inputs para el motor de calculo. Inmutable.
///
/// Reglas de validacion:
/// - [materials] puede estar vacio (costo material = 0).
/// - [totalHours] >= 0 (informacional, no afecta formula).
/// - [discountPercentage] >= 0.
///
/// Formula: totalPrice = materialCost - discountAmount
///   materialCost = Σ(weightGrams * pricePerBobbin / gramsPerBobbin)
///   discountAmount = materialCost * (discountPercentage / 100)
class CalculationInput {
  const CalculationInput({
    required this.materials,
    required this.totalHours,
    required this.discountPercentage,
  });

  /// Lista de materiales (puede ser vacia).
  final List<MaterialInput> materials;

  /// Tiempo total de impresion (horas). Solo informacional.
  final Decimal totalHours;

  /// Descuento comercial (%). 0 permitido.
  final Decimal discountPercentage;
}
