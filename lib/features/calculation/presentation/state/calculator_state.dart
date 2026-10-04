// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/export/pdf_rate_audit.dart';
import '../../../../core/export/quote_report_variant.dart';
import '../../../../core/money/decimal_extensions.dart';
import '../../domain/entities/calculation_output.dart';

/// Modo del calculator.
enum CalculatorMode {
  /// Single material, campos top-level (weight, filamentPrice, filamentGrams).
  /// Default MVP, back-compat con Sprint 3.
  express,

  /// Multi-material. La lista `materials` es la fuente de verdad; los campos
  /// top-level de filamento se ignoran.
  advanced,
}

/// Item individual de desglose de costo de materiales.
/// Usado en DetailSection para mostrar costo por material.
@immutable
class MaterialCostBreakdown {
  const MaterialCostBreakdown({required this.label, required this.cost});

  final String label;
  final Decimal cost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialCostBreakdown &&
          other.label == label &&
          other.cost == cost);

  @override
  int get hashCode => Object.hash(label, cost);
}

/// Fila de material en el calculator (modo advanced).
///
/// Strings raw, parsing en [parseDecimal]. Inmutable.
@immutable
class MaterialRow {
  const MaterialRow({
    this.label = '',
    this.weight = '',
    this.pricePerBobbin = '',
    this.gramsPerBobbin = '',
    this.useOwnTime = false,
    this.materialHours = '',
    this.materialMinutes = '',
  });

  final String label;
  final String weight; // gramos de ESTE material en la pieza
  final String pricePerBobbin;
  final String gramsPerBobbin;

  /// Si true, este material tiene su propio tiempo (hours/minutes)
  /// independiente del tiempo global.
  final bool useOwnTime;
  final String materialHours;
  final String materialMinutes;

  bool get isValid {
    final w = CalculatorState.parseDecimal(weight);
    final p = CalculatorState.parseDecimal(pricePerBobbin);
    final g = CalculatorState.parseDecimal(gramsPerBobbin);
    return w != null &&
        w > Decimal.zero &&
        p != null &&
        p > Decimal.zero &&
        g != null &&
        g > Decimal.zero;
  }

  /// Horas del tiempo propio como Decimal, o null si no aplica.
  Decimal? get ownTimeHoursDecimal => useOwnTime
      ? CalculatorState.parseDecimal(materialHours) ?? Decimal.zero
      : null;

  /// Minutos del tiempo propio como Decimal, o null si no aplica.
  Decimal? get ownTimeMinutesDecimal => useOwnTime
      ? CalculatorState.parseDecimal(materialMinutes) ?? Decimal.zero
      : null;

  /// Tiempo propio de ESTE material en horas decimales, o null si no aplica.
  ///
  /// Retorna null cuando [useOwnTime] es false o cuando el par
  /// horas/minutos esta vacio o en 0 (switch ON pero sin valor aun).
  Decimal? get ownTimeDecimal {
    if (!useOwnTime) return null;
    final h = CalculatorState.parseDecimal(materialHours) ?? Decimal.zero;
    final m = CalculatorState.parseDecimal(materialMinutes) ?? Decimal.zero;
    if (h <= Decimal.zero && m <= Decimal.zero) return null;
    if (m <= Decimal.zero) return h;
    if (h <= Decimal.zero) {
      return (m / Decimal.fromInt(60)).toDecimal(scaleOnInfinitePrecision: 12);
    }
    return h +
        (m / Decimal.fromInt(60)).toDecimal(scaleOnInfinitePrecision: 12);
  }

  /// Tiempo propio de ESTE material en MINUTOS enteros, o null si no aplica.
  ///
  /// Se calcula como `hours*60 + minutes` en aritmetica entera en vez de
  /// derivarlo de [ownTimeDecimal]: `m/60` trunca a 12 decimales y al volver
  /// a minutos (`x*60`) el resultado queda 369.999... → `toBigInt()` perdia
  /// 1 minuto (bug: 3h04m + 3h06m mostraba 6h09m en vez de 6h10m).
  int? get ownTimeMinutes {
    if (!useOwnTime) return null;
    final h = CalculatorState.parseDecimal(materialHours) ?? Decimal.zero;
    final m = CalculatorState.parseDecimal(materialMinutes) ?? Decimal.zero;
    final mins = (h * Decimal.fromInt(60) + m).round().toBigInt().toInt();
    return mins > 0 ? mins : null;
  }

