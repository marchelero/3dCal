// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

import 'calculations_table.dart';

/// Tabla child de materiales de una cotizacion.
///
/// Almacena un material POR FILA con snapshots. Asi, si se borra o edita
/// un filamento del catalogo, las cotizaciones historicas mantienen:
/// - [label] (ej: "PLA Negro")
/// - [pricePerBobbinSnapshot] y [gramsPerBobbinSnapshot]
///
/// La FK a [Calculations] es dura con CASCADE: al borrar la cotizacion, se
/// borran sus materiales. La FK a filamentos es soft (nullable) para que
/// proformas rapidas sin catalogo funcionen.
@DataClassName('CalculationMaterial')
class CalculationMaterials extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get calculationId => integer().references(
        Calculations,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Soft FK a `filaments.id`. Nullable.
  IntColumn get filamentId => integer().nullable()();

  /// Etiqueta visible. Ej: "PLA Negro", "Generico".
  TextColumn get label => text()();

  /// Peso del material en la pieza (gramos).
  RealColumn get weightGrams => real()();

  /// Snapshot del precio por bobina al guardar.
  RealColumn get pricePerBobbinSnapshot => real()();

  /// Snapshot de gramos por bobina al guardar.
  RealColumn get gramsPerBobbinSnapshot => real()();
}
