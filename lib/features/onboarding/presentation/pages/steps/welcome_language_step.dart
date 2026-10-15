// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radii.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../widgets/language_option_card.dart';

/// Paso 0 del flujo de setup: bienvenida + selección de idioma.
///
/// Logo con scale-in (TweenAnimationBuilder, 500 ms, easeOutBack), tagline
/// [EsBO.setupWelcomeTagline] y 5 [LanguageOptionCard] con nombre nativo
/// hardcodeado (proper nouns — PRD AC-02). El tap persiste el locale al
/// instante vía `LocaleNotifier.setLocale` (sin botón de continuar).
/// El scroll lo provee el container (`SetupFlowPage`).
class WelcomeLanguageStep extends ConsumerWidget {
  const WelcomeLanguageStep({super.key});

  /// (locale, nombre nativo) — los nombres son proper nouns, no se traducen.
  static const List<(AppLocale, String)> languages = [
    (AppLocale.es, 'Español'),
    (AppLocale.en, 'English'),
    (AppLocale.de, 'Deutsch'),
    (AppLocale.fr, 'Français'),
    (AppLocale.ptBr, 'Português'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild al cambiar idioma para releer los strings de EsBO (en la app
    // real el listener de app.dart también fuerza un rebuild global).
    final selected = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Logo con entrada scale-in.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.xxxl),
              ),
              child: Image.asset(
                'assets/images/3dlogo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              EsBO.setupWelcomeTagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (final (locale, nativeName) in languages) ...[
            LanguageOptionCard(
              key: ValueKey('setup-language-${locale.name}'),
              name: nativeName,
              selected: selected == locale,
              onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
