// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/payment_service.dart';
import '../notifiers/entitlement_notifier.dart';
import '../providers/entitlement_providers.dart';

/// Pantalla `/paywall` — upsell del unlock one-time a Pro.
///
/// **Estados** (driven por [entitlementNotifierProvider]):
/// - `AsyncValue.loading()` → muestra spinner en body.
/// - `AsyncValue.error(_, _)` → muestra SnackBar con [EsBO.paywallErrorGeneric]
///   + body de Free (asi el user puede reintentar via Unlock).
/// - `AsyncValue.data(EntitlementPro)` → muestra UI "Ya tienes Pro" + Close.
/// - `AsyncValue.data(EntitlementFree)` → muestra UI de compra completa
///   (titulo, subtitulo, precio, 5 features, Unlock, Restore).
///
/// **Acciones**:
/// - `Unlock` → `ref.read(entitlementNotifierProvider.notifier).purchase(...)`
///   con [kProProductId]. El result se maneja internamente en el notifier
///   (success → activate, cancel/error → no-op).
/// - `Restore` → `ref.read(entitlementNotifierProvider.notifier).restore()`.
/// - `Close` (solo en Pro state) → `context.pop()`.
///
/// **SnackBar en error**: usamos [ref.listen] con `fireImmediately: true` para
/// que la SnackBar aparezca en el primer build si el state ya es error. Asi
/// el user ve el feedback sin tener que tocar nada.
///
/// **Loading durante accion**: usamos [EntitlementNotifier.purchase] que NO
/// emite `AsyncValue.loading()` durante el await (devuelve el estado previo
/// hasta que el resultado llega). Asi que la UI no muestra spinner al tap;
/// deshabilitamos los botones mientras la accion corre para evitar doble-tap.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  @override
  void initState() {
    super.initState();
    // Listener reactivo: muestra SnackBar en cada transicion a error.
    // `fireImmediately: true` cubre el caso de cold start con state ya
    // en error. El callback difiere la showSnackBar al proximo frame
    // (`addPostFrameCallback`) porque `ScaffoldMessenger.of(context)` no
    // esta disponible durante `initState` (los InheritedWidgets se
    // setean despues). Sin el postFrame, throw "dependOnInheritedWidget
    // was called before initState completed".
    //
    // `dynamic` para `_errorSub` porque `ProviderSubscription` no es
    // parte de la API publica de `flutter_riverpod`.
    _errorSub = ref.listenManual<AsyncValue<EntitlementState>>(
      entitlementNotifierProvider,
      (prev, next) {
        if (next.hasError && prev?.hasError != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.error(EsBO.paywallErrorGeneric),
            );
          });
        }
      },
      fireImmediately: true,
    );
  }

  // `dynamic` porque `ProviderSubscription` no es parte de la API publica
  // de `flutter_riverpod` (vive en `riverpod/src/framework/`). Solo usamos
  // `.close()` en `dispose`, asi que el cast dinamico no tiene costo.
  // ignore: avoid_dynamic_calls
  late final dynamic _errorSub;

  @override
  void dispose() {
    // ignore: avoid_dynamic_calls
    _errorSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncEntitlement = ref.watch(entitlementNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: EsBO.paywallClose,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: asyncEntitlement.when(
          loading: () => const _LoadingBody(),
          error: (error, stack) {
            // En error, mostramos el body de Free (asi el user puede reintentar
            // Unlock/Restore). La SnackBar de error se dispara via ref.listen.
            return const _FreeBody();
          },
          data: (state) {
            if (state is EntitlementPro) {
              return const _AlreadyProBody();
            }
            return const _FreeBody();
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Loading body
// ───────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Already Pro body
// ───────────────────────────────────────────────────────────

class _AlreadyProBody extends StatelessWidget {
  const _AlreadyProBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              EsBO.paywallAlreadyPro,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              child: Text(EsBO.paywallClose),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Free body (purchase UI)
// ───────────────────────────────────────────────────────────

class _FreeBody extends ConsumerStatefulWidget {
  const _FreeBody();

  @override
  ConsumerState<_FreeBody> createState() => _FreeBodyState();
}

class _FreeBodyState extends ConsumerState<_FreeBody> {
  /// `true` mientras una accion (purchase o restore) esta en curso.
  /// Evita doble-tap + da feedback visual sin bloquear la UI.
  bool _busy = false;

  Future<void> _onUnlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(entitlementNotifierProvider.notifier)
          .purchase(productId: kProProductId);
      if (!mounted) return;
      switch (result) {
        // Success: el notifier ya activo Pro → la UI pasa a "Already Pro".
        case PaymentSuccess():
          break;
        // Cancel: el user se arrepintio en el sheet de Play. No-op.
        case PaymentCancelled():
          break;
        // Error: feedback explicito (el AsyncValue no transiciona a error,
        // asi que el ref.listen del paywall no cubre este caso).
        case PaymentError():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(AppSnackBar.error(EsBO.paywallErrorGeneric));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRestore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(entitlementNotifierProvider.notifier)
          .restore();
      if (!mounted) return;
      switch (result) {
        // Active: el notifier ya activo Pro → la UI pasa a "Already Pro".
        case RestoreActive():
          break;
        // Empty: no hay compras previas en la cuenta — feedback informativo.
        case RestoreEmpty():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(AppSnackBar.info(context, EsBO.settingsRestoreEmpty));
        // Error: feedback explicito (no se cambio el state).
        case RestoreError():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(AppSnackBar.error(EsBO.commonErrorGeneric));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = EsBO.paywallPrice;
    final features = EsBO.paywallFeatures;
    final unlockLabel = EsBO.paywallUnlockButton(price);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero header ──
          Icon(
            Icons.workspace_premium_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            EsBO.paywallTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsBO.paywallSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            price,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Features card ──
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  for (final f in features)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(f),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── CTA: Unlock ──
          FilledButton(
            onPressed: _busy ? null : _onUnlock,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(unlockLabel),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Secondary: Restore ──
          TextButton(
            onPressed: _busy ? null : _onRestore,
            child: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(EsBO.paywallRestoreButton),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Store compliance links (T22) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(kPrivacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  EsBO.paywallPrivacyPolicy,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '|',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(kTermsOfServiceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  EsBO.paywallTermsOfService,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