  /// El switch de tiempo propio esta ON pero sin horas/minutos informadas.
  /// La UI lo marca como incompleto para que el usuario no olvide llenarlo.
  bool get ownTimeMissing => useOwnTime && ownTimeDecimal == null;

  MaterialRow copyWith({
    String? label,
    String? weight,
    String? pricePerBobbin,
    String? gramsPerBobbin,
    bool? useOwnTime,
    String? materialHours,
    String? materialMinutes,
  }) => MaterialRow(
    label: label ?? this.label,
    weight: weight ?? this.weight,
    pricePerBobbin: pricePerBobbin ?? this.pricePerBobbin,
    gramsPerBobbin: gramsPerBobbin ?? this.gramsPerBobbin,
    useOwnTime: useOwnTime ?? this.useOwnTime,
    materialHours: materialHours ?? this.materialHours,
    materialMinutes: materialMinutes ?? this.materialMinutes,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialRow &&
          other.label == label &&
          other.weight == weight &&
          other.pricePerBobbin == pricePerBobbin &&
          other.gramsPerBobbin == gramsPerBobbin &&
          other.useOwnTime == useOwnTime &&
          other.materialHours == materialHours &&
          other.materialMinutes == materialMinutes);

  @override
  int get hashCode => Object.hash(
    label,
    weight,
    pricePerBobbin,
    gramsPerBobbin,
    useOwnTime,
    materialHours,
    materialMinutes,
  );
}

/// Estado del formulario de cotizacion.
///
/// **Inmutable**. Cada cambio genera un nuevo state via [copyWith].
/// El campo [output] se computa lazy en el notifier cuando el form es valido.
///
/// **Modos**:
/// - [CalculatorMode.express]: single material, usa `weight/filamentPrice/filamentGrams`.
/// - [CalculatorMode.advanced]: multi-material, usa `materials` (lista).
///
/// Formula completa (F1):
///   materialCost + electricCost + laborCost + postProcessCost = baseCost
///   baseCost + failureCost + markup + profit = total
///   max(total - discount, minimumCharge) = totalPrice
@immutable
class CalculatorState {
  CalculatorState({
    required this.mode,
    required this.printHours,
    required this.printMinutes,
    required this.discountPct,
    required this.weight,
    required this.filamentPrice,
    required this.filamentGrams,
    required this.label,
    this.filamentLabel = '',
    required this.materials,
    required this.output,
    this.detailMaterialBreakdown = const <MaterialCostBreakdown>[],
    this.reportVariant = QuoteReportVariant.clientSimple,
    this.rateAudit,
    this.detailElectricCost,
    this.detailAmortizationCost,
    this.detailLaborCost,
    this.detailPostProcessCost,
    this.detailExtrasCost,
    this.detailBaseCost,
    this.detailFailureCost,
    this.detailMarkupCost,
    this.detailProfitAmount,
    this.detailTotalFinal,
    this.detailDiscountPct,
    this.extraLaborRate = '',
    this.extraPostProcessRate = '',
    this.extraFailureRate = '',
    this.extraMarkupOnMaterials = '',
    this.quantity = 1,
    this.computeVersion = 0,
    this.batchAppliedPercent,
    this.batchAppliedMinQty,
    Decimal? batchDiscountAmount,
    Decimal? manualDiscountAmount,
    Decimal? subtotalImpression,
    Decimal? lotTotal,
    this.showsBatchLine = false,
    // === Costos adicionales (v17) — overrides por cotizacion ===
    // 'auto'/'off' = sin override (usa el calculo legacy o no cobra).
    // 'pct' = el valor es un porcentaje sobre coreBase.
    // 'fixed' = el valor es un monto fijo en moneda local.
    this.modelingMode = 'fixed',
    this.modelingValue = '',
    this.postprocMode = 'fixed',
    this.postprocValue = '',
    this.extraCostMode = 'fixed',
    this.extraCostValue = '',
    this.extraCostLabel = '',
  }) : assert(quantity >= 1, 'La cantidad minima es 1.'),
       batchDiscountAmount = batchDiscountAmount ?? Decimal.zero,
       manualDiscountAmount = manualDiscountAmount ?? Decimal.zero,
       subtotalImpression = subtotalImpression ?? Decimal.zero,
       lotTotal = lotTotal ?? Decimal.zero;

