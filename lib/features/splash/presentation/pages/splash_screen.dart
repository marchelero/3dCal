// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Pantalla de carga inicial antes del home.
///
/// Muestra loading_screen.png centrado con fade-in, y una barra de progreso
/// en la parte inferior. Despues de ~2.5s navega a `/` via go_router.
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
    final onboardingDone =
        prefs.getBool(SettingsKeys.onboardingDone) ?? false;

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2A3A), // azul profundo arriba
              Color(0xFF0D0D0D), // negro abajo
            ],
          ),
        ),
        child: Stack(
          children: [
            // Logo centrado con fade-in
            Center(
              child: FadeTransition(
                opacity: _fadeController,
                child: Semantics(
                  label: '3dCalc logo',
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Semantics(
                        label: '3dCalc',
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
                label: 'Cargando',
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
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CARGANDO...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
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
