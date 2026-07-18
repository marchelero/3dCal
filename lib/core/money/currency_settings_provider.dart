/// Provider reactivo de [WorldCurrency] basado en settings persistidos.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/notifiers/settings_notifier.dart';
import 'currency.dart';

/// Escucha [settingsNotifierProvider] y deriva la [WorldCurrency] activa.
///
/// Todos los widgets que muestran precios usan este provider en lugar de
/// leer settings directamente. Garantiza que el simbolo se actualiza
/// al cambiar la moneda en settings.
final selectedCurrencyProvider = Provider<WorldCurrency>((ref) {
  final settings = ref.watch(settingsNotifierProvider).valueOrNull;
  return WorldCurrency.fromCode(settings?.currencyCode ?? '');
});
