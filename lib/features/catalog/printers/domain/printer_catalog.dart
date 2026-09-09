// ignore_for_file: public_member_api_docs
/// Catalogo estatico de impresoras: Marca -> Modelo -> consumo promedio (W).
///
/// Fuente: research web 2026-09-09 (specs oficiales + mediciones publicadas;
/// valores extrapolados marcados con [PrinterModelSpec.isEstimated]).
/// 29 marcas / 174 modelos. Capa domain: sin dependencias Flutter (testeable
/// puro, unit tests sin WidgetTester).
library;

class PrinterModelSpec {
  const PrinterModelSpec(this.name, this.watts, {this.isEstimated = false});

  /// Nombre exacto del modelo (ej: 'A1 Combo').
  final String name;

  /// Consumo promedio durante impresion activa (W).
  final int watts;

  /// `true` = valor extrapolado de una fuente similar (hint "estimado" en UI).
  final bool isEstimated;
}

class PrinterBrandSpec {
  const PrinterBrandSpec(this.brand, this.models);

  /// Nombre de la marca (ej: 'Bambu Lab').
  final String brand;

  /// Modelos de la marca, ordenados alfabeticamente.
  final List<PrinterModelSpec> models;
}

/// Catalogo completo de impresoras (29 marcas / 174 modelos).
///
/// Marcas ordenadas alfabeticamente; modelos alfabeticos por marca.
const List<PrinterBrandSpec> kPrinterCatalog = [
  PrinterBrandSpec('Anet', [
    PrinterModelSpec('A8', 130, isEstimated: true),
    PrinterModelSpec('A8 Plus', 150, isEstimated: true),
    PrinterModelSpec('ET4', 130, isEstimated: true),
  ]),
  PrinterBrandSpec('Anycubic', [
    PrinterModelSpec('Kobra', 130, isEstimated: true),
    PrinterModelSpec('Kobra 2', 135, isEstimated: true),
    PrinterModelSpec('Kobra 2 Max', 200, isEstimated: true),
    PrinterModelSpec('Kobra 3', 150, isEstimated: true),
    PrinterModelSpec('Mega S', 120, isEstimated: true),
    PrinterModelSpec('Photon', 60, isEstimated: true),
    PrinterModelSpec('Photon M3', 90, isEstimated: true),
    PrinterModelSpec('Photon M3 Plus', 110, isEstimated: true),
    PrinterModelSpec('Photon Mono 2', 55, isEstimated: true),
    PrinterModelSpec('Photon Mono M5', 100),
    PrinterModelSpec('Photon Mono M5s', 100, isEstimated: true),
    PrinterModelSpec('Photon Mono X', 90, isEstimated: true),
    PrinterModelSpec('Photon Mono X 6Ks', 90, isEstimated: true),
    PrinterModelSpec('Vyper', 150, isEstimated: true),
  ]),
  PrinterBrandSpec('Artillery', [
    PrinterModelSpec('Genius', 120, isEstimated: true),
    PrinterModelSpec('Genius Pro', 130, isEstimated: true),
    PrinterModelSpec('Sidewinder X1', 160, isEstimated: true),
    PrinterModelSpec('Sidewinder X2', 165, isEstimated: true),
    PrinterModelSpec('Sidewinder X3 Plus', 200, isEstimated: true),
  ]),
  PrinterBrandSpec('Bambu Lab', [
    PrinterModelSpec('A1', 95),
    PrinterModelSpec('A1 Combo', 100, isEstimated: true),
    PrinterModelSpec('A1 Mini', 80),
    PrinterModelSpec('H2D', 330),
    PrinterModelSpec('P1P', 110),
    PrinterModelSpec('P1S', 110),
    PrinterModelSpec('X1', 105, isEstimated: true),
    PrinterModelSpec('X1 Carbon', 105),
    PrinterModelSpec('X1E', 185),
  ]),
  PrinterBrandSpec('Creality', [
    PrinterModelSpec('CR-10', 200, isEstimated: true),
    PrinterModelSpec('CR-10 Max', 260, isEstimated: true),
    PrinterModelSpec('CR-10 Smart', 220, isEstimated: true),
    PrinterModelSpec('CR-30', 180, isEstimated: true),
    PrinterModelSpec('CR-6 SE', 130, isEstimated: true),
    PrinterModelSpec('Ender-3', 125),
    PrinterModelSpec('Ender-3 Neo', 120, isEstimated: true),
    PrinterModelSpec('Ender-3 Pro', 130, isEstimated: true),
    PrinterModelSpec('Ender-3 S1', 140, isEstimated: true),
    PrinterModelSpec('Ender-3 S1 Plus', 170, isEstimated: true),
    PrinterModelSpec('Ender-3 S1 Pro', 150, isEstimated: true),
    PrinterModelSpec('Ender-3 V2', 125, isEstimated: true),
    PrinterModelSpec('Ender-3 V3', 160, isEstimated: true),
    PrinterModelSpec('Ender-3 V3 KE', 150, isEstimated: true),
    PrinterModelSpec('Ender-3 V3 Plus', 200, isEstimated: true),
    PrinterModelSpec('Ender-3 V3 SE', 120, isEstimated: true),
    PrinterModelSpec('Ender-5', 140, isEstimated: true),
    PrinterModelSpec('Ender-5 S1', 170, isEstimated: true),
    PrinterModelSpec('Ender-6', 160, isEstimated: true),
    PrinterModelSpec('Halot Mage', 90, isEstimated: true),
    PrinterModelSpec('Halot Mage Pro', 110, isEstimated: true),
    PrinterModelSpec('Halot-One', 70, isEstimated: true),
    PrinterModelSpec('K1', 180, isEstimated: true),
    PrinterModelSpec('K1 Max', 260, isEstimated: true),
    PrinterModelSpec('K1C', 190, isEstimated: true),
    PrinterModelSpec('K2 Plus', 320, isEstimated: true),
  ]),
  PrinterBrandSpec('EPAX', [
    PrinterModelSpec('X1 4K', 60, isEstimated: true),
    PrinterModelSpec('X1 8K', 60, isEstimated: true),
    PrinterModelSpec('X10', 100, isEstimated: true),
    PrinterModelSpec('X133', 120, isEstimated: true),
  ]),
  PrinterBrandSpec('Elegoo', [
    PrinterModelSpec('Mars', 50, isEstimated: true),
    PrinterModelSpec('Mars 2 Pro', 55, isEstimated: true),
    PrinterModelSpec('Mars 3', 55, isEstimated: true),
    PrinterModelSpec('Mars 3 Pro', 55, isEstimated: true),
    PrinterModelSpec('Mars 4', 60, isEstimated: true),
    PrinterModelSpec('Mars 4 Ultra', 60, isEstimated: true),
    PrinterModelSpec('Mars 5', 60, isEstimated: true),
    PrinterModelSpec('Mars 5 Ultra', 65, isEstimated: true),
    PrinterModelSpec('Neptune 3 Max', 200, isEstimated: true),
    PrinterModelSpec('Neptune 3 Plus', 170, isEstimated: true),
    PrinterModelSpec('Neptune 3 Pro', 120, isEstimated: true),
    PrinterModelSpec('Neptune 4', 120, isEstimated: true),
    PrinterModelSpec('Neptune 4 Max', 210, isEstimated: true),
    PrinterModelSpec('Neptune 4 Plus', 180, isEstimated: true),
    PrinterModelSpec('Neptune 4 Pro', 120),
    PrinterModelSpec('Saturn', 90, isEstimated: true),
    PrinterModelSpec('Saturn 2', 100, isEstimated: true),
    PrinterModelSpec('Saturn 3 Ultra', 180),
    PrinterModelSpec('Saturn 4', 110, isEstimated: true),
    PrinterModelSpec('Saturn 4 Ultra', 144),
    PrinterModelSpec('Saturn S', 95, isEstimated: true),
  ]),
  PrinterBrandSpec('FLSun', [
    PrinterModelSpec('Q5', 150, isEstimated: true),
    PrinterModelSpec('QQ-S Pro', 130, isEstimated: true),
    PrinterModelSpec('Super Racer', 170, isEstimated: true),
    PrinterModelSpec('V400', 200, isEstimated: true),
  ]),
  PrinterBrandSpec('Flashforge', [
    PrinterModelSpec('Adventurer 3', 100, isEstimated: true),
    PrinterModelSpec('Adventurer 4', 110, isEstimated: true),
    PrinterModelSpec('Adventurer 5M', 130, isEstimated: true),
    PrinterModelSpec('Adventurer 5M Pro', 140, isEstimated: true),
    PrinterModelSpec('Creator 3', 200, isEstimated: true),
    PrinterModelSpec('Creator 4', 220, isEstimated: true),
    PrinterModelSpec('Guider 2', 180, isEstimated: true),
    PrinterModelSpec('Guider 3', 200, isEstimated: true),
  ]),
  PrinterBrandSpec('Geeetech', [
    PrinterModelSpec('A10M', 130, isEstimated: true),
    PrinterModelSpec('A20M', 150, isEstimated: true),
    PrinterModelSpec('A20T', 180, isEstimated: true),
  ]),
  PrinterBrandSpec('Kingroon', [
    PrinterModelSpec('KLP1', 180, isEstimated: true),
    PrinterModelSpec('KP3S', 110, isEstimated: true),
    PrinterModelSpec('KP3S Pro V2', 120, isEstimated: true),
  ]),
  PrinterBrandSpec('Longer', [
    PrinterModelSpec('LK4', 110, isEstimated: true),
    PrinterModelSpec('LK4 Pro', 120, isEstimated: true),
    PrinterModelSpec('LK5 Pro', 160, isEstimated: true),
    PrinterModelSpec('Orange 30', 40, isEstimated: true),
    PrinterModelSpec('Orange 4K', 55, isEstimated: true),
  ]),
  PrinterBrandSpec('MakerBot', [
    PrinterModelSpec('METHOD', 250, isEstimated: true),
    PrinterModelSpec('METHOD X', 270, isEstimated: true),
    PrinterModelSpec('Replicator+', 160, isEstimated: true),
    PrinterModelSpec('Sketch', 150, isEstimated: true),
  ]),
  PrinterBrandSpec('Monoprice', [
    PrinterModelSpec('MP Select Mini', 90, isEstimated: true),
    PrinterModelSpec('MP Voxel', 140, isEstimated: true),
    PrinterModelSpec('MP10', 150, isEstimated: true),
    PrinterModelSpec('Maker Select Plus', 130, isEstimated: true),
  ]),
  PrinterBrandSpec('Nova3D', [
    PrinterModelSpec('Bene4', 55, isEstimated: true),
    PrinterModelSpec('Elfin 2', 60, isEstimated: true),
    PrinterModelSpec('Whale 2', 120, isEstimated: true),
  ]),
  PrinterBrandSpec('Peopoly', [
    PrinterModelSpec('Moai 200', 60, isEstimated: true),
    PrinterModelSpec('Phenom', 130, isEstimated: true),
    PrinterModelSpec('Phenom L', 160, isEstimated: true),
  ]),
  PrinterBrandSpec('Phrozen', [
    PrinterModelSpec('Sonic Mega 8K', 120, isEstimated: true),
    PrinterModelSpec('Sonic Mighty 4K', 80, isEstimated: true),
    PrinterModelSpec('Sonic Mighty 8K', 85, isEstimated: true),
    PrinterModelSpec('Sonic Mini 4K', 45, isEstimated: true),
    PrinterModelSpec('Sonic Mini 8K', 48, isEstimated: true),
    PrinterModelSpec('Sonic Mini 8K S', 48),
    PrinterModelSpec('Sonic XL 4K', 100, isEstimated: true),
  ]),
  PrinterBrandSpec('Prusa', [
    PrinterModelSpec('CORE One', 160, isEstimated: true),
    PrinterModelSpec('MK3S+', 120),
    PrinterModelSpec('MK4', 130, isEstimated: true),
    PrinterModelSpec('Mini', 85, isEstimated: true),
    PrinterModelSpec('XL', 250, isEstimated: true),
  ]),
  PrinterBrandSpec('Qidi', [
    PrinterModelSpec('Plus 4', 250, isEstimated: true),
    PrinterModelSpec('Q1 Pro', 170, isEstimated: true),
    PrinterModelSpec('X-CF Pro', 230, isEstimated: true),
    PrinterModelSpec('X-Max', 240, isEstimated: true),
    PrinterModelSpec('X-Max 3', 270, isEstimated: true),
    PrinterModelSpec('X-Plus', 200, isEstimated: true),
    PrinterModelSpec('X-Plus 3', 230, isEstimated: true),
    PrinterModelSpec('X-one2', 140, isEstimated: true),
  ]),
  PrinterBrandSpec('Raise3D', [
    PrinterModelSpec('E2', 180, isEstimated: true),
    PrinterModelSpec('Pro2', 230, isEstimated: true),
    PrinterModelSpec('Pro2 Plus', 250, isEstimated: true),
    PrinterModelSpec('Pro3', 260, isEstimated: true),
  ]),
  PrinterBrandSpec('Snapmaker', [
    PrinterModelSpec('J1', 180, isEstimated: true),
    PrinterModelSpec('Original Snapmaker', 80, isEstimated: true),
    PrinterModelSpec('Snapmaker 2.0 A250', 170, isEstimated: true),
    PrinterModelSpec('Snapmaker 2.0 A350', 200, isEstimated: true),
  ]),
  PrinterBrandSpec('Sovol', [
    PrinterModelSpec('SV01 Pro', 130, isEstimated: true),
    PrinterModelSpec('SV06', 120, isEstimated: true),
    PrinterModelSpec('SV06 Plus', 150, isEstimated: true),
    PrinterModelSpec('SV07', 150, isEstimated: true),
    PrinterModelSpec('SV08', 230, isEstimated: true),
  ]),
  PrinterBrandSpec('Tronxy', [
    PrinterModelSpec('X1', 150, isEstimated: true),
    PrinterModelSpec('X5SA', 200, isEstimated: true),
    PrinterModelSpec('X5SA Pro', 220, isEstimated: true),
    PrinterModelSpec('XY-2 Pro', 140, isEstimated: true),
  ]),
  PrinterBrandSpec('Two Trees', [
    PrinterModelSpec('Sapphire Plus', 170, isEstimated: true),
    PrinterModelSpec('Sapphire Pro', 150, isEstimated: true),
  ]),
  PrinterBrandSpec('Ultimaker', [
    PrinterModelSpec('Ultimaker 2+', 140, isEstimated: true),
    PrinterModelSpec('Ultimaker 3', 180, isEstimated: true),
    PrinterModelSpec('Ultimaker S3', 200, isEstimated: true),
    PrinterModelSpec('Ultimaker S5', 250, isEstimated: true),
  ]),
  PrinterBrandSpec('Uniz', [
    PrinterModelSpec('Slash 2', 90, isEstimated: true),
    PrinterModelSpec('ibee', 60, isEstimated: true),
  ]),
  PrinterBrandSpec('Voron', [
    PrinterModelSpec('Trident (kit)', 350),
    PrinterModelSpec('Voron 0.2 (kit)', 180, isEstimated: true),
    PrinterModelSpec('Voron 2.4 (kit)', 350),
  ]),
  PrinterBrandSpec('Voxelab', [
    PrinterModelSpec('Aquila', 125, isEstimated: true),
    PrinterModelSpec('Aquila S2', 140, isEstimated: true),
    PrinterModelSpec('Aquila X2', 125, isEstimated: true),
    PrinterModelSpec('Proxima 8.9', 50, isEstimated: true),
  ]),
  PrinterBrandSpec('Wanhao', [
    PrinterModelSpec('Duplicator 6', 150, isEstimated: true),
    PrinterModelSpec('Duplicator 9', 180, isEstimated: true),
    PrinterModelSpec('Duplicator i3 Plus', 130, isEstimated: true),
  ]),
];

