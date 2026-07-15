// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/es_bo.dart';

/// Shell responsive que envuelve las 4 destinations principales del shell
/// de go_router (Inicio, Historial, Dashboard, Ajustes).
///
/// **Responsive**:
/// - `< 600dp` (mobile portrait): [NavigationBar] (bottom nav).
/// - `600-1023dp` (tablet portrait): [NavigationBar] fallback.
/// - `>= 1024dp` (web desktop): [NavigationRail].
/// - `>= 1280dp`: [NavigationRail] extended (label visible siempre).
///
/// **Tabla de destinos** (sincronizada con [appRouter]):
/// - 0: `/` (Inicio)
/// - 1: `/history` (Historial)
/// - 2: `/dashboard` (Dashboard)
/// - 3: `/settings` (Ajustes)
///
/// **Comportamiento al re-tap**: si el user tap el tab actual, go_router
/// hace pop al root de esa branch (deep-link friendly, sin acumular stacks).
class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_NavDest>[
    _NavDest(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: EsBO.navHome,
    ),
    _NavDest(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: EsBO.navHistory,
    ),
    _NavDest(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: EsBO.navDashboard,
    ),
    _NavDest(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: EsBO.navSettings,
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // initialLocation: true → pop al root de la branch si ya estabas ahi.
      // Evita stacks duplicados al re-tap.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1024;
    final isExtended = width >= 1280;

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                extended: isExtended,
                minExtendedWidth: 160,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onTap,
                labelType: isExtended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// Internal struct para tabular destinations (icon + selected icon + label).
class _NavDest {
  const _NavDest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
