// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla de impresoras del taller.
///
/// Cada impresora tiene un nombre y un consumo promedio en Watts.
/// Una sola puede marcarse como `isDefault = true`.
@DataClassName('PrinterProfile')
class Printers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nombre del modelo (ej: "Anycubic Kobra 3"). Requerido, 1-100 chars.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Consumo promedio en Watts (>= 0). 0 = sin impresora.
  IntColumn get averageWatts => integer()();

  /// Marca como default. Solo uno a la vez (enforcement en repository).
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Fecha de creacion. UTC.
  DateTimeColumn get createdAt => dateTime()();
}