  /// Estado inicial (modo express, sin materiales).
  factory CalculatorState.initial() => CalculatorState(
    mode: CalculatorMode.express,
    printHours: '',
    printMinutes: '',
    discountPct: '0',
    weight: '',
    filamentPrice: '',
    filamentGrams: '',
    label: '',
    materials: <MaterialRow>[],
    output: null,
  );

  final CalculatorMode mode;

  // === Comunes (ambos modos) ===
  /// Horas de impresion (informacional).
  final String printHours;

  /// Minutos de impresion (informacional, 0-59).
  final String printMinutes;

  /// Descuento comercial (%).
  final String discountPct;

  /// Etiqueta opcional de la cotizacion (ej: "Soporte pared").
  final String label;

  /// Etiqueta del filamento/material en modo Express.
  /// En Advanced cada material tiene su propia label en [materials].
  final String filamentLabel;

  // === Modo express (single material) ===
  final String weight;
  final String filamentPrice;
  final String filamentGrams;

  // === Modo advanced (multi-material) ===
  final List<MaterialRow> materials;

  // === Computed ===
  final CalculationOutput? output;

  /// Desglose de costo por material (solo para modo advanced).
  /// Computado en _recompute(). Vacio en modo express.
  final List<MaterialCostBreakdown> detailMaterialBreakdown;

  // === Detalle del reporte ===

  /// Variante del reporte (pantalla, PDF, PNG e impresion).
  ///
  /// Fuente UNICA de verdad: lo que se ve en pantalla y lo que se exporta
  /// se deciden juntos, asi no puede quedar desincronizado. Elegir una
  /// variante interna muestra ademas el desglose en pantalla.
  final QuoteReportVariant reportVariant;

  /// Parametros de calculo ya resueltos, para la tabla de auditoria del
  /// reporte interno. Computado en _recompute() desde el mismo input que
  /// alimenta el engine.
  final PdfRateAudit? rateAudit;
  final Decimal? detailElectricCost;
  final Decimal? detailAmortizationCost;
  final Decimal? detailLaborCost;
  final Decimal? detailPostProcessCost;

  /// v17: Extras (argollas, pegamento, etc.). Si es null o 0, no se
  /// imprime fila en el reporte.
  final Decimal? detailExtrasCost;

  final Decimal? detailBaseCost;
  final Decimal? detailFailureCost;
  final Decimal? detailMarkupCost;
  final Decimal? detailProfitAmount;
  final Decimal? detailTotalFinal;

  /// Porcentaje de descuento real aplicado.
  final Decimal? detailDiscountPct;

  // === OTROS (F1: campos extras por cotizacion) ===
  /// Tarifa de mano de obra (BOB/hora). String vacio = no usado.
  final String extraLaborRate;

  /// Tasa de post-procesado (% del costo de materiales).
  final String extraPostProcessRate;

  /// Tasa de falla (% del costo base).
  final String extraFailureRate;

  /// Markup por desperdicio (% del costo de materiales).
  final String extraMarkupOnMaterials;

  /// Cantidad de unidades. El total se multiplica por este valor.
  final int quantity;

  /// Numero de version que incrementa en cada recomputo.
  /// Usado por la UI para animar "calculando..." cuando cambia el output.
  final int computeVersion;

  // === Lote mayorista (feature A — Hito 1) ===
  /// Porcentaje del escalón aplicado (`%` del descuento por cantidad).
  /// `null` cuando no aplica escalón (N=1 o N bajo el primer escalón).
  final Decimal? batchAppliedPercent;

  /// Cantidad mínima del escalón aplicado. `null` cuando no aplica.
  /// Usado por el hint del campo Cantidad ("X % desde N u.").
  final int? batchAppliedMinQty;

  /// Monto del descuento mayorista (0 sin escalón).
  final Decimal batchDiscountAmount;

  /// Monto del descuento manual escalado: `manualPct × (totalFinal × N)`.
  /// `0` sin descuento manual.
  final Decimal manualDiscountAmount;

  /// `(baseCost + failureCost + markupCost) × N` — base del descuento
  /// mayorista. `0` sin escalón.
  final Decimal subtotalImpression;

  /// Total del lote (`max(totalFinal × N − desc_cantidad − desc_manual,
  /// minimumCharge × N)`). Sin escalón == el math actual escalado
  /// (`output.totalPrice × N`, regla 95 %).
  final Decimal lotTotal;

  /// True cuando hay línea de "Descuento por cantidad (X %)" para mostrar.
  final bool showsBatchLine;

