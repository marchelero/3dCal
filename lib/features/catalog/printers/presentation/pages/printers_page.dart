// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../shared/widgets/empty_view.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/loading_view.dart';
import '../notifiers/printers_notifier.dart';

/// Catalogo de impresoras. Espejo de [FilamentsPage] sin `brand`.
class PrintersPage extends ConsumerWidget {
  const PrintersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(printersNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impresoras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva impresora',
            onPressed: () => context.push('/settings/printers/new'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Error cargando impresoras: $e',
          onRetry: () => ref.invalidate(printersNotifierProvider),
        ),
        data: (printers) {
          if (printers.isEmpty) {
            return const EmptyView(
              icon: Icons.print_outlined,
              message: 'Sin impresoras. Toca + para registrar la primera.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(printersNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: printers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _PrinterTile(printer: printers[i]),
            ),
          );
        },
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
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: printer.isDefault
          ? const Icon(Icons.star, color: Colors.amber)
          : const Icon(Icons.print),
      title: Text(printer.name),
      subtitle: Text(_subtitle(printer)),
      trailing: PopupMenuButton<_TileAction>(
        onSelected: (a) => _handle(context, ref, a),
        itemBuilder: (_) => const [
          PopupMenuItem<_TileAction>(
            value: _TileAction.setDefault,
            child: ListTile(
              leading: Icon(Icons.star),
              title: Text('Marcar como default'),
            ),
          ),
          PopupMenuItem<_TileAction>(
            value: _TileAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Eliminar'),
            ),
          ),
        ],
      ),
      onTap: () => context.push(
        '/settings/printers/${printer.id}',
        extra: printer,
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _TileAction a,
  ) async {
    final notifier = ref.read(printersNotifierProvider.notifier);
    switch (a) {
      case _TileAction.setDefault:
        await notifier.setAsDefault(printer.id);
      case _TileAction.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar impresora'),
            content: Text('¿Eliminar "${printer.name}"?'),
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
          await notifier.delete(printer.id);
        }
    }
  }
}

enum _TileAction { setDefault, delete }
