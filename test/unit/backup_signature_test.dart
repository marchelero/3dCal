// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/backup/backup_models.dart';
import 'package:tresdcal/core/backup/backup_service.dart';
import 'package:tresdcal/core/backup/backup_signature.dart';
import 'package:tresdcal/core/database/app_database.dart';

/// T2-2 (SEC-03): firma HMAC-SHA256 de los backups.
///
/// Contrato fijado aqui:
/// - export → envoltorio `{backup, signature}` con HMAC valido.
/// - import del envoltorio → verifica firma; payload alterado = rechazo.
/// - backup legacy (crudo o envoltorio sin firma) → sigue aceptando.
/// - clave por dispositivo → idempotente (primer uso la crea).
void main() {
  late AppDatabase db;
  late BackupService backup;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backup = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Backup JSON valido (raw, formato legacy) con un filamento seed.
  Map<String, dynamic> validBackupJson({String name = 'PLA'}) => {
    'version': kBackupFormatVersion,
    'schemaVersion': db.schemaVersion,
    'exportedAt': '2026-10-08T12:00:00.000Z',
    'appName': kBackupAppName,
    'filaments': <Map<String, dynamic>>[
      {
        'id': 1,
        'name': name,
        'brand': null,
        'pricePerBobbin': 150.0,
        'gramsPerBobbin': 1000.0,
        'isDefault': true,
        'color': '#FF0000',
        'createdAt': '2026-10-08T12:00:00.000Z',
      },
    ],
    'printers': <Map<String, dynamic>>[],
    'calculations': <Map<String, dynamic>>[],
    'calculationMaterials': <Map<String, dynamic>>[],
    'settings': <Map<String, dynamic>>[],
  };

  /// Envuelve un payload en el formato firmado con la identidad LOCAL
  /// (equivale al export real, sin pasar por _collectAllData).
  Future<String> signedEnvelope(Map<String, dynamic> payload) async {
    final sig = await BackupSignature.signPayload(payload);
    return jsonEncode({
      'backup': payload,
      'signature': sig,
      'deviceId': await BackupSignature.getOrCreateInstallId(),
    });
  }

  /// Clave HMAC actual en prefs (null si nunca se genero).
  Future<String?> prefsKeyOrNull() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kBackupHmacKeyPref);
  }

  test('clave HMAC: primer uso la crea y es idempotente', () async {
    final k1 = await BackupSignature.getOrCreateKeyHex();
    final k2 = await BackupSignature.getOrCreateKeyHex();
    expect(k1, hasLength(64), reason: '256 bits en hex = 64 chars.');
    expect(k1, k2, reason: 'La segunda llamada NO debe regenerar la clave.');

    // Id de instalación: igual de idempotente (viaja en el envoltorio).
    final id1 = await BackupSignature.getOrCreateInstallId();
    final id2 = await BackupSignature.getOrCreateInstallId();
    expect(id1, hasLength(32), reason: '128 bits en hex = 32 chars.');
    expect(id1, id2);
  });

  test('round-trip firmado: export → import restaura los datos', () async {
    final signed = await signedEnvelope(validBackupJson());

    final result = await backup.restoreFromJson(signed);
    expect(result, isEmpty, reason: 'Firma valida → restore exitoso.');

    final rows = await db.select(db.filaments).get();
    expect(rows.single.name, 'PLA');
  });

  test('payload alterado con firma vieja → signatureMismatch, DB intacta',
      () async {
    // Seed local que NO debe perderse si el restore es rechazado.
    await db
        .into(db.filaments)
        .insert(
          FilamentsCompanion.insert(
            name: 'Local',
            pricePerBobbin: 100,
            gramsPerBobbin: 1000,
            isDefault: const Value(true),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    final envelope = await signedEnvelope(validBackupJson());
    final tampered = jsonDecode(envelope) as Map<String, dynamic>;
    // Edita el payload SIN re-firmar (ataque classico: modificar el JSON
    // en un editor externo).
    ((tampered['backup'] as Map<String, dynamic>)['filaments'] as List)
        .cast<Map<String, dynamic>>()
        .first['name'] =
        'HACKED';

    final result = await backup.restoreFromJson(jsonEncode(tampered));
    expect(
      result,
      BackupErrorCodes.signatureMismatch,
      reason: 'La firma no coincide con el payload alterado.',
    );

    final rows = await db.select(db.filaments).get();
    expect(rows.single.name, 'Local', reason: 'La fila local queda intacta.');
  });

  test('clave local NO coincide (rotación/tampering) → rechazado', () async {
    // Firma hecha con key A; la key local cambia a B con el MISMO deviceId
    // (escenario: archivo alterado o clave borrada) → mismatch del mismo
    // dispositivo → rechazo.
    final payload = validBackupJson();
    final sigA = await BackupSignature.signPayload(payload);
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(
        kBackupHmacKeyPref,
        List<String>.filled(32, 'ff').join(), // key B (hex 64 chars)
      ),
    );

    final envelope = jsonEncode({
      'backup': payload,
      'signature': sigA,
      'deviceId': await BackupSignature.getOrCreateInstallId(),
    });
    final result = await backup.restoreFromJson(envelope);
    expect(result, BackupErrorCodes.signatureMismatch);
  });

  test('backup de OTRO dispositivo (deviceId distinto) → ACEPTADO '
      '(restauración cross-device no se rompe)', () async {
    // Firmado con clave ajena + deviceId ajeno: no verificable localmente.
    // Rechazarlo romperia migrar el backup al celular nuevo (el caso de uso
    // principal), asi que se acepta como cualquier backup de otro origen.
    final payload = validBackupJson(name: 'PLA del otro cel');
    final envelope = jsonEncode({
      'backup': payload,
      'signature': List<String>.filled(64, 'ab').join(),
      'deviceId': 'otro-dispositivo-diferente',
    });

    final result = await backup.restoreFromJson(envelope);
    expect(result, isEmpty, reason: 'Cross-device debe restaurar.');
    expect((await db.select(db.filaments).get()).single.name, 'PLA del otro cel');
  });

  test('envoltorio SIN firma (legacy raro) → aceptado con aviso', () async {
    final envelope = jsonEncode({'backup': validBackupJson()});

    final result = await backup.restoreFromJson(envelope);
    expect(result, isEmpty, reason: 'Sin firma no es rechazo (compat).');
    expect((await db.select(db.filaments).get()).single.name, 'PLA');
  });

  test('backup crudo legacy (sin envoltorio) → aceptado sin tocar la clave',
      () async {
    // No se llama a signPayload: el camino legacy ni siquiera consulta la
    // clave del dispositivo.
    final raw = jsonEncode(validBackupJson());

    final result = await backup.restoreFromJson(raw);
    expect(result, isEmpty);
    expect(await prefsKeyOrNull(), isNull, reason: 'No debe generarse clave.');
    expect((await db.select(db.filaments).get()).single.name, 'PLA');
  });

  test('signature no-String → invalidFile', () async {
    final envelope = jsonEncode({
      'backup': validBackupJson(),
      'signature': 12345,
    });
    final result = await backup.restoreFromJson(envelope);
    expect(result, BackupErrorCodes.invalidFile);
  });

  test('buildExportJsonForTest produce envoltorio verificable', () async {
    await db
        .into(db.filaments)
        .insert(
          FilamentsCompanion.insert(
            name: 'PETG',
            pricePerBobbin: 220,
            gramsPerBobbin: 1000,
            isDefault: const Value(true),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    final exported = await backup.buildExportJsonForTest();
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    expect(decoded.keys, containsAll(['backup', 'signature']));
    expect(decoded['signature'], isA<String>());

    // El envoltorio importa en una DB fresca (mismo dispositivo → misma
    // clave → verificacion OK).
    final freshDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(freshDb.close);
    final freshBackup = BackupService(freshDb);
    final result = await freshBackup.restoreFromJson(exported);
    expect(result, isEmpty, reason: 'Round-trip export→import con firma.');
    expect((await freshDb.select(freshDb.filaments).get()).single.name, 'PETG');
  });
}
