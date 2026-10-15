// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Borradores de los pasos de impresora/filamento del flujo /setup (MED-2
/// auditoría 2026-10-14).
///
/// Persiste lo tipeado en los forms del setup para que matar la app antes
/// de navegar no pierda el trabajo (mismo criterio que [DraftStorage] del
/// calculator, que el wipe local ya limpia). Se limpia al confirmar el
/// commit (create/update OK) y en [LocalDataWipeService].
class SetupDraftStorage {
  SetupDraftStorage(this._prefs);

  /// Clave del borrador del paso impresora (JSON).
  static const printerKey = 'setup_printer_draft';

  /// Clave del borrador del paso filamento (JSON).
  static const filamentKey = 'setup_filament_draft';

  final SharedPreferences _prefs;

  /// Borrador del paso impresora o `null` si no existe / no parsea.
  Map<String, Object?>? loadPrinter() => _load(printerKey);

  /// Borrador del paso filamento o `null` si no existe / no parsea.
  Map<String, Object?>? loadFilament() => _load(filamentKey);

  /// Persiste el borrador del paso impresora (reemplaza el anterior).
  void savePrinter(Map<String, Object?> draft) => _save(printerKey, draft);

  /// Persiste el borrador del paso filamento (reemplaza el anterior).
  void saveFilament(Map<String, Object?> draft) => _save(filamentKey, draft);

  /// Limpia el borrador del paso impresora (commit OK / wipe).
  void clearPrinter() => _prefs.remove(printerKey);

  /// Limpia el borrador del paso filamento (commit OK / wipe).
  void clearFilament() => _prefs.remove(filamentKey);

  Map<String, Object?>? _load(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      // JSON corrupto (ej: cambio de versión): se descarta el borrador.
      return null;
    }
  }

  void _save(String key, Map<String, Object?> draft) {
    // Fire-and-forget SIN debounce a propósito: el mapa en memoria de
    // SharedPreferences se actualiza sincrónicamente (el flush a disco es
    // async e irrelevante acá), un Timer de debounce dejaría timers
    // pendientes en los widget tests, y matar la app NO ejecuta dispose()
    // que los cancele — la persistencia por tecla es la más robusta.
    _prefs.setString(key, jsonEncode(draft));
  }
}
