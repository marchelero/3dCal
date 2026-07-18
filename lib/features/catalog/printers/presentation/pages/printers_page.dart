// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/theme/app_radii.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/confirm_dialog.dart';
import '../../../../../shared/widgets/default_badge.dart';
import '../../../../../shared/widgets/empty_view.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/skeleton_widget.dart';
import '../notifiers/printers_notifier.dart';

/// Catalogo de impresoras con busqueda y cards.
class PrintersPage extends ConsumerStatefulWidget {
  const PrintersPage({super.key});

  @override
  ConsumerState<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends ConsumerState<PrintersPage> {
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
    final async = ref.watch(printersNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.printerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: EsBO.printerNewTooltip,
            onPressed: () => context.push('/settings/printers/new'),
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
                hintText: 'Buscar impresoras...',
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
                message: 'Error cargando impresoras: $e',
                onRetry: () => ref.invalidate(printersNotifierProvider),
              ),
              data: (printers) {
                final filtered = _searchQuery.isEmpty
                    ? printers
                    : printers.where((p) {
                        final name = p.name.toLowerCase();
                        final brand = p.brand?.toLowerCase() ?? '';
                        return name.contains(_searchQuery) ||
                            brand.contains(_searchQuery);
                      }).toList();
                if (filtered.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? EmptyView(
                          icon: Icons.search_off,
                          message:
                              'Ninguna impresora coincide con "$_searchQuery"',
                        )
                      : const EmptyView(
                          icon: Icons.print_outlined,
                          message:
                              'Sin impresoras. Toca + para registrar la primera.',
                        );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(printersNotifierProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.xxl,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) =>
                        _PrinterTile(printer: filtered[i]),
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

class _PrinterTile extends ConsumerWidget {
  const _PrinterTile({required this.printer});

  final PrinterProfile printer;

  String _subtitle(PrinterProfile p) {
    final parts = <String>['${p.averageWatts} W'];
    if (p.brand != null && p.brand!.isNotEmpty) {
      parts.insert(0, p.brand!);
    }
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

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
          '/settings/printers/${printer.id}',
          extra: printer,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Leading icon / badge
              printer.isDefault
                  ? const DefaultBadge()
                  : Icon(Icons.print,
                      color: color.onSurfaceVariant, size: 24),
              const SizedBox(width: AppSpacing.md),
              // Name + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(printer),
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
    final notifier = ref.read(printersNotifierProvider.notifier);
    switch (a) {
      case _TileAction.setDefault:
        await notifier.setAsDefault(printer.id);
      case _TileAction.delete:
        final confirm = await showConfirmDialog(
          context,
          title: 'Eliminar impresora',
          message: '¿Eliminar "${printer.name}"?',
        );
        if (confirm != true || !context.mounted) return;
        // Capture data for undo
        final name = printer.name;
        final brand = printer.brand;
        final watts = printer.averageWatts;
        final wasDefault = printer.isDefault;
        await notifier.delete(printer.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('"$name" eliminada'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Deshacer',
                onPressed: () {
                  notifier.create(
                    name: name,
                    brand: brand,
                    averageWatts: watts,
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
