/// Selector de filamentos del cotizador.
///
/// Dialog con identidad visual propia de filamentos: AvatarIcon de etiqueta
/// (tile secondary, consistente con Ajustes → Catálogos → Filamentos),
/// subtitulo "precio sym · X g" y estrella dorada si es el default.
///
/// Retorna el filamento elegido para cargarlo en el formulario, o `null` si
/// el usuario cancela.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/avatar_icon.dart';
import '../../../../shared/widgets/default_badge.dart';
import '../../../../shared/widgets/filament_color_palette.dart';
import 'selector_dialog_shell.dart';

/// Límite de filamentos para usuarios Free.
const int kFreeFilamentLimit = 5;

/// Abre el selector de filamentos.
///
/// Si el usuario es Free y alcanzó el límite [kFreeFilamentLimit], el botón
/// de crear nuevo se reemplaza por un hint de "Desbloquea Pro para más".
Future<Filament?> showFilamentSelectorDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<Filament> filaments,
}) {
  final sym = ref.read(selectedCurrencyProvider).symbol;
  final isPro = ref.read(isProProvider);
  final atLimit = !isPro && filaments.length >= kFreeFilamentLimit;

  return showSelectorDialog<Filament>(
    context: context,
    title: EsBO.calcSelectFilament,
    searchHint: EsBO.calcSearchFilament,
    items: filaments,
    matches: (f, query) {
      if (f.name.toLowerCase().contains(query)) return true;
      if (f.brand?.toLowerCase().contains(query) ?? false) return true;
      // Busqueda por nombre de color (RF2-4 del PRD 2026-09-08). Solo
      // cuando el hex es de paleta reconocida (custom hex no muestra
      // label en la lista, asi que tampoco debe matchear).
      final colorName = _colorNameForFilament(f.color);
      if (colorName != null && colorName.toLowerCase().contains(query)) {
        return true;
      }
      return false;
    },
    itemBuilder: (context, f, select) {
      final theme = Theme.of(context);
      final fColor = colorFromHex(f.color);
      return ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarIcon(
              icon: f.isDefault ? Icons.star_rounded : Icons.label_rounded,
              background: theme.colorScheme.secondaryContainer,
              foreground: f.isDefault
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.onSecondaryContainer,
            ),
            if (fColor != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: fColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${f.pricePerBobbin.toStringAsFixed(0)} $sym · '
          '${f.gramsPerBobbin.toStringAsFixed(0)} g',
          style: AppTheme.num(theme.textTheme.bodySmall ?? const TextStyle()),
        ),
        trailing: f.isDefault ? const DefaultBadge(size: 20) : null,
        onTap: select,
      );
    },
    footer: atLimit
        ? _FreeLimitHint(
            current: filaments.length,
            limit: kFreeFilamentLimit,
            label: 'filamentos',
          )
        : ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('Crear nuevo'),
            subtitle: const Text('Agregar al catálogo'),
            onTap: () {
              Navigator.of(context).pop(); // cerrar dialog
              context.push('/settings/filaments/new');
            },
          ),
  );
}

/// Hint sutil cuando el usuario Free alcanza el límite del catálogo.
class _FreeLimitHint extends StatelessWidget {
  const _FreeLimitHint({
    required this.current,
    required this.limit,
    required this.label,
  });

  final int current;
  final int limit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: cs.tertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$current/$limit $label — desbloquea Pro para más',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resuelve el nombre legible del color en el locale activo (es/en/pt/de/fr).
/// Devuelve `null` si el hex es invalido o no matchea un color de paleta
/// (custom hex sin label explicito).
String? _colorNameForFilament(String? hex) {
  final key = nameKeyFromHex(hex);
  if (key == null || !isPaletteHex(hex)) return null;
  switch (key) {
    case 'red':
      return EsBO.colorNameRed;
    case 'orange':
      return EsBO.colorNameOrange;
    case 'amber':
      return EsBO.colorNameAmber;
    case 'yellow':
      return EsBO.colorNameYellow;
    case 'lime':
      return EsBO.colorNameLime;
    case 'green':
      return EsBO.colorNameGreen;
    case 'teal':
      return EsBO.colorNameTeal;
    case 'cyan':
      return EsBO.colorNameCyan;
    case 'blue':
      return EsBO.colorNameBlue;
    case 'indigo':
      return EsBO.colorNameIndigo;
    case 'purple':
      return EsBO.colorNamePurple;
    case 'magenta':
      return EsBO.colorNameMagenta;
    case 'pink':
      return EsBO.colorNamePink;
    case 'brown':
      return EsBO.colorNameBrown;
    case 'gray':
      return EsBO.colorNameGray;
    case 'black':
      return EsBO.colorNameBlack;
    case 'white':
      return EsBO.colorNameWhite;
    default:
      return null;
  }
}
