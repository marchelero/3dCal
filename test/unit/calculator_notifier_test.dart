import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/notifiers/calculations_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';

void main() {
  group('CalculatorState.initial', () {
    test('tiene defaults MVP', () {
      final s = CalculatorState.initial();
      expect(s.weight, '');
      expect(s.printHours, '');
      expect(s.printMinutes, '');
      expect(s.discountPct, '0');
      expect(s.filamentPrice, '');
      expect(s.filamentGrams, '');
      expect(s.label, '');
      expect(s.output, isNull);
    });

    test('isValid es false en estado inicial (faltan weight/precio/gramos)', () {
      expect(CalculatorState.initial().isValid, isFalse);
    });
  });

  group('CalculatorState.parseDecimal', () {
    test('parsea entero', () {
      expect(CalculatorState.parseDecimal('100'), Decimal.fromInt(100));
    });

    test('parsea decimal con punto', () {
      expect(CalculatorState.parseDecimal('0.70'), Decimal.parse('0.70'));
    });

    test('parsea decimal con coma (locale es_BO)', () {
      expect(CalculatorState.parseDecimal('0,70'), Decimal.parse('0.70'));
    });

    test('parsea con espacios', () {
      expect(CalculatorState.parseDecimal('  42  '), Decimal.fromInt(42));
    });

    test('vacio retorna null', () {
      expect(CalculatorState.parseDecimal(''), isNull);
      expect(CalculatorState.parseDecimal('   '), isNull);
    });

    test('no parseable retorna null', () {
      expect(CalculatorState.parseDecimal('abc'), isNull);
      expect(CalculatorState.parseDecimal('12.34.56'), isNull);
    });
  });

  group('CalculatorState.isValid', () {
    test('true con todos los inputs validos > 0', () {
      final s = CalculatorState.initial().copyWith(
        weight: '50',
        printHours: '5',
        filamentPrice: '120',
        filamentGrams: '1000',
      );
      expect(s.isValid, isTrue);
    });

    test('false si falta weight', () {
      final s = CalculatorState.initial().copyWith(
        printHours: '5',
        filamentPrice: '120',
        filamentGrams: '1000',
      );
      expect(s.isValid, isFalse);
    });

    test('modo advanced: true con 1 material valido', () {
      final s = CalculatorState.initial().copyWith(
        mode: CalculatorMode.advanced,
        printHours: '5',
        materials: const [MaterialRow(weight: '100', pricePerBobbin: '120', gramsPerBobbin: '1000')],
      );
      expect(s.isValid, isTrue);
    });

    test('modo advanced: false sin materiales', () {
      final s = CalculatorState.initial().copyWith(
        mode: CalculatorMode.advanced,
        printHours: '5',
      );
      expect(s.isValid, isFalse);
    });
  });

  group('CalculatorNotifier', () {
    late ProviderContainer container;
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('estado inicial == CalculatorState.initial()', () {
      expect(container.read(calculatorNotifierProvider), CalculatorState.initial());
    });

    test('setWeight actualiza el string en state', () {
      container.read(calculatorNotifierProvider.notifier).setWeight('50');
      expect(container.read(calculatorNotifierProvider).weight, '50');
    });

    test('setWeight con valor no numerico mantiene el state consistente', () {
      container.read(calculatorNotifierProvider.notifier).setWeight('abc');
      expect(container.read(calculatorNotifierProvider).weight, 'abc');
      expect(container.read(calculatorNotifierProvider).output, isNull);
    });

    test('output null si falta algun campo requerido', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('50');
      notifier.setPrintHours('5');
      // Falta precio/gramos del filamento
      expect(container.read(calculatorNotifierProvider).output, isNull);
    });

    test('output computado cuando todos los campos validos', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setPrintHours('5');
      notifier.setFilamentPrice('120');
      notifier.setFilamentGrams('1000');

      final output = container.read(calculatorNotifierProvider).output;
      expect(output, isNotNull);
      // 100g * (120/1000) = 12 BOB material
      expect(output!.materialCost, Decimal.parse('12'));
      // discount = 0 (sin descuento)
      expect(output.discountAmount, Decimal.zero);
      // totalPrice = totalFinal (material 12 + profit 200% = 36)
      expect(output.totalPrice, Decimal.parse('36'));
    });

    test('setWeight=0 invalida el form (output null)', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setPrintHours('5');
      notifier.setFilamentPrice('120');
      notifier.setFilamentGrams('1000');
      expect(container.read(calculatorNotifierProvider).output, isNotNull);

      notifier.setWeight('0');
      expect(container.read(calculatorNotifierProvider).output, isNull);
      expect(container.read(calculatorNotifierProvider).weight, '0');
    });

    test('reset vuelve a defaults y limpia output', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setPrintHours('5');
      notifier.setFilamentPrice('120');
      notifier.setFilamentGrams('1000');
      expect(container.read(calculatorNotifierProvider).output, isNotNull);

      notifier.reset();
      final s = container.read(calculatorNotifierProvider);
      expect(s, CalculatorState.initial());
      expect(s.output, isNull);
    });

    test('loadFilamentDefaults actualiza precio y gramos', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.loadFilamentDefaults(
        pricePerBobbin: '150',
        gramsPerBobbin: '1000',
      );
      final s = container.read(calculatorNotifierProvider);
      expect(s.filamentPrice, '150');
      expect(s.filamentGrams, '1000');
    });

    test('descuento directo reduce totalPrice', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setFilamentPrice('100');
      notifier.setFilamentGrams('1000');
      notifier.setPrintHours('1');
      notifier.setDiscountPct('20');

      final output = container.read(calculatorNotifierProvider).output;
      expect(output, isNotNull);
      // materialCost = 100 * 100/1000 = 10
      expect(output!.materialCost, Decimal.fromInt(10));
      // totalFinal = 10 + profit 200% = 30
      // discountPct 20 → discountOnTotalFinal = 30 * 20% = 6
      expect(output.discountAmount, Decimal.fromInt(6));
      // totalPrice = 30 - 6 = 24
      expect(output.totalPrice, Decimal.fromInt(24));
    });
  });

  group('CalculatorState equality', () {
    test('dos states con mismos campos son iguales', () {
      final a = CalculationOutput.simple(
        materialCost: Decimal.fromInt(10),
        discountAmount: Decimal.fromInt(1),
        totalPrice: Decimal.fromInt(9),
      );
      final b = CalculationOutput.simple(
        materialCost: Decimal.fromInt(10),
        discountAmount: Decimal.fromInt(1),
        totalPrice: Decimal.fromInt(9),
      );
      expect(a, b);
    });
  });

  group('CalculatorNotifier.save', () {
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

    test('form invalido: save() retorna null y no inserta nada', () async {
      final id = await container
          .read(calculatorNotifierProvider.notifier)
          .save();
      expect(id, isNull);
      final all = await db.select(db.calculations).get();
      expect(all, isEmpty);
    });

    test('form valido: save() inserta y retorna id > 0', () async {
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('5');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');

      final id = await n.save(pieceName: 'Pieza Test', clientName: 'Juan');
      expect(id, isPositive);

      final all = await db.select(db.calculations).get();
      expect(all, hasLength(1));
      final c = all.first;
      expect(c.pieceName, 'Pieza Test');
      expect(c.clientName, 'Juan');
      expect(c.printerId, isNull);
      expect(c.totalHours, 5.0);
      // 100g * 120/1000 = 12 material + profit 200% = 36 (sin descuento)
      expect(c.totalPriceSnapshot, 36.0);
    });

    test('pieceName vacio se persiste como null', () async {
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('5');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');

      await n.save(pieceName: '   ', clientName: '');
      final c = (await db.select(db.calculations).get()).first;
      expect(c.pieceName, isNull);
      expect(c.clientName, isNull);
    });

    test('save invalida calculationsNotifierProvider para refrescar historial',
        () async {
      // Inicializa el calculations notifier (estado vacio).
      final initial = await container
          .read(calculationsNotifierProvider.future);
      expect(initial, isEmpty);

      // Llena el form y guarda via calculator notifier.
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('5');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');
      await n.save(pieceName: 'Test');

      // Al releer el notifier (despues del invalidate), ve la nueva cotizacion.
      final after = await container
          .read(calculationsNotifierProvider.future);
      expect(after, hasLength(1));
      expect(after.first.pieceName, 'Test');
    });
  });
}
