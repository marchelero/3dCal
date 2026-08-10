// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/es_bo.dart';

/// Pantalla de carga inicial antes del home.
///
/// Muestra el logo centrado con fade-in y una barra de progreso en la parte
/// inferior. Despues de ~2.5s navega a `/` (o `/initial-config` si falta el
/// onboarding) via go_router.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _startLoading();
  }

  Future<void> _startLoading() async {
    // Esperar 2.5s para que la animacion se complete
    await Future<void>.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Verificar onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(SettingsKeys.onboardingDone) ?? false;

    if (!mounted) return;

    if (onboardingDone) {
      GoRouter.of(context).go('/');
    } else {
      GoRouter.of(context).go('/initial-config');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradiente y barra siguen el scheme (primaryContainer → surface): la
    // splash responde a light/dark en vez de colores fijos fuera de paleta.
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer, cs.surface],
          ),
        ),
        child: Stack(
          children: [
            // Logo centrado con fade-in
            Center(
              child: FadeTransition(
                opacity: _fadeController,
                child: Semantics(
                  label: EsBO.splashLogo,
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Semantics(
                        label: EsBO.appName,
                        child: Image.asset(
                          'assets/images/3dlogo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Barra de carga inferior
            Positioned(
              left: 40,
              right: 40,
              bottom: MediaQuery.of(context).padding.bottom + 60,
              child: Semantics(
                label: EsBO.commonLoading,
                liveRegion: true,
                child: AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _loadingController.value,
                            backgroundColor: cs.primary.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          EsBO.commonLoading.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: cs.primary.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
