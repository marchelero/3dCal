import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';

void main() {
  group('CalculatorState.initial', () {
    test('tiene defaults MVP', () {
      final s = CalculatorState.initial();
      expect(s.weight, '');
      expect(s.printHours, '');
      expect(s.printerWatts, '200');
      expect(s.kwhRate, '0.70');
      expect(s.profitPct, '200');
      expect(s.discountPct, '0');
      expect(s.filamentPrice, '');
      expect(s.filamentGrams, '');
      expect(s.output, isNull);
    });

    test('isValid es false en estado inicial (faltan weight/horas/precio/gramos)', () {
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

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
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
      // 5h * (200/1000) kW * 0.70 BOB/kWh = 0.7 BOB
      expect(output.electricCost, Decimal.parse('0.7'));
      // baseCost = 12 + 0.7 = 12.7
      expect(output.baseCost, Decimal.parse('12.7'));
      // effProfit = 200 - 0*2 = 200
      expect(output.effectiveProfitPercentage, Decimal.fromInt(200));
      // profitAmount = 12.7 * 2 = 25.4
      expect(output.profitAmount, Decimal.parse('25.4'));
      // totalPrice = 12.7 + 25.4 = 38.1
      expect(output.totalPrice, Decimal.parse('38.1'));
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

    test('descuento agresivo (50%) clampea profit a 0', () {
      // profitBase=100, discount=50 => effProfit = 100 - 100 = 0 (borde)
      // profitBase=100, discount=60 => effProfit = 100 - 120 = -20 (negativo)
      // baseCost > 0 => profitAmount = 0 (clamp), effProfit = -20 preservado
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setPrintHours('0'); // anula electricCost
      notifier.setFilamentPrice('100');
      notifier.setFilamentGrams('1000');
      notifier.setProfitPct('100');
      notifier.setDiscountPct('60');

      final output = container.read(calculatorNotifierProvider).output;
      expect(output, isNotNull);
      expect(output!.effectiveProfitPercentage, Decimal.fromInt(-20));
      expect(output.profitAmount, Decimal.zero);
      // totalPrice = baseCost (no profit)
      expect(output.totalPrice, output.baseCost);
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

    test('cambiar kwhRate recomputa output', () {
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setPrintHours('5');
      notifier.setFilamentPrice('120');
      notifier.setFilamentGrams('1000');
      notifier.setKwhRate('0.60');
      final output1 = container.read(calculatorNotifierProvider).output!;
      // 5h * 0.2kW * 0.60 = 0.6
      expect(output1.electricCost, Decimal.parse('0.6'));

      notifier.setKwhRate('0.80');
      final output2 = container.read(calculatorNotifierProvider).output!;
      // 5h * 0.2kW * 0.80 = 0.8
      expect(output2.electricCost, Decimal.parse('0.8'));
    });
  });

  group('CalculatorState equality', () {
    test('dos states con mismos campos son iguales', () {
      final a = CalculationOutput(
        materialCost: Decimal.fromInt(10),
        electricCost: Decimal.fromInt(1),
        baseCost: Decimal.fromInt(11),
        effectiveProfitPercentage: Decimal.fromInt(100),
        profitAmount: Decimal.fromInt(11),
        totalPrice: Decimal.fromInt(22),
      );
      final b = CalculationOutput(
        materialCost: Decimal.fromInt(10),
        electricCost: Decimal.fromInt(1),
        baseCost: Decimal.fromInt(11),
        effectiveProfitPercentage: Decimal.fromInt(100),
        profitAmount: Decimal.fromInt(11),
        totalPrice: Decimal.fromInt(22),
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
          .save(pieceName: 'X');
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
      expect(c.printerId, isNull); // sin impresora activa
      expect(c.totalHours, 5.0);
      expect(c.totalPriceSnapshot, 38.1);
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
  });
}
