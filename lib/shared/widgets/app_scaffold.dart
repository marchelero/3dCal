// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/es_bo.dart';

/// Shell responsive que envuelve las 4 destinations principales del shell
/// de go_router (Inicio, Historial, Dashboard, Ajustes).
///
/// **Responsive**:
/// - `< 600dp` (mobile portrait): [NavigationBar] (bottom nav).
/// - `600-1023dp` (tablet): [NavigationRail] compacto con labels.
/// - `>= 1024dp` (web/desktop): [NavigationRail] extendido.
/// - `>= 1280dp`: [NavigationRail] extended con label visible siempre.
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
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isExtended = width >= 1280;

    if (width < 600) {
      return _buildMobileNav(context);
    }

    if (width < 1024) {
      return _buildTabletNav(context, extended: false);
    }

    // 1024+
    return _buildTabletNav(context, extended: isExtended);
  }

  Widget _buildMobileNav(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        height: 65,
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

  Widget _buildTabletNav(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 180,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: extended
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Icon(
                        Icons.calculate_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
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
}

/// Internal struct para tabular destinations.
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
