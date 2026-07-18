// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';

/// 4 pantallas de onboarding swipeables con ilustraciones decorativas.
///
/// Muestra solo en primera ejecucion. Skip button + indicador de pagina.
/// Al completar, persiste [SettingsKeys.onboardingDone] y navega a `/`.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Colores de fondo por pagina (degradados suaves).
  static const _pageColors = <Color>[
    Color(0xFF1B4D7A), // azul tecnico
    Color(0xFFE67E22), // naranja PLA
    Color(0xFF1A8A7A), // verde teal
    Color(0xFF6C3483), // violeta
  ];

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
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isLast = _currentPage == _screens.length - 1;
    final bgColor = _pageColors[_currentPage % _pageColors.length];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor,
              bgColor.withValues(alpha: 0.85),
              bgColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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
                          // Icono decorativo con fondo
                          Semantics(
                            excludeSemantics: true,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.xxxl),
                              ),
                              child: Icon(
                                  d.icon,
                                  size: 56,
                                  color: Colors.white,
                                ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          // Titulo
                          Semantics(
                            header: true,
                            child: Text(
                              d.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Descripcion
                          Semantics(
                            label: d.description,
                            child: Text(
                              d.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                    Semantics(
                      label:
                          'Pagina ${_currentPage + 1} de ${_screens.length}',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _screens.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 28 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: _currentPage == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Action button
                    Semantics(
                      button: true,
                      label: isLast
                          ? EsBO.onboardingStart
                          : EsBO.onboardingNext,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLast
                              ? _markDone
                              : () {
                                  _pageCtrl.nextPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: bgColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: Text(
                            isLast
                                ? EsBO.onboardingStart
                                : EsBO.onboardingNext,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────

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
