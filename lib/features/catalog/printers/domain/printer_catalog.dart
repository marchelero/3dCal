// ignore_for_file: public_member_api_docs
/// Catalogo estatico de impresoras: Marca -> Modelo -> consumo promedio (W).
///
/// Fuente: research web 2026-09-09 (specs oficiales + mediciones publicadas;
/// valores extrapolados marcados con [PrinterModelSpec.isEstimated]).
/// 29 marcas / 174 modelos. Capa domain: sin dependencias Flutter (testeable
/// puro, unit tests sin WidgetTester).
library;

class PrinterModelSpec {
  const PrinterModelSpec(
    this.name,
    this.watts, {
    this.isEstimated = false,
    this.usefulLifeHours,
  });

  /// Nombre exacto del modelo (ej: 'A1 Combo').
  final String name;

  /// Consumo promedio durante impresion activa (W).
  final int watts;

  /// `true` = valor extrapolado de una fuente similar (hint "estimado" en UI).
  final bool isEstimated;

  /// Vida util estimada en horas de impresion. `null` = sin estimacion.
  /// Basado en: consumer 5000-10000h, pro 10000-15000h, industrial 15000+h.
  final int? usefulLifeHours;
}

class PrinterBrandSpec {
  const PrinterBrandSpec(this.brand, this.models);

  /// Nombre de la marca (ej: 'Bambu Lab').
  final String brand;

  /// Modelos de la marca, ordenados alfabeticamente.
  final List<PrinterModelSpec> models;
}

