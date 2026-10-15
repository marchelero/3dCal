// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/backup/backup_models.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/draft_storage_providers.dart'
    show sharedPreferencesProvider;
import '../../../../core/storage/local_data_wipe_service.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme_mode_provider.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/page_header_card.dart';
import '../../../../shared/widgets/pro_active_badge.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../calculation/domain/dashboard_stats.dart';
import '../../../calculation/presentation/notifiers/calculations_notifier.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../../domain/settings.dart';
import '../notifiers/discount_tiers_notifier.dart';
import '../notifiers/settings_notifier.dart';
import '../widgets/settings_widgets.dart';

/// Pagina `/settings` — DRAMATICAMENTE rediseñada.
///
/// Sin AppBar. Header gradiente heroico. Cards con barra de acento a la
/// izquierda. Espaciado generoso. Visual moderna y limpia.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Filtro para no repetir la explicacion del redirect `/paywall` en cada
  /// rebuild de la pagina (HIGH-04 fix). Se resetea por sesion de app.
  static bool _paywallNoticeShown = false;

  /// Lee `?from=` de la ruta activa via GoRouter. `GoRouterState.of` LANZA
  /// si el arbol no tiene GoRouter (pagina bombeada sola en tests): se
  /// degrada a null sin romper el render.
  static String? _paywallOrigin(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.queryParameters['from'];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    // HIGH-04 fix (auditoria 2026-10-04): en web /paywall redirige a
    // /settings?from=paywall porque no existe flujo de compra. Se explica el
    // destino con un SnackBar (antes el redirect era silencioso y parecia
    // un salto sin motivo).
    //
    // `GoRouterState.of` throws cuando la pagina se bombea fuera de un
    // GoRouter (tests unitarios con MaterialApp suelto): se envuelve en
    // try/catch y se degrada a "sin query".
    final from = _paywallOrigin(context);
    if (from == 'paywall' && !_paywallNoticeShown) {
      _paywallNoticeShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.info(context, EsBO.paywallUnavailable));
      });
    }
    final asyncSettings = ref.watch(settingsNotifierProvider);
    return Scaffold(
      body: SafeArea(
        child: asyncSettings.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: EsBO.settingsErrorLoad,
            details: e.toString(),
            onRetry: () => ref.invalidate(settingsNotifierProvider),
          ),
          data: (settings) => _SettingsBody(
            settings: settings,
            showBack: ModalRoute.of(context)?.canPop ?? false,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Body — scroll vertical con header + secciones
// ─────────────────────────────────────────────────

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings, this.showBack = false});

  final Settings settings;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    // Patron de estado del gate visual (UX): "locked" solo cuando el
    // entitlement esta resuelto y el user es free. Durante el boot async
    // (loading) no se muestra badge ni dimming (evita falso "locked" en
    // cold start para un Pro real).
    final ent = ref.watch(entitlementNotifierProvider);
    final locked = !ent.isLoading && !ref.watch(isProProvider);
    final canRestore = ref.watch(paymentServiceProvider).isAvailable;

    return MaxWidthScrollView(
      maxWidth: 960,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          // ── CABECERA (bloque de titulo del plano) ──
          _SettingsHeader(showBack: showBack),
          const SizedBox(height: AppSpacing.xxl),

          // ── CONTENIDO CON PADDING LATERAL ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Empresa (arriba) ──
                GroupLabel(
                  icon: Icons.business_rounded,
                  title: EsBO.settingsCompany.toUpperCase(),
                  trailing: locked
                      ? ProBadge(accentColor: color.tertiary)
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  accentColor: color.tertiary,
                  divider: true,
                  children: [
                    _CompanyNameField(
                      initialValue: settings.companyName,
                      onSave: (value) => unawaited(
                        _persistAndNotify(
                          context,
                          () => ref
                              .read(settingsNotifierProvider.notifier)
                              .updateCompanyName(value),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _LogoPicker(currentLogoBase64: settings.companyLogoBase64),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Moneda e idioma ──
                GroupLabel(
                  icon: Icons.attach_money_rounded,
                  title: EsBO.settingsGroupCurrencyAndLanguage,
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  accentColor: color.primary,
                  divider: true,
                  children: [
                    _CurrencyPicker(),
                    const SizedBox(height: AppSpacing.lg),
                    _LocalePicker(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Apariencia ──
                GroupLabel(
                  icon: Icons.palette_rounded,
                  title: EsBO.settingsGroupAppearance,
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  accentColor: color.secondary,
                  divider: true,
                  children: [
                    Text(
                      EsBO.settingsTheme,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThemeModeSelector(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Datos (backup) ──
                GroupLabel(
                  icon: Icons.backup_rounded,
                  title: EsBO.settingsGroupYourData,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _BackupSection(),
                const SizedBox(height: AppSpacing.xxl),

                // ── Borrar datos de trabajo (AC-004 gap-remediation) ──
                GroupLabel(
                  icon: Icons.delete_sweep_rounded,
                  title: EsBO.settingsWipeTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _WipeDataSection(),
                const SizedBox(height: AppSpacing.xxl),

                // ── Repetir configuración (MED-4, NO destructivo) ──
                const _RepeatSetupSection(),
                const SizedBox(height: AppSpacing.xxl),

                if (canRestore) ...[
                  // ── Restaurar compras (T11) ──
                  GroupLabel(
                    icon: Icons.restore_rounded,
                    title: EsBO.settingsGroupAccount,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsCard(
                    accentColor: color.primary,
                    children: [RestoreButton()],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // ── Acerca de + Legal ──
                GroupLabel(
                  icon: Icons.info_outline_rounded,
                  title: EsBO.settingsGroupAbout,
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsCard(
                  accentColor: color.tertiary,
                  divider: true,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: IconBadge(
                        icon: Icons.privacy_tip_rounded,
                        background: color.primaryContainer,
                        foreground: color.onPrimaryContainer,
                      ),
                      title: Text(EsBO.paywallPrivacyPolicy),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: color.onSurfaceVariant,
                      ),
                      onTap: () => context.push('/legal/privacy'),
                    ),
                    const CardDivider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: IconBadge(
                        icon: Icons.gavel_rounded,
                        background: color.secondaryContainer,
                        foreground: color.onSecondaryContainer,
                      ),
                      title: Text(EsBO.paywallTermsOfService),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: color.onSurfaceVariant,
                      ),
                      onTap: () => context.push('/legal/terms'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl * 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar unificado.
void _showSavedSnack(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(AppSnackBar.success(EsBO.settingsSaved));
}

/// Ejecuta [action] y muestra el snackbar de exito SOLO si la persistencia
/// termina bien; si falla, muestra un error generico en vez de mentir con
/// "Guardado" (y evita tragarse el error async). Reemplaza el patron
/// `unawaited(updateX(...)); _showSavedSnack()`.
Future<void> _persistAndNotify(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    if (!context.mounted) return;
    _showSavedSnack(context);
  } catch (e) {
    debugPrint('[Settings] persist fallo: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.error(EsBO.commonErrorGeneric));
  }
}

// ─────────────────────────────────────────────────
// HEADER — bloque de titulo del plano
// ─────────────────────────────────────────────────

/// Cabecera de ajustes al estilo "bloque de titulo" del plano tecnico:
/// banda de cota superior, sello de engranaje y titulo AJUSTES en caps.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({this.showBack = false});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    // Cabecera estandar del shell: card generica (PageHeaderCard).
    // Sin version de app ni fila de privacidad; la flecha de retorno solo
    // aparece si la pagina fue empujada (standalone).
    return PageHeaderCard(
      title: EsBO.settingsTitle,
      subtitle: EsBO.settingsSubtitle,
      icon: Icons.tune_rounded,
      onBack: showBack
          ? () {
              if (context.canPop()) {
                context.pop();
              }
            }
          : null,
      backTooltip: EsBO.configBack,
    );
  }
}

// ─────────────────────────────────────────────────
// ThemeModeSelector — Claro / Oscuro / Sistema
// ─────────────────────────────────────────────────

/// Selector de tema Claro / Oscuro / Sistema.
class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return SegmentedButton<AppThemeMode>(
      segments: AppThemeMode.values.map((m) {
        IconData icon;
        switch (m) {
          case AppThemeMode.system:
            icon = Icons.settings_brightness_rounded;
          case AppThemeMode.light:
            icon = Icons.light_mode_rounded;
          case AppThemeMode.dark:
            icon = Icons.dark_mode_rounded;
        }
        return ButtonSegment(value: m, label: Text(m.label), icon: Icon(icon));
      }).toList(),
      selected: {current},
      onSelectionChanged: (selected) {
        ref.read(themeModeProvider.notifier).setMode(selected.first);
      },
      showSelectedIcon: false,
    );
  }
}

// ──────────────────────────────────────────────
// Company section: nombre + logo
// ──────────────────────────────────────────────

/// TextField para el nombre de la empresa con auto-save on blur.
///
/// **T12 gate**: si `isPro=false`, el field es `readOnly` y al tap
/// dispara un SnackBar con [EsBO.settingsBrandingLockedBody] +
/// accion [EsBO.settingsGoProAction] que navega a `/paywall`. El valor
/// visible sigue siendo el persistido (no se borra al upgradear a Pro).
class _CompanyNameField extends ConsumerStatefulWidget {
  const _CompanyNameField({required this.initialValue, required this.onSave});

  final String initialValue;
  final ValueChanged<String> onSave;

  @override
  ConsumerState<_CompanyNameField> createState() => _CompanyNameFieldState();
}

class _CompanyNameFieldState extends ConsumerState<_CompanyNameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _CompanyNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBlur(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == widget.initialValue) return;
    widget.onSave(trimmed);
  }

  /// SnackBar del gate. Llamado en el `onTap` cuando isPro=false.
  void _showLockedSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          EsBO.settingsBrandingLockedBody,
          actionLabel: EsBO.settingsGoProAction,
          onAction: () => GoRouter.of(context).push('/paywall'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final locked = !ent.isLoading && !isPro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.settingsCompanyName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Gate visual (UX): cuando el tier es free resuelto el field
        // esta atenuado (kLockedOpacity) para reforzar que es Pro. El
        // comportamiento (readOnly + SnackBar Go Pro) no cambia.
        Opacity(
          opacity: locked ? kLockedOpacity : 1.0,
          child: TextField(
            controller: _ctrl,
            readOnly: !isPro,
            decoration: InputDecoration(
              helperText: EsBO.settingsCompanyNameHelper,
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            onTap: isPro ? null : _showLockedSnack,
            onTapOutside: isPro
                ? (_) {
                    final value = _ctrl.text;
                    if (value.trim().isNotEmpty) _handleBlur(value);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// Logo picker: muestra logo actual + botones pick/remove.
///
/// **T12 gate**: si `isPro=false`, los botones de pick/remove disparan
/// un SnackBar con [EsBO.settingsBrandingLockedBody] + accion
/// [EsBO.settingsGoProAction] que navega a `/paywall`. El usuario
/// puede ver el logo (si lo tiene de un periodo Pro previo) pero no
/// modificarlo.
class _LogoPicker extends ConsumerWidget {
  const _LogoPicker({required this.currentLogoBase64});

  final String? currentLogoBase64;

  Future<void> _pickLogo(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      if (!context.mounted) return;
      await _persistAndNotify(
        context,
        () => ref
            .read(settingsNotifierProvider.notifier)
            .updateCompanyLogo(base64),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.settingsCompanyLogoError}: $e'));
    }
  }

  Future<void> _removeLogo(BuildContext context, WidgetRef ref) async {
    await _persistAndNotify(
      context,
      () => ref.read(settingsNotifierProvider.notifier).updateCompanyLogo(null),
    );
  }

  /// SnackBar del gate. Llamado en los botones de pick/remove cuando
  /// isPro=false.
  void _showLockedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          EsBO.settingsBrandingLockedBody,
          actionLabel: EsBO.settingsGoProAction,
          onAction: () => GoRouter.of(context).push('/paywall'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final locked = !ent.isLoading && !isPro;
    final hasLogo = currentLogoBase64 != null && currentLogoBase64!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.settingsCompanyLogo,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // Preview
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: color.outlineVariant, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLogo
                  ? Image.memory(
                      _base64ToBytes(currentLogoBase64!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_rounded,
                        color: color.onSurfaceVariant,
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_rounded,
                      color: color.onSurfaceVariant,
                      size: 32,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Buttons. Gate visual (UX): cuando el tier es free resuelto
            // se atenuan (kLockedOpacity) para reforzar que son Pro. El
            // comportamiento (SnackBar Go Pro en tap) no cambia.
            // Expanded: evita overflow de la columna de botones cuando la
            // fuente del dispositivo es grande (los labels envuelven).
            Expanded(
              child: Opacity(
                opacity: locked ? kLockedOpacity : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.image_rounded, size: 18),
                      label: Text(EsBO.settingsCompanyLogoPick),
                      onPressed: isPro
                          ? () => _pickLogo(context, ref)
                          : () => _showLockedSnack(context),
                    ),
                    if (hasLogo)
                      TextButton.icon(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: color.error,
                        ),
                        label: Text(
                          EsBO.settingsCompanyLogoRemove,
                          style: TextStyle(color: color.error),
                        ),
                        onPressed: isPro
                            ? () => _removeLogo(context, ref)
                            : () => _showLockedSnack(context),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Uint8List _base64ToBytes(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }
}

// ─────────────────────────────────────────────────
// CurrencyPicker — searchable dialog
// ─────────────────────────────────────────────────

/// Selector de moneda con busqueda integrada.
class _CurrencyPicker extends ConsumerWidget {
  const _CurrencyPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings =
        ref.watch(settingsNotifierProvider).value ?? Settings.defaults;
    final current = WorldCurrency.fromCode(settings.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.settingsCurrency,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.settingsCurrencyHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => _showCurrencySearch(context, ref, current),
          child: InputDecorator(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              suffixIcon: Icon(Icons.search),
            ),
            child: Text(
              '${current.code} — ${current.name} (${current.symbol})',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCurrencySearch(
    BuildContext context,
    WidgetRef ref,
    WorldCurrency current,
  ) async {
    final selected = await showDialog<WorldCurrency>(
      context: context,
      useSafeArea: false,
      builder: (_) => _CurrencySearchDialog(initial: current),
    );
    if (selected != null && context.mounted) {
      await _persistAndNotify(
        context,
        () => ref
            .read(settingsNotifierProvider.notifier)
            .updateCurrency(selected.code),
      );
    }
  }
}

/// Dialog de busqueda de monedas.
class _CurrencySearchDialog extends StatefulWidget {
  const _CurrencySearchDialog({required this.initial});
  final WorldCurrency initial;

  @override
  State<_CurrencySearchDialog> createState() => _CurrencySearchDialogState();
}

class _CurrencySearchDialogState extends State<_CurrencySearchDialog> {
  late final TextEditingController _ctrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    // Filtrar
    final all = WorldCurrency.all;
    final filtered = _query.isEmpty
        ? all
        : all.where((c) {
            final q = _query.toLowerCase();
            return c.code.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q);
          }).toList();

    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            // Header with search
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    // T2-5 (a11y): icon-only sin nombre accesible antes.
                    tooltip: EsBO.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: EsBO.settingsCurrencySearchHint,
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: EsBO.commonClearSearch,
                                onPressed: () {
                                  _ctrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        EsBO.settingsCurrencyNoResults(_query),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected = c.code == widget.initial.code;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: color.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? color.primary
                                : color.onSurfaceVariant,
                          ),
                          title: Text(
                            '${c.code} — ${c.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${EsBO.settingsCurrencySymbolPrefix}${c.symbol}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// LOCALE PICKER
// ─────────────────────────────────────────────────

class _LocalePicker extends ConsumerWidget {
  const _LocalePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final strings = ref.watch(localeStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.localeLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppLocale>(
              value: locale,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: AppLocale.es,
                  child: Text(strings.localeEs),
                ),
                DropdownMenuItem(
                  value: AppLocale.en,
                  child: Text(strings.localeEn),
                ),
                DropdownMenuItem(
                  value: AppLocale.ptBr,
                  child: Text(strings.localePtBr),
                ),
                DropdownMenuItem(
                  value: AppLocale.de,
                  child: Text(strings.localeDe),
                ),
                DropdownMenuItem(
                  value: AppLocale.fr,
                  child: Text(strings.localeFr),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// BACKUP SECTION — export/import database
// ─────────────────────────────────────────────────

class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _isExporting = false;
  bool _isImporting = false;

  /// Gate Pro: los backups (exportar/importar) son funcion paga.
  void _showLockedSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          EsBO.settingsBackupLockedBody,
          actionLabel: EsBO.settingsGoProAction,
          onAction: () => GoRouter.of(context).push('/paywall'),
        ),
      );
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    if (!ent.isLoading && !isPro) {
      _showLockedSnack();
      return;
    }
    setState(() => _isExporting = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final service = BackupService(db);
      await service.export();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.success(EsBO.settingsBackupExportSuccess));
    } catch (e) {
      debugPrint('Backup export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupExportError));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImport() async {
    if (_isImporting) return;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    if (!ent.isLoading && !isPro) {
      _showLockedSnack();
      return;
    }

    // First, preview what's in the backup
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [kBackupExtension, 'json'],
    );
    if (files.isEmpty) return;

    // En web no hay `path` (se lee con readAsBytes); en movil/desktop por path.
    final file = files.single;

    // Limite de tamaño ANTES de cargar a memoria (helper compartido con
    // BackupService.import para no duplicar la regla).
    final sizeError = BackupService.validateFileSize(file);
    if (sizeError != null) {
      debugPrint('[Backup] validateFileSize devolvió: $sizeError');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(_backupErrorText(sizeError)));
      return;
    }

    final String content;
    try {
      final path = file.path;
      if (path != null) {
        content = await File(path).readAsString();
      } else {
        content = utf8.decode(await file.readAsBytes());
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupImportInvalidFile));
      return;
    }

    // Read and validate (JSON malformado o campos invalidos -> mensaje
    // amigable, nunca una excepcion cruda ni un crash).
    final BackupData backup;
    try {
      final parsed = jsonDecode(content);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('estructura inesperada');
      }
      backup = BackupData.fromJson(parsed);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupImportInvalidFile));
      return;
    }

    final error = backup.validate();
    if (error != null) {
      // LOW-14: el detalle de validate() es diagnóstico (solo log); al
      // usuario se le muestra el mensaje localizado genérico.
      debugPrint('[Backup] validate rechazó: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsBackupImportInvalidFile));
      return;
    }

    // Rechazar backups de un schema FUTURO.
    final db = ref.read(appDatabaseProvider);
    if (backup.schemaVersion > db.schemaVersion) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar.error(EsBO.settingsBackupImportFutureVersion),
        );
      return;
    }

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      // Usar el context DEL DIALOGO (root navigator), no el de la pagina
      // (nested navigator del StatefulShellRoute) — si no, el pop intenta
      // sacar la ultima pagina del branch y go_router lanza assertion.
      builder: (dialogContext) => AlertDialog(
        title: Text(EsBO.settingsBackupImportConfirmTitle),
        content: Text(
          EsBO.settingsBackupImportConfirmBody(
            EsBO.settingsBackupImportSummary(
              backup.summary.calculationCount,
              backup.summary.filamentCount,
              backup.summary.printerCount,
              backup.summary.discountTierCount,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(EsBO.settingsBackupImportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(EsBO.settingsBackupImportConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Perform import (reusa `db` obtenido arriba para validar el schema).
    setState(() => _isImporting = true);
    try {
      final service = BackupService(db);
      final importResult = await service.restoreFromJson(content);
      if (!mounted) return;
      if (importResult == null) {
        // Should not happen here (validation already done above)
        return;
      }
      if (importResult.isEmpty) {
        final summary = backup.summary;
        // Invalida todos los providers de datos: son fetch-once (listAll o
        // cómputos únicos), así que sin esto el historial/dashboard/catálogo
        // seguirían mostrando el estado viejo hasta el próximo refresh.
        ref
          ..invalidate(calculationsNotifierProvider)
          // dashboardStatsProvider es family: invalidar la instancia default
          // (null = todo) cubre la home/dashboard en rango "Todo". Ademas
          // reseteamos el rango activo para que un filtro previo del
          // dashboard no tape los datos re-importados.
          ..invalidate(dashboardRangeProvider)
          ..invalidate(dashboardStatsProvider(null))
          ..invalidate(filamentsNotifierProvider)
          ..invalidate(printersNotifierProvider)
          ..invalidate(settingsNotifierProvider);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            AppSnackBar.success(
              EsBO.settingsBackupImportSuccess(
                summary.calculationCount,
                summary.filamentCount,
                summary.printerCount,
              ),
            ),
          );
      } else {
        debugPrint('[Backup] restore devolvió código: $importResult');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(AppSnackBar.error(_backupErrorText(importResult)));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// LOW-14: traduce los códigos de error de backup (`BackupErrorCodes`)
  /// a mensajes localizados con el locale activo. Los códigos desconocidos
  /// caen al mensaje genérico de error de importación.
  String _backupErrorText(String code) => switch (code) {
    BackupErrorCodes.sizeTooLarge => EsBO.settingsBackupImportSizeError,
    BackupErrorCodes.futureVersion => EsBO.settingsBackupImportFutureVersion,
    // T2-2 (SEC-03): firma HMAC invalida = archivo alterado/corrupto.
    BackupErrorCodes.signatureMismatch =>
      EsBO.settingsBackupImportSignatureMismatch,
    BackupErrorCodes.invalidFile ||
    BackupErrorCodes.invalidData => EsBO.settingsBackupImportInvalidFile,
    _ => EsBO.settingsBackupImportError,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final locked = !ent.isLoading && !isPro;

    return SettingsCard(
      accentColor: color.primary,
      children: [
        Text(
          EsBO.settingsBackupHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Opacity(
          opacity: locked ? kLockedOpacity : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isExporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color.onPrimary,
                      ),
                    )
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(EsBO.settingsBackupExport),
              onPressed: _isExporting ? null : _handleExport,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: locked ? kLockedOpacity : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _isImporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color.primary,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(EsBO.settingsBackupImport),
              onPressed: _isImporting ? null : _handleImport,
            ),
          ),
        ),
        // AC-006 (gap-remediation 2026-10-10): transparencia del backup —
        // manual, sin sync, sin cifrado; HMAC = integridad, no cifrado.
        const SizedBox(height: AppSpacing.md),
        Text(
          EsBO.settingsBackupDisclosure,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Restore purchases button (T11)
// ─────────────────────────────────────────────────
// El botón de restaurar compras vive en `lib/shared/widgets/pro_active_badge.dart`
// ([RestoreButton]) para reutilizarse en la sheet de beneficios y en settings.

// ─────────────────────────────────────────────────
// Borrar datos de trabajo (AC-004 gap-remediation 2026-10-10)
// ─────────────────────────────────────────────────
// Confirmación explícita y localizada. En éxito invalida los providers
// fetch-once y reinicia onboarding. En fallo muestra error (nunca éxito falso).

class _WipeDataSection extends ConsumerStatefulWidget {
  const _WipeDataSection();

  @override
  ConsumerState<_WipeDataSection> createState() => _WipeDataSectionState();
}

class _WipeDataSectionState extends ConsumerState<_WipeDataSection> {
  bool _wiping = false;

  Future<void> _handleWipe() async {
    // Mismo patron de dialogo que `_handleImport`: pop con el context del
    // dialogo (root navigator) para no chocar con el StatefulShellRoute.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(EsBO.settingsWipeConfirmTitle),
        content: Text(EsBO.settingsWipeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(EsBO.settingsWipeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(EsBO.settingsWipeConfirmDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _wiping = true);
    try {
      await ref.read(localDataWipeServiceProvider).wipeWorkData();
      if (!mounted) return;
      // Invalidar los providers fetch-once (mismo patron que `_handleImport`)
      // para que historial/dashboard/catalogos no sigan mostrando lo borrado.
      ref
        ..invalidate(calculationsNotifierProvider)
        ..invalidate(dashboardRangeProvider)
        ..invalidate(dashboardStatsProvider(null))
        ..invalidate(filamentsNotifierProvider)
        ..invalidate(printersNotifierProvider)
        ..invalidate(settingsNotifierProvider)
        ..invalidate(discountTiersNotifierProvider)
        ..invalidate(currentPartialIdProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.success(EsBO.settingsWipeSuccess));
      // Reinicia onboarding: sin `onboarding_done` el splash lleva a la
      // configuracion inicial (nueva ruta `/setup`). `context.go` lanza sin
      // GoRouter (tests con MaterialApp suelto) — se degrada a solo snackbar.
      try {
        if (mounted) context.go('/setup');
      } catch (_) {
        // Sin router disponible (entorno de test).
      }
    } catch (e) {
      debugPrint('[Wipe] error borrando datos: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.settingsWipeError));
    } finally {
      if (mounted) setState(() => _wiping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return SettingsCard(
      accentColor: color.error,
      children: [
        Text(
          EsBO.settingsWipeHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: color.error,
              side: BorderSide(color: color.error),
            ),
            icon: _wiping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep_rounded, size: 18),
            label: Text(EsBO.settingsWipeAction),
            onPressed: _wiping ? null : _handleWipe,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Repetir configuración (MED-4 auditoría 2026-10-14)
// ─────────────────────────────────────────────────
// Re-corre el flujo /setup SIN borrar datos (a diferencia del wipe): solo
// baja el flag onboarding_done y navega. No es destructivo ⇒ sin diálogo
// de confirmación; el feedback es la navegación al flujo mismo (el guard
// de /setup en app_router ve el flag en false y permite la entrada).

class _RepeatSetupSection extends ConsumerWidget {
  const _RepeatSetupSection();

  Future<void> _handleRepeatSetup(BuildContext context, WidgetRef ref) async {
    // MED-4: flag en false ANTES de navegar (el redirect de /setup lo
    // exige). Los datos (DB + prefs de trabajo) quedan intactos.
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(SettingsKeys.onboardingDone, false);
    if (!context.mounted) return;
    // `context.go` lanza sin GoRouter (tests con MaterialApp suelto) — se
    // degrada a solo el cambio de flag (mismo patrón que el wipe).
    try {
      context.go('/setup');
    } catch (_) {
      // Sin router disponible (entorno de test).
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return SettingsCard(
      accentColor: color.secondary,
      children: [
        Text(
          EsBO.settingsRepeatSetupHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          key: const ValueKey('settings-repeat-setup'),
          contentPadding: EdgeInsets.zero,
          leading: IconBadge(
            icon: Icons.replay_rounded,
            background: color.secondaryContainer,
            foreground: color.onSecondaryContainer,
          ),
          title: Text(
            EsBO.settingsRepeatSetup,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: color.onSurfaceVariant,
          ),
          onTap: () => _handleRepeatSetup(context, ref),
        ),
      ],
    );
  }
}
