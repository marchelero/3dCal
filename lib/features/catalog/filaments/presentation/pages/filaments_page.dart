// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/theme/app_radii.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../features/entitlement/presentation/providers/entitlement_providers.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/confirm_dialog.dart';
import '../../../../../shared/widgets/default_badge.dart';
import '../../../../../shared/widgets/empty_view.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/filament_color_palette.dart';
import '../../../../../shared/widgets/skeleton_widget.dart';
import '../notifiers/filaments_notifier.dart';

/// Límite de filamentos para usuarios Free.
const int _kFreeFilamentLimit = 5;

/// Catalogo de filamentos con busqueda y cards.
class FilamentsPage extends ConsumerStatefulWidget {
  const FilamentsPage({super.key});

  @override
  ConsumerState<FilamentsPage> createState() => _FilamentsPageState();
}

class _FilamentsPageState extends ConsumerState<FilamentsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final async = ref.watch(filamentsNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final filamentCount = async.value?.length ?? 0;
    final atLimit = !isPro && filamentCount >= _kFreeFilamentLimit;

    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.filamentTitle),
        actions: [
          if (atLimit)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Límite Free ($_kFreeFilamentLimit filamentos)',
              onPressed: () => _showLimitSnack(context),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: EsBO.filamentNewTooltip,
              onPressed: () => context.push('/settings/filaments/new'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search field ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: EsBO.filamentSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          // ── List ──
          Expanded(
            child: async.when(
              loading: () => const ListPageSkeleton(),
              error: (e, _) => ErrorView(
                message: '${EsBO.filamentErrorLoad}: $e',
                onRetry: () => ref.invalidate(filamentsNotifierProvider),
              ),
              data: (filaments) {
                final filtered = _searchQuery.isEmpty
                    ? filaments
                    : filaments.where((f) {
                        final name = f.name.toLowerCase();
                        final brand = f.brand?.toLowerCase() ?? '';
                        final colorName = _localizedColorName(
                          f.color,
                        )?.toLowerCase() ?? '';
                        return name.contains(_searchQuery) ||
                            brand.contains(_searchQuery) ||
                            colorName.contains(_searchQuery);
                      }).toList();
                if (filtered.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? EmptyView(
                          icon: Icons.search_off,
                          message: EsBO.filamentNoResults(_searchQuery),
                        )
                      : EmptyView(
                          icon: Icons.inventory_2_outlined,
                          message: EsBO.filamentEmptyList,
                        );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(filamentsNotifierProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.xxl,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _FilamentTile(filament: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar.info(
          context,
          'Límite de $_kFreeFilamentLimit filamentos en modo Free. '
          'Desbloquea Pro para agregar más.',
        ),
      );
  }
}

class _FilamentTile extends ConsumerWidget {
  const _FilamentTile({required this.filament});

  final Filament filament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);
    final price = filament.pricePerBobbin.toStringAsFixed(2);
    final grams = filament.gramsPerBobbin.toStringAsFixed(0);
    final brand = filament.brand;
    final base = '${currency.symbol} $price  ·  $grams g';
    // Subtitulo: si hay color, anade el nombre legible entre parentesis
    // (solo cuando el hex matchea la paleta; los custom hex no muestran
    // nombre para evitar inventar un label).
    final colorName = _localizedColorName(filament.color);
    final subtitle = colorName == null
        ? (brand == null || brand.isEmpty ? base : '$brand  ·  $base')
        : (brand == null || brand.isEmpty
            ? '$base  · $colorName'
            : '$brand  ·  $base  · $colorName');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () =>
            context.push('/settings/filaments/${filament.id}', extra: filament),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Leading avatar: color si esta definido; DefaultBadge o
              // icono etiqueta si no hay color (compatibilidad con el
              // comportamiento anterior).
              _FilamentLeading(filament: filament),
              const SizedBox(width: AppSpacing.md),
              // Name + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filament.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions menu
              PopupMenuButton<_TileAction>(
                onSelected: (a) => _handleAction(context, ref, a),
                itemBuilder: (_) => [
                  PopupMenuItem<_TileAction>(
                    value: _TileAction.setDefault,
                    child: ListTile(
                      leading: const Icon(Icons.star),
                      title: Text(EsBO.commonDefault),
                    ),
                  ),
                  PopupMenuItem<_TileAction>(
                    value: _TileAction.delete,
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(EsBO.commonDelete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _TileAction a,
  ) async {
    final notifier = ref.read(filamentsNotifierProvider.notifier);
    switch (a) {
      case _TileAction.setDefault:
        await notifier.setAsDefault(filament.id);
      case _TileAction.delete:
        final confirm = await showConfirmDialog(
          context,
          title: EsBO.filamentDeleteTitle,
          message: EsBO.filamentDeleteConfirm(filament.name),
        );
        if (confirm != true || !context.mounted) return;
        // Capture data for undo
        final name = filament.name;
        final brand = filament.brand;
        final price = filament.pricePerBobbin;
        final grams = filament.gramsPerBobbin;
        final wasDefault = filament.isDefault;
        await notifier.delete(filament.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            AppSnackBar.info(
              context,
              EsBO.filamentDeleted(name),
              actionLabel: EsBO.commonUndo,
              onAction: () {
                notifier.create(
                  name: name,
                  brand: brand,
                  pricePerBobbin: Decimal.parse(price.toString()),
                  gramsPerBobbin: Decimal.parse(grams.toString()),
                  asDefault: wasDefault,
                );
              },
            ),
          );
    }
  }
}

enum _TileAction { setDefault, delete }

/// Leading widget de la fila: avatar con color si hay, sino DefaultBadge o
/// icono etiqueta (compatibilidad con el comportamiento anterior).
class _FilamentLeading extends StatelessWidget {
  const _FilamentLeading({required this.filament});

  final Filament filament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = colorFromHex(filament.color);
    final size = 40.0;
    if (color != null) {
      // Avatar circular con color. Si ademas es default, monta la estrella
      // dorada encima via Stack.
      final isWhite = color.toARGB32() == 0xFFFFFFFF;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWhite ? cs.outline : cs.outlineVariant,
                  width: 1,
                ),
              ),
              child: isWhite
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            if (filament.isDefault)
              const Positioned(
                right: -2,
                bottom: -2,
                child: DefaultBadge(size: 18),
              ),
          ],
        ),
      );
    }
    // Sin color: comportamiento previo intacto.
    if (filament.isDefault) return const DefaultBadge();
    return Icon(
      Icons.label_outline,
      color: cs.onSurfaceVariant,
      size: 24,
    );
  }
}

/// Resuelve la clave i18n del nombre del color al locale activo (es/en/pt/de/fr).
/// Devuelve `null` para hex invalidos o custom hex sin match exacto de paleta
/// (para evitar inventar un label).
String? _localizedColorName(String? hex) {
  final key = nameKeyFromHex(hex);
  if (key == null) return null;
  if (!isPaletteHex(hex)) return null;
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