  // === Costos de la pieza (v17) ===
  //
  // Cada uno de los 3 campos de servicio tiene un modo de 2 posiciones
  // (`pct` | `fixed`) y un valor texto libre. `pct` significa "el valor es un
  // porcentaje sobre coreBase"; `fixed` significa "el valor es un monto fijo
  // en moneda local". No existe modo automatico: el switch de la UI solo
  // ofrece esas 2 opciones.
  //
  // Default: `fixed` con valor vacio (= 0), o sea que una cotizacion nueva no
  // suma nada por estos 3 campos hasta que el usuario los configure.
  //
  // Los modos legacy `auto` / `off` SIGUEN siendo validos en el motor: filas
  // guardadas antes de este cambio los tienen persistidos y deben seguir
  // calculando igual (historial / computeFromSnapshot). `loadFromCalculation`
  // los normaliza a `fixed` al reeditar.
  final String modelingMode;
  final String modelingValue;
  final String postprocMode;
  final String postprocValue;
  final String extraCostMode;
  final String extraCostValue;

  /// Texto libre que describe los extras ("2 argollas M3", etc.). Aparece
  /// en el reporte si no esta vacio. No afecta el calculo.
  final String extraCostLabel;

  CalculatorState copyWith({
    CalculatorMode? mode,
    String? printHours,
    String? printMinutes,
    String? discountPct,
    String? weight,
    String? filamentPrice,
    String? filamentGrams,
    String? label,
    String? filamentLabel,
    List<MaterialRow>? materials,
    CalculationOutput? output,
    List<MaterialCostBreakdown>? detailMaterialBreakdown,
    bool clearOutput = false,
    QuoteReportVariant? reportVariant,
    PdfRateAudit? rateAudit,
    Decimal? batchAppliedPercent,
    int? batchAppliedMinQty,
    Decimal? batchDiscountAmount,
    Decimal? manualDiscountAmount,
    Decimal? subtotalImpression,
    Decimal? lotTotal,
    bool? showsBatchLine,
    bool clearBatch = false,
    Decimal? detailElectricCost,
    Decimal? detailAmortizationCost,
    Decimal? detailLaborCost,
    Decimal? detailPostProcessCost,
    Decimal? detailExtrasCost,
    Decimal? detailBaseCost,
    Decimal? detailFailureCost,
    Decimal? detailMarkupCost,
    Decimal? detailProfitAmount,
    Decimal? detailTotalFinal,
    Decimal? detailDiscountPct,
    bool clearDetail = false,
    String? extraLaborRate,
    String? extraPostProcessRate,
    String? extraFailureRate,
    String? extraMarkupOnMaterials,
    int? quantity,
    int? computeVersion,
    String? modelingMode,
    String? modelingValue,
    String? postprocMode,
    String? postprocValue,
    String? extraCostMode,
    String? extraCostValue,
    String? extraCostLabel,
  }) => CalculatorState(
    mode: mode ?? this.mode,
    printHours: printHours ?? this.printHours,
    printMinutes: printMinutes ?? this.printMinutes,
    discountPct: discountPct ?? this.discountPct,
    weight: weight ?? this.weight,
    filamentPrice: filamentPrice ?? this.filamentPrice,
    filamentGrams: filamentGrams ?? this.filamentGrams,
    label: label ?? this.label,
    filamentLabel: filamentLabel ?? this.filamentLabel,
    materials: materials ?? this.materials,
    output: clearOutput ? null : (output ?? this.output),
    detailMaterialBreakdown:
        detailMaterialBreakdown ?? this.detailMaterialBreakdown,
    reportVariant: reportVariant ?? this.reportVariant,
    rateAudit: rateAudit ?? this.rateAudit,
    batchAppliedPercent: clearBatch
        ? null
        : (batchAppliedPercent ?? this.batchAppliedPercent),
    batchAppliedMinQty: clearBatch
        ? null
        : (batchAppliedMinQty ?? this.batchAppliedMinQty),
    batchDiscountAmount: clearBatch
        ? Decimal.zero
        : (batchDiscountAmount ?? this.batchDiscountAmount),
    manualDiscountAmount: clearBatch
        ? Decimal.zero
        : (manualDiscountAmount ?? this.manualDiscountAmount),
    subtotalImpression: clearBatch
        ? Decimal.zero
        : (subtotalImpression ?? this.subtotalImpression),
    lotTotal: clearBatch ? Decimal.zero : (lotTotal ?? this.lotTotal),
    showsBatchLine: clearBatch
        ? false
        : (showsBatchLine ?? this.showsBatchLine),
    detailElectricCost: clearDetail
        ? null
        : (detailElectricCost ?? this.detailElectricCost),
    detailAmortizationCost: clearDetail
        ? null
        : (detailAmortizationCost ?? this.detailAmortizationCost),
    detailLaborCost: clearDetail
        ? null
        : (detailLaborCost ?? this.detailLaborCost),
    detailPostProcessCost: clearDetail
        ? null
        : (detailPostProcessCost ?? this.detailPostProcessCost),
    detailExtrasCost: clearDetail
        ? null
        : (detailExtrasCost ?? this.detailExtrasCost),
    detailBaseCost: clearDetail
        ? null
        : (detailBaseCost ?? this.detailBaseCost),
    detailFailureCost: clearDetail
        ? null
        : (detailFailureCost ?? this.detailFailureCost),
    detailMarkupCost: clearDetail
        ? null
        : (detailMarkupCost ?? this.detailMarkupCost),
    detailProfitAmount: clearDetail
        ? null
        : (detailProfitAmount ?? this.detailProfitAmount),
    detailTotalFinal: clearDetail
        ? null
        : (detailTotalFinal ?? this.detailTotalFinal),
    detailDiscountPct: clearDetail
        ? null
        : (detailDiscountPct ?? this.detailDiscountPct),
    extraLaborRate: extraLaborRate ?? this.extraLaborRate,
    extraPostProcessRate: extraPostProcessRate ?? this.extraPostProcessRate,
    extraFailureRate: extraFailureRate ?? this.extraFailureRate,
    extraMarkupOnMaterials:
        extraMarkupOnMaterials ?? this.extraMarkupOnMaterials,
    quantity: quantity ?? this.quantity,
    computeVersion: computeVersion ?? this.computeVersion,
    // v17: override per-cotizacion de los 3 campos de servicio. Pasar null
    // conserva el valor actual (pattern copyWith de Dart). Si el caller
    // quiere "borrar" el valor, debe pasar explicitamente `''`.
    modelingMode: modelingMode ?? this.modelingMode,
    modelingValue: modelingValue ?? this.modelingValue,
    postprocMode: postprocMode ?? this.postprocMode,
    postprocValue: postprocValue ?? this.postprocValue,
    extraCostMode: extraCostMode ?? this.extraCostMode,
    extraCostValue: extraCostValue ?? this.extraCostValue,
    extraCostLabel: extraCostLabel ?? this.extraCostLabel,
  );

