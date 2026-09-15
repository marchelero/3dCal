// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla de impresoras del taller.
///
/// Cada impresora tiene una marca, un modelo (nombre) y consumo en Watts.
/// Una sola puede marcarse como `isDefault = true`.
///
/// F5 (depreciacion): [purchaseCost] + [usefulLifeHours] opcionales.
/// [currentHours] registra las horas acumuladas de uso.
@DataClassName('PrinterProfile')
class Printers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Marca (ej: "Anycubic", "Creality"). Opcional.
  TextColumn get brand => text().nullable()();

  /// Nombre del modelo (ej: "Kobra 3"). Requerido, 1-100 chars.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Consumo promedio en Watts (>= 0). 0 = sin impresora.
  IntColumn get averageWatts => integer()();

  /// Precio de compra de la impresora (BOB). Null = no configurado.
  RealColumn get purchaseCost => real().nullable()();

  /// Vida util estimada en horas de impresion. Null = no configurado.
  /// Se auto-carga del catalogo al seleccionar modelo.
  IntColumn get usefulLifeHours => integer().nullable()();

  /// Horas acumuladas de uso. Se incrementa automaticamente al validar
  /// cotizaciones. Null = 0 (impresora nueva sin uso registrado).
  IntColumn get currentHours => integer().nullable()();

  /// Marca como default. Solo uno a la vez (enforcement en repository).
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Fecha de creacion. UTC.
  DateTimeColumn get createdAt => dateTime()();
}
