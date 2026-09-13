// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/batch_lot_composer.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';

/// Tests de `BatchLotComposer` (feature A — Hito 1).
///
/// Verifica las fórmulas de la decisión D2 del plan:
///   subtotal_impresion = (baseCost + failureCost + markupCost) × N
///   desc_cantidad      = pct × subtotal_impresion
///   desc_manual        = manualPct × (totalFinal × N)   (base de hoy)
///   total              = max(totalFinal × N − desc − desc, minimumCharge × N)
///   unitario           = total ÷ N
///
/// Y la **regla del 95 %**: N=1 sin tier → resultado IDÉNTICO al math actual.
void main() {
  /// Output para el ejemplo del PRD adaptado a hito 1:
  /// base 20, falla 10 % (2), markup 5 % × 8 = 0,40 → totalFinal 22,40.
  CalculationOutput prdOutput() => CalculationOutput(
    materialCost: Decimal.parse('8'),
    electricCost: Decimal.zero,
    amortizationCost: Decimal.zero,
    laborCost: Decimal.zero,
    postProcessCost: Decimal.zero,
    baseCost: Decimal.parse('20'),
    failureCost: Decimal.parse('2'),
    costWithFailure: Decimal.parse('22'),
    markupCost: Decimal.parse('0.4'),
    totalBeforeProfit: Decimal.parse('22.4'),
    profitAmount: Decimal.zero,
    totalFinal: Decimal.parse('22.4'),
    discountAmount: Decimal.zero,
    totalPrice: Decimal.parse('22.4'),
    totalOriginal: Decimal.parse('22.4'),
  );

  final tier10 = DiscountTier.create(
    minQty: 10,
    percent: Decimal.fromInt(10),
  );

  test('ejemplo PRD adaptado: N=10, escalón 10 %, manual 0', () {
    final r = BatchLotComposer.compose(
      output: prdOutput(),
      quantity: 10,
      minimumCharge: Decimal.zero,
      tier: tier10,
      manualDiscountPct: Decimal.zero,
    );

    expect(r.appliedTier, tier10);
    expect(
      r.subtotalImpression,
      Decimal.parse('224.00'),
      reason: '(base 20 + falla 2 + markup 0,40) × 10 = 224,00',
    );
    expect(
      r.batchDiscountAmount,
      Decimal.parse('22.40'),
      reason: '10 % × 224 = 22,40',
    );
    expect(
      r.lotTotal,
      Decimal.parse('201.60'),
      reason: '224 − 22,40 − 0 = 201,60',
    );
    expect(r.unitPrice, Decimal.parse('20.16'));
    expect(r.manualDiscountAmount, Decimal.zero);
  });

  test('escalón no aplica (N < min_qty) → sin descuento mayorista', () {
    final r = BatchLotComposer.compose(
      output: prdOutput(),
      quantity: 9,
      minimumCharge: Decimal.zero,
      tier: tier10,
    );
    expect(r.appliedTier, isNull);
    expect(r.subtotalImpression, Decimal.zero);
    expect(r.batchDiscountAmount, Decimal.zero);
    expect(r.lotTotal, Decimal.parse('201.6'));
  });

  test('regla 95 %: N=1 sin tier → idéntico al math de hoy', () {
    // Engine: totalFinal 10, descuento manual 20 % → discountAmount 2,
    // totalPrice 8. El math de hoy con N=1 es output.totalPrice × 1 = 8.
    final output = CalculationOutput(
      materialCost: Decimal.fromInt(10),
      electricCost: Decimal.zero,
      amortizationCost: Decimal.zero,
      laborCost: Decimal.zero,
      postProcessCost: Decimal.zero,
      baseCost: Decimal.fromInt(10),
      failureCost: Decimal.zero,
      costWithFailure: Decimal.fromInt(10),
      markupCost: Decimal.zero,
      totalBeforeProfit: Decimal.fromInt(10),
      profitAmount: Decimal.zero,
      totalFinal: Decimal.fromInt(10),
      discountAmount: Decimal.fromInt(2),
      totalPrice: Decimal.fromInt(8),
      totalOriginal: Decimal.fromInt(10),
    );

    final r = BatchLotComposer.compose(
      output: output,
      quantity: 1,
      minimumCharge: Decimal.zero,
      tier: null,
      manualDiscountPct: Decimal.fromInt(20),
    );

    expect(r.appliedTier, isNull);
    expect(r.subtotalImpression, Decimal.zero);
    expect(r.batchDiscountAmount, Decimal.zero);
    expect(r.lotTotal, output.totalPrice, reason: 'idéntico al math de hoy.');
    expect(r.unitPrice, output.totalPrice);
  });

  test('regla 95 % con mínimo: N=3 sin tier respeta minimumCharge × N', () {
    // Engine: totalFinal 5, discount 0 → totalPrice 5 (unitario, no clamp).
    // minimumCharge 10: el lote de 3 debe quedar en max(15, 30) = 30.
    final output = CalculationOutput(
      materialCost: Decimal.fromInt(5),
      electricCost: Decimal.zero,
      amortizationCost: Decimal.zero,
      laborCost: Decimal.zero,
      postProcessCost: Decimal.zero,
      baseCost: Decimal.fromInt(5),
      failureCost: Decimal.zero,
      costWithFailure: Decimal.fromInt(5),
      markupCost: Decimal.zero,
      totalBeforeProfit: Decimal.fromInt(5),
      profitAmount: Decimal.zero,
      totalFinal: Decimal.fromInt(5),
      discountAmount: Decimal.zero,
      totalPrice: Decimal.fromInt(5),
      totalOriginal: Decimal.fromInt(5),
    );

    final r = BatchLotComposer.compose(
      output: output,
      quantity: 3,
      minimumCharge: Decimal.fromInt(10),
    );

    expect(r.lotTotal, Decimal.fromInt(30), reason: 'max(15, minCharge 10×3)');
    expect(r.unitPrice, Decimal.fromInt(10));
  });

  test('profit > 0: la base de desc_manual sigue siendo totalFinal × N', () {
    // engine: totalFinal 30 incluye profit 20 sobre totalBeforeProfit 10
    // (falla/markup 0). desc_manual 10 % → 3,00 (NO sobre base amortizada).
    final output = CalculationOutput(
      materialCost: Decimal.fromInt(8),
      electricCost: Decimal.zero,
      amortizationCost: Decimal.zero,
      laborCost: Decimal.zero,
      postProcessCost: Decimal.zero,
      baseCost: Decimal.fromInt(10),
      failureCost: Decimal.zero,
      costWithFailure: Decimal.fromInt(10),
      markupCost: Decimal.zero,
      totalBeforeProfit: Decimal.fromInt(10),
      profitAmount: Decimal.fromInt(20),
      totalFinal: Decimal.fromInt(30),
      discountAmount: Decimal.zero,
      totalPrice: Decimal.fromInt(30),
      totalOriginal: Decimal.fromInt(30),
    );

    final r = BatchLotComposer.compose(
      output: output,
      quantity: 2,
      minimumCharge: Decimal.zero,
      manualDiscountPct: Decimal.fromInt(10),
    );

    expect(
      r.manualDiscountAmount,
      Decimal.parse('6'),
      reason: '10 % de totalFinal 30 × 2 = 6 (base total de hoy).',
    );
    expect(r.subtotalImpression, Decimal.zero, reason: 'sin escalón.');
    expect(r.lotTotal, Decimal.parse('54'));
  });

  test('descuento manual 9 % con decimales se calcula exacto', () {
    // totalFinal 100 × 10 × 7,5 % = 75,00.
    final output = CalculationOutput(
      materialCost: Decimal.fromInt(100),
      electricCost: Decimal.zero,
      amortizationCost: Decimal.zero,
      laborCost: Decimal.zero,
      postProcessCost: Decimal.zero,
      baseCost: Decimal.fromInt(100),
      failureCost: Decimal.zero,
      costWithFailure: Decimal.fromInt(100),
      markupCost: Decimal.zero,
      totalBeforeProfit: Decimal.fromInt(100),
      profitAmount: Decimal.zero,
      totalFinal: Decimal.fromInt(100),
      discountAmount: Decimal.zero,
      totalPrice: Decimal.fromInt(100),
      totalOriginal: Decimal.fromInt(100),
    );

    final r = BatchLotComposer.compose(
      output: output,
      quantity: 10,
      minimumCharge: Decimal.zero,
      manualDiscountPct: Decimal.parse('7.5'),
    );
    expect(r.manualDiscountAmount, Decimal.parse('75'));
    expect(r.lotTotal, Decimal.parse('925'));
    expect(r.unitPrice, Decimal.parse('92.5'));
  });

  test('punto de extensión: additionalCost no altera hito 1 (additive)', () {
    // Aunque se pase insumos/servicios, en hito 1 las fórmulas no cambian.
    final r = BatchLotComposer.compose(
      output: prdOutput(),
      quantity: 10,
      minimumCharge: Decimal.zero,
      tier: tier10,
      additionalCost: Decimal.parse('500'),
    );
    expect(r.subtotalImpression, Decimal.parse('224.00'));
    expect(r.lotTotal, Decimal.parse('201.60'));
  });

  test('unity: quantity 0 se clampa a 1 (defensa)', () {
    final r = BatchLotComposer.compose(
      output: prdOutput(),
      quantity: 0,
      minimumCharge: Decimal.zero,
    );
    expect(r.lotTotal, prdOutput().totalFinal);
    expect(r.unitPrice, prdOutput().totalFinal);
  });
}
