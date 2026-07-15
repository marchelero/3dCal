// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/settings.dart';

/// Notifier de los settings globales.
///
/// **Comportamiento**:
/// - `build()` lee los settings persistidos desde [SettingsRepository].
/// - `updateProfitBase` / `updateKwhRate` persisten inmediatamente
///   (auto-save on blur, sin boton "Guardar" explicito en la UI).
/// - Despues de persistir, emite un nuevo [Settings] con el campo actualizado
///   para que la UI se re-renderice con el valor confirmado.
class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    return Settings(
      profitBase: await repo.getProfitBase(),
      kwhRate: await repo.getKwhRate(),
    );
  }

  /// Persiste [value] como nuevo `profit_base_percentage`.
  Future<void> updateProfitBase(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setProfitBase(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(profitBase: value));
  }

  /// Persiste [value] como nuevo `kwh_rate`.
  Future<void> updateKwhRate(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setKwhRate(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(kwhRate: value));
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
