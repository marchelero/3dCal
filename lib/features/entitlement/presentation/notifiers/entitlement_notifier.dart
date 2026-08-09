// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/revenuecat_keys.dart';
import '../../../../core/database/app_database.dart';
import '../../data/entitlement_cache.dart';
import '../../data/entitlement_repository.dart';
import '../../data/payment_service.dart';
import '../providers/entitlement_providers.dart';

/// Sealed hierarchy del estado de entitlement.
///
/// [EntitlementNotifier] emite uno de estos valores como data del
/// [AsyncValue]. `isProProvider` (derived) chequea `is EntitlementPro`
/// y retorna `true` solo en ese caso — asi, durante loading o cuando
/// el state es [EntitlementFree]/[EntitlementUnknown], isPro=false y
/// los gates se mantienen cerrados (no flicker "Pro" durante cold start).
sealed class EntitlementState {
  const EntitlementState();
}

/// "No tenemos respuesta definitiva todavia".
///
/// Reservado para escenarios donde el notifier esta en un estado
/// intermedio (e.g. tras un reset manual o antes del primer `build`
/// exitoso). El `build()` actual NO emite este valor — emite
/// [EntitlementFree] o [EntitlementPro] directo. Se mantiene en el
/// type system para que callers puedan distinguir "free conocido" de
/// "loading" sin inspeccionar el [AsyncValue].
class EntitlementUnknown extends EntitlementState {
  const EntitlementUnknown();
}

/// Usuario en el tier free. `isPro = false` (gates cerrados).
class EntitlementFree extends EntitlementState {
  const EntitlementFree();
}

/// Usuario en el tier Pro. [source] indica el origen del entitlement
/// (hoy: `'lifetime_purchase'`). [validatedAt] es la ultima vez que
/// se valido el receipt contra la store (UTC), o `null` si nunca se
/// valido (ej: compra offline).
class EntitlementPro extends EntitlementState {
  const EntitlementPro({required this.source, this.validatedAt});

  final String source;
  final DateTime? validatedAt;
}

/// Async notifier del estado de entitlement.
///
/// **Boot path** (en [build]):
/// 1. Lee [EntitlementCache] (sincrono — SharedPreferences es in-process).
/// 2. Si el cache dice Pro, emite [EntitlementPro] inmediato. Si el
///    `validatedAt` del cache tiene > [kEntitlementStaleThreshold] dias
///    (o es null), dispara un [restore] fire-and-forget contra
///    [PaymentService] (no bloquea el primer frame; el state visible
///    sigue siendo Pro mientras corre).
/// 3. Si el cache esta vacio o dice Free, consulta
///    [EntitlementRepository.getActive]. Si retorna fila, hidrata el
///    cache + emite [EntitlementPro]. Si no, emite [EntitlementFree].
///
/// **Mutaciones** (post-purchase / restore / refresh manual):
/// - [activate] — purchase success o restore-active. Inserta fila en
///   DB + actualiza cache.
/// - [deactivate] — restore-empty. `repo.clear()` + cache clean.
/// - [purchase] — wrapper que delega al [PaymentService.purchase] y
///   reacciona al resultado.
/// - [restore] — wrapper que delega al [PaymentService.restore] y
///   reacciona al resultado.
/// - [refresh] — re-consulta DB, actualiza state segun resultado.
class EntitlementNotifier extends AsyncNotifier<EntitlementState> {
  @override
  Future<EntitlementState> build() async {
    final cache = ref.read(entitlementCacheProvider);

    if (cache.isPro) {
      if (_isStale(cache.validatedAt)) {
        // Fire and forget — emite Pro desde cache, restore en background.
        // El resultado puede downgradear a Free si el store dice empty.
        unawaited(restore());
      }
      return EntitlementPro(
        source: cache.source ?? kSourceLifetimePurchase,
        validatedAt: cache.validatedAt,
      );
    }

    // Cache dice Free (o vacio) → consultamos DB.
    final repo = ref.read(entitlementRepositoryProvider);
    final active = await repo.getActive();
    if (active != null) {
      // Hidratamos el cache para que el proximo boot sea instant.
      await cache.setActive(
        source: active.source,
        validatedAt: active.validatedAt,
      );
      return EntitlementPro(
        source: active.source,
        validatedAt: active.validatedAt,
      );
    }
    return const EntitlementFree();
  }

