// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../domain/discount_tier.dart';
import '../notifiers/discount_tiers_notifier.dart';

/// Sección CRUD de escalones de descuento por cantidad (feature A — Hito 1).
///
/// Tabla con columnas: min_qty | % | acciones (editar/eliminar).
/// Add/edit vía bottom sheet con validación (`min_qty ≥ 2`, `% 0–100`).
/// Auto-sort al guardar. Empty state cuando no hay escalones.
/// SIN badge Pro ni paywall (FREE, decisión P1).
class DiscountTiersSection extends ConsumerWidget {
  const DiscountTiersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiersAsync = ref.watch(discountTiersNotifierProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return tiersAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Error: $e',
          style: theme.textTheme.bodySmall?.copyWith(color: color.error),
        ),
      ),
      data: (tiers) {
        if (tiers.isEmpty) {
          return _EmptyState(onAdd: () => _showAddSheet(context, ref));
        }
        return Column(
          children: [
            // Header de la tabla
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      EsBO.discountTierMinQty,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      EsBO.discountTierPercent,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Filas
            for (final tier in tiers) ...[
              _TierRow(
                tier: tier,
                onEdit: () => _showEditSheet(context, ref, tier),
                onDelete: () => _confirmDelete(context, ref, tier),
              ),
              if (tier != tiers.last)
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
            // Botón agregar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: TextButton.icon(
                onPressed: () => _showAddSheet(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(EsBO.discountTierAdd),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TierEditSheet(
        onSave: (minQty, percent) async {
          final tier = DiscountTier.create(
            minQty: minQty,
            percent: percent,
          );
          await ref
              .read(discountTiersNotifierProvider.notifier)
              .upsert(tier);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, DiscountTier tier) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TierEditSheet(
        initialMinQty: tier.minQty,
        initialPercent: tier.percent,
        onSave: (minQty, percent) async {
          final updated = tier.copyWith(
            minQty: minQty,
            percent: percent,
          );
          await ref
              .read(discountTiersNotifierProvider.notifier)
              .upsert(updated);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DiscountTier tier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(EsBO.discountTierDelete),
        content: Text(
          '${EsBO.discountTierMinQty}: ${tier.minQty} · '
          '${EsBO.discountTierPercent}: ${tier.percent.toStringAsFixed(0)}%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(EsBO.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(discountTiersNotifierProvider.notifier)
                  .delete(tier.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(EsBO.commonDelete),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: color.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsBO.discountTierEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: onAdd,
            child: Text(EsBO.discountTierAdd),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.onEdit,
    required this.onDelete,
  });

  final DiscountTier tier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${tier.minQty}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${tier.percent.toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierEditSheet extends StatefulWidget {
  const _TierEditSheet({
    this.initialMinQty,
    this.initialPercent,
    required this.onSave,
  });

  final int? initialMinQty;
  final Decimal? initialPercent;
  final Future<void> Function(int minQty, Decimal percent) onSave;

  @override
  State<_TierEditSheet> createState() => _TierEditSheetState();
}

class _TierEditSheetState extends State<_TierEditSheet> {
  late final TextEditingController _minQtyController;
  late final TextEditingController _percentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _minQtyController = TextEditingController(
      text: widget.initialMinQty?.toString() ?? '10',
    );
    _percentController = TextEditingController(
      text: widget.initialPercent?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minQtyController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialMinQty == null
                  ? EsBO.discountTierAdd
                  : EsBO.discountTierEdit,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _minQtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: EsBO.discountTierMinQty,
                suffixText: 'u.',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null) return EsBO.commonInvalidNumber;
                if (!DiscountTier.isValidMinQty(n)) {
                  return EsBO.discountTierValidationMinQty;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _percentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Descuento',
                suffixText: '%',
              ),
              validator: (v) {
                final n = Decimal.tryParse(v ?? '');
                if (n == null) return EsBO.commonInvalidNumber;
                if (!DiscountTier.isValidPercent(n)) {
                  return EsBO.discountTierValidationPercent;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final minQty = int.parse(_minQtyController.text);
                final percent = Decimal.parse(_percentController.text);
                await widget.onSave(minQty, percent);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(EsBO.commonSave),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
