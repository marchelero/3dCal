// ignore_for_file: public_member_api_docs
import 'package:shared_preferences/shared_preferences.dart';

import 'calculation_draft.dart';

/// Wrapper sobre SharedPreferences para persistir el draft del calculator.
///
/// **Uso**: el calculator guarda el state en cada cambio (debounced) y
/// restaura al iniciar. Al guardar exitosamente una cotizacion, limpia
/// el draft.
class DraftStorage {
  DraftStorage(this._prefs);

  static const _key = 'form_draft';

  final SharedPreferences _prefs;

  /// Carga el draft o `null` si no existe / no parsea.
  Future<CalculationDraft?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return CalculationDraft.tryDecode(raw);
  }

  /// Persiste el draft. Reemplaza el valor anterior.
  Future<void> save(CalculationDraft draft) async {
    await _prefs.setString(_key, draft.encode());
  }

  /// Limpia el draft (ej: al guardar la cotizacion exitosamente).
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
