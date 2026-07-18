// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/theme/app_radii.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/confirm_dialog.dart';
import '../../../../../shared/widgets/default_badge.dart';
import '../../../../../shared/widgets/empty_view.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/skeleton_widget.dart';
import '../notifiers/filaments_notifier.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.filamentTitle),
        actions: [
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
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar filamentos...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
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
                message: 'Error cargando filamentos: $e',
                onRetry: () => ref.invalidate(filamentsNotifierProvider),
              ),
              data: (filaments) {
                final filtered = _searchQuery.isEmpty
                    ? filaments
                    : filaments.where((f) {
                        final name = f.name.toLowerCase();
                        final brand = f.brand?.toLowerCase() ?? '';
                        return name.contains(_searchQuery) ||
                            brand.contains(_searchQuery);
                      }).toList();
                if (filtered.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? EmptyView(
                          icon: Icons.search_off,
                          message:
                              'Ningun filamento coincide con "$_searchQuery"',
                        )
                      : const EmptyView(
                          icon: Icons.inventory_2_outlined,
                          message:
                              'Sin filamentos. Toca + para crear el primero.',
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
                    itemBuilder: (_, i) =>
                        _FilamentTile(filament: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
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
    final subtitle = brand == null || brand.isEmpty ? base : '$brand  ·  $base';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => context.push(
          '/settings/filaments/${filament.id}',
          extra: filament,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Leading icon / badge
              filament.isDefault
                  ? const DefaultBadge()
                  : Icon(Icons.label_outline,
                      color: color.onSurfaceVariant, size: 24),
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
                  const PopupMenuItem<_TileAction>(
                    value: _TileAction.setDefault,
                    child: ListTile(
                      leading: Icon(Icons.star),
                      title: Text('Predeterminado'),
                    ),
                  ),
                  const PopupMenuItem<_TileAction>(
                    value: _TileAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar'),
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
      BuildContext context, WidgetRef ref, _TileAction a) async {
    final notifier = ref.read(filamentsNotifierProvider.notifier);
    switch (a) {
      case _TileAction.setDefault:
        await notifier.setAsDefault(filament.id);
      case _TileAction.delete:
        final confirm = await showConfirmDialog(
          context,
          title: 'Eliminar filamento',
          message: '¿Eliminar "${filament.name}"?',
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
            SnackBar(
              content: Text('"$name" eliminado'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Deshacer',
                onPressed: () {
                  notifier.create(
                    name: name,
                    brand: brand,
                    pricePerBobbin: Decimal.parse(price.toString()),
                    gramsPerBobbin: Decimal.parse(grams.toString()),
                    asDefault: wasDefault,
                  );
                },
              ),
            ),
          );
    }
  }
}

enum _TileAction { setDefault, delete }
