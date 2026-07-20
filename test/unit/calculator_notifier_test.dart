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

  group('CalculatorState.totalHoursDecimal', () {
    // Bug reportado: si solo se ingresan minutos (horas vacias), el calculo
    // devolvia 0 horas. El getter ahora trata horas vacias como 0.

    test('solo horas: retorna el valor tal cual', () {
      final s = CalculatorState.initial().copyWith(printHours: '5');
      expect(s.totalHoursDecimal, Decimal.fromInt(5));
    });

    test('solo minutos: convierte a fraccion de hora (33 min = 0.55h)', () {
      final s = CalculatorState.initial().copyWith(printMinutes: '33');
      // 33/60 = 0.55
      expect(s.totalHoursDecimal, Decimal.parse('0.55'));
    });

    test('horas + minutos: suma ambas (1h 33min = 1.55h)', () {
      final s = CalculatorState.initial().copyWith(
        printHours: '1',
        printMinutes: '33',
      );
      expect(s.totalHoursDecimal, Decimal.parse('1.55'));
    });

    test('ambos vacios: retorna null', () {
      final s = CalculatorState.initial();
      expect(s.totalHoursDecimal, isNull);
    });

    test('ambos en 0: retorna null (no hay tiempo real)', () {
      final s = CalculatorState.initial().copyWith(
        printHours: '0',
        printMinutes: '0',
      );
      expect(s.totalHoursDecimal, isNull);
    });

    test('horas 0 + minutos 45: retorna 0.75h', () {
      final s = CalculatorState.initial().copyWith(
        printHours: '0',
        printMinutes: '45',
      );
      expect(s.totalHoursDecimal, Decimal.parse('0.75'));
    });

    test('minutos 0 + horas 2: retorna 2h (ignora minutos 0)', () {
      final s = CalculatorState.initial().copyWith(
        printHours: '2',
        printMinutes: '0',
      );
      expect(s.totalHoursDecimal, Decimal.fromInt(2));
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

    test('regression: solo minutos (horas vacias) calcula correctamente',
        () {
      // Bug original: con printHours='' y printMinutes='33', el calculo
      // usaba 0 horas en vez de 0.55. Ahora debe usar 0.55.
      // Para hacer el test observable, agregamos labor rate (que depende
      // de totalHours): labor = totalHours * rate. Con rate=10 y horas=0.55,
      // labor = 5.5. Si horas fuera 0, labor seria 0.
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setFilamentPrice('100');
      notifier.setFilamentGrams('1000');
      notifier.setPrintHours('');
      notifier.setPrintMinutes('33');
      notifier.setExtraLaborRate('10');

      final output = container.read(calculatorNotifierProvider).output;
      expect(output, isNotNull);
      // materialCost = 100 * 100/1000 = 10
      expect(output!.materialCost, Decimal.fromInt(10));
      // labor = 0.55h * 10 = 5.5 (prueba que totalHours=0.55, no 0)
      expect(output.laborCost, Decimal.parse('5.5'));
      // baseCost = 10 + 5.5 = 15.5
      // profit 200% → totalFinal = 15.5 * 3 = 46.5
      // discount 0 → totalPrice = 46.5
      expect(output.totalPrice, Decimal.parse('46.5'));
    });

    test('horas + minutos se suman en el output final', () {
      // 1h 33min = 1.55h. Sin electric (no printer) ni extras,
      // totalPrice = materialCost * 3 (profit 200%) = 10 * 3 = 30.
      final notifier = container.read(calculatorNotifierProvider.notifier);
      notifier.setWeight('100');
      notifier.setFilamentPrice('100');
      notifier.setFilamentGrams('1000');
      notifier.setPrintHours('1');
      notifier.setPrintMinutes('33');

      final output = container.read(calculatorNotifierProvider).output;
      expect(output, isNotNull);
      expect(output!.materialCost, Decimal.fromInt(10));
      expect(output.totalPrice, Decimal.fromInt(30));
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

    test('save persiste printMinutes (schema v4)', () async {
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('1');
      n.setPrintMinutes('33');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');

      await n.save(pieceName: 'Test');
      final c = (await db.select(db.calculations).get()).first;
      expect(c.printMinutes, 33);
      expect(c.totalHours, closeTo(1.55, 0.001));
    });

    test('save con printMinutes=0 lo persiste como 0', () async {
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('5');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');

      await n.save(pieceName: 'Test');
      final c = (await db.select(db.calculations).get()).first;
      expect(c.printMinutes, 0);
    });

    test(
        'loadFromCalculation preserva el split h+m (regression v4)',
        () async {
      // Setup: guardar cotizacion con 1h 33min
      final n = container.read(calculatorNotifierProvider.notifier);
      n.setWeight('100');
      n.setPrintHours('1');
      n.setPrintMinutes('33');
      n.setFilamentPrice('120');
      n.setFilamentGrams('1000');
      await n.save(pieceName: 'Reusar Test');

      // Reset del form (simula que el user sale y vuelve).
      n.reset();

      // Carga la cotizacion guardada ("Reusar" en historial).
      final calculations = await container
          .read(calculationsNotifierProvider.future);
      final calc = calculations.first;
      await container
          .read(calculatorNotifierProvider.notifier)
          .loadFromCalculation(calc);

      // Verifica que el split se preserva.
      final state = container.read(calculatorNotifierProvider);
      expect(state.printHours, '1');
      expect(state.printMinutes, '33');
    });

    test('loadFromCalculation backfill: row v3 sin printMinutes (0) deriva split del decimal',
        () async {
      // Simula una row v3 (legacy) construida directamente con printMinutes=0.
      // loadFromCalculation recibe la entidad, no necesita estar en DB para
      // el split.
      final legacyCalc = Calculation(
        id: 1,
        createdAt: DateTime.now(),
        pieceName: 'Legacy v3',
        printerWattsSnapshot: 0,
        totalHours: 1.55,
        printMinutes: 0, // v3: siempre 0
        discountPercentage: 0,
        kwhRateSnapshot: 0.6,
        profitBaseSnapshot: 200,
        isSold: false,
        materialCostSnapshot: 12,
        electricCostSnapshot: 0,
        laborCostSnapshot: 0,
        postProcessCostSnapshot: 0,
        baseCostSnapshot: 0,
        failureCostSnapshot: 0,
        markupCostSnapshot: 0,
        profitAmountSnapshot: 24,
        minimumChargeAppliedSnapshot: 0,
        effectiveTotalSnapshot: 36,
        totalPriceSnapshot: 36,
        laborRateSnapshot: 50,
        postProcessRateSnapshot: 0,
        failureRateSnapshot: 0,
        minimumChargeSnapshot: 0,
        markupOnMaterialsSnapshot: 0,
      );

      await container
          .read(calculatorNotifierProvider.notifier)
          .loadFromCalculation(legacyCalc);

      // Backfill: 1.55h = 93min = 1h 33min.
      final state = container.read(calculatorNotifierProvider);
      expect(state.printHours, '1');
      expect(state.printMinutes, '33');
    });
  });
}