  /// True si algun material tiene su propio switch de tiempo activado.
  /// Cuando es true, el tiempo global queda deshabilitado (exclusion mutua).
  bool get anyMaterialOwnTime => materials.any((m) => m.useOwnTime);

  /// Suma de los tiempos propios de los materiales que los tienen activados.
  /// Null si ninguno aporta tiempo (> 0).
  Decimal? get materialsOwnTimeDecimal {
    Decimal? acc;
    for (final m in materials) {
      final t = m.ownTimeDecimal;
      if (t == null) continue;
      acc = (acc ?? Decimal.zero) + t;
    }
    if (acc == null || acc <= Decimal.zero) return null;
    return acc;
  }

  /// True si hay tiempo disponible para calcular: tiempo global O suma de
  /// tiempos propios de materiales (exclusion mutua: si hay tiempo propio,
  /// el global se ignora).
  bool get hasTimeInput {
    if (anyMaterialOwnTime) return materialsOwnTimeMinutes > 0;
    return _parsePos(printHours) != null || _parsePos(printMinutes) != null;
  }

  /// Suma de los tiempos propios en MINUTOS enteros. 0 si ninguno aporta.
  ///
  /// Aritmetica entera (`h*60 + m`) para no arrastrar el error de
  /// [materialsOwnTimeDecimal] (ver [MaterialRow.ownTimeMinutes]).
  int get materialsOwnTimeMinutes {
    var acc = 0;
    for (final m in materials) {
      acc += m.ownTimeMinutes ?? 0;
    }
    return acc;
  }

