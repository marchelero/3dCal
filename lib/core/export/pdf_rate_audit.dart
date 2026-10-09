/// Parametros de calculo que se imprimen en la seccion "Parametros de
/// calculo" del reporte interno.
///
/// Existe para que el dueño pueda **auditar** un PDF: con la tabla de tasas al
/// lado del desglose de montos, cualquier linea se puede recalcular a mano.
///
/// Todos los montos son [Decimal] (prohibido `double` en dinero, ver
/// `docs/PROJECT.md`). Los campos son `null` cuando el dato no aplica, para
/// que la seccion se oculte en vez de mostrar ceros falsos.
library;

import 'package:decimal/decimal.dart';

/// Tasas y parametros resueltos de una cotizacion.
///
/// **Inmutable**. Se construye con [PdfRateAudit.fromRates], que es la unica
/// via soportada: centraliza el calculo de los porcentajes derivados
/// (margen, markup sobre costo) y sus guards contra division por cero.
class PdfRateAudit {
  const PdfRateAudit({
    this.printerName,
    this.printerWatts,
    this.kwhRate,
    this.laborRate,
    this.amortizationPerHour,
    this.postProcessRate,
    this.failureRate,
    this.markupOnMaterials,
    this.profitBase,
    this.profitMarginPct,
    this.markupOverCostPct,
    this.totalHours,
  });

  /// Resuelve el audit desde tasas ya resueltas (snapshot -> fallback) y los
  /// montos unitarios del engine.
  ///
  /// [rates] debe venir de [CalculationEngine.resolveRates] para garantizar
  /// que el PDF muestra las **mismas** tasas que uso el calculo. Si se
  /// construyera a mano con otros valores, la tabla de parametros podria
  /// contradecir al desglose de montos.
  ///
  /// [profitAmount], [baseCost] y [totalFinal] son **unitarios** (antes de
  /// escalar por cantidad): son insumos de ratios, no montos a imprimir.
  ///
  /// `totalBeforeProfit` no se recibe: se elimino al corregir el margen, que
  /// ahora se calcula sobre [totalFinal] (precio de venta) y no sobre la base
  /// previa a la ganancia.
  factory PdfRateAudit.fromRates({
    required ResolvedRates rates,
    required Decimal profitAmount,
    required Decimal baseCost,
    required Decimal totalFinal,
    required Decimal totalHours,
    String? printerName,
    int? printerWatts,
  }) {
    return PdfRateAudit(
      printerName: printerName,
      printerWatts: printerWatts,
      kwhRate: rates.kwhRate,
      laborRate: rates.laborRate,
      postProcessRate: rates.postProcessRate,
      failureRate: rates.failureRate,
      markupOnMaterials: rates.markupOnMaterials,
      profitBase: rates.profitBase,
      totalHours: totalHours,
      // F5: la amortizacion de la impresora no forma parte de los reportes.
      // Se deja en null (ademas de forzar `rates.amortizationCost` a 0 en
      // `CalculationEngine.resolveRates`) para que ninguna variante pueda
      // imprimir una fila/hora de amortizacion.
      amortizationPerHour: null,
      // Margen (sobre precio de venta) = ganancia / precio final. Es el
      // porcentaje del precio que es ganancia pura; siempre < 100%. `null` si
      // el precio es 0 para no imprimir NaN/Infinity.
      //
      // OJO: antes se calculaba sobre `totalBeforeProfit`, lo que lo hacia
      // identico a `profitBase` (el markup aplicado) y confundia al usuario:
      // un "margen 200%" es imposible. El markup sobre costo es la otra fila.
      profitMarginPct: _ratioPct(
        numerator: profitAmount,
        denominator: totalFinal,
      ),
      // Recargo sobre costo = (totalFinal - costoBase) / costoBase. Mide cuanto
      // crece el costo base (material + luz + modelado + postproc + extras)
      // hasta el precio final, incorporando tambien falla y desperdicio.
      // Coincide con `profitBase` solo cuando ambos son 0.
      markupOverCostPct: baseCost > Decimal.zero
          ? _ratioPct(numerator: totalFinal - baseCost, denominator: baseCost)
          : null,
    );
  }

  static final Decimal _pct = Decimal.fromInt(100);

  /// `numerator / denominator * 100`, o `null` si el denominador es <= 0.
  ///
  /// El orden de operaciones importa con `package:decimal`: `Decimal / Decimal`
  /// devuelve un `Rational`, y multiplicar un `Rational` por un `Decimal` no
  /// compila. Por eso se multiplica primero y recien ahi se divide.
  static Decimal? _ratioPct({
    required Decimal numerator,
    required Decimal denominator,
  }) {
    if (denominator <= Decimal.zero) return null;
    return ((numerator * _pct) / denominator).toDecimal(
      scaleOnInfinitePrecision: 2,
    );
  }

