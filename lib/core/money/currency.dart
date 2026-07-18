/// Monedas del mundo para display de precios.
///
/// La app guarda los valores numericamente sin conversion de moneda.
/// La moneda seleccionada solo afecta el simbolo que se muestra
/// (Bs., $, EUR, etc.) y el nombre de la moneda en la UI.
library;

/// Moneda del mundo con codigo ISO 4217, simbolo y nombre en espanol.
class WorldCurrency {
  const WorldCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  /// Codigo ISO 4217: USD, BOB, EUR, GBP...
  final String code;

  /// Simbolo monetario visible: $, Bs., €, £...
  final String symbol;

  /// Nombre en espanol: Dolar estadounidense, Boliviano...
  final String name;

  // ─── Predefinidas ──────────────────────────────────

  static const usd = WorldCurrency(
    code: 'USD',
    symbol: r'$',
    name: 'Dolar estadounidense',
  );

  static const bob = WorldCurrency(
    code: 'BOB',
    symbol: 'Bs.',
    name: 'Boliviano',
  );

  static const eur = WorldCurrency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
  );

  static const gbp = WorldCurrency(
    code: 'GBP',
    symbol: '£',
    name: 'Libra esterlina',
  );

  static const jpy = WorldCurrency(
    code: 'JPY',
    symbol: '¥',
    name: 'Yen japones',
  );

  static const cny = WorldCurrency(
    code: 'CNY',
    symbol: '¥',
    name: 'Yuan chino',
  );

  static const brl = WorldCurrency(
    code: 'BRL',
    symbol: 'R\$',
    name: 'Real brasileno',
  );

  static const ars = WorldCurrency(
    code: 'ARS',
    symbol: r'$',
    name: 'Peso argentino',
  );

  static const clp = WorldCurrency(
    code: 'CLP',
    symbol: r'$',
    name: 'Peso chileno',
  );

  static const cop = WorldCurrency(
    code: 'COP',
    symbol: r'$',
    name: 'Peso colombiano',
  );

  static const pen = WorldCurrency(
    code: 'PEN',
    symbol: 'S/',
    name: 'Sol peruano',
  );

  static const mxn = WorldCurrency(
    code: 'MXN',
    symbol: r'$',
    name: 'Peso mexicano',
  );

  static const chf = WorldCurrency(
    code: 'CHF',
    symbol: 'Fr.',
    name: 'Franco suizo',
  );

  static const cad = WorldCurrency(
    code: 'CAD',
    symbol: r'$',
    name: 'Dolar canadiense',
  );

  static const aud = WorldCurrency(
    code: 'AUD',
    symbol: r'$',
    name: 'Dolar australiano',
  );

  // ─── Lista completa ────────────────────────────────

  /// Todas las monedas disponibles en orden alfabetico por codigo.
  static const List<WorldCurrency> all = [
    ars,
    aud,
    bob,
    brl,
    cad,
    chf,
    clp,
    cny,
    cop,
    eur,
    gbp,
    jpy,
    mxn,
    pen,
    usd,
  ];

  /// Busca por codigo ISO. Devuelve USD si no encuentra.
  static WorldCurrency fromCode(String code) {
    // Match exacto.
    for (final c in all) {
      if (c.code == code) return c;
    }
    return usd;
  }
}
