import 'package:decimal/decimal.dart';

import 'entities/calculation_input.dart';
import 'entities/calculation_output.dart';
import 'entities/material_input.dart';

/// Motor de calculo de cotizaciones. **Pure Dart, sin dependencias de Flutter**.
///
/// Formula simplificada:
///
///   materialCost  = Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i])
///   discountAmount = materialCost * (discountPercentage / 100)
///   totalPrice    = materialCost - discountAmount
///
/// **Reglas de borde**:
/// - Si no hay materiales, `materialCost = 0` y `totalPrice = 0`.
/// - Si `discountPercentage = 0`, `discountAmount = 0`.
/// - Si descuento > 100%, `totalPrice` quedaria negativo (caso borde, se
///   preserva para que la UI lo maneje).
///
/// **Precision**: todo en `Decimal`. Prohibido `double` en este archivo.
class CalculationEngine {
  const CalculationEngine._();

  /// Divisor para pasar de % a fraccion.
  static final Decimal _percentToFraction = Decimal.fromInt(100);

  /// Calcula la salida financiera para los [input] dados.
  static CalculationOutput compute(CalculationInput input) {
    final materialCost = _sumMaterialCost(input.materials);

    final discountAmount = input.discountPercentage > Decimal.zero
        ? (materialCost * input.discountPercentage / _percentToFraction)
            .toDecimal()
        : Decimal.zero;

    final totalPrice = materialCost - discountAmount;

    return CalculationOutput(
      materialCost: materialCost,
      discountAmount: discountAmount,
      totalPrice: totalPrice,
    );
  }

  /// Σ(weightGrams[i] * pricePerBobbin[i] / gramsPerBobbin[i]).
  static Decimal _sumMaterialCost(List<MaterialInput> materials) {
    var total = Decimal.zero;
    for (final m in materials) {
      total += m.weightGrams * m.pricePerGram;
    }
    return total;
  }
}