/// Retorna la [PrinterBrandSpec] de [brand], o `null` si no esta en el
/// catalogo.
PrinterBrandSpec? findBrand(String brand) {
  for (final spec in kPrinterCatalog) {
    if (spec.brand == brand) return spec;
  }
  return null;
}

/// Retorna la [PrinterModelSpec] de [model] en [brand], o `null` si la marca
/// no existe o el modelo no esta en el catalogo.
PrinterModelSpec? findModel(String brand, String model) {
  final brandSpec = findBrand(brand);
  if (brandSpec == null) return null;
  for (final modelSpec in brandSpec.models) {
    if (modelSpec.name == model) return modelSpec;
  }
  return null;
}

/// Consumo promedio en watts de [model] en [brand], o `null` si no existe.
int? catalogWattsFor(String brand, String model) {
  return findModel(brand, model)?.watts;
}

/// Marcas del catalogo, ordenadas alfabeticamente.
List<String> catalogBrands() =>
    kPrinterCatalog.map((b) => b.brand).toList(growable: false);

/// Modelos de [brand] ordenados alfabeticamente, o `[]` si la marca no
/// existe en el catalogo.
List<String> catalogModels(String brand) {
  final spec = findBrand(brand);
  if (spec == null) return const [];
  return spec.models.map((m) => m.name).toList(growable: false);
}
