// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla de settings globales (key-value).
///
/// Almacena preferencias de la app: ganancia base, tarifa electrica, etc.
/// Key es unica por fila.
@DataClassName('Setting')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  /// Clave unica del setting (ej: "profit_base_percentage").
  TextColumn get key => text().withLength(min: 1, max: 100)();

  /// Valor del setting como string. Conversion a tipo especifico en repository.
  TextColumn get value => text()();

  /// Ultima actualizacion. UTC.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
