// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';

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

  group('FilamentsNotifier.build', () {
    test('estado inicial = lista vacia', () async {
      final list = await container.read(filamentsNotifierProvider.future);
      expect(list, isEmpty);
    });

    test('build reactivo: tras seed externo, refresh() trae los datos', () async {
      // Seed via repo directo (simula otro modulo que inserta)
      await container.read(filamentRepositoryProvider).create(
        name: 'PLA Seed',
        pricePerBobbin: Decimal.parse('150'),
        gramsPerBobbin: Decimal.parse('1000'),
      );

      // El notifier ya fue build-eado en vacio, hay que refresh
      await container.read(filamentsNotifierProvider.notifier).refresh();
      final list = await container.read(filamentsNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.name, 'PLA Seed');
    });
  });

  group('FilamentsNotifier.create', () {
    test('inserta y la lista tiene 1 elemento', () async {
      final n = container.read(filamentsNotifierProvider.notifier);
      await container.read(filamentsNotifierProvider.future); // build

      await n.create(
        name: 'PLA',
        pricePerBobbin: Decimal.parse('150'),
        gramsPerBobbin: Decimal.parse('1000'),
      );

      final list = await container.read(filamentsNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.name, 'PLA');
      expect(list.first.pricePerBobbin, 150.0);
      expect(list.first.gramsPerBobbin, 1000.0);
      expect(list.first.isDefault, isFalse);
    });

    test('asDefault=true al crear desmarca otros existentes', () async {
      final n = container.read(filamentsNotifierProvider.notifier);
      await container.read(filamentsNotifierProvider.future);

      await n.create(
        name: 'A',
        pricePerBobbin: Decimal.parse('100'),
        gramsPerBobbin: Decimal.parse('1000'),
        asDefault: true,
      );
      await n.create(
        name: 'B',
        pricePerBobbin: Decimal.parse('200'),
        gramsPerBobbin: Decimal.parse('1000'),
        asDefault: true,
      );

      final list = await container.read(filamentsNotifierProvider.future);
      final defaults = list.where((f) => f.isDefault).toList();
      expect(defaults, hasLength(1));
      expect(defaults.first.name, 'B');
    });

    test('create con brand opcional se persiste', () async {
      final n = container.read(filamentsNotifierProvider.notifier);
      await container.read(filamentsNotifierProvider.future);

      await n.create(
        name: 'PETG',
        brand: 'Prusament',
        pricePerBobbin: Decimal.parse('199.99'),
        gramsPerBobbin: Decimal.parse('850.50'),
      );

      final list = await container.read(filamentsNotifierProvider.future);
      expect(list.first.brand, 'Prusament');
    });
  });

  group('FilamentsNotifier.update', () {
    test('actualiza nombre, precio, gramos', () async {
      final n = container.read(filamentsNotifierProvider.notifier);
      await container.read(filamentsNotifierProvider.future);
      await n.create(
        name: 'Old',
        pricePerBobbin: Decimal.parse('100'),
        gramsPerBobbin: Decimal.parse('1000'),
      );
      final id = (await container.read(filamentsNotifierProvider.future)).first.id;

      await n.updateFilament(
        id: id,
        name: 'New',
        pricePerBobbin: Decimal.parse('200'),
        gramsPerBobbin: Decimal.parse('800'),
      );

      final updated = await container.read(filamentsNotifierProvider.future);
      expect(updated.first.name, 'New');
      expect(updated.first.pricePerBobbin, 200.0);
      expect(updated.first.gramsPerBobbin, 800.0);
    });
  });

  group('FilamentsNotifier.delete', () {
    test('elimina y la lista queda vacia', () async {
      final n = container.read(filamentsNotifierProvider.notifier);
      await container.read(filamentsNotifierProvider.future);
      await n.create(
        name: 'X',
        pricePerBobbin: Decimal.parse('100'),
        gramsPerBobbin: Decimal.parse('1000'),
      );
      final id = (await container.read(filamentsNotifierProvider.future)).first.id;

      await n.delete(id);

      final after = await container.read(filamentsNotifierProvider.future);
      expect(after, isEmpty);
    });
  });

  group('FilamentsNotifier.setAsDefault', () {
    test('marca uno como default y desmarca los demas', () async {
      final n = container.read(filamentsNotifierProvider.notifier);
      await container.read(filamentsNotifierProvider.future);
      await n.create(
        name: 'A',
        pricePerBobbin: Decimal.parse('100'),
        gramsPerBobbin: Decimal.parse('1000'),
        asDefault: true,
      );
      await n.create(
        name: 'B',
        pricePerBobbin: Decimal.parse('200'),
        gramsPerBobbin: Decimal.parse('1000'),
      );
      final bId = (await container.read(filamentsNotifierProvider.future))
          .firstWhere((f) => f.name == 'B')
          .id;

      await n.setAsDefault(bId);

      final after = await container.read(filamentsNotifierProvider.future);
      expect(after.firstWhere((f) => f.name == 'B').isDefault, isTrue);
      expect(after.firstWhere((f) => f.name == 'A').isDefault, isFalse);
    });
  });
}