/// Catalogo completo de impresoras (30 marcas / 200+ modelos).
///
/// Marcas ordenadas alfabeticamente; modelos alfabeticos por marca.
/// Watts: fuente oficial cuando disponible (Bambu Lab wiki, datasheets),
///resto extrapolado de reviews y specs publicadas.
/// Vida util (horas de impresion):
/// - Resin/SLA: 3000-5000h (limitado por LCD mono: 2000-3000h)
/// - FDM consumer: 5000-8000h (linear rails > v-slot wheels)
/// - FDM prosumer: 8000-12000h (Prusa, Bambu X1, Raise3D)
/// - FDM industrial: 12000-15000+h (Voron, H2D, XL)
const List<PrinterBrandSpec> kPrinterCatalog = [
  PrinterBrandSpec('Anet', [
    PrinterModelSpec('A8', 130, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('A8 Plus', 150, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('ET4', 130, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Anycubic', [
    PrinterModelSpec('Kobra', 130, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Kobra 2', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Kobra 2 Max', 200, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Kobra 3', 150, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Kobra 3 Combo', 160, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Kobra S1', 180, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Mega S', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Photon', 60, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon M3', 90, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon M3 Plus', 110, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon Mono 2', 55, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon Mono M5', 100, usefulLifeHours: 5000),
    PrinterModelSpec('Photon Mono M5s', 100, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Photon Mono X', 90, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon Mono X 6Ks', 90, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon Mono X2', 85, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Photon Ultra', 60, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Vyper', 150, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Artillery', [
    PrinterModelSpec('Genius', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Genius Pro', 75, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Hornet', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sidewinder X1', 160, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sidewinder X2', 165, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sidewinder X3 Plus', 200, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Sidewinder X4', 180, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Sidewinder X4 Plus', 220, isEstimated: true, usefulLifeHours: 6000),
  ]),
  PrinterBrandSpec('Bambu Lab', [
    // Oficiales de wiki.bambulab.com (PLA avg power)
    PrinterModelSpec('A1', 95, usefulLifeHours: 8000),
    PrinterModelSpec('A1 Combo', 100, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('A1 Mini', 80, usefulLifeHours: 8000),
    PrinterModelSpec('A1 Mini Combo', 85, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('A2L', 100, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('H2D', 330, usefulLifeHours: 12000),
    PrinterModelSpec('P1P', 110, usefulLifeHours: 8000),
    PrinterModelSpec('P1S', 105, usefulLifeHours: 8000),
    PrinterModelSpec('P2S', 120, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('X1', 105, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('X1 Carbon', 105, usefulLifeHours: 10000),
    PrinterModelSpec('X1E', 185, usefulLifeHours: 10000),
  ]),
  PrinterBrandSpec('Creality', [
    PrinterModelSpec('CR-10', 200, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('CR-10 Max', 260, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('CR-10 Smart', 220, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('CR-30', 180, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('CR-6 SE', 130, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3', 125, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 Neo', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 Pro', 130, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 S1', 140, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 S1 Plus', 170, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 S1 Pro', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 V2', 125, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 V2 Neo', 135, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-3 V3', 160, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Ender-3 V3 KE', 150, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Ender-3 V3 Plus', 350, usefulLifeHours: 6000),
    PrinterModelSpec('Ender-3 V3 SE', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-5', 140, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-5 S1', 170, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-5 Max', 200, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Ender-6', 160, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Halot Mage', 90, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Halot Mage Pro', 110, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Halot-One', 70, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('K1', 180, usefulLifeHours: 7000),
    PrinterModelSpec('K1 Max', 260, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('K1C', 190, usefulLifeHours: 7000),
    PrinterModelSpec('K2 Plus', 320, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('Sermoon D3', 200, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('EPAX', [
    PrinterModelSpec('X1 4K', 60, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('X1 8K', 60, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('X10', 100, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('X133', 120, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Elegoo', [
    PrinterModelSpec('Mars', 50, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Mars 2 Pro', 55, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Mars 3', 55, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Mars 3 Pro', 55, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Mars 4', 60, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Mars 4 Ultra', 60, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Mars 5', 60, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Mars 5 Ultra', 65, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Neptune 3 Max', 200, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Neptune 3 Plus', 170, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Neptune 3 Pro', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Neptune 4', 120, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Neptune 4 Max', 210, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Neptune 4 Plus', 180, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Neptune 4 Pro', 120, usefulLifeHours: 6000),
    PrinterModelSpec('Saturn', 90, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Saturn 2', 100, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Saturn 3 Ultra', 180, usefulLifeHours: 5000),
    PrinterModelSpec('Saturn 4', 110, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Saturn 4 Ultra', 144, usefulLifeHours: 5000),
    PrinterModelSpec('Saturn S', 95, isEstimated: true, usefulLifeHours: 4000),
  ]),
  PrinterBrandSpec('FLSun', [
    PrinterModelSpec('Q5', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('QQ-S Pro', 130, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Super Racer', 170, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('V400', 200, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('V400 Plus', 220, isEstimated: true, usefulLifeHours: 6000),
  ]),
  PrinterBrandSpec('Flashforge', [
    PrinterModelSpec('Adventurer 3', 100, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Adventurer 4', 110, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Adventurer 5M', 130, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Adventurer 5M Pro', 140, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Creator 3', 200, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('Creator 4', 220, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('Guider 2', 180, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Guider 3', 200, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('Guider 3 Plus', 230, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('Inventor IIS', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Photo 12', 85, isEstimated: true, usefulLifeHours: 4000),
  ]),
  PrinterBrandSpec('Geeetech', [
    PrinterModelSpec('A10M', 130, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('A20M', 150, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('A20T', 180, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Mizar S', 150, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Kingroon', [
    PrinterModelSpec('KLP1', 180, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('KP3S', 110, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('KP3S Pro V2', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('KP5L', 160, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Longer', [
    PrinterModelSpec('LK4', 110, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('LK4 Pro', 120, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('LK5 Pro', 160, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('LK5X', 170, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Orange 30', 40, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Orange 4K', 55, isEstimated: true, usefulLifeHours: 4000),
  ]),
  PrinterBrandSpec('MakerBot', [
    PrinterModelSpec('METHOD', 250, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('METHOD X', 270, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('Replicator+', 160, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Sketch', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sketch Large', 170, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Monoprice', [
    PrinterModelSpec('MP Select Mini', 90, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('MP Voxel', 140, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('MP10', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Maker Select Plus', 130, isEstimated: true, usefulLifeHours: 4000),
  ]),
  PrinterBrandSpec('Nova3D', [
    PrinterModelSpec('Bene4', 55, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Elfin 2', 60, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Whale 2', 120, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Peopoly', [
    PrinterModelSpec('Moai 200', 60, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Phenom', 130, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Phenom L', 160, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Phenom XXL', 200, isEstimated: true, usefulLifeHours: 6000),
  ]),
  PrinterBrandSpec('Phrozen', [
    PrinterModelSpec('Sonic Mega 8K', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sonic Mighty 4K', 80, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sonic Mighty 8K', 85, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sonic Mighty Revo', 95, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sonic Mini 4K', 45, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('Sonic Mini 8K', 48, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sonic Mini 8K S', 48, usefulLifeHours: 5000),
    PrinterModelSpec('Sonic XL 4K', 100, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Prusa', [
    PrinterModelSpec('CORE One', 160, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('MK3S+', 120, usefulLifeHours: 10000),
    PrinterModelSpec('MK4', 130, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('MK4S', 140, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('Mini', 85, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('XL', 250, isEstimated: true, usefulLifeHours: 12000),
  ]),
  PrinterBrandSpec('Qidi', [
    PrinterModelSpec('Plus 4', 250, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('Q1 Pro', 170, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('X-CF Pro', 230, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('X-Max', 240, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('X-Max 3', 270, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('X-Plus', 200, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('X-Plus 3', 230, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('X-Smart 3', 150, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('X-one2', 140, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Raise3D', [
    PrinterModelSpec('E2', 180, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('E2 CF', 200, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('Pro2', 230, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('Pro2 Plus', 250, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('Pro3', 260, isEstimated: true, usefulLifeHours: 12000),
    PrinterModelSpec('Pro3 Plus', 300, isEstimated: true, usefulLifeHours: 12000),
  ]),
  PrinterBrandSpec('Snapmaker', [
    PrinterModelSpec('J1', 180, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('J1s', 200, isEstimated: true, usefulLifeHours: 7000),
    PrinterModelSpec('Original Snapmaker', 80, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Snapmaker 2.0 A250', 170, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('Snapmaker 2.0 A350', 200, isEstimated: true, usefulLifeHours: 6000),
  ]),
  PrinterBrandSpec('Sovol', [
    PrinterModelSpec('SV01 Pro', 130, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('SV06', 120, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('SV06 Plus', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('SV07', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('SV07 Plus', 180, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('SV08', 230, isEstimated: true, usefulLifeHours: 6000),
    PrinterModelSpec('SV08 Plus', 280, isEstimated: true, usefulLifeHours: 6000),
  ]),
  PrinterBrandSpec('Tronxy', [
    PrinterModelSpec('X1', 150, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('X5SA', 200, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('X5SA Pro', 220, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('XY-2 Pro', 140, isEstimated: true, usefulLifeHours: 4000),
    PrinterModelSpec('XY-3 Pro', 160, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Two Trees', [
    PrinterModelSpec('Sapphire Plus', 170, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Sapphire Pro', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Bluer', 150, isEstimated: true, usefulLifeHours: 5000),
  ]),
  PrinterBrandSpec('Ultimaker', [
    PrinterModelSpec('Ultimaker 2+', 140, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('Ultimaker 3', 180, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('Ultimaker S3', 200, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('Ultimaker S5', 250, isEstimated: true, usefulLifeHours: 10000),
    PrinterModelSpec('Ultimaker S7', 300, isEstimated: true, usefulLifeHours: 10000),
  ]),
  PrinterBrandSpec('Uniz', [
    PrinterModelSpec('Slash 2', 90, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('ibee', 60, isEstimated: true, usefulLifeHours: 4000),
  ]),
  PrinterBrandSpec('Voron', [
    PrinterModelSpec('Trident (kit)', 350, usefulLifeHours: 12000),
    PrinterModelSpec('Voron 0.2 (kit)', 180, isEstimated: true, usefulLifeHours: 8000),
    PrinterModelSpec('Voron 2.4 (kit)', 350, usefulLifeHours: 12000),
    PrinterModelSpec('Voron 2.4 r2 (kit)', 360, isEstimated: true, usefulLifeHours: 12000),
  ]),
  PrinterBrandSpec('Voxelab', [
    PrinterModelSpec('Aquila', 125, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Aquila S2', 140, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Aquila X2', 125, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Proxima 8.9', 50, isEstimated: true, usefulLifeHours: 4000),
  ]),
  PrinterBrandSpec('Wanhao', [
    PrinterModelSpec('Duplicator 6', 150, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Duplicator 9', 180, isEstimated: true, usefulLifeHours: 5000),
    PrinterModelSpec('Duplicator i3 Plus', 130, isEstimated: true, usefulLifeHours: 4000),
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
