/// Clasificacion de marcas del ecosistema 3D por dominio.
///
/// Una marca puede vivir en **ambos** dominios cuando en la realidad
/// vende filamento Y fabrica impresoras (ej: Creality, Bambu Lab, Elegoo).
/// Las marcas duales estan listadas en las dos listas y ademas en
/// [kDualDomainBrands]. Para ampliar una lista, agregar al final del array
/// correspondiente y, si corresponde, al mapa [kBrandClassification] y a
/// [kDualDomainBrands].
enum BrandDomain {
  /// Marcas de filamentos (PLA, PETG, ABS, TPU, ...).
  filament,

  /// Marcas de impresoras (FDM, resina, kits DIY, ...).
  printer,
}

/// Marcas conocidas de filamentos. Ordenadas alfabeticamente.
///
/// Lista cerrada (23 entradas): 9 marcas exclusive de filamento + 14 duales
/// de [kDualDomainBrands].
const List<String> kKnownFilamentBrands = [
  'Amolen',
  'Anycubic',
  'Bambu Lab',
  'Creality',
  'Elegoo',
  'Eryone',
  'Flashforge',
  'Geeetech',
  'Hatchbox',
  'Kingroon',
  'Longer',
  'Overture',
  'Polymaker',
  'Prusa',
  'Prusament',
  'Qidi',
  'Raise3D',
  'Snapmaker',
  'Sovol',
  'Sunlu',
  'Tronxy',
  'Voxelab',
  'eSun',
];

/// Marcas conocidas de impresoras. Ordenadas alfabeticamente.
///
/// Lista cerrada (19 entradas): 14 duales de [kDualDomainBrands] + 5 marcas
/// exclusive de impresoras.
const List<String> kKnownPrinterBrands = [
  'Anycubic',
  'Artillery',
  'Bambu Lab',
  'Creality',
  'Elegoo',
  'FLSun',
  'Flashforge',
  'Geeetech',
  'Longer',
  'MakerBot',
  'Prusa',
  'Qidi',
  'Raise3D',
  'Snapmaker',
  'Sovol',
  'Tronxy',
  'Ultimaker',
  'Voron',
  'Voxelab',
];

/// Marcas que existen en AMBOS dominios (venden filamento y fabrican
/// impresoras). Es la interseccion exacta de las dos listas (14 entradas).
const Set<String> kDualDomainBrands = {
  'Anycubic',
  'Bambu Lab',
  'Creality',
  'Elegoo',
  'Flashforge',
  'Geeetech',
  'Longer',
  'Prusa',
  'Qidi',
  'Raise3D',
  'Snapmaker',
  'Sovol',
  'Tronxy',
  'Voxelab',
};

/// Clasificacion auditable de cada marca conocida por su dominio PRIMARIO.
///
/// Las marcas duales ([kDualDomainBrands]) figuran con su dominio primario
/// (donde son mas conocidas, para este catalogo: impresoras). Usada por
/// tests y por tooling futuro (CLI, export). En runtime el widget
/// [BrandSelectorField] consume las listas, no este mapa.
const Map<String, BrandDomain> kBrandClassification = {
  // Filamentos (exclusive de filamento)
  'Amolen': BrandDomain.filament,
  'Eryone': BrandDomain.filament,
  'eSun': BrandDomain.filament,
  'Hatchbox': BrandDomain.filament,
  'Kingroon': BrandDomain.filament,
  'Overture': BrandDomain.filament,
  'Polymaker': BrandDomain.filament,
  'Prusament': BrandDomain.filament,
  'Sunlu': BrandDomain.filament,
  // Impresoras (incluye las 14 duales, cuyo primario es impresora)
  'Anycubic': BrandDomain.printer,
  'Artillery': BrandDomain.printer,
  'Bambu Lab': BrandDomain.printer,
  'Creality': BrandDomain.printer,
  'Elegoo': BrandDomain.printer,
  'Flashforge': BrandDomain.printer,
  'FLSun': BrandDomain.printer,
  'Geeetech': BrandDomain.printer,
  'Longer': BrandDomain.printer,
  'MakerBot': BrandDomain.printer,
  'Prusa': BrandDomain.printer,
  'Qidi': BrandDomain.printer,
  'Raise3D': BrandDomain.printer,
  'Snapmaker': BrandDomain.printer,
  'Sovol': BrandDomain.printer,
  'Tronxy': BrandDomain.printer,
  'Ultimaker': BrandDomain.printer,
  'Voxelab': BrandDomain.printer,
  'Voron': BrandDomain.printer,
};
