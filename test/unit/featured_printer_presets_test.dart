// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/catalog/printers/domain/printer_catalog.dart';
import 'package:tresdcal/features/onboarding/presentation/domain/featured_printer_presets.dart';

/// R10: cada preset curado debe resolver en `kPrinterCatalog` con el nombre
/// EXACTO; si el catálogo renombra un modelo, este test falla y hay que
/// actualizar `kFeaturedPrinterPairs`.
void main() {
  group('featured_printer_presets', () {
    test('la lista curada tiene entre 8 y 12 presets', () {
      expect(kFeaturedPrinterPairs.length, inInclusiveRange(8, 12));
    });

    test('todos los pares (brand, model) resuelven en kPrinterCatalog', () {
      for (final (brand, model) in kFeaturedPrinterPairs) {
        final spec = findModel(brand, model);
        expect(
          spec,
          isNotNull,
          reason: 'Preset ($brand, $model) no resuelve en kPrinterCatalog',
        );
        expect(
          spec!.watts,
          greaterThan(0),
          reason: 'Preset ($brand, $model) tiene watts inválidos',
        );
      }
    });

    test('featuredPresets() resuelve watts + usefulLifeHours del catálogo', () {
      final presets = featuredPresets();
      expect(presets, hasLength(kFeaturedPrinterPairs.length));
      for (final p in presets) {
        final spec = findModel(p.brand, p.model)!;
        expect(p.watts, spec.watts);
        expect(p.usefulLifeHours, spec.usefulLifeHours);
        // Todos los pares curados tienen vida útil en el catálogo.
        expect(p.usefulLifeHours, isNotNull);
      }
    });
  });
}
