// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/catalog/printers/domain/printer_catalog.dart';

void main() {
  group('kPrinterCatalog (integridad)', () {
    test('contiene exactamente 29 marcas y 174 modelos', () {
      expect(kPrinterCatalog, hasLength(29));
      final totalModels = kPrinterCatalog.fold<int>(
        0,
        (acc, b) => acc + b.models.length,
      );
      expect(totalModels, 174);
    });

    test('cada marca tiene >= 1 modelo y watts >= 0', () {
      for (final brand in kPrinterCatalog) {
        expect(brand.models, isNotEmpty, reason: '${brand.brand} sin modelos');
        for (final m in brand.models) {
          expect(
            m.watts,
            greaterThanOrEqualTo(0),
            reason: '${brand.brand} ${m.name} watts < 0',
          );
        }
      }
    });

    test('marcas ordenadas alfabeticamente', () {
      final names = catalogBrands();
      final sorted = [...names]..sort();
      expect(names, sorted);
    });

    test('modelos ordenados alfabeticamente dentro de cada marca', () {
      for (final brand in kPrinterCatalog) {
        final models = brand.models.map((m) => m.name).toList();
        final sorted = [...models]..sort();
        expect(models, sorted, reason: 'modelos de ${brand.brand}');
      }
    });
  });

  group('lookup helpers', () {
    test('findModel + catalogWattsFor Bambu A1 Combo = 100', () {
      final spec = findModel('Bambu Lab', 'A1 Combo');
      expect(spec, isNotNull);
      expect(spec!.watts, 100);
      expect(catalogWattsFor('Bambu Lab', 'A1 Combo'), 100);
    });

    test('findModel de marca inexistente o modelo inexistente -> null', () {
      expect(findModel('NoExiste', 'X'), isNull);
      expect(findModel('Bambu Lab', 'Modelo Falso'), isNull);
    });

    test('catalogModels Bambu Lab incluye los 9 modelos + A1 Combo', () {
      final models = catalogModels('Bambu Lab');
      expect(models.length, greaterThanOrEqualTo(9));
      expect(models, contains('A1 Combo'));
      for (final m in ['A1', 'A1 Mini', 'H2D', 'P1P', 'P1S', 'X1']) {
        expect(models, contains(m));
      }
    });

    test('catalogModels marca inexistente -> []', () {
      expect(catalogModels('NoExiste'), isEmpty);
    });

    test('catalogWattsFor marca inexistente -> null', () {
      expect(catalogWattsFor('NoExiste', 'X'), isNull);
    });

    test('valores ancla verificados', () {
      expect(catalogWattsFor('Creality', 'Ender-3'), 125);
      expect(catalogWattsFor('Prusa', 'MK3S+'), 120);
      expect(catalogWattsFor('Elegoo', 'Saturn 4 Ultra'), 144);
      expect(catalogWattsFor('Bambu Lab', 'H2D'), 330);
      expect(catalogWattsFor('Voron', 'Voron 2.4 (kit)'), 350);
    });
  });
}
