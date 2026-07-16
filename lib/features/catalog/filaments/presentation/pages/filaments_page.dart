// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../shared/widgets/confirm_dialog.dart';
import '../../../../../shared/widgets/empty_view.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/loading_view.dart';
import '../notifiers/filaments_notifier.dart';

/// Catalogo de filamentos.
///
/// **Comportamiento**:
/// - Lista todos los filamentos (orden alfabetico via repo).
/// - Tap en row → edita (`FilamentFormPage` con `existing`).
/// - Boton "+" en AppBar → crea (`FilamentFormPage` sin `existing`).
/// - Menu por fila: "Marcar como default" / "Eliminar".
/// - Pull-to-refresh recarga el catalogo.
/// - Estrella amarilla en el filamento que es `isDefault`.
class FilamentsPage extends ConsumerWidget {
  const FilamentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(filamentsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo filamento',
            onPressed: () => context.push('/settings/filaments/new'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Error cargando filamentos: $e',
          onRetry: () => ref.invalidate(filamentsNotifierProvider),
        ),
        data: (filaments) {
          if (filaments.isEmpty) {
            return const EmptyView(
              icon: Icons.inventory_2_outlined,
              message: 'Sin filamentos. Toca + para crear el primero.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(filamentsNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: filaments.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _FilamentTile(filament: filaments[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FilamentTile extends ConsumerWidget {
  const _FilamentTile({required this.filament});

  final Filament filament;

  String _subtitle() {
    final price = filament.pricePerBobbin.toStringAsFixed(2);
    final grams = filament.gramsPerBobbin.toStringAsFixed(0);
    final brand = filament.brand;
    final base = 'BOB $price · $grams g';
    return brand == null || brand.isEmpty ? base : '$brand · $base';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: filament.isDefault
          ? const Icon(Icons.star, color: Colors.amber)
          : const Icon(Icons.label_outline),
      title: Text(filament.name),
      subtitle: Text(_subtitle()),
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
        '/settings/filaments/${filament.id}',
        extra: filament,
      ),
    );
  }

  Future<void> _handle(BuildContext context, WidgetRef ref, _TileAction a) async {
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
        if (confirm) {
          await notifier.delete(filament.id);
        }
    }
  }
}

enum _TileAction { setDefault, delete }
