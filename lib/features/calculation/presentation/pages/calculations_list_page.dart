// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../notifiers/calculations_notifier.dart';

/// Historial de cotizaciones guardadas — version mejorada con cards.
class CalculationsListPage extends ConsumerWidget {
  const CalculationsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(calculationsNotifierProvider);
    final notifier = ref.read(calculationsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(EsBO.historyTitle),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: EsBO.historyErrorLoad,
          details: e.toString(),
          onRetry: () => ref.invalidate(calculationsNotifierProvider),
        ),
        data: (calcs) {
          if (calcs.isEmpty) {
            return EmptyView(
              icon: Icons.receipt_long_outlined,
              message: EsBO.historyEmpty,
              subtitle: 'Crea una desde el calculator y toca Guardar.',
              ctaLabel: EsBO.homeActionNewCalc,
              ctaIcon: Icons.add_rounded,
              onCta: () => context.push('/calculator'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(calculationsNotifierProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: calcs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CalculationCard(calc: calcs[i], notifier: notifier),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalculationCard extends ConsumerWidget {
  const _CalculationCard({required this.calc, required this.notifier});

  final Calculation calc;
  final CalculationsNotifier notifier;

  String _title() {
    final piece = calc.pieceName;
    if (piece != null && piece.isNotEmpty) return piece;
    final client = calc.clientName;
    if (client != null && client.isNotEmpty) return 'Cotizacion · $client';
    return EsBO.calcDetailNoName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final client = calc.clientName;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/history/${calc.id}', extra: calc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: calc.isSold
                      ? color.tertiaryContainer
                      : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  calc.isSold
                      ? Icons.check_circle_rounded
                      : Icons.receipt_long_rounded,
                  color: calc.isSold
                      ? color.tertiary
                      : color.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (client != null && client.isNotEmpty) ...[
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: color.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              client,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: color.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          DateFormat('dd MMM HH:mm')
                              .format(calc.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price + menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatBob(Decimal.parse(
                        calc.totalPriceSnapshot.toString())),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PopupMenu(calc: calc, notifier: notifier),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopupMenu extends StatelessWidget {
  const _PopupMenu({required this.calc, required this.notifier});

  final Calculation calc;
  final CalculationsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TileAction>(
      onSelected: (a) => _handle(context, a),
      padding: EdgeInsets.zero,
      iconSize: 18,
      itemBuilder: (_) => [
        PopupMenuItem<_TileAction>(
          value: _TileAction.toggleSold,
          child: ListTile(
            leading: Icon(
              calc.isSold ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
              size: 20,
            ),
            title: Text(
                calc.isSold ? EsBO.calcDetailMarkPending : EsBO.calcDetailMarkSold,
                style: const TextStyle(fontSize: 14)),
            dense: true,
          ),
        ),
        const PopupMenuItem<_TileAction>(
          value: _TileAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, size: 20),
            title: Text(EsBO.commonDelete, style: TextStyle(fontSize: 14)),
            dense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handle(BuildContext context, _TileAction a) async {
    switch (a) {
      case _TileAction.toggleSold:
        await notifier.toggleSold(calc.id, !calc.isSold);
      case _TileAction.delete:
        final confirm = await showConfirmDialog(
          context,
          title: EsBO.calcDetailDeleteTitle,
          message: '¿Eliminar permanentemente?',
        );
        if (confirm) {
          await notifier.delete(calc.id);
        }
    }
  }
}

enum _TileAction { toggleSold, delete }
