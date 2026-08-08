// ignore_for_file: public_member_api_docs
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Wrapper sobre [SharedPreferences] para los 3 keys del cache rapido de
/// entitlement (leidos en `main()` antes de que la DB este lista).
///
/// **Por que existe**: el boot path de [EntitlementNotifier] (T4) lee
/// este cache primero para evitar flicker "free → pro" durante el cold
/// start. La tabla `entitlements` de Drift es la source of truth; este
/// cache es solo un mirror para el primer frame.
///
/// **Keys** (definidas en [app_constants.dart]):
/// - [kIsProKey] (`'is_pro'`) → bool
/// - [kEntitlementSourceKey] (`'entitlement_source'`) → String
/// - [kEntitlementValidatedAtKey] (`'entitlement_validated_at'`) → ISO 8601
class EntitlementCache {
  /// Crea el wrapper sobre una instancia de [SharedPreferences]. La
  /// instancia es inyectada (no se hace `getInstance()` aca) para
  /// permitir override en tests via
  /// [sharedPreferencesProvider] (`SharedPreferences.setMockInitialValues`).
  EntitlementCache(this._sp);

  final SharedPreferences _sp;

  /// `true` si el cache dice que el user es Pro. `false` en cache vacio
  /// (no es un getter nullable — la ausencia = free).
  bool get isPro => _sp.getBool(kIsProKey) ?? false;

  /// Origen del entitlement (e.g. `'lifetime_purchase'`). `null` si
  /// [isPro] es false o si el key nunca se seteo.
  String? get source => _sp.getString(kEntitlementSourceKey);

  /// Ultima vez que se valido el entitlement contra la store, en UTC.
  /// `null` si nunca se valido (ej: compra offline). Se parsea de
  /// ISO 8601 — un string corrupto retorna `null` (defensive).
  DateTime? get validatedAt {
    final raw = _sp.getString(kEntitlementValidatedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Persiste los 3 keys. Llamado tras un `purchase success` o tras
  /// hidratar desde DB en el boot path.
  ///
  /// Si [validatedAt] es `null`, NO escribe el key de timestamp (asi
  /// `validatedAt` getter retorna `null` correctamente).
  Future<void> setActive({
    required String source,
    DateTime? validatedAt,
  }) async {
    await _sp.setBool(kIsProKey, true);
    await _sp.setString(kEntitlementSourceKey, source);
    if (validatedAt != null) {
      await _sp.setString(
        kEntitlementValidatedAtKey,
        validatedAt.toIso8601String(),
      );
    } else {
      await _sp.remove(kEntitlementValidatedAtKey);
    }
  }

  /// Borra los 3 keys. Llamado en `deactivate` y cuando el boot
  /// detecta que el cache dice Pro pero la DB no tiene fila activa.
  Future<void> clear() async {
    await _sp.remove(kIsProKey);
    await _sp.remove(kEntitlementSourceKey);
    await _sp.remove(kEntitlementValidatedAtKey);
  }
}
