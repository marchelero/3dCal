import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/calculation_engine.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_input.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/catalog/filaments/data/filament_repository.dart';
import 'package:tresdcal/features/catalog/printers/data/printer_repository.dart';
import 'package:tresdcal/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  late PrinterRepository printers;
  late FilamentRepository filaments;
  late SettingsRepository settings;
  late CalculationRepository calculations;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    printers = PrinterRepository(db);
    filaments = FilamentRepository(db);
    settings = SettingsRepository(db);
    calculations = CalculationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase initialization', () {
    test('abre y crea todas las tablas', () async {
      final allPrinters = await printers.listAll();
      expect(allPrinters, isEmpty);
    });
  });

  group('PrinterRepository', () {
    test('create + listAll', () async {
      final id = await printers.create(
        name: 'Ender 3',
        averageWatts: 150,
      );
      expect(id, greaterThan(0));

      final list = await printers.listAll();
      expect(list, hasLength(1));
      expect(list.first.name, 'Ender 3');
      expect(list.first.averageWatts, 150);
      expect(list.first.isDefault, isFalse);
    });

    test('asDefault desmarca otros', () async {
      await printers.create(name: 'P1', averageWatts: 100, asDefault: true);
      await printers.create(name: 'P2', averageWatts: 200, asDefault: true);

      final all = await printers.listAll();
      final defaults = all.where((p) => p.isDefault).toList();
      expect(defaults, hasLength(1));
      expect(defaults.first.name, 'P2');
    });

    test('getDefault devuelve la unica default', () async {
      await printers.create(name: 'A', averageWatts: 100);
      await printers.create(name: 'B', averageWatts: 200, asDefault: true);

      final def = await printers.getDefault();
      expect(def, isNotNull);
      expect(def!.name, 'B');
    });

    test('update cambia nombre y watts', () async {
      final id = await printers.create(name: 'Old', averageWatts: 100);
      final ok = await printers.update(
        id: id,
        name: 'New',
        averageWatts: 250,
      );
      expect(ok, isTrue);

      final all = await printers.listAll();
      expect(all.first.name, 'New');
      expect(all.first.averageWatts, 250);
    });

    test('delete elimina', () async {
      final id = await printers.create(name: 'X', averageWatts: 100);
      final deleted = await printers.delete(id);
      expect(deleted, 1);

      final all = await printers.listAll();
      expect(all, isEmpty);
    });
  });

  group('FilamentRepository', () {
    test('create + listAll con Decimal', () async {
      await filaments.create(
        name: 'PLA Negro',
        brand: 'eSun',
        pricePerBobbin: _d('150.50'),
        gramsPerBobbin: _d('1000'),
      );

      final list = await filaments.listAll();
      expect(list, hasLength(1));
      expect(list.first.name, 'PLA Negro');
      expect(list.first.brand, 'eSun');
    });

    test('decimal round-trip con 2 lugares', () async {
      await filaments.create(
        name: 'PETG',
        pricePerBobbin: _d('199.99'),
        gramsPerBobbin: _d('850.50'),
      );
      final list = await filaments.listAll();
      // Drift guarda como REAL, recuperamos double. Comparamos con tolerancia.
      expect(list.first.pricePerBobbin, closeTo(199.99, 0.001));
      expect(list.first.gramsPerBobbin, closeTo(850.50, 0.001));
    });
  });

  group('SettingsRepository', () {
    test('getProfitBase devuelve default 200 si no existe', () async {
      final profit = await settings.getProfitBase();
      expect(profit, _d('200'));
    });

    test('setProfitBase + getProfitBase', () async {
      await settings.setProfitBase(_d('150'));
      final profit = await settings.getProfitBase();
      expect(profit, _d('150'));
    });

    test('getKwhRate / setKwhRate', () async {
      await settings.setKwhRate(_d('0.85'));
      final rate = await settings.getKwhRate();
      expect(rate, _d('0.85'));
    });
  });

  group('CalculationRepository', () {
    test('create con materiales persiste y devuelve id', () async {
      final draft = _simpleDraft('Engranaje X', 'Juan');

      final id = await calculations.create(draft);
      expect(id, greaterThan(0));

      final all = await calculations.listAll();
      expect(all, hasLength(1));
      expect(all.first.pieceName, 'Engranaje X');
      expect(all.first.clientName, 'Juan');
      expect(all.first.isSold, isFalse);

      final mats = await calculations.materialsOf(id);
      expect(mats, hasLength(1));
      expect(mats.first.label, 'PLA');
    });

    test('toggleSold cambia isSold', () async {
      final id = await calculations.create(_simpleDraft('P1'));

      final ok = await calculations.toggleSold(id, true);
      expect(ok, isTrue);

      final all = await calculations.listAll();
      expect(all.first.isSold, isTrue);
    });

    test('totalQuoted > totalSold cuando hay pendientes', () async {
      final id1 = await calculations.create(_simpleDraft('P1'));
      await calculations.create(_simpleDraft('P2'));
      await calculations.toggleSold(id1, true);

      final total = await calculations.totalQuoted();
      final sold = await calculations.totalSold();
      expect(total, greaterThan(sold));
      expect(sold, greaterThan(Decimal.zero));
    });

    test('countAll y countSold', () async {
      final id1 = await calculations.create(_simpleDraft('P1'));
      await calculations.create(_simpleDraft('P2'));
      await calculations.toggleSold(id1, true);

      expect(await calculations.countAll(), 2);
      expect(await calculations.countSold(), 1);
    });

    test('updateMetadata cambia piece/client', () async {
      final id = await calculations.create(_simpleDraft('Old'));
      final ok = await calculations.updateMetadata(
        id: id,
        pieceName: 'Nuevo',
        clientName: 'Maria',
      );
      expect(ok, isTrue);

      final all = await calculations.listAll();
      expect(all.first.pieceName, 'Nuevo');
      expect(all.first.clientName, 'Maria');
    });
  });
}

// ---------- Helpers ----------

Decimal _d(String s) => Decimal.parse(s);

CalculationDraft _simpleDraft(String pieceName, [String? clientName]) {
  final materials = [
    MaterialInput(
      label: 'PLA',
      weightGrams: _d('100'),
      pricePerBobbin: _d('150'),
      gramsPerBobbin: _d('1000'),
    ),
  ];
  final input = CalculationInput(
    materials: materials,
    totalHours: _d('2.5'),
    discountPercentage: Decimal.zero,
    printerWatts: 0,
    kwhRate: Decimal.zero,
    profitBase: Decimal.zero,
    laborRate: Decimal.zero,
    postProcessRate: Decimal.zero,
    failureRate: Decimal.zero,
    markupOnMaterials: Decimal.zero,
  );
  final output = CalculationEngine.compute(input);
  return CalculationDraft(
    materials: materials,
    totalHours: input.totalHours,
    discountPercentage: input.discountPercentage,
    output: output,
    pieceName: pieceName,
    clientName: clientName,
  );
}
