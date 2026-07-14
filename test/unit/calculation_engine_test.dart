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
  String printerWatts = '0',
  String discount = '0',
  String profitBase = '200',
  String kwhRate = '0.7',
}) {
  return CalculationInput(
    materials: materials,
    totalHours: DecimalParse.fromString(totalHours),
    printerWatts: DecimalParse.fromString(printerWatts),
    discountPercentage: DecimalParse.fromString(discount),
    profitBasePercentage: DecimalParse.fromString(profitBase),
    kwhRate: DecimalParse.fromString(kwhRate),
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
    test('Express basico: 100g PLA @ 150/1000g, 0h, 0W, 0% descuento', () {
      final out = CalculationEngine.compute(
        _input(materials: [_material()]),
      );

      // materialCost = 100 * 150/1000 = 15.00
      expect(out.materialCost, DecimalParse.fromString('15'));
      // electricCost = 0 (sin tiempo)
      expect(out.electricCost, Decimal.zero);
      // baseCost = 15
      expect(out.baseCost, DecimalParse.fromString('15'));
      // effProfit = 200 - 0*2 = 200
      expect(out.effectiveProfitPercentage, DecimalParse.fromString('200'));
      // profitAmount = 15 * 200/100 = 30
      expect(out.profitAmount, DecimalParse.fromString('30'));
      // totalPrice = 15 + 30 = 45
      expect(out.totalPrice, DecimalParse.fromString('45'));
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
      expect(out.baseCost, DecimalParse.fromString('25'));
      // profitAmount = 25 * 200/100 = 50
      expect(out.profitAmount, DecimalParse.fromString('50'));
      // totalPrice = 75
      expect(out.totalPrice, DecimalParse.fromString('75'));
    });

    test('Con tiempo + electrico: 2.5h, 200W, 0.7 BOB/kWh', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          totalHours: '2.5',
          printerWatts: '200',
        ),
      );

      // materialCost = 15
      expect(out.materialCost, DecimalParse.fromString('15'));
      // electricCost = 2.5 * (200/1000) * 0.7 = 2.5 * 0.2 * 0.7 = 0.35
      expect(out.electricCost, DecimalParse.fromString('0.35'));
      // baseCost = 15.35
      expect(out.baseCost, DecimalParse.fromString('15.35'));
      // effProfit = 200
      // profitAmount = 15.35 * 200/100 = 30.70
      expect(out.profitAmount, DecimalParse.fromString('30.7'));
      // totalPrice = 46.05
      expect(out.totalPrice, DecimalParse.fromString('46.05'));
    });

    test('AC-3: descuento 10% baja total', () {
      // Mismos inputs que test anterior + descuento 10%
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          totalHours: '2.5',
          printerWatts: '200',
          discount: '10',
        ),
      );

      // effProfit = 200 - 10*2 = 180
      expect(out.effectiveProfitPercentage, DecimalParse.fromString('180'));
      // baseCost = 15.35
      expect(out.baseCost, DecimalParse.fromString('15.35'));
      // profitAmount = 15.35 * 180/100 = 27.63
      expect(out.profitAmount, DecimalParse.fromString('27.63'));
      // totalPrice = 42.98
      // NOTA: PRD AC-3 dice "Bs. 43.04" pero la formula exacta da 42.98.
      // Los tests validan la formula matematica, no el numero narrativo.
      expect(out.totalPrice, DecimalParse.fromString('42.98'));
    });

    test('Edge: printerWatts=0 → electricCost=0', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          totalHours: '2.5',
          printerWatts: '0',
        ),
      );

      expect(out.electricCost, Decimal.zero);
      expect(out.baseCost, DecimalParse.fromString('15'));
    });

    test('Edge: totalHours=0 → electricCost=0', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          totalHours: '0',
          printerWatts: '200',
        ),
      );

      expect(out.electricCost, Decimal.zero);
    });

    test('Edge: empty materials → materialCost=0, profit puede ser 0', () {
      final out = CalculationEngine.compute(_input());

      expect(out.materialCost, Decimal.zero);
      expect(out.electricCost, Decimal.zero);
      expect(out.baseCost, Decimal.zero);
      expect(out.profitAmount, Decimal.zero);
      expect(out.totalPrice, Decimal.zero);
    });

    test('Edge: effProfit < 0 clampea profitAmount a 0', () {
      // discount=60 con profitBase=100 → effProfit = 100 - 60*2 = -20
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          discount: '60',
          profitBase: '100',
        ),
      );

      expect(out.effectiveProfitPercentage, DecimalParse.fromString('-20'));
      // profitAmount clampeado a 0 (no se vende a perdida)
      expect(out.profitAmount, Decimal.zero);
      // totalPrice = baseCost (sin profit)
      expect(out.totalPrice, out.baseCost);
    });

    test('Edge: effProfit = 0 exacto', () {
      // discount=100 con profitBase=200 → effProfit = 200 - 100*2 = 0
      final out = CalculationEngine.compute(
        _input(
          materials: [_material()],
          discount: '100',
        ),
      );

      expect(out.effectiveProfitPercentage, Decimal.zero);
      expect(out.profitAmount, Decimal.zero);
      expect(out.totalPrice, out.baseCost);
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
        electricCost: DecimalParse.fromString('2'),
        baseCost: DecimalParse.fromString('3'),
        effectiveProfitPercentage: DecimalParse.fromString('4'),
        profitAmount: DecimalParse.fromString('5'),
        totalPrice: DecimalParse.fromString('6'),
      );
      final out2 = CalculationOutput(
        materialCost: DecimalParse.fromString('1'),
        electricCost: DecimalParse.fromString('2'),
        baseCost: DecimalParse.fromString('3'),
        effectiveProfitPercentage: DecimalParse.fromString('4'),
        profitAmount: DecimalParse.fromString('5'),
        totalPrice: DecimalParse.fromString('6'),
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
