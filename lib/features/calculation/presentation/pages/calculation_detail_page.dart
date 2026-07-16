// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../notifiers/calculations_notifier.dart';

/// Detalle de una cotizacion guardada. Readonly — version mejorada.
class CalculationDetailPage extends ConsumerWidget {
  const CalculationDetailPage({super.key, required this.calcId});

  final int calcId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(_calculationByIdProvider(calcId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(EsBO.calcDetailTitle),
        actions: [
          IconButton(
            tooltip: EsBO.calcDetailDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: calc == null
                ? null
                : () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: EsBO.calcDetailDeleteTitle,
                      message: '¿Eliminar definitivamente?',
                    );
                    if (confirm && context.mounted) {
                      await ref
                          .read(calculationsNotifierProvider.notifier)
                          .delete(calcId);
                      if (context.mounted) context.pop();
                    }
                  },
          ),
        ],
      ),
      body: calc == null
          ? const Center(child: CircularProgressIndicator())
          : _Detail(calc: calc),
      floatingActionButton: calc == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.replay_rounded),
              label: const Text(EsBO.calcDetailReuse),
              onPressed: () {
                context.push('/calculator/prefill', extra: calc);
              },
            ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.calc});

  final Calculation calc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(_materialsOfProvider(calc.id));
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return MaxWidthScrollView(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        shrinkWrap: true,
        children: [
        // === Header card (hero) ===
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.primaryContainer,
                color.primaryContainer.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.xxxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      calc.pieceName ?? EsBO.calcDetailNoName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (calc.isSold)
                    Chip(
                      label: const Text(EsBO.calcDetailSold),
                      backgroundColor: color.tertiaryContainer,
                      labelStyle: TextStyle(color: color.onTertiaryContainer),
                      avatar: Icon(
                        Icons.check_circle_rounded,
                        color: color.tertiary,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              if (calc.clientName != null && calc.clientName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: color.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Cliente: ${calc.clientName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: color.onPrimaryContainer.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm')
                        .format(calc.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  if (calc.totalHours > 0) ...[
                    const SizedBox(width: AppSpacing.lg),
                    Icon(Icons.timer_outlined,
                        size: 14, color: color.onPrimaryContainer.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '${calc.totalHours.toStringAsFixed(1)} h',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // === Materiales ===
        Text('Materiales',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        materials.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (ms) {
            if (ms.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('Sin materiales.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant)),
                ),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < ms.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: color.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ms[i].label,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500)),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${ms[i].weightGrams.toStringAsFixed(0)} g · '
                                  'BOB ${ms[i].pricePerBobbinSnapshot.toStringAsFixed(2)} / '
                                  '${ms[i].gramsPerBobbinSnapshot.toStringAsFixed(0)} g',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatBob(Decimal.parse(
                              (ms[i].weightGrams *
                                      ms[i].pricePerBobbinSnapshot /
                                      ms[i].gramsPerBobbinSnapshot)
                                  .toStringAsFixed(2),
                            )),
                            // M2: precio por material usa JetBrains Mono + tabular.
                            style: GoogleFonts.jetBrainsMono(
                              textStyle: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // === Desglose ===
        Text('Desglose',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _Row(
                  label: 'Costo material',
                  value: formatBob(
                    Decimal.parse(
                      calc.materialCostSnapshot.toStringAsFixed(2),
                    ),
                  ),
                ),
                if (calc.discountPercentage > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: color.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Descuento (${calc.discountPercentage.toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '-${formatBob(Decimal.parse((calc.materialCostSnapshot * calc.discountPercentage / 100).toStringAsFixed(2)))}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      // V1: label del gran total sube a titleLarge para
                      // acompanar el peso del valor (headlineMedium).
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatBob(
                          Decimal.parse(
                            calc.totalPriceSnapshot.toStringAsFixed(2),
                          ),
                        ),
                        // M2: total del detalle usa JetBrains Mono + tabular
                        // para coincidir con la cifra principal del calculator.
                        // V1: headlineMedium (28sp) con FittedBox, mas prominente
                        // que el headlineSmall anterior.
                        style: GoogleFonts.jetBrainsMono(
                          textStyle: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // === Acciones ===
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: Icon(
                  calc.isSold
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(calc.isSold ? EsBO.calcDetailMarkPending : EsBO.calcDetailMarkSold),
                onPressed: () async {
                  await ref
                      .read(calculationsNotifierProvider.notifier)
                      .toggleSold(calc.id, !calc.isSold);
                },
              ),
            ),
          ],
        ),
        // Padding bottom para FAB.
        const SizedBox(height: 80),
      ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            // M2: cost breakdown usa JetBrains Mono + tabular para que
            // cada linea del breakdown muestre cifras alineadas.
            style: GoogleFonts.jetBrainsMono(
              textStyle: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _calculationByIdProvider =
    Provider.family<Calculation?, int>((ref, id) {
  final list = ref.watch(calculationsNotifierProvider).valueOrNull;
  if (list == null) return null;
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

final _materialsOfProvider =
    FutureProvider.family<List<CalculationMaterial>, int>((ref, id) {
  // watch (no read) para que los overrides de repository en tests sean
  // respetados y para que el provider reaccione a cambios en el repo.
  final repo = ref.watch(calculationRepositoryProvider);
  return repo.materialsOf(id);
});
