// ignore_for_file: public_member_api_docs
/// Presets destacados de impresora para el paso 2 del flujo `/setup`.
///
/// Lista curada de ~10 modelos populares (AC-04 sin grid de 208 modelos).
/// Cada par (brand, model) debe resolver contra `kPrinterCatalog`
/// (`findModel != null`) — el unit test `featured_printer_presets_test`
/// falla si el catálogo renombra un modelo (R10).
library;

import '../../../catalog/printers/domain/printer_catalog.dart';

/// Pares (marca, modelo) curados. Nombres EXACTOS del catálogo.
const List<(String, String)> kFeaturedPrinterPairs = [
  ('Bambu Lab', 'A1'),
  ('Bambu Lab', 'A1 Combo'),
  ('Bambu Lab', 'P1S'),
  ('Bambu Lab', 'X1 Carbon'),
  ('Creality', 'Ender-3 V3'),
  ('Creality', 'K1 Max'),
  ('Anycubic', 'Kobra 3'),
  ('Anycubic', 'Photon Mono M5'),
  ('Prusa', 'MK4S'),
  ('Elegoo', 'Neptune 4 Pro'),
];

/// Preset resuelto contra el catálogo: watts y vida útil ya poblados.
class FeaturedPrinterPreset {
  const FeaturedPrinterPreset({
    required this.brand,
    required this.model,
    required this.watts,
    this.usefulLifeHours,
  });

  final String brand;
  final String model;
  final int watts;
  final int? usefulLifeHours;
}

/// Resuelve [kFeaturedPrinterPairs] contra `kPrinterCatalog` devolviendo
/// watts + usefulLifeHours de cada modelo. Pares que no resuelvan se
/// descartan defensivamente (el unit test los detecta como regresión).
List<FeaturedPrinterPreset> featuredPresets() {
  final out = <FeaturedPrinterPreset>[];
  for (final (brand, model) in kFeaturedPrinterPairs) {
    final spec = findModel(brand, model);
    if (spec == null) continue;
    out.add(
      FeaturedPrinterPreset(
        brand: brand,
        model: model,
        watts: spec.watts,
        usefulLifeHours: spec.usefulLifeHours,
      ),
    );
  }
  return out;
}
