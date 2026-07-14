// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla de filamentos del catalogo.
///
/// Cada filamento tiene un nombre, marca opcional, precio por bobina (BOB) y
/// gramos por bobina. Una sola bobina puede marcarse como `isDefault = true`.
///
/// **Nota sobre tipos monetarios**: drift no soporta `Decimal` nativamente.
/// Almacenamos precio/gramos en `REAL` (double). Conversion a `Decimal` en
/// la capa de repository. Para valores <= 1e15 con 2 decimales, double es
/// exacto. Riesgo acotado para MVP.
@DataClassName('Filament')
class Filaments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nombre del filamento (ej: "PLA Negro"). Requerido, 1-100 chars.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Marca (ej: "eSun", "Prusament"). Opcional.
  TextColumn get brand => text().nullable()();

  /// Precio de la bobina en BOB. > 0.
  RealColumn get pricePerBobbin => real()();

  /// Gramos por bobina. > 0.
  RealColumn get gramsPerBobbin => real()();

  /// Marca como default. Solo uno a la vez.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Fecha de creacion. UTC.
  DateTimeColumn get createdAt => dateTime()();
}
