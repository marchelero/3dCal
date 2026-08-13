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
/// 2. Si el cache dice Pro, emite [EntitlementPro] inmediato y dispara
///    [syncEntitlementWithStore] fire-and-forget: consulta la store como
///    fuente de verdad (no bloquea el primer frame; el state visible
///    sigue siendo Pro mientras corre). Si la store no puede determinar
///    (offline/web) y ademas el cache esta stale
///    (> [kEntitlementStaleThreshold] dias o validatedAt null), cae al
///    fallback legacy [restore] async.
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
  /// Subscripción al [PaymentService.proRevocationStream]. Se cancela con
  /// `ref.onDispose` (el notifier no es autoDispose: vive con la app).
  StreamSubscription<void>? _revocationSub;

  @override
  Future<EntitlementState> build() async {
    _subscribeToRevocations();

    final cache = ref.read(entitlementCacheProvider);

    if (cache.isPro) {
      // Fire and forget — emite Pro desde cache (primer frame rapido) y
      // valida contra la store en background. Asi un refund/revocacion que
      // paso con la app cerrada no deja el cache mintiendo hasta el
      // restore stale de 7 dias. El fallback legacy [restore] corre solo
      // cuando la store no puede determinar (offline) y el cache esta stale.
      unawaited(_syncEntitlementWithStore());
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

  /// Escucha revocaciones del entitlement (refund/cancel detectado por
  /// RevenueCat mientras la app corre) para bajar a Free en tiempo real.
  ///
  /// **Race guard**: solo actuamos si el state actual es [EntitlementPro].
  /// Asi un evento que llega durante el boot (loading), tras un cancel,
  /// o mientras un purchase/restore esta en vuelo, es un no-op. La
  /// desactivacion es idempotente ([deactivate] con state Free es no-op).
  void _subscribeToRevocations() {
    if (_revocationSub != null) return;
    _revocationSub = ref
        .read(paymentServiceProvider)
        .proRevocationStream
        .listen((_) {
          final current = state.value;
          if (current is EntitlementPro) {
            unawaited(deactivate());
          }
        });
    ref.onDispose(() => _revocationSub?.cancel());
  }

  /// Valida contra la store (fuente de verdad) que el entitlement `pro`
  /// siga activo. Se dispara en cada boot con cache Pro (fire-and-forget,
  /// no bloquea el primer frame).
  ///
  /// - `true` → refresh `validatedAt` (cache + repo) para espaciar futuros
  ///   checks. Solo si el state actual es [EntitlementPro] y el validatedAt
  ///   cacheado no es mas nuevo que este sync (una purchase/restore en
  ///   vuelo gana con su propio timestamp).
  /// - `false` → downgrade a Free via [deactivate], race-guardado igual que
  ///   [proRevocationStream] (solo si el state actual es [EntitlementPro]).
  /// - `null` → no se puede determinar (offline / web / no configurado). El
  ///   cache local se mantiene como fallback; si ademas estaba stale, cae
  ///   al legacy [restore] para que el user se re-valide eventualmente.
  Future<void> _syncEntitlementWithStore() async {
    // Momento del sync capturado ANTES del await: si durante la consulta a
    // la store ocurre una purchase/restore, su validatedAt sera mas nuevo
    // y este sync no lo pisara (regla "nunca sobrescribir timestamp nuevo").
    final syncTime = DateTime.now().toUtc();
    final storeActive = await ref
        .read(paymentServiceProvider)
        .isProActiveOnStore();

    if (storeActive == null) {
      // Offline / web / SDK no configurado → cache local como fallback.
      // Si ademas el cache esta stale, revalidamos via el legacy restore.
      final cache = ref.read(entitlementCacheProvider);
      if (_isStale(cache.validatedAt)) {
        unawaited(restore());
      }
      return;
    }

    // Si el build aun no emitió su primer state (posible solo cuando el
    // chequeo a la store es instantaneo, e.g. fakes en tests), cedemos un
    // tick del event loop: los microtasks del build (que setean
    // `state.value` a Pro desde cache) se flush antes de cualquier timer,
    // asi los race guards de abajo ven el state ya emitido.
    if (state.value == null) {
      await Future<void>.delayed(Duration.zero);
    }

    if (storeActive) {
      await _refreshValidatedAt(syncTime);
      return;
    }

    // Store dice que `pro` NO esta activo (refund/revocado con la app
    // cerrada). Race guard: solo actuamos si el state es Pro.
    final current = state.value;
    if (current is EntitlementPro) {
      unawaited(deactivate());
    }
  }

  /// Refresca el `validatedAt` de cache + repo (si hay fila activa) al
  /// momento del sync. Non-throwing: cualquier fallo → debugPrint + no-op.
  ///
  /// Guards:
  /// - El state actual debe ser [EntitlementPro] (mismo race guard que la
  ///   revocacion en vivo).
  /// - Nunca sobrescribir un validatedAt cacheado mas nuevo que [validatedAt]
  ///   (una purchase/restore en vuelo gana con su propio timestamp).
  Future<void> _refreshValidatedAt(DateTime validatedAt) async {
    try {
      final current = state.value;
      if (current is! EntitlementPro) return;

      final cache = ref.read(entitlementCacheProvider);
      final cachedValidatedAt = cache.validatedAt;
      if (cachedValidatedAt != null &&
          cachedValidatedAt.isAfter(validatedAt)) {
        return;
      }

      await cache.setActive(
        source: cache.source ?? current.source,
        validatedAt: validatedAt,
      );

      final repo = ref.read(entitlementRepositoryProvider);
      final active = await repo.getActive();
      if (active != null) {
        await repo.save(
          EntitlementsCompanion.insert(
            source: active.source,
            productId: active.productId,
            purchasedAt: active.purchasedAt,
            validatedAt: Value(validatedAt),
          ),
        );
      }

      // State consistente con el cache (solo si sigue siendo Pro).
      if (state.value is EntitlementPro) {
        state = AsyncData(
          EntitlementPro(source: current.source, validatedAt: validatedAt),
        );
      }
    } catch (e) {
      debugPrint('[Entitlement] refresh validatedAt fallo: $e');
    }
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
    final result = await ref
        .read(paymentServiceProvider)
        .purchase(productId: productId);
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
      await repo.save(
        EntitlementsCompanion.insert(
          source: source,
          productId: kProProductId,
          purchasedAt: now,
          validatedAt: Value(now),
        ),
      );
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