  /// Compra el [productId] via [PaymentService].
  ///
  /// **Success** → [activate] (persiste DB + cache + state).
  /// **Cancel** → no-op. El user tap "Atras" en el sheet de Play.
  /// **Error** → no-op + log. El state queda como estaba.
  ///
  /// Retorna el [PaymentResult] para que el caller (paywall) pueda dar
  /// feedback segun el caso (contrato de `payment_service.dart`: "el
  /// caller debe mostrar feedback segun el caso").
  Future<PaymentResult> purchase({required String productId}) async {
    final result = await ref.read(paymentServiceProvider).purchase(
          productId: productId,
        );
    switch (result) {
      case PaymentSuccess():
        await activate(source: kSourceLifetimePurchase);
      case PaymentCancelled():
        // User cancelo. No tocar state.
        break;
      case PaymentError(:final message):
        debugPrint('[Entitlement] purchase error: $message');
      // No tocar state.
    }
    return result;
  }

  /// Restaura purchases via [PaymentService].
  ///
  /// Llamado desde:
  /// - **Boton "Restaurar"** en settings o paywall (T11).
  /// - **Boot stale** (en [build]) si el cache dice Pro pero esta stale.
  ///
  /// **Active** → [activate] (persiste DB + cache + state).
  /// **Empty** → [deactivate] (clear DB + cache + state).
  /// **Error** → log + no-op (mantenemos state actual).
  ///
  /// Retorna el [RestoreResult] para que el caller (settings page, paywall)
  /// pueda mostrar feedback segun el caso: exito / sin compras / error.
  Future<RestoreResult> restore() async {
    final result = await ref.read(paymentServiceProvider).restore();
    switch (result) {
      case RestoreActive():
        await activate(source: kSourceLifetimePurchase);
      case RestoreEmpty():
        await deactivate();
      case RestoreError(:final message):
        debugPrint('[Entitlement] restore error: $message');
      // No tocar state — cache local podria seguir siendo valido.
    }
    return result;
  }

  /// Activa el entitlement Pro (tras un purchase success o restore-active).
  ///
  /// Persiste fila en [EntitlementRepository] + actualiza [EntitlementCache].
  /// El state final es [EntitlementPro] con [source] del parametro.
  /// [validatedAt] = `DateTime.now().toUtc()` (momento de activacion).
  Future<void> activate({required String source}) async {
    final repo = ref.read(entitlementRepositoryProvider);
    final cache = ref.read(entitlementCacheProvider);
    final now = DateTime.now().toUtc();

    final next = await AsyncValue.guard<EntitlementState>(() async {
      await repo.save(EntitlementsCompanion.insert(
        source: source,
        productId: kProProductId,
        purchasedAt: now,
        validatedAt: Value(now),
      ));
      await cache.setActive(source: source, validatedAt: now);
      return EntitlementPro(source: source, validatedAt: now);
    });
    state = next;
  }

  /// Desactiva el entitlement (tras un restore que reporta vacio).
  ///
  /// `repo.clear()` marca todas las filas inactivas (soft delete,
  /// preserva historial de auditoria) + borra los 3 keys de SP.
  /// State final: [EntitlementFree].
  Future<void> deactivate() async {
    final repo = ref.read(entitlementRepositoryProvider);
    final cache = ref.read(entitlementCacheProvider);

    final next = await AsyncValue.guard<EntitlementState>(() async {
      await repo.clear();
      await cache.clear();
      return const EntitlementFree();
    });
    state = next;
  }

  /// Re-consulta [EntitlementRepository.getActive] y actualiza state
  /// + cache. Usado por el "Restore purchases" manual y por
  /// integraciones que necesitan forzar un resync (e.g. despues de un
  /// webhook del payment provider).
  Future<void> refresh() async {
    final repo = ref.read(entitlementRepositoryProvider);
    final cache = ref.read(entitlementCacheProvider);

    final next = await AsyncValue.guard<EntitlementState>(() async {
      final active = await repo.getActive();
      if (active != null) {
        await cache.setActive(
          source: active.source,
          validatedAt: active.validatedAt,
        );
        return EntitlementPro(
          source: active.source,
          validatedAt: active.validatedAt,
        );
      }
      await cache.clear();
      return const EntitlementFree();
    });
    state = next;
  }

  bool _isStale(DateTime? validatedAt) {
    if (validatedAt == null) return true;
    final now = DateTime.now().toUtc();
    return now.difference(validatedAt) > kEntitlementStaleThreshold;
  }
}
