// ignore_for_file: public_member_api_docs
//
// H1 — Fundaciones de las 4 variantes de reporte.
//
// Cubre las dos piezas nuevas que todo lo demas depende:
//
// 1. `QuoteReportVariant` — el enum que reemplaza al toggle binario
//    `showDetail`. Los getters son la superficie real: el generador de PDF y
//    el de imagen deben decidir SIEMPRE por getters, nunca comparando
//    casos, para que agregar una variante rompa en compilacion y no en
//    silencio.
// 2. `PdfRateAudit` + `CalculationEngine.resolveRates` — la tabla de
//    parametros del reporte interno. El test clave es AC-42/CA-44: la tabla de
//    tasas tiene que contradecir al desglose de montos, porque ambas salen de
//    `resolveRates`.
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/export/pdf_rate_audit.dart';
import 'package:tresdcal/core/export/quote_report_variant.dart';
import 'package:tresdcal/features/calculation/domain/calculation_engine.dart';

Decimal _d(num v) => Decimal.parse(v.toString());

void main() {
  group('QuoteReportVariant — getters de contenido', () {
    test('isClientFacing: solo las 2 variantes de cliente', () {
      expect(QuoteReportVariant.clientSimple.isClientFacing, isTrue);
      expect(QuoteReportVariant.clientAdvanced.isClientFacing, isTrue);
      expect(QuoteReportVariant.internalDetail.isClientFacing, isFalse);
      expect(QuoteReportVariant.internalAdvanced.isClientFacing, isFalse);
    });

    test('isAdvanced: solo la variante advanced de cada audience', () {
      expect(QuoteReportVariant.clientSimple.isAdvanced, isFalse);
      expect(QuoteReportVariant.clientAdvanced.isAdvanced, isTrue);
      expect(QuoteReportVariant.internalDetail.isAdvanced, isFalse);
      expect(QuoteReportVariant.internalAdvanced.isAdvanced, isTrue);
    });

    test('showCostDetail == internalDetail | internalAdvanced', () {
      expect(
        QuoteReportVariant.values.where((v) => v.showCostDetail).toSet(),
        {
          QuoteReportVariant.internalDetail,
          QuoteReportVariant.internalAdvanced,
        },
        reason: 'El desglose de costos SOLO puede salir en variantes internas.',
      );
    });

    test('showRateAudit == showCostDetail (misma audience)', () {
      for (final v in QuoteReportVariant.values) {
        expect(
          v.showRateAudit,
          v.showCostDetail,
          reason:
              '${v.name}: la tabla de parametros debe compartir gate con el '
              'desglose. Si divergen, el PDF podria imprimir tasas sin '
              'desglose y filtrar informacion sensible al cliente.',
        );
      }
    });

    test('showCostDetail implica !isClientFacing (no fuga de costos)', () {
      for (final v in QuoteReportVariant.values) {
        if (v.showCostDetail) {
          expect(
            v.isClientFacing,
            isFalse,
            reason: '${v.name} expone costos: no puede ser variant de cliente.',
          );
        }
      }
    });

    test('showsMaterialTime: las 2 advanced + las 2 internas', () {
      expect(
        QuoteReportVariant.clientAdvanced.showsMaterialTime,
        isTrue,
      );
      expect(QuoteReportVariant.internalAdvanced.showsMaterialTime, isTrue);
      expect(
        QuoteReportVariant.internalDetail.showsMaterialTime,
        isTrue,
        reason:
            'El unico caso sin tiempo es la variante "para cliente" simple: '
            'cualquier variante interna ya delata que es un documento de '
            'trabajo, asi que el tiempo por material no agrega exposicion.',
      );
      expect(QuoteReportVariant.clientSimple.showsMaterialTime, isFalse);
    });

    test('showsSummaryBlock == isClientFacing', () {
      for (final v in QuoteReportVariant.values) {
        expect(v.showsSummaryBlock, v.isClientFacing);
      }
    });

    test('uiOrder tiene las 4 variantes, en orden cliente -> interno', () {
      expect(QuoteReportVariant.uiOrder, hasLength(4));
      expect(
        QuoteReportVariant.uiOrder.toSet(),
        QuoteReportVariant.values.toSet(),
        reason: 'Las 4 variantes existen; solo 2 se muestran por modo.',
      );
      expect(QuoteReportVariant.uiOrder[0].isClientFacing, isTrue);
      expect(QuoteReportVariant.uiOrder[3].showCostDetail, isTrue);
    });
  });

  group('QuoteReportVariant — selector de 2 opciones por modo', () {
    test('express ofrece clientSimple | internalDetail', () {
      expect(QuoteReportVariant.optionsForMode(isAdvanced: false), [
        QuoteReportVariant.clientSimple,
        QuoteReportVariant.internalDetail,
      ]);
    });

    test('advanced ofrece clientAdvanced | internalAdvanced', () {
      expect(QuoteReportVariant.optionsForMode(isAdvanced: true), [
        QuoteReportVariant.clientAdvanced,
        QuoteReportVariant.internalAdvanced,
      ]);
    });

    test('cada modo ofrece 1 variante de cliente y 1 interna', () {
      // Es el contrato de seguridad: 2 opciones, una por audiencia, para que
      // el usuario nunca tenga que decidir "cuanta complejidad" aparte de
      // "a quien se lo mando".
      for (final isAdvanced in [false, true]) {
        final options = QuoteReportVariant.optionsForMode(
          isAdvanced: isAdvanced,
        );
        expect(options, hasLength(2));
        expect(options.where((v) => v.isClientFacing), hasLength(1));
        expect(options.where((v) => v.showCostDetail), hasLength(1));
        expect(
          options.every((v) => v.isAdvanced == isAdvanced),
          isTrue,
          reason: 'Las 2 opciones deben pertenecer al eje del modo.',
        );
      }
    });

    test('las opciones de un modo son disjuntas de las del otro', () {
      expect(
        QuoteReportVariant.optionsForMode(
          isAdvanced: false,
        ).toSet().intersection(
          QuoteReportVariant.optionsForMode(isAdvanced: true).toSet(),
        ),
        isEmpty,
      );
    });

    test('forMode proyecta al eje del otro modo conservando la audiencia', () {
      expect(
        QuoteReportVariant.clientSimple.forMode(isAdvanced: true),
        QuoteReportVariant.clientAdvanced,
      );
      expect(
        QuoteReportVariant.internalDetail.forMode(isAdvanced: true),
        QuoteReportVariant.internalAdvanced,
      );
      expect(
        QuoteReportVariant.clientAdvanced.forMode(isAdvanced: false),
        QuoteReportVariant.clientSimple,
      );
      expect(
        QuoteReportVariant.internalAdvanced.forMode(isAdvanced: false),
        QuoteReportVariant.internalDetail,
      );
    });

    test('forMode es idempotente dentro del mismo eje', () {
      for (final isAdvanced in [false, true]) {
        for (final v in QuoteReportVariant.optionsForMode(
          isAdvanced: isAdvanced,
        )) {
          expect(v.forMode(isAdvanced: isAdvanced), v);
        }
      }
    });

    test('forMode nunca cambia la audiencia', () {
      // El error grave seria "el usuario pide Detalle y al tocar el modo le
      // aparece una variante de cliente con los costos a la vista".
      for (final v in QuoteReportVariant.values) {
        for (final isAdvanced in [false, true]) {
          expect(
            v.forMode(isAdvanced: isAdvanced).isClientFacing,
            v.isClientFacing,
            reason: '${v.name} -> isAdvanced=$isAdvanced cambio de audiencia.',
          );
        }
      }
    });

    test('isAdvancedVariant marca el eje, no la audiencia', () {
      expect(QuoteReportVariant.clientAdvanced.isAdvancedVariant, isTrue);
      expect(QuoteReportVariant.internalAdvanced.isAdvancedVariant, isTrue);
      expect(QuoteReportVariant.clientSimple.isAdvancedVariant, isFalse);
      expect(QuoteReportVariant.internalDetail.isAdvancedVariant, isFalse);
    });
  });

  group('CalculationEngine.resolveRates — politica snapshot -> fallback', () {
    // Snapshot > 0 gana; snapshot == 0 cae al valor de Settings.
    // Esta es la MISMA politica que applyaba inline en computeFromSnapshot
    // antes del refactor: el refactor no puede cambiar el resultado.
    test('snapshot > 0 gana sobre el fallback', () {
      final rates = CalculationEngine.resolveRates(
        kwhRateSnapshot: 1.5,
        laborRateSnapshot: 40,
        postProcessRateSnapshot: 12,
        failureRateSnapshot: 6,
        markupOnMaterialsSnapshot: 9,
        profitBaseSnapshot: 150,
        printerWattsSnapshot: 180,
        amortizationCostSnapshot: 20,
        fallbackKwhRate: _d(0.7),
        fallbackLaborRate: _d(25),
        fallbackPostProcessRate: _d(10),
        fallbackFailureRate: _d(5),
        fallbackMarkupOnMaterials: _d(8),
        fallbackProfitBase: _d(100),
        fallbackPrinterWatts: 120,
      );

      expect(rates.kwhRate, _d(1.5));
      expect(rates.laborRate, _d(40));
      expect(rates.postProcessRate, _d(12));
      expect(rates.failureRate, _d(6));
      expect(rates.markupOnMaterials, _d(9));
      expect(rates.profitBase, _d(150));
      expect(rates.printerWatts, 180);
      expect(rates.amortizationCost, _d(20));
    });

    test('snapshot == 0 (legacy) cae al fallback de Settings', () {
      final rates = CalculationEngine.resolveRates(
        kwhRateSnapshot: 0,
        laborRateSnapshot: 0,
        postProcessRateSnapshot: 0,
        failureRateSnapshot: 0,
        markupOnMaterialsSnapshot: 0,
        profitBaseSnapshot: 0,
        printerWattsSnapshot: 0,
        amortizationCostSnapshot: 0,
        fallbackKwhRate: _d(0.7),
        fallbackLaborRate: _d(25),
        fallbackPostProcessRate: _d(10),
        fallbackFailureRate: _d(5),
        fallbackMarkupOnMaterials: _d(8),
        fallbackProfitBase: _d(100),
        fallbackPrinterWatts: 120,
      );

      expect(rates.kwhRate, _d(0.7));
      expect(rates.laborRate, _d(25));
      expect(rates.postProcessRate, _d(10));
      expect(rates.failureRate, _d(5));
      expect(rates.markupOnMaterials, _d(8));
      expect(rates.profitBase, _d(100));
      expect(rates.printerWatts, 120);
      expect(rates.amortizationCost, Decimal.zero);
    });

    test('resolveRates coincide con lo que usa computeFromSnapshot', () {
      // El reporte PDF imprime `resolveRates`, el desglose de montos lo imprime
      // `computeFromSnapshot`. Si divergieran, la tabla de parametros
      // contradiria al desglose (CA-43/CA-44).
      const kwhSnapshot = 0.85;
      const laborSnapshot = 30.0;

      final rates = CalculationEngine.resolveRates(
        kwhRateSnapshot: kwhSnapshot,
        laborRateSnapshot: laborSnapshot,
        postProcessRateSnapshot: 0,
        failureRateSnapshot: 0,
        markupOnMaterialsSnapshot: 0,
        profitBaseSnapshot: 0,
        printerWattsSnapshot: 0,
        fallbackKwhRate: _d(99), // No debe ganar: el snapshot es > 0.
        fallbackLaborRate: _d(99),
        fallbackPostProcessRate: _d(99),
        fallbackFailureRate: _d(99),
        fallbackMarkupOnMaterials: _d(99),
        fallbackProfitBase: _d(99),
        fallbackPrinterWatts: 999,
      );

      final output = CalculationEngine.computeFromSnapshot(
        materials: const [
          MaterialSnapshot(
            weightGrams: 100,
            pricePerBobbinSnapshot: 70,
            gramsPerBobbinSnapshot: 1000,
          ),
        ],
        materialCostSnapshot: 7,
        totalHours: 2,
        printerWattsSnapshot: 100,
        kwhRateSnapshot: kwhSnapshot,
        laborRateSnapshot: laborSnapshot,
        postProcessRateSnapshot: 0,
        failureRateSnapshot: 0,
        markupOnMaterialsSnapshot: 0,
        profitBaseSnapshot: 0,
        discountPercentage: 0,
        fallbackKwhRate: _d(99),
        fallbackLaborRate: _d(99),
        fallbackPostProcessRate: _d(99),
        fallbackFailureRate: _d(99),
        fallbackMarkupOnMaterials: _d(99),
        fallbackProfitBase: _d(99),
        fallbackPrinterWatts: 999,
      );

      expect(output, isNotNull);
      // electricCost = watts * hours * kwh / 1000 = 100 * 2 * 0.85 / 1000
      expect(output!.electricCost, _d(0.17));
      // laborCost = hours * laborRate = 2 * 30
      expect(output.laborCost, _d(60));
      // Las tasas del audit son las que el engine uso de verdad.
      expect(rates.kwhRate, _d(0.85));
      expect(rates.laborRate, _d(30));
    });
  });

  group('PdfRateAudit.fromRates — ratios derivados', () {
    final rates = ResolvedRates(
      kwhRate: _d(0.7),
      printerWatts: 120,
      laborRate: _d(25),
      postProcessRate: _d(10),
      failureRate: _d(5),
      markupOnMaterials: _d(8),
      profitBase: _d(100),
      amortizationCost: _d(10),
    );

    test('margen = profitAmount / totalBeforeProfit * 100', () {
      // totalBeforeProfit = 200, profit = 100 -> 50%.
      final audit = PdfRateAudit.fromRates(
        rates: rates,
        profitAmount: _d(100),
        totalBeforeProfit: _d(200),
        baseCost: _d(150),
        totalFinal: _d(300),
        totalHours: _d(2),
      );
      expect(audit.profitMarginPct, _d(50));
    });

    test('markup sobre costo = (totalFinal - baseCost) / baseCost * 100', () {
      // (300 - 150) / 150 = 100%.
      final audit = PdfRateAudit.fromRates(
        rates: rates,
        profitAmount: _d(100),
        totalBeforeProfit: _d(200),
        baseCost: _d(150),
        totalFinal: _d(300),
        totalHours: _d(2),
      );
      expect(audit.markupOverCostPct, _d(100));
    });

    test('amortizacion por hora = amortCost / horas', () {
      final audit = PdfRateAudit.fromRates(
        rates: rates,
        profitAmount: _d(100),
        totalBeforeProfit: _d(200),
        baseCost: _d(150),
        totalFinal: _d(300),
        totalHours: _d(4),
      );
      expect(audit.amortizationPerHour, _d(2.5));
    });

    test('CA-45: denominador 0 NO produce NaN/Infinity', () {
      final audit = PdfRateAudit.fromRates(
        rates: rates,
        profitAmount: Decimal.zero,
        totalBeforeProfit: Decimal.zero,
        baseCost: Decimal.zero,
        totalFinal: Decimal.zero,
        totalHours: Decimal.zero,
      );
      expect(
        audit.profitMarginPct,
        isNull,
        reason: 'Margen con base 0 -> null',
      );
      expect(
        audit.markupOverCostPct,
        isNull,
        reason: 'Markup con costo base 0 -> null',
      );
      expect(
        audit.amortizationPerHour,
        Decimal.zero,
        reason: 'Sin horas no hay base para amortizar por hora.',
      );
    });

    test(
      'isEmpty con todas las tasas en 0 (caso CalculationOutput.simple)',
      () {
        final audit = PdfRateAudit.fromRates(
          rates: ResolvedRates(
            kwhRate: Decimal.zero,
            printerWatts: 0,
            laborRate: Decimal.zero,
            postProcessRate: Decimal.zero,
            failureRate: Decimal.zero,
            markupOnMaterials: Decimal.zero,
            profitBase: Decimal.zero,
            amortizationCost: Decimal.zero,
          ),
          profitAmount: Decimal.zero,
          totalBeforeProfit: Decimal.zero,
          baseCost: Decimal.zero,
          totalFinal: Decimal.zero,
          totalHours: Decimal.zero,
        );
        expect(
          audit.isEmpty,
          isTrue,
          reason:
              'Con todo en 0 la seccion de parametros debe ocultarse, no '
              'imprimir una tabla de ceros.',
        );
      },
    );

    test('isEmpty == false si hay al menos una tasa o la impresora', () {
      final conTasa = PdfRateAudit.fromRates(
        rates: rates,
        profitAmount: _d(100),
        totalBeforeProfit: _d(200),
        baseCost: _d(150),
        totalFinal: _d(300),
        totalHours: _d(2),
      );
      expect(conTasa.isEmpty, isFalse);

      final conImpresora = PdfRateAudit.fromRates(
        rates: ResolvedRates(
          kwhRate: Decimal.zero,
          printerWatts: 120,
          laborRate: Decimal.zero,
          postProcessRate: Decimal.zero,
          failureRate: Decimal.zero,
          markupOnMaterials: Decimal.zero,
          profitBase: Decimal.zero,
          amortizationCost: Decimal.zero,
        ),
        profitAmount: Decimal.zero,
        totalBeforeProfit: Decimal.zero,
        baseCost: Decimal.zero,
        totalFinal: Decimal.zero,
        totalHours: Decimal.zero,
        printerName: 'Kobra 3',
        printerWatts: 120,
      );
      expect(conImpresora.isEmpty, isFalse);
    });
  });
}
