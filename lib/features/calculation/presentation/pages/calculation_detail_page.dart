// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../notifiers/calculations_notifier.dart';

/// Detalle de una cotizacion guardada. Readonly.
///
/// **Comportamiento**:
/// - Muestra metadata (pieceName, clientName, fecha, impresora snapshot).
/// - Lista los materiales con sus snapshots.
/// - Desglose financiero (costos + profit + total).
/// - Acciones: "Reusar" (push Calculator prefill), "Marcar vendida",
///   "Editar nombre/cliente" (Sprint 5+), "Eliminar".
class CalculationDetailPage extends ConsumerWidget {
  const CalculationDetailPage({super.key, required this.calcId});

  final int calcId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(_calculationByIdProvider(calcId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle cotizacion'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: calc == null
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar cotizacion'),
                        content: Text('¿Eliminar definitivamente?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
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
              icon: const Icon(Icons.replay),
              label: const Text('Reusar'),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // === Header ===
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        calc.pieceName ?? 'Sin nombre',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (calc.isSold)
                      Chip(
                        label: const Text('Vendida'),
                        backgroundColor: Colors.green.shade100,
                        avatar: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                if (calc.clientName != null && calc.clientName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Cliente: ${calc.clientName}'),
                  ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd MMM yyyy · HH:mm').format(
                    calc.createdAt.toLocal(),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                if (calc.printerNameSnapshot != null)
                  Text(
                    'Impresora: ${calc.printerNameSnapshot} '
                    '(${calc.printerWattsSnapshot.toStringAsFixed(0)} W)',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // === Materiales ===
        Text('Materiales', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        materials.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (ms) {
            if (ms.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin materiales.'),
                ),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < ms.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      title: Text(ms[i].label),
                      subtitle: Text(
                        '${ms[i].weightGrams.toStringAsFixed(0)} g · '
                        'BOB ${ms[i].pricePerBobbinSnapshot.toStringAsFixed(2)} / '
                        '${ms[i].gramsPerBobbinSnapshot.toStringAsFixed(0)} g',
                      ),
                      trailing: Text(
                        formatBob(
                          Decimal.parse(
                            (ms[i].weightGrams *
                                    ms[i].pricePerBobbinSnapshot /
                                    ms[i].gramsPerBobbinSnapshot)
                                .toStringAsFixed(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // === Desglose ===
        Text('Desglose', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                _Row(
                  label: 'Costo electrico',
                  value: formatBob(
                    Decimal.parse(
                      calc.electricCostSnapshot.toStringAsFixed(2),
                    ),
                  ),
                ),
                const Divider(),
                _Row(
                  label: 'Costo base',
                  value: formatBob(
                    Decimal.parse(
                      calc.baseCostSnapshot.toStringAsFixed(2),
                    ),
                  ),
                ),
                _Row(
                  label: 'Profit',
                  value: formatBob(
                    Decimal.parse(
                      calc.profitAmountSnapshot.toStringAsFixed(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      formatBob(
                        Decimal.parse(
                          calc.totalPriceSnapshot.toStringAsFixed(2),
                        ),
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // === Acciones ===
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: Icon(
                  calc.isSold
                      ? Icons.undo
                      : Icons.check_circle_outline,
                ),
                label: Text(calc.isSold ? 'Pendiente' : 'Marcar vendida'),
                onPressed: () async {
                  await ref
                      .read(calculationsNotifierProvider.notifier)
                      .toggleSold(calc.id, !calc.isSold);
                },
              ),
            ),
          ],
        ),
        // Padding bottom para no chocar con FAB.
        const SizedBox(height: 80),
      ],
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
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider de un [Calculation] especifico por id.
final _calculationByIdProvider = Provider.family<Calculation?, int>((ref, id) {
  final list = ref.watch(calculationsNotifierProvider).valueOrNull;
  if (list == null) return null;
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

/// Provider de los [CalculationMaterial]s de una cotizacion.
final _materialsOfProvider =
    FutureProvider.family<List<CalculationMaterial>, int>((ref, id) {
  return ref.read(calculationRepositoryProvider).materialsOf(id);
});