  /// Nombre del modelo de la impresora (ej: "Kobra 3"). `null` = no hay
  /// impresora configurada.
  final String? printerName;

  /// Consumo promedio en watts. `null` = sin impresora.
  final int? printerWatts;

  /// Tarifa electrica por kWh (BOB).
  final Decimal? kwhRate;

  /// Tarifa de mano de obra por hora (BOB).
  final Decimal? laborRate;

  /// Amortizacion de la impresora por hora (BOB).
  ///
  /// F5: siempre `null` — la amortizacion ya no aparece en ningun reporte
  /// (PDF, imagen ni detalle). El campo se conserva por compatibilidad.
  final Decimal? amortizationPerHour;

  /// Tasa de post-procesado (% del costo de materiales).
  final Decimal? postProcessRate;

  /// Tasa de falla (% del costo base).
  final Decimal? failureRate;

  /// Markup por desperdicio (% del costo de materiales).
  final Decimal? markupOnMaterials;

  /// Profit base (% de (base + falla + markup)).
  final Decimal? profitBase;

  /// Ganancia / precio final * 100 (porcentaje del precio que es ganancia).
  /// `null` si el precio final es 0.
  final Decimal? profitMarginPct;

  /// (totalFinal - costoBase) / costoBase * 100: cuanto crece el costo base
  /// hasta el precio final (incluye falla y desperdicio). `null` si baseCost
  /// es 0.
  final Decimal? markupOverCostPct;

  /// Horas facturadas de la impresion.
  final Decimal? totalHours;

  /// True cuando no hay nada imprimible: ni parametros ni rates.
  ///
  /// Evita que la seccion aparezca con un unico "0" cuando la cotizacion se
  /// genero con todos los extras en 0 (caso `CalculationOutput.simple`).
  bool get isEmpty =>
      (printerName == null || printerName!.isEmpty) &&
      (printerWatts == null || printerWatts == 0) &&
      _isZeroish(kwhRate) &&
      _isZeroish(laborRate) &&
      _isZeroish(amortizationPerHour) &&
      _isZeroish(postProcessRate) &&
      _isZeroish(failureRate) &&
      _isZeroish(markupOnMaterials) &&
      _isZeroish(profitBase) &&
      _isZeroish(totalHours);

  static bool _isZeroish(Decimal? v) => v == null || v <= Decimal.zero;
}

/// Tasas ya resueltas con la politica snapshot -> fallback de Settings.
///
/// Ver [CalculationEngine.resolveRates]. Es el unico tipo que debe entrar a
/// [PdfRateAudit.fromRates].
class ResolvedRates {
  const ResolvedRates({
    required this.kwhRate,
    required this.printerWatts,
    required this.laborRate,
    required this.postProcessRate,
    required this.failureRate,
    required this.markupOnMaterials,
    required this.profitBase,
    required this.amortizationCost,
  });

  final Decimal kwhRate;
  final int printerWatts;
  final Decimal laborRate;
  final Decimal postProcessRate;
  final Decimal failureRate;
  final Decimal markupOnMaterials;
  final Decimal profitBase;

  /// Costo de amortizacion acumulado.
  ///
  /// F5: siempre `Decimal.zero`. `CalculationEngine.resolveRates` ignora el
  /// snapshot y [PdfRateAudit.fromRates] no lo propaga: la amortizacion
  /// queda fuera de los reportes y fuera del costo.
  final Decimal amortizationCost;

  @override
  bool operator ==(Object other) =>
      other is ResolvedRates &&
      kwhRate == other.kwhRate &&
      printerWatts == other.printerWatts &&
      laborRate == other.laborRate &&
      postProcessRate == other.postProcessRate &&
      failureRate == other.failureRate &&
      markupOnMaterials == other.markupOnMaterials &&
      profitBase == other.profitBase &&
      amortizationCost == other.amortizationCost;

  @override
  int get hashCode => Object.hash(
    kwhRate,
    printerWatts,
    laborRate,
    postProcessRate,
    failureRate,
    markupOnMaterials,
    profitBase,
    amortizationCost,
  );

  @override
  String toString() =>
      'ResolvedRates(kwh: $kwhRate, W: $printerWatts, labor: $laborRate, '
      'post: $postProcessRate, failure: $failureRate, markup: $markupOnMaterials, '
      'profit: $profitBase, amort: $amortizationCost)';
}
