// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que indica si el user actual es Pro.
///
/// **Uso**: el dashboard hace `ref.watch(dashboardIsProProvider)` para
/// decidir si muestra los chart sections completos o la teaser card
/// de upsell (T17).
///
/// **Override en prod**: la app real (en `main.dart` o donde se monta
/// el `ProviderScope` root) debe override este provider con la fuente
/// de verdad — `isProProvider` de `features/entitlement/` — para que
/// el dashboard refleje el estado de compra real.
///
/// **Override en tests**: los widget tests overridean este provider
/// directamente con `overrideWithValue(true|false)`. Esto desacopla
/// el dashboard del modulo de entitlement (que requiere DB + IAP mock
/// setup), y mantiene la superficie del gate trivial de testear.
final dashboardIsProProvider = Provider<bool>((ref) {
  // Default conservador: free. La app real lo override en el root
  // ProviderScope. En tests, cada test hace su propio override.
  return false;
});
