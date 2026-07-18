// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radii.dart';
import '../../l10n/es_bo.dart';

/// Shell responsive que envuelve las 4 destinations principales del shell
/// de go_router (Inicio, Historial, Dashboard, Ajustes).
///
/// **Responsive**:
/// - `< 600dp` (mobile portrait): [NavigationBar] (bottom nav).
/// - `600-1023dp` (tablet): [NavigationRail] compacto con labels.
/// - `>= 1024dp` (web/desktop): [NavigationRail] extendido.
/// - `>= 1280dp`: [NavigationRail] extended con label visible siempre.
///
/// **Transition**: cross-fade al cambiar de tab.
class AppScaffold extends StatefulWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  int _prevIndex = 0;

  static final _destinations = <_NavDest>[
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

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.navigationShell.currentIndex;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
  }

  @override
  void didUpdateWidget(AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prevIndex != widget.navigationShell.currentIndex) {
      _prevIndex = widget.navigationShell.currentIndex;
      _fadeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
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
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.surfaceContainerLow,
              color.surfaceContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Barra naranja superior (muy visible) ──
            Container(
              height: 2.5,
              width: double.infinity,
              color: color.secondary.withValues(alpha: 0.5),
            ),
            NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              height: 68,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletNav(BuildContext context, {required bool extended}) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // ── NavigationRail con fondo y borde ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.surfaceContainerLow,
                    color.surfaceContainer,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon top
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                    child: Icon(
                      Icons.calculate_rounded,
                      size: extended ? 32 : 24,
                      color: color.primary,
                    ),
                  ),
                  // Rail
                  Expanded(
                    child: NavigationRail(
                      extended: extended,
                      minExtendedWidth: 180,
                      selectedIndex: widget.navigationShell.currentIndex,
                      onDestinationSelected: _onTap,
                      labelType: extended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      backgroundColor: Colors.transparent,
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                      leading: const SizedBox.shrink(),
                      destinations: [
                        for (final d in _destinations)
                          NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon),
                            label: Text(d.label),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Separador con borde naranja ──
            Container(
              width: 2.5,
              color: color.secondary.withValues(alpha: 0.3),
            ),
            // ── Contenido ──
            Expanded(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: widget.navigationShell,
              ),
            ),
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
