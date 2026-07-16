import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/money/currency_formatter.dart';
import 'package:tresdcal/core/money/decimal_extensions.dart';
import 'package:tresdcal/features/calculation/domain/calculation_engine.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_input.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';

/// Helper para construir un CalculationInput con defaults sensatos.
CalculationInput _input({
  List<MaterialInput> materials = const [],
  String totalHours = '0',
  String discount = '0',
}) {
  return CalculationInput(
    materials: materials,
    totalHours: DecimalParse.fromString(totalHours),
    discountPercentage: DecimalParse.fromString(discount),
  );
}

MaterialInput _material({
  String label = 'PLA',
  String weight = '100',
  String pricePerBobbin = '150',
  String gramsPerBobbin = '1000',
}) {
  return MaterialInput(
    label: label,
    weightGrams: DecimalParse.fromString(weight),
    pricePerBobbin: DecimalParse.fromString(pricePerBobbin),
    gramsPerBobbin: DecimalParse.fromString(gramsPerBobbin),
  );
}

void main() {
  group('CalculationEngine.compute', () {
    test('Express basico: 100g PLA @ 150/1000g, 0% descuento', () {
      final out = CalculationEngine.compute(
        _input(materials: [_material()]),
      );

      // materialCost = 100 * 150/1000 = 15.00
      expect(out.materialCost, DecimalParse.fromString('15'));
      // discountAmount = 0 (sin descuento)
      expect(out.discountAmount, Decimal.zero);
      // totalPrice = 15
      expect(out.totalPrice, DecimalParse.fromString('15'));
    });

    test('Multi-material: 2 filamentos suman costos', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [
            _material(label: 'PLA Negro', weight: '100', pricePerBobbin: '150'),
            _material(label: 'PETG', weight: '50', pricePerBobbin: '200'),
          ],
        ),
      );

      // materialCost = 100*150/1000 + 50*200/1000 = 15 + 10 = 25
      expect(out.materialCost, DecimalParse.fromString('25'));
      // discountAmount = 0
      expect(out.discountAmount, Decimal.zero);
      // totalPrice = 25
      expect(out.totalPrice, DecimalParse.fromString('25'));
    });

    test('Con descuento 10%: totalPrice = materialCost - discountAmount', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          discount: '10',
        ),
      );

      // materialCost = 15
      expect(out.materialCost, DecimalParse.fromString('15'));
      // discountAmount = 15 * 10/100 = 1.5
      expect(out.discountAmount, DecimalParse.fromString('1.5'));
      // totalPrice = 15 - 1.5 = 13.5
      expect(out.totalPrice, DecimalParse.fromString('13.5'));
    });

    test('Edge: empty materials → materialCost=0, totalPrice=0', () {
      final out = CalculationEngine.compute(_input());

      expect(out.materialCost, Decimal.zero);
      expect(out.discountAmount, Decimal.zero);
      expect(out.totalPrice, Decimal.zero);
    });

    test('Edge: descuento 100% → totalPrice=0', () {
      final out = CalculationEngine.compute(
        _input(materials: [_material()], discount: '100'),
      );

      expect(out.materialCost, DecimalParse.fromString('15'));
      expect(out.discountAmount, DecimalParse.fromString('15'));
      expect(out.totalPrice, Decimal.zero);
    });

    test('Edge: descuento > 100% → totalPrice negativo (preservado)', () {
      final out = CalculationEngine.compute(
        _input(materials: [_material()], discount: '200'),
      );

      expect(out.materialCost, DecimalParse.fromString('15'));
      expect(out.discountAmount, DecimalParse.fromString('30'));
      expect(out.totalPrice, DecimalParse.fromString('-15'));
    });

    test('Precision: 0.1 + 0.2 != 0.30000000000000004', () {
      // Test del bug clasico de double. Aqui no hay double, asi que:
      final a = DecimalParse.fromString('0.1');
      final b = DecimalParse.fromString('0.2');
      final c = a + b;
      expect(c, DecimalParse.fromString('0.3'));
      expect(c.toString(), '0.3'); // Exact representation
    });

    test('Precision: calculo largo no acumula error de double', () {
      // 1000 iteraciones de 0.1 + 0.1 deberian dar 200 exacto
      var sum = Decimal.zero;
      for (var i = 0; i < 1000; i++) {
        sum += DecimalParse.fromString('0.1');
        sum += DecimalParse.fromString('0.1');
      }
      expect(sum, DecimalParse.fromString('200'));
    });

    test('Inmutabilidad: CalculationOutput es value object', () {
      final out1 = CalculationOutput(
        materialCost: DecimalParse.fromString('1'),
        discountAmount: DecimalParse.fromString('2'),
        totalPrice: DecimalParse.fromString('3'),
      );
      final out2 = CalculationOutput(
        materialCost: DecimalParse.fromString('1'),
        discountAmount: DecimalParse.fromString('2'),
        totalPrice: DecimalParse.fromString('3'),
      );
      expect(out1, out2);
      expect(out1.hashCode, out2.hashCode);
    });

    test('MaterialInput.pricePerGram = price/grams', () {
      final m = _material(pricePerBobbin: '150', gramsPerBobbin: '1000');
      expect(m.pricePerGram, DecimalParse.fromString('0.15'));
    });

    test('MaterialInput.cost = weight * pricePerGram', () {
      final m = _material(weight: '200', pricePerBobbin: '150', gramsPerBobbin: '1000');
      // 200 * 0.15 = 30
      expect(m.cost, DecimalParse.fromString('30'));
    });
  });

  group('Currency formatter (es_BO)', () {
    test('formatBob Bs. 1.234,56', () {
      expect(formatBob(DecimalParse.fromString('1234.56')), 'Bs. 1.234,56');
    });

    test('formatBob Bs. 0,00', () {
      expect(formatBob(Decimal.zero), 'Bs. 0,00');
    });

    test('formatBob millones', () {
      expect(formatBob(DecimalParse.fromString('1000000')), 'Bs. 1.000.000,00');
    });

    test('formatBobNumber sin simbolo', () {
      expect(formatBobNumber(DecimalParse.fromString('1234.56')), '1.234,56');
    });

    test('formatBobNumber Bs. 0,00 sin simbolo', () {
      expect(formatBobNumber(Decimal.zero), '0,00');
    });

    test('formatPercentage 200%', () {
      expect(formatPercentage(DecimalParse.fromString('200')), '200%');
    });

    test('formatPercentage decimal', () {
      expect(formatPercentage(DecimalParse.fromString('12.5')), '12,5%');
    });

    test('formatHours 2h 30m', () {
      expect(formatHours(DecimalParse.fromString('2.5')), '2h 30m');
    });

    test('formatHours 0h 15m', () {
      expect(formatHours(DecimalParse.fromString('0.25')), '0h 15m');
    });

    test('formatHours 10h 0m', () {
      expect(formatHours(DecimalParse.fromString('10')), '10h 0m');
    });

    test('formatHours negativo → 0h 0m', () {
      expect(formatHours(DecimalParse.fromString('-1')), '0h 0m');
    });
  });

  group('Constants', () {
    test('kDefaultKwhRate es BOB/kWh residencial Bolivia', () {
      expect(kDefaultKwhRate, inInclusiveRange(0.6, 0.8));
    });

    test('kDefaultProfitBasePercentage es 200%', () {
      expect(kDefaultProfitBasePercentage, 200);
    });

    test('kMaxMaterialsPerCalculation = 10', () {
      expect(kMaxMaterialsPerCalculation, 10);
    });

    test('kMaxDiscountPercentage <= 50%', () {
      expect(kMaxDiscountPercentage, lessThanOrEqualTo(50));
    });
  });
}
