// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
