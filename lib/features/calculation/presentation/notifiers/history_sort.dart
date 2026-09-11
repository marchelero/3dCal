// ignore_for_file: public_member_api_docs

/// Orden de la lista del historial (PRD 2026-09-11).
///
/// [dateNewest] es el orden por defecto (mas recientes primero), identico
/// al de `CalculationRepository.listItems` — cambiar el orden NO es un
/// filtro (no afecta el contador free ni la barra de resumen).
///
/// El orden por precio usa el TOTAL EFECTIVO de cada cotizacion
/// (`totalPriceSnapshot * quantity`, clamp quantity < 1 a 1), el mismo
/// criterio que el card del historial.
enum HistorySort {
  /// Mas recientes primero (default).
  dateNewest,

  /// Mas antiguos primero.
  dateOldest,

  /// Mayor total efectivo primero.
  priceHigh,

  /// Menor total efectivo primero.
  priceLow,

  /// Clientes A-Z (case-insensitive).
  clientAz,
}
