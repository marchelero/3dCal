// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/money/currency.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../settings/domain/settings.dart';
import '../../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../widgets/currency_chips.dart';
import '../../widgets/currency_picker_sheet.dart';
import '../../widgets/theme_picker.dart';

/// Paso 1 del flujo de setup: estilo (tema) + moneda.
///
/// [ThemePicker] extraído (F2) + [CurrencyChips] con pre-selección por
/// idioma (AC-03). Ambos persisten al tocar vía los notifiers existentes
/// (`themeModeProvider.setMode`, `settingsNotifierProvider.updateCurrency`)
/// — sin botón "Guardar" (AC-07). El scroll lo provee el container
/// (`SetupFlowPage`).
class StyleCurrencyStep extends ConsumerStatefulWidget {
  const StyleCurrencyStep({super.key});

  @override
  ConsumerState<StyleCurrencyStep> createState() => _StyleCurrencyStepState();
}

class _StyleCurrencyStepState extends ConsumerState<StyleCurrencyStep> {
  // BUG-006: flags UI locales efímeros (no son estado de negocio; la
  // moneda persistida vive en settingsNotifierProvider).
  bool _userTouchedCurrency = false;
  bool _preselectTried = false;

  /// Moneda sugerida por locale (AC-03): es→BOB, en→USD, ptBr→BRL,
  /// de/fr→EUR.
  static WorldCurrency _suggestedFor(AppLocale locale) => switch (locale) {
    AppLocale.es => WorldCurrency.bob,
    AppLocale.en => WorldCurrency.usd,
    AppLocale.ptBr => WorldCurrency.brl,
    AppLocale.de => WorldCurrency.eur,
    AppLocale.fr => WorldCurrency.eur,
  };

  void _selectCurrency(String code) {
    _userTouchedCurrency = true;
    ref.read(settingsNotifierProvider.notifier).updateCurrency(code);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final suggested = _suggestedFor(locale);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currentCode =
        settingsAsync.value?.currencyCode ?? Settings.defaults.currencyCode;

    // Pre-selección por idioma (AC-03 / R5): al primer arrival, si la moneda
    // persistida sigue en el default de fábrica ('USD') y el sugerido
    // difiere, se auto-aplica. El flag `_userTouchedCurrency` corta la
    // auto-aplicación tras el primer tap explícito; `_preselectTried` evita
    // repetirla en rebuilds (el AsyncValue resuelve tras el primer frame).
    if (!_preselectTried && !_userTouchedCurrency) {
      final settings = settingsAsync.value;
      if (settings != null) {
        _preselectTried = true;
        if (settings.currencyCode == Settings.defaults.currencyCode &&
            suggested.code != settings.currencyCode) {
          // Fire-and-forget: la persistencia es el notifier existente.
          ref
              .read(settingsNotifierProvider.notifier)
              .updateCurrency(suggested.code);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(icon: Icons.palette_rounded, title: EsBO.configTheme),
          const SizedBox(height: AppSpacing.md),
          const ThemePicker(),
          const SizedBox(height: AppSpacing.xxl),
          _StepHeader(
            icon: Icons.attach_money_rounded,
            title: EsBO.configCurrency,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsBO.configCurrencyHelper,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          CurrencyChips(
            currentCode: currentCode,
            suggestedCode: suggested.code,
            onSelected: _selectCurrency,
            onSeeAll: () => showCurrencyPickerSheet(
              context,
              currentCode: currentCode,
              onSelected: (currency) => _selectCurrency(currency.code),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Header de sección del paso: icono en chip translúcido + título blanco
/// (el contenido vive sobre el gradiente del container).
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
