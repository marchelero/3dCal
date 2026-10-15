// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/providers.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme_mode_provider.dart';
import '../../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/perforation.dart';
import '../../widgets/summary_row.dart';

/// Cierre del flujo de setup: celebración + resumen tipo ticket de TODO lo
/// configurado + CTA final.
///
/// - `configStartButton` ("Empezar a cotizar") con EXACTAMENTE la semántica
///   de `_finish()` del stepper viejo: `SettingsKeys.onboardingDone = true`
///   (misma vía: SharedPreferences directo, igual que initial_config_page)
///   + `router.go('/')` (stack limpio → Home) + `push('/calculator')`.
/// - No persiste profit/kwh de nuevo: ya se persisten en vivo en el paso 4.
/// - Terminal: sin onNext; el back del sistema lo maneja el PopScope del
///   container (retrocede al paso 4, no cierra la app a mitad del flujo).
/// - Sin [TicketPreviewCard] abajo: el resumen completo ya está aquí.
/// - **Gate de obligatoriedad (2026-10-11)**: impresora y filamento son
///   obligatorios para llegar al cierre, así que sus filas SIEMPRE muestran
///   valor real. El fallback a `setupTicketPending` se mantiene como estado
///   defensivo barato (p. ej. si en el futuro se relaja el gate o el
///   usuario borra el default desde Ajustes con el flujo vivo).
class SummaryStep extends ConsumerStatefulWidget {
  const SummaryStep({super.key});

  @override
  ConsumerState<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends ConsumerState<SummaryStep> {
  // BUG-006: flag UI local efímero (evita doble tap del CTA final).
  bool _finishing = false;

  /// Semántica idéntica a `_finish()` del stepper viejo
  /// (initial_config_page.dart): marcar onboardingDone como pref cruda,
  /// cerrar /setup con go() para dejar stack limpio y recién entonces abrir
  /// el calculador encima. Sin este go(), /setup queda vivo en el stack y
  /// al volver atrás desde el calculador se regresa al setup → ciclo sin
  /// salida.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.onboardingDone, true);
    if (!mounted) return;
    final router = GoRouter.of(context);
    router.go('/');
    await router.push('/calculator');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);
    final themeMode = ref.watch(themeModeProvider).label;
    final defaultPrinter = ref.watch(defaultPrinterProvider);
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final settings = ref.watch(settingsNotifierProvider).value;
    final pending = EsBO.setupTicketPending;
    final profit = settings?.profitBase ?? Decimal.zero;
    final kwh = settings?.kwhRate ?? Decimal.zero;

    final rows = <(IconData, String, String)>[
      (
        Icons.attach_money_rounded,
        EsBO.configCurrency,
        '${currency.code} (${currency.symbol})',
      ),
      (Icons.palette_rounded, EsBO.settingsTheme, themeMode),
      (Icons.print_rounded, EsBO.printerTitle, defaultPrinter?.name ?? pending),
      (
        Icons.label_rounded,
        EsBO.filamentTitle,
        defaultFilament?.name ?? pending,
      ),
      (
        Icons.percent_rounded,
        EsBO.settingsProfitBase,
        profit > Decimal.zero ? '$profit %' : pending,
      ),
      (
        Icons.bolt_rounded,
        EsBO.settingsKwhRate(currency.symbol),
        kwh > Decimal.zero ? '$kwh ${currency.symbol}/kWh' : pending,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Celebración discreta: check grande con scale-in (sin deps).
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              key: const ValueKey('setup-done-check'),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            EsBO.setupDoneTitle,
            key: const ValueKey('setup-done-title'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsBO.setupDoneSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Ticket de resumen (mismo lenguaje visual que el preview).
          Container(
            key: const ValueKey('setup-done-summary'),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Perforation(
                    color: color.outlineVariant,
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < rows.length; i++)
                    _StaggeredRow(
                      index: i,
                      icon: rows[i].$1,
                      label: rows[i].$2,
                      value: rows[i].$3,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('setup-finish-button'),
              onPressed: _finishing ? null : _finish,
              child: Text(EsBO.configStartButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de resumen con aparición escalonada (Interval 0.1×i, 600 ms): la
/// celebración se siente sin dependencias nuevas de animación.
class _StaggeredRow extends StatelessWidget {
  const _StaggeredRow({
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
  });

  final int index;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Interval(0.1 * index, 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: SummaryRow(icon: icon, label: label, value: value),
    );
  }
}
