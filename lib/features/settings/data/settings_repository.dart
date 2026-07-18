// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';

/// Acceso a settings globales como key-value store.
///
/// Tabla `settings` con clave primaria = key.
class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  /// Lee el valor de un setting como [Decimal]. Default si no existe.
  Future<Decimal> getDecimal(String key, Decimal fallback) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    if (row == null) {
      return fallback;
    }
    return DecimalParseSafe.fromStringOrFallback(row.value, fallback);
  }

  /// Lee el valor como String.
  Future<String> getString(String key, String fallback) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value ?? fallback;
  }

  /// Lee el valor como bool. Default si no existe o no parsea.
  Future<bool> getBool(String key, bool fallback) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    if (row == null) {
      return fallback;
    }
    return row.value == 'true';
  }

  /// Guarda un setting Decimal.
  Future<void> setDecimal(String key, Decimal value) async {
    await _upsert(key, value.toString());
  }

  /// Guarda un setting String.
  Future<void> setString(String key, String value) async {
    await _upsert(key, value);
  }

  /// Guarda un setting bool.
  Future<void> setBool(String key, bool value) async {
    await _upsert(key, value.toString());
  }

  /// Helper que hace upsert: insert si no existe, update si existe.
  Future<void> _upsert(String key, String value) async {
    final existing = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.settingsTable).insert(
            SettingsTableCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    } else {
      await (_db.update(_db.settingsTable)..where((s) => s.key.equals(key)))
          .write(
        SettingsTableCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  // -------- Typed accessors para settings comunes --------

  /// Ganancia base global (%). Default: [kDefaultProfitBasePercentage].
  Future<Decimal> getProfitBase() => getDecimal(
      SettingsKeys.profitBasePercentage,
      Decimal.fromInt(kDefaultProfitBasePercentage.toInt()));

  Future<void> setProfitBase(Decimal value) =>
      setDecimal(SettingsKeys.profitBasePercentage, value);

  /// Tarifa electrica (BOB/kWh). Default: [kDefaultKwhRate].
  Future<Decimal> getKwhRate() =>
      getDecimal(SettingsKeys.kwhRate, Decimal.parse(kDefaultKwhRate.toString()));

  Future<void> setKwhRate(Decimal value) =>
      setDecimal(SettingsKeys.kwhRate, value);

  /// Nombre de la empresa. Default: '3dCalc'.
  Future<String> getCompanyName() =>
      getString(SettingsKeys.companyName, '3dCalc');

  Future<void> setCompanyName(String value) =>
      setString(SettingsKeys.companyName, value);

  /// Logo de la empresa en base64. Null si no configurado.
  Future<String?> getCompanyLogo() =>
      getStringOrNull(SettingsKeys.companyLogo);

  Future<void> setCompanyLogo(String? base64) async {
    if (base64 == null) {
      // Borrar la key
      await (_db.delete(_db.settingsTable)
            ..where((s) => s.key.equals(SettingsKeys.companyLogo)))
          .go();
      return;
    }
    await setString(SettingsKeys.companyLogo, base64);
  }

  /// Lee el valor como String? (null si no existe).
  Future<String?> getStringOrNull(String key) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  // === F1: Mano de obra + Post-procesado ===

  /// Tarifa de mano de obra (BOB/hora).
  Future<Decimal> getLaborRate() =>
      getDecimal(SettingsKeys.laborRate, Decimal.zero);

  Future<void> setLaborRate(Decimal value) =>
      setDecimal(SettingsKeys.laborRate, value);

  /// Tasa de post-procesado (% del costo de materiales).
  Future<Decimal> getPostProcessRate() =>
      getDecimal(SettingsKeys.postProcessRate, Decimal.zero);

  Future<void> setPostProcessRate(Decimal value) =>
      setDecimal(SettingsKeys.postProcessRate, value);

  /// Tasa de falla (% del costo base).
  Future<Decimal> getFailureRate() =>
      getDecimal(SettingsKeys.failureRate, Decimal.zero);

  Future<void> setFailureRate(Decimal value) =>
      setDecimal(SettingsKeys.failureRate, value);

  /// Cargo minimo por cotizacion (BOB).
  Future<Decimal> getMinimumCharge() =>
      getDecimal(SettingsKeys.minimumCharge, Decimal.zero);

  Future<void> setMinimumCharge(Decimal value) =>
      setDecimal(SettingsKeys.minimumCharge, value);

  /// Markup por desperdicio de materiales (%).
  Future<Decimal> getMarkupOnMaterials() =>
      getDecimal(SettingsKeys.markupOnMaterials, Decimal.zero);

  Future<void> setMarkupOnMaterials(Decimal value) =>
      setDecimal(SettingsKeys.markupOnMaterials, value);

  // === F4: Moneda ===

  /// Codigo ISO de moneda activa. Default: "USD".
  Future<String> getCurrencyCode() =>
      getString(SettingsKeys.currencyCode, 'USD');

  Future<void> setCurrencyCode(String value) =>
      setString(SettingsKeys.currencyCode, value);
}

/// Helper privado para parseo seguro.
class DecimalParseSafe {
  const DecimalParseSafe._();

  static Decimal fromStringOrFallback(String value, Decimal fallback) {
    try {
      return Decimal.parse(value);
    } on Exception {
      return fallback;
    }
  }
}
