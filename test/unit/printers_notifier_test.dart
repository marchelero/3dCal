// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/catalog/printers/presentation/notifiers/printers_notifier.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('build + create', () async {
    final list = await container.read(printersNotifierProvider.future);
    expect(list, isEmpty);

    await container.read(printersNotifierProvider.notifier).create(
          name: 'Ender 3',
          averageWatts: 150,
        );
    final after = await container.read(printersNotifierProvider.future);
    expect(after, hasLength(1));
    expect(after.first.name, 'Ender 3');
    expect(after.first.averageWatts, 150);
    expect(after.first.isDefault, isFalse);
  });

  test('setAsDefault desmarca otros', () async {
    final n = container.read(printersNotifierProvider.notifier);
    await container.read(printersNotifierProvider.future); // build
    await n.create(name: 'A', averageWatts: 100, asDefault: true);
    await n.create(name: 'B', averageWatts: 200);
    final bId =
        (await container.read(printersNotifierProvider.future)).last.id;

    await n.setAsDefault(bId);

    final after = await container.read(printersNotifierProvider.future);
    expect(after.firstWhere((p) => p.name == 'B').isDefault, isTrue);
    expect(after.firstWhere((p) => p.name == 'A').isDefault, isFalse);
  });
}
