// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// 4 pantallas de onboarding swipeables.
///
/// Muestra solo en primera ejecucion. Skip button + indicador de pagina.
/// Al completar, persiste [SettingsKeys.onboardingDone] y navega a `/`.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  List<_OnboardingScreenData> get _screens => [
        _OnboardingScreenData(
          icon: Icons.calculate_rounded,
          title: EsBO.onboardingTitle1,
          description: EsBO.onboardingDesc1,
        ),
        _OnboardingScreenData(
          icon: Icons.flash_on_rounded,
          title: EsBO.onboardingTitle2,
          description: EsBO.onboardingDesc2,
        ),
        _OnboardingScreenData(
          icon: Icons.inventory_2_rounded,
          title: EsBO.onboardingTitle3,
          description: EsBO.onboardingDesc3,
        ),
        _OnboardingScreenData(
          icon: Icons.bar_chart_rounded,
          title: EsBO.onboardingTitle4,
          description: EsBO.onboardingDesc4,
        ),
      ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.onboardingDone, true);
    if (!mounted) return;
    GoRouter.of(context).go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isLast = _currentPage == _screens.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
              Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: TextButton(
                  onPressed: _markDone,
                  child: Text(
                    isLast ? '' : EsBO.onboardingSkip,
                    style: TextStyle(color: color.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _screens.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final d = _screens[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(d.icon, size: 80, color: color.primary),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          d.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          d.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _screens.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? color.primary
                              : color.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLast ? _markDone : () {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(isLast ? EsBO.onboardingStart : EsBO.onboardingNext),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────

class _OnboardingData {
  const _OnboardingData({required this.pages});
  final List<_OnboardingScreenData> pages;
}

class _OnboardingScreenData {
  const _OnboardingScreenData({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
}
