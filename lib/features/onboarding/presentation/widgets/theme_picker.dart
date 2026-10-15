// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme_mode_provider.dart';

/// Selector de tema Claro/Oscuro del setup inicial: dos tarjetas grandes
/// con preview de gradiente. Solo esas dos opciones; el modo "Sistema"
/// (y la preferencia persistida) viven en Ajustes.
///
/// Extraído (F2, paso 9) de `initial_config_page.dart` para reutilizarse en
/// el paso 1 del flujo `/setup` sin duplicar comportamiento.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final selected = switch (current) {
      AppThemeMode.light => AppThemeMode.light,
      AppThemeMode.dark => AppThemeMode.dark,
      // Sin preferencia explícita todavía (default = claro desde 2026-09).
      AppThemeMode.system => null,
    };

    return Row(
      children: [
        Expanded(
          child: ThemeOptionCard(
            mode: AppThemeMode.light,
            selected: selected == AppThemeMode.light,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setMode(AppThemeMode.light),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ThemeOptionCard(
            mode: AppThemeMode.dark,
            selected: selected == AppThemeMode.dark,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(AppThemeMode.dark),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta con preview de tema (gradiente claro/oscuro) + estado seleccionado.
class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    required this.mode,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = mode == AppThemeMode.light;
    final borderRadius = BorderRadius.circular(20);
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: mode.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)]
                    : const [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              border: Border.all(
                color: selected ? primary : Colors.grey.withValues(alpha: 0.4),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLight
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 34,
                        color: isLight
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        mode.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
