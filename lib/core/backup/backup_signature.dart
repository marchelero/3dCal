/// Firma HMAC-SHA256 de los archivos de backup (T2-2 / SEC-03).
///
/// **Threat model**: el archivo `.3dcal` vive fuera de la app (compartido,
/// descargado, editado en un editor). Un JSON alterado a mano podria meter
/// datos corruptos en la DB local; el HMAC con clave por dispositivo detecta
/// esa alteracion en el mismo dispositivo.
///
/// **Limitaciones documentadas** (no son bugs, son el trade-off elegido):
/// - Un atacante que REESCRIBE el archivo puede quitar el envoltorio y
///   pasar por el camino legacy (sin firma) → aceptado con aviso. Mismo
///   comportamiento que antes de T2-2, sin regresion.
/// - La clave vive en `SharedPreferences` (sandbox de la app): extraerla
///   requiere root/acceso al sandbox. No es un HSM; es deteccion de
///   corrupcion/tampering casual, no criptografia fuerte.
///
/// **Formato del envoltorio** (el `BackupData` va anidado, SIN cambios al
/// schema de tablas ni a `BackupData`):
/// ```json
/// { "backup": { ...BackupData... }, "signature": "<hex hmac-sha256>" }
/// ```
/// La firma se calcula sobre `jsonEncode(backup)` — en el import se
/// re-serializa el payload anidado con `jsonEncode` y se compara
/// (round-trip de `jsonEncode→jsonDecode→jsonEncode` es estable en Dart).
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prefijo de la clave HMAC por dispositivo en `SharedPreferences`.
const String kBackupHmacKeyPref = 'backup_hmac_key_v1';

/// Id de instalación (por dispositivo) en `SharedPreferences`.
///
/// Viaja en el envoltorio (`deviceId`) para que el import sepa si la firma
/// es verificable con la clave LOCAL: un backup firmado en OTRO dispositivo
/// no se puede verificar (clave distinta) y debe aceptarse como
/// restauración cross-device en vez de rechazarse.
const String kInstallIdPref = 'install_id_v1';

/// Largo de la clave en bytes (256 bits).
const int kBackupHmacKeyBytes = 32;

/// Utilidades de firma/verificacion de backups.
abstract final class BackupSignature {
  /// Retorna el id de instalación hex, creandolo en el primer uso.
  ///
  /// Idempotente (ver test). Identifica EL DISPOSITIVO en el envoltorio del
  /// backup; NO es un identificador de hardware ni PII — bytes aleatorios.
  static Future<String> getOrCreateInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(kInstallIdPref);
    if (existing != null && existing.isNotEmpty) return existing;
    final rnd = Random.secure();
    final id = StringBuffer();
    for (var i = 0; i < 16; i++) {
      id.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    final installId = id.toString();
    await prefs.setString(kInstallIdPref, installId);
    return installId;
  }

  /// Retorna la clave HMAC hex del dispositivo, creandola en el primer uso.
  ///
  /// Idempotente: la segunda llamada reutiliza la misma clave (ver test de
  /// idempotencia). `Random.secure()` para los bytes.
  static Future<String> getOrCreateKeyHex() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(kBackupHmacKeyPref);
    if (existing != null && existing.length == kBackupHmacKeyBytes * 2) {
      return existing;
    }
    final rnd = Random.secure();
    final hex = StringBuffer();
    for (var i = 0; i < kBackupHmacKeyBytes; i++) {
      hex.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    final keyHex = hex.toString();
    await prefs.setString(kBackupHmacKeyPref, keyHex);
    return keyHex;
  }

  /// Firma el payload (el `BackupData` serializado) y retorna el MAC hex.
  ///
  /// El MAC se calcula sobre `jsonEncode(payload)` — el mismo string que el
  /// import recomputa al verificar.
  static Future<String> signPayload(Map<String, dynamic> payload) async {
    final keyHex = await getOrCreateKeyHex();
    final mac = Hmac(sha256, _hexToBytes(keyHex)).convert(
      utf8.encode(jsonEncode(payload)),
    );
    return mac.toString(); // hex lowercase
  }

  /// Comparacion en tiempo constante de los MACs hex (evita timing
  /// side-channels en la comparacion — buena practica, costo cero).
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Convierte hex a bytes. Lanza [FormatException] si el hex es invalido.
  static List<int> _hexToBytes(String hex) {
    if (hex.length.isOdd) {
      throw const FormatException('hex impar');
    }
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byte = int.parse(hex.substring(i, i + 2), radix: 16);
      bytes.add(byte);
    }
    return bytes;
  }
}
