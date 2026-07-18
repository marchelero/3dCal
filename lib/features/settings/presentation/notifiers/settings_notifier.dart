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
      companyName: await repo.getCompanyName(),
      companyLogoBase64: await repo.getCompanyLogo(),
      laborRate: await repo.getLaborRate(),
      postProcessRate: await repo.getPostProcessRate(),
      failureRate: await repo.getFailureRate(),
      minimumCharge: await repo.getMinimumCharge(),
      markupOnMaterials: await repo.getMarkupOnMaterials(),
      currencyCode: await repo.getCurrencyCode(),
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

  /// Persiste [value] como nombre de la empresa.
  Future<void> updateCompanyName(String value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setCompanyName(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(companyName: value));
  }

  /// Persiste el logo en base64. null para borrar.
  Future<void> updateCompanyLogo(String? base64) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setCompanyLogo(base64);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(
      companyLogoBase64: base64,
      clearLogo: base64 == null,
    ));
  }

  // === F1: Mano de obra + Post-procesado ===

  /// Persiste [value] como tarifa de mano de obra.
  Future<void> updateLaborRate(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setLaborRate(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(laborRate: value));
  }

  /// Persiste [value] como tasa de post-procesado.
  Future<void> updatePostProcessRate(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setPostProcessRate(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(postProcessRate: value));
  }

  /// Persiste [value] como tasa de falla.
  Future<void> updateFailureRate(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setFailureRate(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(failureRate: value));
  }

  /// Persiste [value] como cargo minimo.
  Future<void> updateMinimumCharge(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setMinimumCharge(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(minimumCharge: value));
  }

  /// Persiste [value] como markup por desperdicio.
  Future<void> updateMarkupOnMaterials(Decimal value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setMarkupOnMaterials(value);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(markupOnMaterials: value));
  }

  // === F4: Moneda ===

  /// Persiste [value] como codigo ISO de moneda activa.
  Future<void> updateCurrency(String code) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setCurrencyCode(code);
    final current = state.valueOrNull ?? Settings.defaults;
    state = AsyncValue.data(current.copyWith(currencyCode: code));
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
