// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/settings/domain/settings.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';

/// Primera pantalla al abrir la app por primera vez.
///
/// Usuario selecciona idioma y moneda antes del onboarding.
/// Solo se muestra una vez (antes de que [SettingsKeys.onboardingDone] sea true).
class InitialConfigPage extends ConsumerWidget {
  const InitialConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: MaxWidthScrollView(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // App icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/3dlogo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Title
                Text(
                  EsBO.configTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Language
                _LanguagePicker(),
                const SizedBox(height: AppSpacing.xl),
                // Currency
                _CurrencyPicker(),
                const Spacer(flex: 2),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      // Locale + currency already saved by pickers on change
                      GoRouter.of(context).go('/onboarding');
                    },
                    child: Text(EsBO.configContinue),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Language picker ──────────────────────────────────

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.configLanguage,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<AppLocale>(
          segments: const [
            ButtonSegment(
              value: AppLocale.es,
              label: Text('ES'),
              icon: Icon(Icons.language),
            ),
            ButtonSegment(
              value: AppLocale.en,
              label: Text('EN'),
              icon: Icon(Icons.language),
            ),
          ],
          selected: {locale},
          onSelectionChanged: (s) {
            ref.read(localeProvider.notifier).setLocale(s.first);
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

// ─── Currency picker ──────────────────────────────────

class _CurrencyPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings =
        ref.watch(settingsNotifierProvider).valueOrNull ?? Settings.defaults;
    final current = WorldCurrency.fromCode(settings.currencyCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EsBO.configCurrency,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<WorldCurrency>(
          value: current,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          items: WorldCurrency.all.map((wc) {
            return DropdownMenuItem(
              value: wc,
              child: Text('${wc.code} — ${wc.name} (${wc.symbol})'),
            );
          }).toList(),
          onChanged: (selected) {
            if (selected == null) return;
            ref
                .read(settingsNotifierProvider.notifier)
                .updateCurrency(selected.code);
          },
        ),
      ],
    );
  }
}
