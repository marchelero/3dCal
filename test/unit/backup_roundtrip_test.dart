// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tresdcal/core/backup/backup_models.dart';
import 'package:tresdcal/core/backup/backup_service.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// Round-trip del backup con fotos de piezas (F2).
///
/// Bug F7 (verificado): el export serializaba `pieceImageBlob` (base64 via
/// `toJson()` de drift), pero `_insertCalculations` lo ignoraba → la foto se
/// perdia silenciosamente al restaurar. Estos tests fijan ese contrato.
void main() {
  late AppDatabase db;
  late BackupService backup;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backup = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Genera un PNG solido de `w x h` (mismo patron que calculator_notifier_test).
  Uint8List pngOf(int w, int h) {
    final image = img.Image(width: w, height: h);
    img.fill(image, color: img.ColorRgb8(60, 120, 200));
    return Uint8List.fromList(img.encodePng(image));
  }

  Map<String, dynamic> validBackupJson({String? pieceImageBase64}) => {
    'version': kBackupFormatVersion,
    'schemaVersion': db.schemaVersion,
    'exportedAt': '2026-09-07T12:00:00.000Z',
    'appName': kBackupAppName,
    'filaments': <Map<String, dynamic>>[
      {
        'id': 1,
        'name': 'PLA',
        'brand': null,
        'pricePerBobbin': 150.0,
        'gramsPerBobbin': 1000.0,
        'isDefault': true,
        'color': '#FF0000',
        'createdAt': '2026-09-07T12:00:00.000Z',
      },
    ],
    'printers': <Map<String, dynamic>>[
      {
        'id': 1,
        'brand': null,
        'name': 'Ender 3',
        'averageWatts': 120,
        'purchaseCost': 2400.0,
        'usefulLifeHours': 5000,
        'isDefault': true,
        'createdAt': '2026-09-07T12:00:00.000Z',
      },
    ],
    'calculations': <Map<String, dynamic>>[
      {
        'id': 1,
        'createdAt': '2026-09-07T12:00:00.000Z',
        'pieceName': 'Vaso con foto',
        'clientName': null,
        'notes': null,
        'conditions': null,
        'printerId': 1,
        'printerNameSnapshot': 'Ender 3',
        'printerWattsSnapshot': 120,
        'totalHours': 2.0,
        'printMinutes': 120,
        'discountPercentage': 0,
        'kwhRateSnapshot': 0,
        'profitBaseSnapshot': 0,
        'quantity': 3,
        'isSold': false,
        'isTemplate': true,
        'materialCostSnapshot': 12.0,
        'electricCostSnapshot': 0,
        'amortizationCostSnapshot': 3.5,
        'laborCostSnapshot': 0,
        'postProcessCostSnapshot': 0,
        'baseCostSnapshot': 12.0,
        'failureCostSnapshot': 0,
        'markupCostSnapshot': 0,
        'profitAmountSnapshot': 0,
        'minimumChargeAppliedSnapshot': 0,
        'effectiveTotalSnapshot': 12.0,
        'totalPriceSnapshot': 12.0,
        'laborRateSnapshot': 0,
        'postProcessRateSnapshot': 0,
        'failureRateSnapshot': 0,
        'minimumChargeSnapshot': 0,
        'markupOnMaterialsSnapshot': 0,
        'pieceImageBlob': pieceImageBase64,
      },
    ],
    'calculationMaterials': <Map<String, dynamic>>[],
    'settings': <Map<String, dynamic>>[],
  };

  test(
    'round-trip: restaurar backup con foto preserva pieceImageBlob',
    () async {
      final png = pngOf(800, 600);
      final json = jsonEncode(
        validBackupJson(pieceImageBase64: base64Encode(png)),
      );

      final result = await backup.restoreFromJson(json);
      expect(result, isEmpty, reason: 'Restore debe ser exitoso.');

      final rows = await db.select(db.calculations).get();
      expect(rows, hasLength(1));
      expect(rows.first.pieceImageBlob, isNotNull);
      expect(rows.first.pieceImageBlob, equals(png));
    },
  );

  test(
    'backup sin key pieceImageBlob restaura null (compatibilidad v1)',
    () async {
      final json = jsonEncode(validBackupJson(pieceImageBase64: null));

      final result = await backup.restoreFromJson(json);
      expect(result, isEmpty);

      final rows = await db.select(db.calculations).get();
      expect(rows, hasLength(1));
      expect(rows.first.pieceImageBlob, isNull);
    },
  );

  test(
    'R2-MED-06/07: backup pre-v17 sin printMinutes/modos usa defaults',
    () async {
      // Simula un backup anterior a v17: no trae modelingMode/postprocMode/
      // extraMode (el fixture ya no los incluye) y ahora tampoco printMinutes.
      final json = validBackupJson();
      final row = (json['calculations'] as List).single as Map<String, dynamic>;
      row.remove('printMinutes');
      expect(row.containsKey('modelingMode'), isFalse);

      final result = await backup.restoreFromJson(jsonEncode(json));
      expect(
        result,
        isEmpty,
        reason: 'printMinutes ausente NO debe abortar el restore (MED-07)',
      );

      final calc = (await db.select(db.calculations).get()).single;
      expect(calc.printMinutes, 0, reason: 'default de columna (MED-07)');
      expect(calc.modelingMode, 'auto', reason: 'default de columna (MED-06)');
      expect(calc.postprocMode, 'auto', reason: 'default de columna (MED-06)');
      expect(calc.extraMode, 'off', reason: 'default de columna (MED-06)');
    },
  );

  test('round-trip: catalogo y snapshots preservan campos nuevos', () async {
    final json = jsonEncode(validBackupJson());

    final result = await backup.restoreFromJson(json);
    expect(result, isEmpty, reason: 'Restore debe ser exitoso.');

    final filaments = await db.select(db.filaments).get();
    expect(filaments.single.color, '#FF0000');

    final printers = await db.select(db.printers).get();
    expect(printers.single.purchaseCost, 2400.0);
    expect(printers.single.usefulLifeHours, 5000);

    final calcs = await db.select(db.calculations).get();
    expect(calcs.single.quantity, 3);
    expect(calcs.single.amortizationCostSnapshot, 3.5);
    expect(calcs.single.isTemplate, isTrue);
  });

  test('base64 corrupto → error claro y rollback (DB actual intacta)', () async {
    // Seed: una cotizacion existente que NO debe perderse si el restore falla.
    await db
        .into(db.calculations)
        .insert(
          CalculationsCompanion.insert(
            createdAt: DateTime.now().toUtc(),
            pieceName: const Value('Existente'),
            totalHours: 1,
            printMinutes: const Value(60),
            discountPercentage: 0,
            kwhRateSnapshot: 0,
            profitBaseSnapshot: 0,
            isSold: const Value(false),
            isTemplate: const Value(false),
            materialCostSnapshot: 5,
            electricCostSnapshot: 0,
            laborCostSnapshot: const Value(0),
            postProcessCostSnapshot: const Value(0),
            baseCostSnapshot: 5,
            failureCostSnapshot: const Value(0),
            markupCostSnapshot: const Value(0),
            profitAmountSnapshot: 0,
            minimumChargeAppliedSnapshot: const Value(0),
            effectiveTotalSnapshot: const Value(5),
            totalPriceSnapshot: 5,
            laborRateSnapshot: const Value(0),
            postProcessRateSnapshot: const Value(0),
            failureRateSnapshot: const Value(0),
            minimumChargeSnapshot: const Value(0),
            markupOnMaterialsSnapshot: const Value(0),
          ),
        );

    final json = jsonEncode(
      validBackupJson(pieceImageBase64: '!!!esto-no-es-base64!!!'),
    );

    final result = await backup.restoreFromJson(json);
    expect(result, isNotEmpty, reason: 'Debe fallar con mensaje de error.');

    // Rollback: la fila existente sigue intacta y el backup no se inserto.
    final rows = await db.select(db.calculations).get();
    expect(rows, hasLength(1));
    expect(rows.first.pieceName, 'Existente');
  });

  test('validate() rechaza pieceImageBlob no-String', () {
    final json = validBackupJson(pieceImageBase64: 'aGVsbG8=');
    (json['calculations'] as List)
            .cast<Map<String, dynamic>>()
            .first['pieceImageBlob'] =
        12345;
    expect(BackupData.fromJson(json).validate(), isNotNull);
  });

  test(
    'validate() rechaza pieceImageBlob oversize (> kBackupMaxImageBase64Length)',
    () {
      final json = validBackupJson();
      (json['calculations'] as List)
              .cast<Map<String, dynamic>>()
              .first['pieceImageBlob'] =
          'a' * (kBackupMaxImageBase64Length + 1);
      expect(BackupData.fromJson(json).validate(), isNotNull);
    },
  );

  test('validate() acepta base64 valido dentro del limite', () {
    final png = pngOf(64, 64);
    final json = validBackupJson(pieceImageBase64: base64Encode(png));
    expect(BackupData.fromJson(json).validate(), isNull);
  });

  // ─────────────────────────────────────────────────────────────
  // v14/v15/v16: los datos nuevos NO deben perderse en el round-trip.
  //
  // `_insertCalculations` / `_insertCalculationMaterials` listan las columnas
  // a mano. Una columna nueva olvidada ahi se pierde en silencio: el export la
  // escribe (via `toJson()` de drift) pero el import la ignora.
  // ─────────────────────────────────────────────────────────────

  group('Round-trip de columnas anadidas (v13-v16)', () {
    /// Backup con TODAS las columnas anadidas desde v11, simultaneamente.
    Map<String, dynamic> modernBackupJson() {
      final json = validBackupJson();
      final calc = (json['calculations'] as List)
          .cast<Map<String, dynamic>>()
          .first;
      calc['isPartial'] = false;
      calc['isAdvanced'] = true; // Advanced de un solo material
      calc['batchDiscountPercent'] = '7.5';
      calc['batchDiscountAmount'] = '12.25';
      calc['pieceImageBlob'] = null;

      json['printers'] = [
        {
          ...(json['printers'] as List).cast<Map<String, dynamic>>().first,
          'currentHours': 320, // v13
        },
      ];

      json['calculationMaterials'] = [
        {
          'id': 1,
          'calculationId': 1,
          'filamentId': 1,
          'label': 'PLA Negro',
          'weightGrams': 120.0,
          'pricePerBobbinSnapshot': 150.0,
          'gramsPerBobbinSnapshot': 1000.0,
          'useOwnTime': true, // v15
          'materialHours': 2.0,
          'materialMinutes': 30.0,
        },
        {
          'id': 2,
          'calculationId': 1,
          'filamentId': null,
          'label': 'ABS',
          'weightGrams': 80.0,
          'pricePerBobbinSnapshot': 160.0,
          'gramsPerBobbinSnapshot': 1000.0,
          'useOwnTime': null, // usaba el tiempo global
          'materialHours': null,
          'materialMinutes': null,
        },
      ];
      return json;
    }

    test('restaura isAdvanced / isPartial / batchDiscount (v12-v16)', () async {
      final result = await backup.restoreFromJson(
        jsonEncode(modernBackupJson()),
      );
      expect(result, isEmpty, reason: 'El import debe ser exitoso.');

      final calc = (await db.select(db.calculations).get()).single;
      expect(calc.isAdvanced, isTrue, reason: 'v16 no debe perderse');
      expect(calc.isPartial, isFalse, reason: 'v14 no debe perderse');
      expect(calc.batchDiscountPercent, '7.5', reason: 'v12 no debe perderse');
      expect(calc.batchDiscountAmount, '12.25');
    });

    test('restaura el tiempo propio por material (v15)', () async {
      final result = await backup.restoreFromJson(
        jsonEncode(modernBackupJson()),
      );
      expect(result, isEmpty);

      final mats = await db.select(db.calculationMaterials).get();
      expect(mats, hasLength(2));

      final pla = mats.firstWhere((m) => m.label == 'PLA Negro');
      expect(pla.useOwnTime, isTrue);
      expect(pla.materialHours, 2.0);
      expect(pla.materialMinutes, 30.0);

      // El material sin tiempo propio debe quedar en NULL, no en 0: asi se
      // distingue "usaba el global" de "tenia tiempo propio de 0".
      final abs = mats.firstWhere((m) => m.label == 'ABS');
      expect(abs.useOwnTime, isNull);
      expect(abs.materialHours, isNull);
      expect(abs.materialMinutes, isNull);
    });

    test('restaura currentHours de la impresora (v13)', () async {
      await backup.restoreFromJson(jsonEncode(modernBackupJson()));
      final printer = (await db.select(db.printers).get()).single;
      expect(printer.currentHours, 320);
    });

    test('el export incluye las columnas nuevas', () async {
      // Seed con una cotizacion Advanced + tiempo propio, luego export.
      await db
          .into(db.calculations)
          .insert(
            CalculationsCompanion.insert(
              createdAt: DateTime.utc(2026, 9, 30, 10),
              pieceName: const Value('Advanced'),
              clientName: const Value(''),
              printerWattsSnapshot: const Value(120),
              totalHours: 3.75,
              printMinutes: const Value(45),
              discountPercentage: 0,
              kwhRateSnapshot: 0,
              profitBaseSnapshot: 0,
              quantity: const Value(1),
              isSold: const Value(false),
              isTemplate: const Value(false),
              isAdvanced: const Value(true),
              materialCostSnapshot: 20,
              electricCostSnapshot: 0,
              amortizationCostSnapshot: const Value(0),
              laborCostSnapshot: const Value(0),
              postProcessCostSnapshot: const Value(0),
              baseCostSnapshot: 20,
              failureCostSnapshot: const Value(0),
              markupCostSnapshot: const Value(0),
              profitAmountSnapshot: 0,
              minimumChargeAppliedSnapshot: const Value(0),
              effectiveTotalSnapshot: const Value(20),
              totalPriceSnapshot: 20,
              laborRateSnapshot: const Value(0),
              postProcessRateSnapshot: const Value(0),
              failureRateSnapshot: const Value(0),
              minimumChargeSnapshot: const Value(0),
              markupOnMaterialsSnapshot: const Value(0),
            ),
          );
      await db
          .into(db.calculationMaterials)
          .insert(
            CalculationMaterialsCompanion.insert(
              calculationId: 1,
              filamentId: const Value(null),
              label: 'PLA',
              weightGrams: 120,
              pricePerBobbinSnapshot: 150,
              gramsPerBobbinSnapshot: 1000,
              useOwnTime: const Value(true),
              materialHours: const Value(3),
              materialMinutes: const Value(45),
            ),
          );

      final data = await backup.collectAllDataForTest();
      expect(data.calculations.single['isAdvanced'], isTrue);
      expect(data.calculationMaterials.single['useOwnTime'], isTrue);
      expect(data.calculationMaterials.single['materialHours'], 3.0);
      expect(data.calculationMaterials.single['materialMinutes'], 45.0);
    });

    test(
      'backup viejo (sin las columnas) importa con defaults seguros',
      () async {
        // Simula un backup exportado antes de v14: sin isPartial, isAdvanced,
        // batchDiscount* ni las columnas de tiempo propio.
        final json = validBackupJson();
        json['calculationMaterials'] = [
          {
            'id': 1,
            'calculationId': 1,
            'filamentId': 1,
            'label': 'PLA',
            'weightGrams': 100.0,
            'pricePerBobbinSnapshot': 150.0,
            'gramsPerBobbinSnapshot': 1000.0,
          },
        ];

        final result = await backup.restoreFromJson(jsonEncode(json));
        expect(
          result,
          isEmpty,
          reason: 'Un backup viejo debe seguir importando',
        );

        final calc = (await db.select(db.calculations).get()).single;
        expect(calc.isPartial, isFalse);
        expect(calc.isAdvanced, isFalse);
        expect(calc.batchDiscountPercent, isNull);

        final mat = (await db.select(db.calculationMaterials).get()).single;
        expect(mat.useOwnTime, isNull, reason: 'NULL = tiempo global');
        expect(mat.materialHours, isNull);
      },
    );

    test('validate() rechaza tipos erroneos en las columnas nuevas', () {
      final json = modernBackupJson();
      final calc = (json['calculations'] as List)
          .cast<Map<String, dynamic>>()
          .first;
      calc['isAdvanced'] = 'si'; // string en vez de bool
      expect(BackupData.fromJson(json).validate(), isNotNull);

      final json2 = modernBackupJson();
      final mat = (json2['calculationMaterials'] as List)
          .cast<Map<String, dynamic>>()
          .first;
      mat['materialHours'] = 'dos'; // string en vez de numero
      expect(BackupData.fromJson(json2).validate(), isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // discount_tiers (v12): tabla CREADA POR EL USUARIO en Ajustes.
  // No estaba en el backup → sus escalones se perdian en cada restore.
  // ─────────────────────────────────────────────────────────────

  group('Round-trip de discount_tiers (v12)', () {
    /// Backup v12+ con dos escalones. `percent` es TEXT decimal a proposito.
    Map<String, dynamic> backupWithTiers() {
      final json = validBackupJson();
      json['discountTiers'] = [
        {'id': 'tier-a', 'minQty': 3, 'percent': '5.00', 'sortOrder': 0},
        {
          'id': 'tier-b',
          'minQty': 10,
          'percent': '12.50', // no debe perder precision
          'sortOrder': 1,
        },
      ];
      return json;
    }

    test('restaura los escalones y preserva percent como TEXT', () async {
      final result = await backup.restoreFromJson(
        jsonEncode(backupWithTiers()),
      );
      expect(result, isEmpty);

      final tiers = await db.select(db.discountTiersTable).get();
      expect(tiers, hasLength(2));

      final b = tiers.firstWhere((t) => t.id == 'tier-b');
      expect(b.minQty, 10);
      expect(b.percent, '12.50', reason: 'No debe castearse a double');
      expect(b.sortOrder, 1);
    });

    test('el export incluye los escalones', () async {
      await db
          .into(db.discountTiersTable)
          .insert(
            DiscountTiersTableCompanion.insert(
              id: 'tier-x',
              minQty: 5,
              percent: '8.75',
              sortOrder: 0,
            ),
          );

      final data = await backup.collectAllDataForTest();
      expect(data.discountTiers, hasLength(1));
      expect(data.discountTiers.single['id'], 'tier-x');
      expect(data.discountTiers.single['percent'], '8.75');
      expect(data.summary.discountTierCount, 1);
      expect(data.toJson()['discountTiers'], hasLength(1));
    });

    test('el restore REEMPLAZA los escalones (no acumula)', () async {
      // Escalon local que NO esta en el backup → debe desaparecer.
      await db
          .into(db.discountTiersTable)
          .insert(
            DiscountTiersTableCompanion.insert(
              id: 'tier-local',
              minQty: 2,
              percent: '3.00',
              sortOrder: 0,
            ),
          );

      final result = await backup.restoreFromJson(
        jsonEncode(backupWithTiers()),
      );
      expect(result, isEmpty);

      final ids = (await db.select(db.discountTiersTable).get())
          .map((t) => t.id)
          .toSet();
      expect(ids, {'tier-a', 'tier-b'});
    });

    test('backup viejo sin la clave discountTiers sigue importando', () async {
      final json = validBackupJson();
      expect(json.containsKey('discountTiers'), isFalse);

      final result = await backup.restoreFromJson(jsonEncode(json));
      expect(result, isEmpty);
      expect(await db.select(db.discountTiersTable).get(), isEmpty);
    });

    test('validate() rechaza percent no-String y minQty no-int', () {
      final json = backupWithTiers();
      (json['discountTiers'] as List)
              .cast<Map<String, dynamic>>()
              .first['percent'] =
          5.0; // double en vez de TEXT
      expect(BackupData.fromJson(json).validate(), isNotNull);

      final json2 = backupWithTiers();
      (json2['discountTiers'] as List)
              .cast<Map<String, dynamic>>()
              .first['minQty'] =
          'tres';
      expect(BackupData.fromJson(json2).validate(), isNotNull);
    });

    test('validate() rechaza id duplicado de escalon', () {
      final json = backupWithTiers();
      json['discountTiers'] = [
        {'id': 'dup', 'minQty': 3, 'percent': '5.00', 'sortOrder': 0},
        {'id': 'dup', 'minQty': 10, 'percent': '9.00', 'sortOrder': 1},
      ];
      expect(BackupData.fromJson(json).validate(), isNotNull);
    });
  });
}
