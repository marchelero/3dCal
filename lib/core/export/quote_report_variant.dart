/// Las 4 variantes del reporte de cotizacion.
///
/// Reemplazan al toggle binario `showDetail` que existia antes. La dimension
/// cubierta son dos ejes independientes:
///
/// - **Audience**: cliente (`client*`) vs. dueño (`internal*`). Las variantes
///   de cliente nunca exponen costos internos, tasas ni la impresora.
/// - **Complexity**: simple vs. `advanced` (multi-material, tiempos sueltos
///   por material, sumas y total final por capas).
///
/// El mismo enum gobierna los 3 canales de salida — imagen PNG, PDF e
/// impresion — para que nunca se desincronicen.
///
/// **Regla de uso**: en el codigo de render se usan los getters
/// ([isClientFacing], [isAdvanced], [showCostDetail], [showRateAudit]) en vez
/// de comparar contra casos concretos. Es la razon de existir del enum: si se
/// agrega una variante y no se actualizan los getters, el error es de
/// compilacion, no silencioso.
library;

/// Modo de salida del reporte.
///
/// No es un enum con valores default: el default es
/// [QuoteReportVariant.clientSimple] porque es el unico seguro para enviar a un
/// tercero sin revisarlo.
enum QuoteReportVariant {
  /// Para el cliente, cotizacion de un solo material (o multi-material sin
  /// tiempos propios). Muestra materiales (nombre + peso) y el bloque "Resumen
  /// de la cotizacion". Nunca muestra costos.
  clientSimple,

  /// Para el cliente, cotizacion avanzada: tabla por material con Peso y
  /// Tiempo, mas el bloque "Resumen de la cotizacion" completo. Nunca muestra
  /// costos.
  clientAdvanced,

  /// Uso interno. Desglose completo de costos + tabla de materiales con costo
  /// y fila TOTAL + cierre aritmetico + seccion "Parametros de calculo".
  internalDetail,

  /// Uso interno, cotizacion avanzada. Todo lo de [internalDetail] mas la
  /// tabla por material con costo unitario / costo de lote y el reparto de
  /// tiempos por material.
  internalAdvanced;

  /// Variantes seguras para enviar al cliente: sin costos, sin tasas, sin
  /// identificacion de la impresora.
  bool get isClientFacing =>
      this == QuoteReportVariant.clientSimple ||
      this == QuoteReportVariant.clientAdvanced;

  /// Variantes con tabla por material completa (multi-material / tiempos
  /// sueltos por material).
  bool get isAdvanced =>
      this == QuoteReportVariant.clientAdvanced ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes que exponen el desglose interno de costos.
  bool get showCostDetail =>
      this == QuoteReportVariant.internalDetail ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes que exponen la seccion "Parametros de calculo" (tasas,
  /// impresora, margenes).
  bool get showRateAudit =>
      this == QuoteReportVariant.internalDetail ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes cuya tabla de materiales incluye la columna de costo.
  /// [internalDetail] tambien la incluye aunque no sea `isAdvanced`: el
  /// desglose de costos ya esta, cobrar el costo por material no agrega
  /// exposicion nueva.
  bool get showsMaterialCost =>
      this == QuoteReportVariant.internalDetail ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes cuya tabla de materiales incluye la columna de tiempo por
  /// material (con el indicador de tiempo global cuando el material no tiene
  /// tiempo propio). Todas las internas la muestran: el desglose ya delata que
  /// es un documento de trabajo, asi que el tiempo no agrega exposicion.
  bool get showsMaterialTime =>
      this == QuoteReportVariant.clientAdvanced ||
      this == QuoteReportVariant.internalDetail ||
      this == QuoteReportVariant.internalAdvanced;

  /// Variantes que muestran el bloque "Resumen de la cotizacion" (tabla de
  /// sumas que junte peso / tiempo / cantidad / unitario / descuentos /
  /// total). Las internas ya exponen esa misma informacion via el desglose de
  /// costos, asi que alli se omite para no duplicar.
  bool get showsSummaryBlock => isClientFacing;

  /// Orden de las 4 variantes (de menor a mayor complejidad).
  static const List<QuoteReportVariant> uiOrder = <QuoteReportVariant>[
    QuoteReportVariant.clientSimple,
    QuoteReportVariant.clientAdvanced,
    QuoteReportVariant.internalDetail,
    QuoteReportVariant.internalAdvanced,
  ];

  /// Las 2 opciones que el usuario puede elegir en un modo dado.
  ///
  /// Mostrar las 4 siempre es ruido: en una cotizacion express no existe el
  /// desglose multi-material que justifica la variante "advanced", y en una
  /// avanzada la version simple oculta informacion que el usuario ya cargo.
  /// El modo de calculo decide el eje; la audiencia decide el nivel de detalle.
  static List<QuoteReportVariant> optionsForMode({required bool isAdvanced}) =>
      isAdvanced
      ? const [
          QuoteReportVariant.clientAdvanced,
          QuoteReportVariant.internalAdvanced,
        ]
      : const [
          QuoteReportVariant.clientSimple,
          QuoteReportVariant.internalDetail,
        ];

  /// Proyecta la variante al eje del modo indicado.
  ///
  /// Usar al cambiar de express a avanzado (o al revés): sin esto quedaria
  /// seleccionada una variante que el selector ya no muestra, y el usuario
  /// creeria estar viendo otra cosa.
  QuoteReportVariant forMode({required bool isAdvanced}) {
    if (isAdvanced == isAdvancedVariant) return this;
    return switch (this) {
      QuoteReportVariant.clientSimple => QuoteReportVariant.clientAdvanced,
      QuoteReportVariant.clientAdvanced => QuoteReportVariant.clientSimple,
      QuoteReportVariant.internalDetail => QuoteReportVariant.internalAdvanced,
      QuoteReportVariant.internalAdvanced => QuoteReportVariant.internalDetail,
    };
  }

  /// Si la variante pertenece al eje "advanced" (multi-material).
  bool get isAdvancedVariant =>
      this == QuoteReportVariant.clientAdvanced ||
      this == QuoteReportVariant.internalAdvanced;
}
