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
    'filaments': <Map<String, dynamic>>[],
    'printers': <Map<String, dynamic>>[],
    'calculations': <Map<String, dynamic>>[
      {
        'id': 1,
        'createdAt': '2026-09-07T12:00:00.000Z',
        'pieceName': 'Vaso con foto',
        'clientName': null,
        'notes': null,
        'conditions': null,
        'printerId': null,
        'printerNameSnapshot': null,
        'printerWattsSnapshot': 0,
        'totalHours': 2.0,
        'printMinutes': 120,
        'discountPercentage': 0,
        'kwhRateSnapshot': 0,
        'profitBaseSnapshot': 0,
        'isSold': false,
        'isTemplate': false,
        'materialCostSnapshot': 12.0,
        'electricCostSnapshot': 0,
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

  test('round-trip: restaurar backup con foto preserva pieceImageBlob', () async {
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
  });

  test('backup sin key pieceImageBlob restaura null (compatibilidad v1)', () async {
    final json = jsonEncode(validBackupJson(pieceImageBase64: null));

    final result = await backup.restoreFromJson(json);
    expect(result, isEmpty);

    final rows = await db.select(db.calculations).get();
    expect(rows, hasLength(1));
    expect(rows.first.pieceImageBlob, isNull);
  });

  test('base64 corrupto → error claro y rollback (DB actual intacta)', () async {
    // Seed: una cotizacion existente que NO debe perderse si el restore falla.
    await db.into(db.calculations).insert(
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
        laborCostSnapshot: 0,
        postProcessCostSnapshot: 0,
        baseCostSnapshot: 5,
        failureCostSnapshot: 0,
        markupCostSnapshot: 0,
        profitAmountSnapshot: 0,
        minimumChargeAppliedSnapshot: 0,
        effectiveTotalSnapshot: 5,
        totalPriceSnapshot: 5,
        laborRateSnapshot: 0,
        postProcessRateSnapshot: 0,
        failureRateSnapshot: 0,
        minimumChargeSnapshot: 0,
        markupOnMaterialsSnapshot: 0,
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
    (json['calculations'] as List).cast<Map<String, dynamic>>().first[
      'pieceImageBlob'
    ] = 12345;
    expect(BackupData.fromJson(json).validate(), isNotNull);
  });

  test('validate() rechaza pieceImageBlob oversize (> kBackupMaxImageBase64Length)', () {
    final json = validBackupJson();
    (json['calculations'] as List).cast<Map<String, dynamic>>().first[
      'pieceImageBlob'
    ] = 'a' * (kBackupMaxImageBase64Length + 1);
    expect(BackupData.fromJson(json).validate(), isNotNull);
  });

  test('validate() acepta base64 valido dentro del limite', () {
    final png = pngOf(64, 64);
    final json = validBackupJson(pieceImageBase64: base64Encode(png));
    expect(BackupData.fromJson(json).validate(), isNull);
  });
}
