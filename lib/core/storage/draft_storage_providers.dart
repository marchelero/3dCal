// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calculation_draft.dart';
import 'draft_storage.dart';

/// Provider de SharedPreferences. Overridable en tests con
/// `SharedPreferences.setMockInitialValues({})` + override.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope before use.');
});

/// Provider de [DraftStorage] que depende de [sharedPreferencesProvider].
final draftStorageProvider = Provider<DraftStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DraftStorage(prefs);
});

/// Provee el draft persistido (o `null` si no hay).
///
/// La Home lo usa para ofrecer "Continuar cotización" cuando hay un
/// trabajo a medio hacer (la calculadora persiste el draft en cada
/// cambio, debounced).
final draftStatusProvider = FutureProvider<CalculationDraft?>((ref) {
  final storage = ref.watch(draftStorageProvider);
  return storage.load();
});
