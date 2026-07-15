// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../notifiers/calculations_notifier.dart';
import 'calculation_detail_page.dart';

/// Historial de cotizaciones guardadas.
///
/// **Comportamiento**:
/// - Lista todas las cotizaciones ordenadas por fecha desc (repo).
/// - Tap en row → detalle (`CalculationDetailPage`).
/// - Menu por fila: "Marcar como vendida" / "Eliminar".
/// - Estrella verde si `isSold = true`.
/// - Pull-to-refresh recarga el historial.
/// - Empty state si no hay cotizaciones.
class CalculationsListPage extends ConsumerWidget {
  const CalculationsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(calculationsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error cargando cotizaciones: $e'),
          ),
        ),
        data: (calcs) {
          if (calcs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin cotizaciones guardadas. '
                      'Crea una desde el calculator y toca "Guardar".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < calcs.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _CalculationTile(calc: calcs[i]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalculationTile extends ConsumerWidget {
  const _CalculationTile({required this.calc});

  final Calculation calc;

  String _title() {
    final piece = calc.pieceName;
    if (piece != null && piece.isNotEmpty) return piece;
    final client = calc.clientName;
    if (client != null && client.isNotEmpty) return 'Cotizacion · $client';
    return 'Cotizacion sin nombre';
  }

  String _subtitle() {
    final parts = <String>[];
    final client = calc.clientName;
    if (client != null && client.isNotEmpty) parts.add(client);
    parts.add(formatBob(Decimal.parse(calc.totalPriceSnapshot.toString())));
    parts.add(DateFormat('dd MMM HH:mm').format(calc.createdAt.toLocal()));
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        calc.isSold ? Icons.check_circle : Icons.receipt_long,
        color: calc.isSold ? Colors.green : null,
      ),
      title: Text(_title()),
      subtitle: Text(_subtitle()),
      trailing: PopupMenuButton<_TileAction>(
        onSelected: (a) => _handle(context, ref, a),
        itemBuilder: (_) => [
          PopupMenuItem<_TileAction>(
            value: _TileAction.toggleSold,
            child: ListTile(
              leading: Icon(
                calc.isSold ? Icons.undo : Icons.check_circle_outline,
              ),
              title: Text(
                calc.isSold ? 'Marcar pendiente' : 'Marcar vendida',
              ),
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CalculationDetailPage(calcId: calc.id),
        ),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _TileAction a,
  ) async {
    final notifier = ref.read(calculationsNotifierProvider.notifier);
    switch (a) {
      case _TileAction.toggleSold:
        await notifier.toggleSold(calc.id, !calc.isSold);
      case _TileAction.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar cotizacion'),
            content: Text('¿Eliminar "${_title()}"?'),
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
        if (confirm == true) {
          await notifier.delete(calc.id);
        }
    }
  }
}

enum _TileAction { toggleSold, delete }
