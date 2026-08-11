// ignore_for_file: public_member_api_docs
import 'package:flutter/foundation.dart';
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
      duration: const Duration(milliseconds: 2500),
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
    // La splash mantiene una tonalidad fija para que el logo conserve
    // contraste aunque la aplicación esté usando el tema claro.
    const splashBackground = Color(0xFF101A2E);
    const splashForeground = Color(0xFFF8FAFC);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: splashBackground),
        child: Stack(
          children: [
            // Logo centrado con fade-in
            Center(
              child: FadeTransition(
                opacity: _fadeController,
                child: Semantics(
                  label: EsBO.splashLogo,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final preferredWidth = constraints.maxWidth * 0.6;
                      final logoWidth = preferredWidth.clamp(
                        180.0,
                        kIsWeb ? 420.0 : 340.0,
                      );
                      return SizedBox(
                        width: logoWidth,
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
                      );
                    },
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
                            backgroundColor: splashForeground.withValues(
                              alpha: 0.24,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              splashForeground,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          EsBO.commonLoading.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: splashForeground.withValues(alpha: 0.72),
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
