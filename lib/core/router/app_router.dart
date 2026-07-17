// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/calculation/presentation/pages/calculation_detail_page.dart';
import '../../features/calculation/presentation/pages/calculations_list_page.dart';
import '../../features/calculation/presentation/pages/calculator_page.dart';
import '../../features/calculation/presentation/pages/home_page.dart';
import '../../features/calculation/presentation/pages/prefill_cotizacion.dart';
import '../../features/catalog/filaments/presentation/pages/filament_form_page.dart';
import '../../features/catalog/filaments/presentation/pages/filaments_page.dart';
import '../../features/catalog/printers/presentation/pages/printer_form_page.dart';
import '../../features/catalog/printers/presentation/pages/printers_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../database/app_database.dart';
import '../theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────
// Transition helpers — animaciones visibles para push routes
// ─────────────────────────────────────────────────────────────

Page<void> _slideRight(Widget child) => CustomTransitionPage<void>(
      key: ValueKey(child.hashCode),
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.35, 0);
        const end = Offset.zero;
        final tween = Tween<Offset>(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return SlideTransition(position: tween, child: child);
      },
    );

/// Router principal de la app (PRD §8.3, Sprint 7 — go_router migration).
///
/// **Estructura**:
/// - `StatefulShellRoute.indexedStack` con 4 branches: Inicio, Historial,
///   Dashboard, Ajustes. Mantiene state per-tab.
/// - Rutas fuera del shell (full-screen, push): calculator, calculation detail,
///   catalogos (filamentos/impresoras) + form pages.
///
/// **Convenciones**:
/// - `context.go('/ruta')` para tab switches (reemplaza la branch actual).
/// - `context.push('/ruta')` para sub-pantallas (preserva el shell debajo).
/// - `context.pop()` para volver.
/// - Datos no serializables (Calculation, Filament, PrinterProfile) se pasan
///   via `state.extra` (no URL). Es valido porque la app es 100% local.
final appRouter = GoRouter(
  initialLocation: '/splash',
  errorBuilder: (context, state) => const _RouterErrorPage(),
  routes: [
    // === Splash screen (full-screen, sin shell) ===
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // === Shell: 4 tabs principales ===
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const CalculationsListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // === Full-screen (push, no shell) ===
    GoRoute(
      path: '/calculator',
      pageBuilder: (context, state) => _slideRight(const CalculatorPage()),
    ),
    GoRoute(
      path: '/calculator/prefill',
      pageBuilder: (context, state) {
        final calc = state.extra as Calculation;
        return _slideRight(PrefilledCalculatorPage(calc: calc));
      },
    ),
    GoRoute(
      path: '/history/:id',
      pageBuilder: (context, state) {
        final calc = state.extra as Calculation;
        return _slideRight(CalculationDetailPage(calcId: calc.id));
      },
    ),

    // === Catalogos ===
    GoRoute(
      path: '/settings/filaments',
      pageBuilder: (context, state) => _slideRight(const FilamentsPage()),
      routes: [
        GoRoute(
          path: 'new',
          pageBuilder: (context, state) => _slideRight(const FilamentFormPage()),
        ),
        GoRoute(
          path: ':id',
          pageBuilder: (context, state) {
            final f = state.extra as Filament;
            return _slideRight(FilamentFormPage(existing: f));
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings/printers',
      pageBuilder: (context, state) => _slideRight(const PrintersPage()),
      routes: [
        GoRoute(
          path: 'new',
          pageBuilder: (context, state) => _slideRight(const PrinterFormPage()),
        ),
        GoRoute(
          path: ':id',
          pageBuilder: (context, state) {
            final p = state.extra as PrinterProfile;
            return _slideRight(PrinterFormPage(existing: p));
          },
        ),
      ],
    ),
  ],
);

/// Pagina de error para rutas no encontradas.
///
/// **Comportamiento**: se muestra cuando go_router no puede resolver una URL
/// (ej: deep link invalido o bug). Ofrece volver a Home via goBranch(0).
class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 96),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pagina no encontrada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Volver a Inicio'),
                onPressed: () => GoRouter.of(context).go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