  /// Tiempo total del form en MINUTOS enteros, con la misma precedencia que
  /// [totalHoursDecimal]: si algun material tiene tiempo propio, la suma de
  /// esos; si no, el tiempo global (`printHours*60 + printMinutes`).
  ///
  /// Null cuando no hay tiempo (> 0). Es la fuente para mostrar el total en
  /// h/min sin perder 1 minuto por truncamiento decimal.
  int? get totalMinutes {
    if (anyMaterialOwnTime) {
      final mins = materialsOwnTimeMinutes;
      return mins > 0 ? mins : null;
    }
    final h = CalculatorState.parseDecimal(printHours) ?? Decimal.zero;
    final m = CalculatorState.parseDecimal(printMinutes) ?? Decimal.zero;
    final mins = (h * Decimal.fromInt(60) + m).round().toBigInt().toInt();
    return mins > 0 ? mins : null;
  }

  /// True si el form completo es valido y se puede calcular output.
  bool get isValid {
    final hasTime = hasTimeInput;
    if (mode == CalculatorMode.express) {
      return _parsePos(weight) != null &&
          _parsePos(filamentPrice) != null &&
          hasTime;
      // filamentGrams optional — defaults to 1000 en notifier.
    }
    // Advanced: al menos 1 material valido + time requerido.
    return materials.any((m) => m.isValid) && hasTime;
  }

  /// Lista de campos requeridos que faltan (en orden del formulario, top-down).
  /// Usado por la UI para hint dinamico: "Completa X, Y y Z para ver la cotizacion".
  /// Lista vacia cuando [isValid] es true.
  ///
  /// Retorna keys (weight/price/time/material), no strings resueltos.
  /// Orden:
  ///   - express: weight, price, time (mismo orden visual en el form).
  ///   - advanced: material, time.
  List<String> get missingRequiredFields {
    if (isValid) return const <String>[];
    final missing = <String>[];
    final hasTime = hasTimeInput;
    if (mode == CalculatorMode.express) {
      if (_parsePos(weight) == null) missing.add('weight');
      if (_parsePos(filamentPrice) == null) missing.add('price');
      if (!hasTime) missing.add('time');
    } else {
      if (!materials.any((m) => m.isValid)) missing.add('material');
      if (!hasTime) missing.add('time');
    }
    return missing;
  }

  /// Total hours como Decimal (printHours + printMinutes/60).
  /// Minutos se convierten a fraccion de hora (33 min = 0.55h).
  ///
  /// Comportamiento:
  /// - Si AMBOS campos (horas y minutos) estan vacios o en 0, retorna null.
  /// - Si solo minutos tienen valor (horas vacio), trata horas como 0.
  /// - Si solo horas tienen valor, retorna ese valor directamente.
  /// - Si ambos tienen valor, retorna la suma.
  ///
  /// Esto es importante porque el usuario puede legitimamente querer cotizar
  /// una pieza que imprime en 45 min sin escribir "0" en horas. El form ya
  /// valida via [isValid] que al menos uno sea > 0, asi que aqui el
  /// resultado sera > 0 cuando [isValid] es true.
  ///
  /// **Exclusion mutua**: si algun material tiene `useOwnTime`, el tiempo
  /// global se ignora por completo y el total es la suma de los tiempos
  /// propios de los materiales. Si todos los switches estan OFF, se usa el
  /// tiempo global como siempre.
  Decimal? get totalHoursDecimal {
    if (anyMaterialOwnTime) return materialsOwnTimeDecimal;
    final h = parseDecimal(printHours) ?? Decimal.zero;
    final m = parseDecimal(printMinutes) ?? Decimal.zero;
    if (h <= Decimal.zero && m <= Decimal.zero) return null;
    if (m <= Decimal.zero) return h;
    // `scaleOnInfinitePrecision`: 59/60 = 0.9833... (precision infinita) y
    // Rational.toDecimal() LANZA AssertionError sin este parametro (decimal
    // ^3.x). Trunca a 12 decimales: 1 min = 1.67e-2h, 12dp sobra.
    if (h <= Decimal.zero) {
      return (m / Decimal.fromInt(60)).toDecimal(scaleOnInfinitePrecision: 12);
    }
    return h +
        (m / Decimal.fromInt(60)).toDecimal(scaleOnInfinitePrecision: 12);
  }

  Decimal? _parsePos(String raw) {
    final d = parseDecimal(raw);
    if (d == null || d <= Decimal.zero) return null;
    return d;
  }

