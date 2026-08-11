// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/backup/backup_models.dart';

void main() {
  group('BackupData.validate', () {
    Map<String, dynamic> validJson({int schemaVersion = 5}) => {
      'version': kBackupFormatVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': '2026-08-11T12:00:00.000Z',
      'appName': kBackupAppName,
      'filaments': <Map<String, dynamic>>[
        {
          'id': 1,
          'name': 'PLA',
          'brand': null,
          'pricePerBobbin': 150.0,
          'gramsPerBobbin': 1000.0,
          'isDefault': true,
          'createdAt': '2026-08-11T12:00:00.000Z',
        },
      ],
      'printers': <Map<String, dynamic>>[
        {
          'id': 1,
          'brand': null,
          'name': 'Ender 3',
          'averageWatts': 120,
          'isDefault': true,
          'createdAt': '2026-08-11T12:00:00.000Z',
        },
      ],
      'calculations': <Map<String, dynamic>>[
        {
          'id': 1,
          'createdAt': '2026-08-11T12:00:00.000Z',
          'pieceName': 'Vaso',
          'clientName': null,
          'printerId': 1,
          'printerNameSnapshot': 'Ender 3',
          'printerWattsSnapshot': 120,
          'totalHours': 4.0,
          'printMinutes': 240,
          'discountPercentage': 0,
          'kwhRateSnapshot': 0.5,
          'profitBaseSnapshot': 30,
          'isSold': false,
          'materialCostSnapshot': 12.5,
          'electricCostSnapshot': 2.4,
          'laborCostSnapshot': 20.0,
          'postProcessCostSnapshot': 0,
          'baseCostSnapshot': 34.9,
          'failureCostSnapshot': 0,
          'markupCostSnapshot': 0,
          'profitAmountSnapshot': 10.47,
          'minimumChargeAppliedSnapshot': 0,
          'effectiveTotalSnapshot': 45.37,
          'totalPriceSnapshot': 45.37,
          'laborRateSnapshot': 5,
          'postProcessRateSnapshot': 0,
          'failureRateSnapshot': 5,
          'minimumChargeSnapshot': 0,
          'markupOnMaterialsSnapshot': 0,
        },
      ],
      'calculationMaterials': <Map<String, dynamic>>[
        {
          'id': 1,
          'calculationId': 1,
          'filamentId': 1,
          'label': 'PLA',
          'weightGrams': 83.0,
          'pricePerBobbinSnapshot': 150.0,
          'gramsPerBobbinSnapshot': 1000.0,
        },
      ],
      'settings': <Map<String, dynamic>>[
        {
          'key': 'currencyCode',
          'value': 'BOB',
          'updatedAt': '2026-08-11T12:00:00.000Z',
        },
      ],
    };

    Map<String, dynamic> firstRow(Map<String, dynamic> json, String key) {
      return (json[key] as List).cast<Map<String, dynamic>>().first;
    }

    test('backup valido pasa la validacion', () {
      expect(BackupData.fromJson(validJson()).validate(), isNull);
    });

    test('timestamps Unix en milisegundos son aceptados', () {
      final json = validJson();
      const timestamp = 1786475972000;
      firstRow(json, 'filaments')['createdAt'] = timestamp;
      firstRow(json, 'printers')['createdAt'] = timestamp;
      firstRow(json, 'calculations')['createdAt'] = timestamp;
      firstRow(json, 'settings')['updatedAt'] = timestamp;

      expect(BackupData.fromJson(json).validate(), isNull);
    });

    test('timestamp no entero o fuera de rango es rechazado', () {
      final json = validJson();
      firstRow(json, 'calculations')['createdAt'] = 1786.5;

      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('fechas de impresoras y settings tambien se validan', () {
      final json = validJson();
      firstRow(json, 'printers')['createdAt'] = 'fecha rota';
      firstRow(json, 'settings')['updatedAt'] = 'fecha rota';

      final error = BackupData.fromJson(json).validate();
      expect(error, contains('Impresora #1: createdAt invalido'));
      expect(error, contains('Setting #currencyCode: updatedAt invalido'));
    });

    test('appName desconocido es rechazado', () {
      final json = validJson()..['appName'] = 'OtraApp';
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('version de formato incompatible es rechazada', () {
      final json = validJson()..['version'] = 99;
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('id duplicado de cotizacion es rechazado', () {
      final json = validJson();
      final calcs = List<Map<String, dynamic>>.from(
        (json['calculations'] as List).cast<Map<String, dynamic>>(),
      );
      final second = Map<String, dynamic>.from(calcs.first);
      second['id'] = 1; // duplicado
      calcs.add(second);
      json['calculations'] = calcs;
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('material que referencia cotizacion inexistente es rechazado', () {
      final json = validJson();
      final materials = List<Map<String, dynamic>>.from(
        (json['calculationMaterials'] as List).cast<Map<String, dynamic>>(),
      );
      materials.first['calculationId'] = 999;
      json['calculationMaterials'] = materials;
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('numero negativo en filamento es rechazado', () {
      final json = validJson();
      final filaments = List<Map<String, dynamic>>.from(
        (json['filaments'] as List).cast<Map<String, dynamic>>(),
      );
      filaments.first['pricePerBobbin'] = -5;
      json['filaments'] = filaments;
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('conteo patologico de filamentos es rechazado', () {
      final json = validJson();
      json['filaments'] = List.generate(
        kBackupMaxFilaments + 1,
        (i) => {
          'id': i + 1,
          'name': 'F$i',
          'brand': null,
          'pricePerBobbin': 1,
          'gramsPerBobbin': 1000,
          'isDefault': false,
          'createdAt': '2026-08-11T12:00:00.000Z',
        },
      );
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });

    test('settings vacio es aceptado (solo con calculos validos)', () {
      final json = validJson()..['settings'] = <Map<String, dynamic>>[];
      expect(BackupData.fromJson(json).validate(), isNull);
    });
  });
}
