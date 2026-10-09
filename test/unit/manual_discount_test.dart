// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/batch_lot_composer.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/lot_totals.dart';
import 'package:tresdcal/features/calculation/domain/manual_discount.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';

Decimal _d(String s) => Decimal.parse(s);

CalculationOutput _output({
  String base = '40',
  String failure = '10',
  String markup = '20',
  String totalFinal = '100',
  String discountAmount = '0',
  String totalPrice = '100',
}) => CalculationOutput(
  materialCost: _d(base),
  electricCost: Decimal.zero,
  laborCost: Decimal.zero,
  postProcessCost: Decimal.zero,
  baseCost: _d(base),
  failureCost: _d(failure),
  costWithFailure: _d(base) + _d(failure),
  markupCost: _d(markup),
  totalBeforeProfit: _d(base) + _d(failure) + _d(markup),
  profitAmount: Decimal.zero,
  totalFinal: _d(totalFinal),
  discountAmount: _d(discountAmount),
  totalPrice: _d(totalPrice),
);

/// T1-3: única fuente de verdad del descuento manual.
///
/// Los tests son **golden de equivalencia**: el helper nuevo debe producir
/// EXACTAMENTE el mismo `Decimal` que la expresión que reemplaza
/// (`discountAmount × N` / `pct × (totalFinal × N)`), sin redondeos nuevos.
void main() {
  group('ManualDiscount.pctOf', () {
    test('aplica el porcentaje (amount × pct / 100)', () {
      expect(ManualDiscount.pctOf(_d('100'), _d('10')), _d('10'));
      expect(ManualDiscount.pctOf(_d('33.33'), _d('7.5')), _d('2.49975'));
      expect(ManualDiscount.pctOf(_d('7.5'), _d('7.5')), _d('0.5625'));
    });

    test('pct <= 0 devuelve 0', () {
      expect(ManualDiscount.pctOf(_d('100'), Decimal.zero), Decimal.zero);
      expect(ManualDiscount.pctOf(_d('100'), _d('-5')), Decimal.zero);
    });
  });

  group('ManualDiscount.scaled == legacy discountAmount × N', () {
    for (final unit in ['0', '0.01', '12', '12.345678', '99.999999']) {
      for (final n in [1, 2, 5, 37]) {
        test('unit=$unit N=$n', () {
          final u = _d(unit);
          final legacy = u * Decimal.fromInt(n);
          expect(
            ManualDiscount.scaled(unitDiscountAmount: u, quantity: n),
            legacy,
          );
        });
      }
    }

    test('N < 1 se fija en 1 y unit <= 0 devuelve 0', () {
      expect(
        ManualDiscount.scaled(unitDiscountAmount: _d('3'), quantity: 0),
        _d('3'),
      );
      expect(
        ManualDiscount.scaled(unitDiscountAmount: Decimal.zero, quantity: 9),
        Decimal.zero,
      );
    });
  });

  group('equivalencia scaled(pctOf(tf,pct), N) == pctOf(tf × N, pct)', () {
    for (final tf in ['100', '99.99', '1234.56', '7.5']) {
      for (final pct in ['5', '7.5', '12.34', '50']) {
        for (final n in [1, 2, 3, 10]) {
          test('tf=$tf pct=$pct N=$n', () {
            final unit = ManualDiscount.pctOf(_d(tf), _d(pct));
            final scaled = ManualDiscount.scaled(
              unitDiscountAmount: unit,
              quantity: n,
            );
            final direct = ManualDiscount.pctOf(
              _d(tf) * Decimal.fromInt(n),
              _d(pct),
            );
            expect(scaled, direct);
          });
        }
      }
    }
  });

  group('BatchLotComposer.manualDiscountAmount usa el helper', () {
    for (final n in [1, 2, 5, 12]) {
      test('N=$n sin escalón', () {
        final manualPct = _d('10');
        final output = _output(totalFinal: '100');
        final result = BatchLotComposer.compose(
          output: output,
          quantity: n,
          minimumCharge: Decimal.zero,
          manualDiscountPct: manualPct,
        );
        final expected = ManualDiscount.scaled(
          unitDiscountAmount: ManualDiscount.pctOf(output.totalFinal, manualPct),
          quantity: n,
        );
        expect(result.manualDiscountAmount, expected);
        expect(result.batchDiscountAmount, Decimal.zero);
      });
    }
  });

  group('BatchLotComposer con escalón + descuento manual + piso', () {
    test('mantiene total = max(totalFinal × N − desc_cantidad − desc_manual, piso)', () {
      const n = 10;
      final output = _output();
      final tier = DiscountTier.create(minQty: 5, percent: _d('10'));
      final manualPct = _d('5');
      final minimumCharge = _d('50');

      final result = BatchLotComposer.compose(
        output: output,
        quantity: n,
        minimumCharge: minimumCharge,
        tier: tier,
        manualDiscountPct: manualPct,
      );

      final nD = Decimal.fromInt(n);
      final expectedBatch = ManualDiscount.pctOf(
        (output.baseCost + output.failureCost + output.markupCost) * nD,
        _d('10'),
      );
      final expectedManual = ManualDiscount.pctOf(output.totalFinal * nD, manualPct);
      final after =
          output.totalFinal * nD - expectedBatch - expectedManual;
      final floor = minimumCharge * nD;

      expect(result.batchDiscountAmount, expectedBatch);
      expect(result.manualDiscountAmount, expectedManual);
      expect(result.lotTotal, after > floor ? after : floor);
    });
  });

  group('LotTotals.batchAmount delega el porcentaje', () {
    for (final pct in ['0', '10', '12.5']) {
      for (final n in [1, 3, 8]) {
        test('pct=$pct N=$n', () {
          final expected = _d(pct) <= Decimal.zero
              ? Decimal.zero
              : ManualDiscount.pctOf(
                  (_d('40') + _d('10') + _d('20')) * Decimal.fromInt(n),
                  _d(pct),
                );
          expect(
            LotTotals.batchAmount(
              base: _d('40'),
              failure: _d('10'),
              markup: _d('20'),
              pct: _d(pct),
              quantity: n,
            ),
            expected,
          );
        });
      }
    }
  });
}
