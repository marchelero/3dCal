// ignore_for_file: public_member_api_docs
import 'package:drift/drift.dart';

/// Tabla de entitlements (suscripciones / compras one-time).
///
/// Almacena el estado Pro del usuario para que persista entre cierres de
/// app. Una sola fila activa a la vez (enforcement en repository, NO
/// constraint de DB — soft rule para simplicidad y para no romper
/// restores transaccionales).
///
/// **Por que existe**: cache persistente del Pro state. El cache rapido
/// en SharedPreferences se hidrata desde esta tabla al boot (T4 del
/// plan). Si la DB esta vacia y SP vacio → isPro = false. Si DB tiene
/// una fila activa → isPro = true.
///
/// **Multi-store-ready**: `source` admite 'play_store' (hoy),
/// 'appstore' | 'license_key' (futuro). El codigo mobile no se rompe
/// cuando se sume un nuevo store.
///
/// **Sin DEFAULT para purchasedAt** porque siempre viene del receipt —
/// inventar un default aca seria un foot-gun (fila con fecha 1970 que
/// parece "valida" en queries). El repository SIEMPRE pasa purchasedAt
/// en el insert (T3).
@DataClassName('Entitlement')
class Entitlements extends Table {
  /// PK auto-increment. Identificador interno de la fila.
  IntColumn get id => integer().autoIncrement()();

  /// Origen de la compra. Valores esperados: 'play_store' (hoy),
  /// 'appstore' o 'license_key' (futuro). CHECK constraint en
  /// repository si hace falta (T3).
  TextColumn get source => text()();

  /// Producto comprado. Ej: 'tresdcal_pro_lifetime'.
  TextColumn get productId => text()();

  /// Fecha de la compra (UTC). Sale del receipt, no del cliente.
  DateTimeColumn get purchasedAt => dateTime()();

  /// Ultima vez que RevenueCat valido el receipt (UTC). Nullable si
  /// nunca se valido (ej: compra offline). Se actualiza en revalidates.
  DateTimeColumn get validatedAt => dateTime().nullable()();

  /// Fecha de expiracion (UTC). **NULL = lifetime (one-time unlock)**.
  /// El modelo soporta suscripciones futuras cambiando este campo, sin
  /// tocar la tabla.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Receipt original en base64 o JSON. Nullable. Sirve para auditoria
  /// offline y revalidacion. Tamano puede ser grande (KBs).
  TextColumn get receiptData => text().nullable()();

  /// Si la fila representa el entitlement activo. Default `true` para
  /// que la primera fila insertada sea la activa sin tocar el repository.
  /// Solo 1 fila activa a la vez (enforcement en repository).
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
