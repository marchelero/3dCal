// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';

/// Primera pantalla en la primera ejecución: selección de idioma.
///
/// El idioma se persiste al cambiar ([LocaleNotifier.setLocale]) y se aplica
/// a toda la app (EsBO se actualiza en la raíz), así que el onboarding que
/// sigue se muestra en el idioma elegido. Al continuar navega a
/// `/onboarding`.
class LanguageSelectionPage extends ConsumerWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: MaxWidthScrollView(
            maxWidth: 480,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // App icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/3dlogo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Title
                  Text(
                    EsBO.languagePageTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    EsBO.languagePageSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Language selector
                  InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppLocale>(
                        value: ref.watch(localeProvider),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: AppLocale.es,
                            child: Text(EsBO.localeEs),
                          ),
                          DropdownMenuItem(
                            value: AppLocale.en,
                            child: Text(EsBO.localeEn),
                          ),
                          DropdownMenuItem(
                            value: AppLocale.ptBr,
                            child: Text(EsBO.localePtBr),
                          ),
                          DropdownMenuItem(
                            value: AppLocale.de,
                            child: Text(EsBO.localeDe),
                          ),
                          DropdownMenuItem(
                            value: AppLocale.fr,
                            child: Text(EsBO.localeFr),
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
                  const SizedBox(height: AppSpacing.xxl),
                  // CTA → onboarding (se muestra en el idioma elegido)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => GoRouter.of(context).go('/onboarding'),
                      child: Text(EsBO.configContinue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