  /// Parsea un string como [Decimal]. Acepta `.` o `,` como separador decimal
  /// y normaliza separadores de miles (es_BO o en-US).
  /// Retorna `null` si vacio, whitespace, o no parseable.
  static Decimal? parseDecimal(String raw) {
    final cleaned = normalizeDecimalString(raw.trim());
    if (cleaned.isEmpty) return null;
    try {
      return Decimal.parse(cleaned);
    } on FormatException {
      return null;
    }
  }

  /// Convierte horas decimales a MINUTOS enteros redondeando al minuto mas
  /// cercano (half-up).
  ///
  /// Usar esto en vez de `(horas * 60).toBigInt()`: `toBigInt()` trunca y
  /// convierte 6.166666666666 h en 369 min (6h09m) cuando el valor real es
  /// 6h10m. El redondeo recupera el minuto perdido por la representacion
  /// decimal de `m/60`.
  static int decimalHoursToMinutes(Decimal hours) =>
      (hours * Decimal.fromInt(60)).round().toBigInt().toInt();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CalculatorState) return false;
    return mode == other.mode &&
        printHours == other.printHours &&
        printMinutes == other.printMinutes &&
        discountPct == other.discountPct &&
        label == other.label &&
        filamentLabel == other.filamentLabel &&
        weight == other.weight &&
        filamentPrice == other.filamentPrice &&
        filamentGrams == other.filamentGrams &&
        _listEq(materials, other.materials) &&
        output == other.output &&
        _listEqBD(detailMaterialBreakdown, other.detailMaterialBreakdown) &&
        reportVariant == other.reportVariant &&
        rateAudit == other.rateAudit &&
        detailElectricCost == other.detailElectricCost &&
        detailAmortizationCost == other.detailAmortizationCost &&
        detailLaborCost == other.detailLaborCost &&
        detailPostProcessCost == other.detailPostProcessCost &&
        detailExtrasCost == other.detailExtrasCost &&
        detailBaseCost == other.detailBaseCost &&
        detailFailureCost == other.detailFailureCost &&
        detailMarkupCost == other.detailMarkupCost &&
        detailProfitAmount == other.detailProfitAmount &&
        detailTotalFinal == other.detailTotalFinal &&
        detailDiscountPct == other.detailDiscountPct &&
        extraLaborRate == other.extraLaborRate &&
        extraPostProcessRate == other.extraPostProcessRate &&
        extraFailureRate == other.extraFailureRate &&
        extraMarkupOnMaterials == other.extraMarkupOnMaterials &&
        quantity == other.quantity &&
        computeVersion == other.computeVersion &&
        batchAppliedPercent == other.batchAppliedPercent &&
        batchAppliedMinQty == other.batchAppliedMinQty &&
        batchDiscountAmount == other.batchDiscountAmount &&
        manualDiscountAmount == other.manualDiscountAmount &&
        subtotalImpression == other.subtotalImpression &&
        lotTotal == other.lotTotal &&
        modelingMode == other.modelingMode &&
        modelingValue == other.modelingValue &&
        postprocMode == other.postprocMode &&
        postprocValue == other.postprocValue &&
        extraCostMode == other.extraCostMode &&
        extraCostValue == other.extraCostValue &&
        extraCostLabel == other.extraCostLabel &&
        showsBatchLine == other.showsBatchLine;
  }

  static bool _listEq(List<MaterialRow> a, List<MaterialRow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqBD(
    List<MaterialCostBreakdown> a,
    List<MaterialCostBreakdown> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    mode,
    printHours,
    printMinutes,
    discountPct,
    label,
    filamentLabel,
    weight,
    filamentPrice,
    filamentGrams,
    Object.hashAll(materials),
    output,
    Object.hashAll(detailMaterialBreakdown),
    reportVariant,
    rateAudit,
    detailElectricCost,
    detailAmortizationCost,
    detailLaborCost,
    detailPostProcessCost,
    detailExtrasCost,
    detailBaseCost,
    detailFailureCost,
    detailMarkupCost,
    detailProfitAmount,
    detailTotalFinal,
    detailDiscountPct,
    extraLaborRate,
    extraPostProcessRate,
    extraFailureRate,
    extraMarkupOnMaterials,
    quantity,
    computeVersion,
    batchAppliedPercent,
    batchAppliedMinQty,
    batchDiscountAmount,
    manualDiscountAmount,
    subtotalImpression,
    lotTotal,
    showsBatchLine,
    modelingMode,
    modelingValue,
    postprocMode,
    postprocValue,
    extraCostMode,
    extraCostValue,
    extraCostLabel,
  ]);
}
