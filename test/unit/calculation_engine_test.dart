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
  String? amortizationPerHour,
  String minimumCharge = '0',
}) {
  return CalculationInput(
    materials: materials,
    totalHours: DecimalParse.fromString(totalHours),
    discountPercentage: DecimalParse.fromString(discount),
    printerWatts: 0,
    kwhRate: Decimal.zero,
    profitBase: Decimal.zero,
    laborRate: Decimal.zero,
    postProcessRate: Decimal.zero,
    failureRate: Decimal.zero,
    markupOnMaterials: Decimal.zero,
    amortizationPerHour: amortizationPerHour == null
        ? null
        : DecimalParse.fromString(amortizationPerHour),
    minimumCharge: DecimalParse.fromString(minimumCharge),
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
      final out = CalculationEngine.compute(_input(materials: [_material()]));

      // materialCost = 100 * 150/1000 = 15.00
      expect(out.materialCost, DecimalParse.fromString('15'));
      // discountAmount = 0 (sin descuento)
      expect(out.discountAmount, Decimal.zero);
      // totalPrice = 15
      expect(out.totalPrice, DecimalParse.fromString('15'));
    });

    test(
      'ratio price/grams no-terminante (100/300) no lanza (bug latente toDecimal)',
      () {
        // 100/300 = 0.3333... → Rational.toDecimal() sin
        // scaleOnInfinitePrecision lanzaba AssertionError congelando el output.
        final out = CalculationEngine.compute(
          _input(
            materials: [
              _material(
                weight: '300',
                pricePerBobbin: '100',
                gramsPerBobbin: '300',
              ),
            ],
          ),
        );
        // materialCost = 300g * (100 BOB / 300g) = 100.00
        expect(out.materialCost.toDouble(), closeTo(100.0, 0.001));
        expect(out.totalPrice, out.materialCost);
      },
    );

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
        _input(materials: [_material()], discount: '10'),
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
      final out1 = CalculationOutput.simple(
        materialCost: DecimalParse.fromString('1'),
        discountAmount: DecimalParse.fromString('2'),
        totalPrice: DecimalParse.fromString('3'),
      );
      final out2 = CalculationOutput.simple(
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
      final m = _material(
        weight: '200',
        pricePerBobbin: '150',
        gramsPerBobbin: '1000',
      );
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
    test('kDefaultKwhRate es 0 (vacio, el usuario la define)', () {
      expect(kDefaultKwhRate, 0);
    });

    test('kDefaultProfitBasePercentage es 0 (vacio, el usuario la define)', () {
      expect(kDefaultProfitBasePercentage, 0);
    });

    test('kMaxMaterialsPerCalculation = 10', () {
      expect(kMaxMaterialsPerCalculation, 10);
    });

    test('kMaxDiscountPercentage = 100%', () {
      expect(kMaxDiscountPercentage, 100);
    });

    test(
      'F1 labor rate: 1h + 2 Bs/h labor aumenta total en 2 (sin profit)',
      () {
        final out = CalculationEngine.compute(
          CalculationInput(
            materials: [
              _material(
                weight: '23',
                pricePerBobbin: '200',
                gramsPerBobbin: '1000',
              ),
            ],
            totalHours: Decimal.one,
            discountPercentage: Decimal.zero,
            printerWatts: 0,
            kwhRate: Decimal.zero,
            profitBase: Decimal.zero,
            laborRate: DecimalParse.fromString('2'),
            postProcessRate: Decimal.zero,
            failureRate: Decimal.zero,
            markupOnMaterials: Decimal.zero,
          ),
        );
        // materialCost = 23 * 200/1000 = 4.60
        expect(out.materialCost, DecimalParse.fromString('4.6'));
        // laborCost = 1h * 2 Bs/h = 2.00
        expect(out.laborCost, DecimalParse.fromString('2'));
        // baseCost = 4.60 + 0 (electric) + 2.00 (labor) + 0 (post) = 6.60
        expect(out.baseCost, DecimalParse.fromString('6.6'));
        // profit = 0 → totalFinal = 6.60
        expect(out.totalFinal, DecimalParse.fromString('6.6'));
        // totalPrice = 6.60 - 0 descuento = 6.60
        expect(out.totalPrice, DecimalParse.fromString('6.6'));
      },
    );

    test('F1 labor rate: 1h + 2 Bs/h + 200% profit', () {
      final out = CalculationEngine.compute(
        CalculationInput(
          materials: [
            _material(
              weight: '23',
              pricePerBobbin: '200',
              gramsPerBobbin: '1000',
            ),
          ],
          totalHours: Decimal.one,
          discountPercentage: Decimal.zero,
          printerWatts: 0,
          kwhRate: Decimal.zero,
          profitBase: Decimal.fromInt(200),
          laborRate: DecimalParse.fromString('2'),
          postProcessRate: Decimal.zero,
          failureRate: Decimal.zero,
          markupOnMaterials: Decimal.zero,
        ),
      );
      // materialCost = 4.60, laborCost = 2.00, baseCost = 6.60
      // profit = 6.60 * 200/100 = 13.20
      expect(out.profitAmount, DecimalParse.fromString('13.2'));
      // totalFinal = 6.60 + 13.20 = 19.80
      expect(out.totalFinal, DecimalParse.fromString('19.8'));
      expect(out.totalPrice, DecimalParse.fromString('19.8'));
    });
  });

  group('F5 amortizacion de impresora', () {
    test('AC1: helper costo/vida util + linea en desglose y total', () {
      // costo_hora = 3500 / 4000 = 0.875 (escala 6 interna).
      final perHour = CalculationEngine.amortizationPerHour(
        purchaseCost: Decimal.fromInt(3500),
        usefulLifeHours: 4000,
      );
      expect(perHour, DecimalParse.fromString('0.875'));

      // 2h de impresion → amortizacion = 0.875 * 2 = 1.75.
      final out = CalculationEngine.compute(
        _input(
          materials: [_material(weight: '100', pricePerBobbin: '120')],
          totalHours: '2',
          amortizationPerHour: '0.875',
        ),
      );
      // materialCost = 100 * 120/1000 = 12
      expect(out.materialCost, DecimalParse.fromString('12'));
      expect(out.amortizationCost, DecimalParse.fromString('1.75'));
      // baseCost = 12 + 0 + 1.75 + 0 + 0 = 13.75
      expect(out.baseCost, DecimalParse.fromString('13.75'));
      // totalPrice = baseCost (profit 0, sin descuento) = 13.75
      expect(out.totalPrice, DecimalParse.fromString('13.75'));
    });

    test('AC2: sin amortizationPerHour la linea es 0 y el total no cambia', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material(weight: '100', pricePerBobbin: '120')],
          totalHours: '2',
        ),
      );
      expect(out.amortizationCost, Decimal.zero);
      expect(out.baseCost, DecimalParse.fromString('12'));
      expect(out.totalPrice, DecimalParse.fromString('12'));
    });

    test(
      'AC3: vida util 0 → helper null (sin division por cero, sin linea)',
      () {
        final perHour = CalculationEngine.amortizationPerHour(
          purchaseCost: Decimal.fromInt(3500),
          usefulLifeHours: 0,
        );
        expect(perHour, isNull);

        final out = CalculationEngine.compute(
          _input(materials: [_material()], totalHours: '2'),
        );
        expect(out.amortizationCost, Decimal.zero);
        expect(out.baseCost, out.materialCost);
      },
    );

    test('costo <= 0 → null (impresora sin precio de compra)', () {
      final perHour = CalculationEngine.amortizationPerHour(
        purchaseCost: Decimal.zero,
        usefulLifeHours: 4000,
      );
      expect(perHour, isNull);
    });

    test('la amortizacion fluye por profit% (esta en baseCost)', () {
      final out = CalculationEngine.compute(
        CalculationInput(
          materials: [_material(weight: '100', pricePerBobbin: '120')],
          totalHours: Decimal.fromInt(2),
          discountPercentage: Decimal.zero,
          printerWatts: 0,
          kwhRate: Decimal.zero,
          profitBase: Decimal.fromInt(200),
          laborRate: Decimal.zero,
          postProcessRate: Decimal.zero,
          failureRate: Decimal.zero,
          markupOnMaterials: Decimal.zero,
          amortizationPerHour: DecimalParse.fromString('0.875'),
        ),
      );
      // baseCost = 12 + 1.75 = 13.75; profit 200% = 27.5; total = 41.25
      expect(out.amortizationCost, DecimalParse.fromString('1.75'));
      expect(out.profitAmount, DecimalParse.fromString('27.5'));
      expect(out.totalPrice, DecimalParse.fromString('41.25'));
    });
  });

  group('Cargo minimo (minimumCharge)', () {
    test('total 50 < minimumCharge 80 → totalPrice sube a 80', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material(weight: '100', pricePerBobbin: '500')],
          minimumCharge: '80',
        ),
      );
      // materialCost = 100 * 500/1000 = 50
      expect(out.materialCost, DecimalParse.fromString('50'));
      expect(out.totalPrice, DecimalParse.fromString('80'));
    });

    test('total 100 >= minimumCharge 80 → totalPrice sin cambio', () {
      final out = CalculationEngine.compute(
        _input(
          materials: [_material(weight: '100', pricePerBobbin: '1000')],
          minimumCharge: '80',
        ),
      );
      // materialCost = 100 * 1000/1000 = 100
      expect(out.totalPrice, DecimalParse.fromString('100'));
    });

    test('minimumCharge 0 → sin efecto', () {
      final out = CalculationEngine.compute(
        _input(materials: [_material()], minimumCharge: '0'),
      );
      expect(out.totalPrice, DecimalParse.fromString('15'));
    });

    test('el piso se aplica DESPUES del descuento', () {
      // totalFinal = 60, descuento 10% = 6 → 54 < 80 → piso 80.
      final out = CalculationEngine.compute(
        _input(
          materials: [_material(weight: '100', pricePerBobbin: '600')],
          discount: '10',
          minimumCharge: '80',
        ),
      );
      expect(out.discountAmount, DecimalParse.fromString('6'));
      expect(out.totalPrice, DecimalParse.fromString('80'));
    });
  });

  group('v17: 3 campos de servicio con modo % / fijo', () {
    /// v17 inputs en su forma optima.
    CalculationInput v17Input({
      String totalHours = '0',
      String laborMode = 'auto',
      String laborPct = '0',
      String laborFixed = '0',
      String postprocMode = 'auto',
      String postprocPct = '0',
      String postprocFixed = '0',
      String extraMode = 'off',
      String extraPct = '0',
      String extraFixed = '0',
      String laborRate = '0',
      String postProcessRate = '0',
      String amortizationPerHour = '0',
    }) {
      return CalculationInput(
        materials: [_material()],
        totalHours: DecimalParse.fromString(totalHours),
        discountPercentage: Decimal.zero,
        printerWatts: 0,
        kwhRate: Decimal.zero,
        profitBase: Decimal.zero,
        laborRate: DecimalParse.fromString(laborRate),
        postProcessRate: DecimalParse.fromString(postProcessRate),
        failureRate: Decimal.zero,
        markupOnMaterials: Decimal.zero,
        amortizationPerHour: DecimalParse.fromString(amortizationPerHour),
        modelingMode: ServiceCostMode.parse(laborMode),
        modelingPct: DecimalParse.fromString(laborPct),
        modelingFixed: DecimalParse.fromString(laborFixed),
        postprocMode: ServiceCostMode.parse(postprocMode),
        postprocPct: DecimalParse.fromString(postprocPct),
        postprocFixed: DecimalParse.fromString(postprocFixed),
        extraCostMode: ServiceCostMode.parse(extraMode),
        extraCostPct: DecimalParse.fromString(extraPct),
        extraCostFixed: DecimalParse.fromString(extraFixed),
      );
    }

    test(
      'equivalencia legacy: auto + auto + off reproduce el calculo antiguo',
      () {
        // Material 15 kg (legacy). Mira F: con labor rate=0 (auto) y
        // postProcessRate=0 (auto) el resultado DEBE ser identico a la
        // formula pre-v17.
        final out = CalculationEngine.compute(
          v17Input(totalHours: '0', laborRate: '0', postProcessRate: '0'),
        );
        // materialCost = 100*150/1000 = 15. Sin labor, sin postproc.
        expect(out.laborCost, Decimal.zero);
        expect(out.postProcessCost, Decimal.zero);
        expect(out.extrasCost, Decimal.zero);
        expect(out.baseCost, DecimalParse.fromString('15'));
        expect(out.totalPrice, DecimalParse.fromString('15'));
      },
    );

    test('modelado pct sobre coreBase (15) → 15% = 2.25', () {
      final out = CalculationEngine.compute(
        v17Input(laborMode: 'pct', laborPct: '15'),
      );
      expect(out.laborCost, DecimalParse.fromString('2.25'));
      expect(out.baseCost, DecimalParse.fromString('17.25'));
    });

    test('modelado fixed = 7.5 → baseCost = 22.5', () {
      final out = CalculationEngine.compute(
        v17Input(laborMode: 'fixed', laborFixed: '7.5'),
      );
      expect(out.laborCost, DecimalParse.fromString('7.5'));
      expect(out.baseCost, DecimalParse.fromString('22.5'));
    });

    test('postproc pct sobre coreBase = 20%', () {
      final out = CalculationEngine.compute(
        v17Input(postprocMode: 'pct', postprocPct: '20'),
      );
      // coreBase = 15. postproc = 15 * 20 / 100 = 3.
      expect(out.postProcessCost, DecimalParse.fromString('3'));
    });

    test(
      'extras off (sin nada) no aporta, total = material',
      () {
        final out = CalculationEngine.compute(v17Input(extraMode: 'off'));
        expect(out.extrasCost, Decimal.zero);
        expect(out.baseCost, DecimalParse.fromString('15'));
      },
    );

    test('extras pct 10 sobre coreBase (15) = 1.5', () {
      final out = CalculationEngine.compute(
        v17Input(extraMode: 'pct', extraPct: '10'),
      );
      expect(out.extrasCost, DecimalParse.fromString('1.5'));
      expect(out.baseCost, DecimalParse.fromString('16.5'));
    });

    test('extras fixed 5.5 → baseCost = 20.5', () {
      final out = CalculationEngine.compute(
        v17Input(extraMode: 'fixed', extraFixed: '5.5'),
      );
      expect(out.extrasCost, DecimalParse.fromString('5.5'));
      expect(out.baseCost, DecimalParse.fromString('20.5'));
    });

    test(
      'pct + fixed + pct en simultaneo: cada uno aporta su monto',
      () {
        final out = CalculationEngine.compute(
          v17Input(
            laborMode: 'pct',
            laborPct: '10', // 1.5
            postprocMode: 'fixed',
            postprocFixed: '2', // 2
            extraMode: 'pct',
            extraPct: '5', // 0.75
          ),
        );
        expect(out.laborCost, DecimalParse.fromString('1.5'));
        expect(out.postProcessCost, DecimalParse.fromString('2'));
        expect(out.extrasCost, DecimalParse.fromString('0.75'));
        // 15 + 1.5 + 2 + 0.75 = 19.25
        expect(out.baseCost, DecimalParse.fromString('19.25'));
      },
    );

    test(
      'amortizacion SI entra en coreBase (fix live vs snapshot)',
      () {
        // v17: live y snapshot ahora SI la incluyen (antes live la omitia).
        // Confirma que ammort en base produce sube el % del modelo.
        final out = CalculationEngine.compute(
          v17Input(
            totalHours: '2',
            amortizationPerHour: '0.875',
            laborMode: 'pct',
            laborPct: '50', // brackets + electricity + amort
          ),
        );
        // electricCost = 0 (no watts)
        // amort = 0.875 * 2 = 1.75
        // coreBase = 15 + 0 + 1.75 = 16.75
        // labor = 16.75 * 50 / 100 = 8.375
        expect(out.amortizationCost, DecimalParse.fromString('1.75'));
        expect(out.laborCost, DecimalParse.fromString('8.375'));
        // baseCost = coreBase (16.75) + modeling (8.375) = 25.125
        expect(
          out.baseCost,
          DecimalParse.fromString('25.125'),
        );
      },
    );
  });
}
