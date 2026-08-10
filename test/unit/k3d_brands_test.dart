// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/shared/widgets/k3d_brands.dart';

/// Marcas que venden filamento y NO fabrican impresoras (esperadas).
const _filamentOnly = <String>[
  'Amolen',
  'Eryone',
  'eSun',
  'Hatchbox',
  'Kingroon',
  'Overture',
  'Polymaker',
  'Prusament',
  'Sunlu',
];

/// Marcas que fabrican impresoras y NO venden filamento (esperadas).
const _printerOnly = <String>[
  'Artillery',
  'FLSun',
  'MakerBot',
  'Ultimaker',
  'Voron',
];

void main() {
  group('kKnownFilamentBrands', () {
    test('contiene exactamente 23 marcas (9 exclusive + 14 duales)', () {
      expect(kKnownFilamentBrands, hasLength(23));
    });

    test('contiene las marcas exclusive de filamento esperadas', () {
      expect(kKnownFilamentBrands, containsAll(_filamentOnly));
    });

    test('contiene las 14 marcas duales', () {
      expect(kKnownFilamentBrands, containsAll(kDualDomainBrands));
    });

    test('NO contiene marcas exclusive de impresoras '
        '(Artillery, FLSun, MakerBot, Ultimaker, Voron)', () {
      for (final printerOnly in _printerOnly) {
        expect(
          kKnownFilamentBrands,
          isNot(contains(printerOnly)),
          reason: '$printerOnly no debe estar en kKnownFilamentBrands',
        );
      }
    });

    test('esta ordenada alfabeticamente', () {
      final sorted = [...kKnownFilamentBrands]..sort();
      expect(kKnownFilamentBrands, equals(sorted));
    });
  });

  group('kKnownPrinterBrands', () {
    test('contiene exactamente 19 marcas (14 duales + 5 exclusive)', () {
      expect(kKnownPrinterBrands, hasLength(19));
    });

    test('contiene las marcas exclusive de impresoras esperadas', () {
      expect(kKnownPrinterBrands, containsAll(_printerOnly));
    });

    test('contiene las 14 marcas duales', () {
      expect(kKnownPrinterBrands, containsAll(kDualDomainBrands));
    });

    test('NO contiene marcas exclusive de filamentos', () {
      for (final filamentOnly in _filamentOnly) {
        expect(
          kKnownPrinterBrands,
          isNot(contains(filamentOnly)),
          reason: '$filamentOnly no debe estar en kKnownPrinterBrands',
        );
      }
    });

    test('esta ordenada alfabeticamente', () {
      final sorted = [...kKnownPrinterBrands]..sort();
      expect(kKnownPrinterBrands, equals(sorted));
    });
  });

  group('Relacion entre listas', () {
    test(
      'kDualDomainBrands es exactamente la interseccion de ambas listas',
      () {
        final intersection = kKnownFilamentBrands.toSet().intersection(
          kKnownPrinterBrands.toSet(),
        );
        expect(intersection, equals(kDualDomainBrands));
        expect(kDualDomainBrands, hasLength(14));
      },
    );

    test('cada dual esta en ambas listas', () {
      for (final dual in kDualDomainBrands) {
        expect(kKnownFilamentBrands, contains(dual));
        expect(kKnownPrinterBrands, contains(dual));
      }
    });
  });

  group('kBrandClassification', () {
    test('cada marca filament-only esta clasificada como filament', () {
      for (final brand in _filamentOnly) {
        expect(
          kBrandClassification[brand],
          equals(BrandDomain.filament),
          reason: '$brand deberia estar clasificada como filament',
        );
      }
    });

    test('cada marca printer-only esta clasificada como printer', () {
      for (final brand in _printerOnly) {
        expect(
          kBrandClassification[brand],
          equals(BrandDomain.printer),
          reason: '$brand deberia estar clasificada como printer',
        );
      }
    });

    test('cada dual esta clasificada como printer (dominio primario)', () {
      for (final dual in kDualDomainBrands) {
        expect(
          kBrandClassification[dual],
          equals(BrandDomain.printer),
          reason: '$dual es dual pero su dominio primario es impresora',
        );
      }
    });

    test(
      'kBrandClassification cubre exactamente la union de las dos listas (sin extras)',
      () {
        final union = kKnownFilamentBrands.toSet().union(
          kKnownPrinterBrands.toSet(),
        );
        expect(kBrandClassification.keys.toSet().difference(union), isEmpty);
        expect(union.difference(kBrandClassification.keys.toSet()), isEmpty);
      },
    );
  });
}
