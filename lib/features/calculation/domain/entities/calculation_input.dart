import 'package:decimal/decimal.dart';

import 'material_input.dart';

/// Inputs para el motor de calculo. Inmutable, validado en constructor.
///
/// Reglas de validacion (asserts en debug, documentadas para caller):
/// - [materials] puede estar vacio (costo material = 0).
/// - [totalHours] >= 0.
/// - [printerWatts] >= 0.
/// - [kwhRate] > 0.
/// - [profitBasePercentage] >= 0.
/// - [discountPercentage] >= 0.
class CalculationInput {
  /// Construye inputs del motor. Ver [kMaxDiscountPercentage] y [kMaxMaterialsPerCalculation]
  /// para limites.
  const CalculationInput({
    required this.materials,
    required this.totalHours,
    required this.printerWatts,
    required this.discountPercentage,
    required this.profitBasePercentage,
    required this.kwhRate,
  });

  /// Lista de materiales (puede ser vacia).
  final List<MaterialInput> materials;

  /// Tiempo total de impresion (horas). 0 permitido.
  final Decimal totalHours;

  /// Consumo promedio de la impresora (Watts). 0 permitido (sin impresora).
  final Decimal printerWatts;

  /// Descuento comercial (%). 0 permitido.
  final Decimal discountPercentage;

  /// Ganancia base global (%). Default MVP: 200.
  final Decimal profitBasePercentage;

  /// Tarifa electrica local (BOB/kWh). Default MVP: 0.70.
  final Decimal kwhRate;
}
