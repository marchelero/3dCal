// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Contrato del repository de entitlements.
///
/// Define las operaciones de lectura/escritura sobre la tabla `entitlements`.
/// La invariante "1 fila activa a la vez" se enforce en [save] (no en DB —
/// decision documentada en `entitlements_table.dart`).
///
/// **Por que abstract**: el plan/model layer (`EntitlementService` de T4)
/// depende solo de este contrato, no de Drift. Esto permite:
/// - Mockear facilmente en tests de T4/T9 (PaymentService flow).
/// - Migrar de Drift a otra DB sin tocar el domain layer.
/// - Tener multiples impls (ej: fake para onboarding, real para prod).
abstract class EntitlementRepository {
  /// Inserta una fila de entitlement. Si [entry] quiere estar activa
  /// (`isActive` absent o `Value(true)`), primero desactiva cualquier fila
  /// activa existente para mantener la invariante "1 activa". Si
  /// `isActive=Value(false)` se pasa explicito, inserta como registro
  /// historico sin tocar la activa actual.
  ///
  /// Retorna el id de la fila insertada.
  Future<int> save(EntitlementsCompanion entry);

  /// Retorna la unica fila activa, o null si no hay ninguna.
  Future<Entitlement?> getActive();

  /// Marca TODAS las filas como inactivas (no borra — mantiene historial
  /// para auditoria). Usado en `restore()` cuando RevenueCat reporta
  /// "no subscription" — el entitlement anterior se desactiva pero
  /// permanece en la DB.
  ///
  /// Retorna el count de filas afectadas.
  Future<int> clear();

  /// Stream reactivo de la fila activa. Emite `null` cuando no hay activa.
  /// Alimenta el `isProProvider` de Riverpod (T4): cualquier cambio en
  /// la tabla (purchase, restore, clear) se propaga automaticamente.
  Stream<Entitlement?> watchActive();
}

/// Implementacion Drift de [EntitlementRepository].
///
/// **Patron del proyecto**: queries inline en el repository (no
/// `@DriftAccessor`). El repo envuelve la tabla con `AppDatabase`. Esto
/// matchea el resto del codebase (`PrinterRepository`, `FilamentRepository`,
/// `SettingsRepository`, `CalculationRepository`).
///
/// **Atomicidad de [save]**: la operacion "desactivar previa + insertar
/// nueva" corre dentro de `_db.transaction`. Si la insercion falla, el
/// `UPDATE` hace rollback y la fila activa previa se mantiene. Esto es
/// importante para no perder el estado Pro ante un fallo de I/O.
///
/// **No-op en DB vacia**: `_deactivateAll` ejecuta un `UPDATE` sin `WHERE`.
/// Drift lo traduce a un no-op si la tabla tiene 0 filas, retornando 0
/// filas afectadas.
class DriftEntitlementRepository implements EntitlementRepository {
  const DriftEntitlementRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> save(EntitlementsCompanion entry) {
    return _db.transaction(() async {
      if (_wantsActive(entry)) {
        await _deactivateAll();
      }
      return _db.into(_db.entitlements).insert(entry);
    });
  }

  @override
  Future<Entitlement?> getActive() {
    return (_db.select(_db.entitlements)
          ..where((e) => e.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<int> clear() => _deactivateAll();

  @override
  Stream<Entitlement?> watchActive() {
    // NO usar `..limit(1); watchSingleOrNull()` aca: Drift cierra el
    // stream cuando la row trackeada deja de matchear el WHERE (ej: tras
    // `clear()` que pone isActive=false). En su lugar, observamos la lista
    // completa y mapeamos a la primera fila o null. Stream nunca cierra.
    return (_db.select(_db.entitlements)
          ..where((e) => e.isActive.equals(true)))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// True si el companion quiere que la nueva fila quede activa
  /// (`isActive` absent o `Value(true)`).
  ///
  /// Si el caller pasa `isActive=Value(false)` explicito, asumimos que
  /// quiere un registro historico (audit) y no tocamos la activa actual.
  bool _wantsActive(EntitlementsCompanion entry) {
    return !entry.isActive.present || entry.isActive.value == true;
  }

  /// Marca todas las filas como `isActive=false`. Usado por:
  /// - [save] (cuando reemplazamos la activa).
  /// - [clear] (restore dice "no hay entitlement").
  Future<int> _deactivateAll() {
    return _db.update(_db.entitlements)
        .write(const EntitlementsCompanion(isActive: Value(false)));
  }
}
