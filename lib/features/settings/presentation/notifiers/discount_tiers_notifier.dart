// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/discount_tier.dart';

/// AsyncNotifier de escalones de descuento por cantidad (feature A — Hito 1).
///
/// Expone el listado ordenado desde [DiscountTiersRepository.watchAll] y
/// delega las operaciones CRUD al repository.
class DiscountTiersNotifier extends AsyncNotifier<List<DiscountTier>> {
  @override
  Future<List<DiscountTier>> build() async {
    final repo = ref.watch(discountTiersRepositoryProvider);
    // El stream se materializa como first para el estado inicial.
    // Los cambios subsiguientes se manejan via ref.listen en la UI o
    // invalidando el provider tras cada operación.
    return repo.listAll();
  }

  /// Inserta o actualiza un escalón y refresca el estado.
  Future<void> upsert(DiscountTier tier) async {
    final repo = ref.read(discountTiersRepositoryProvider);
    await repo.upsert(tier);
    ref.invalidateSelf();
  }

  /// Elimina un escalón por id y refresca el estado.
  Future<void> delete(String id) async {
    final repo = ref.read(discountTiersRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final discountTiersNotifierProvider =
    AsyncNotifierProvider<DiscountTiersNotifier, List<DiscountTier>>(
  DiscountTiersNotifier.new,
);
