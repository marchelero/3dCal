// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_notifier.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';

void main() {
  group('isValidProvider', () {
    test('devuelve false con state invalido (initial)', () {
      final container = ProviderContainer(
        overrides: [
          calculatorNotifierProvider.overrideWith(_StubNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final isValid = container.read(isValidProvider);
      expect(isValid, isFalse);
    });

    test('devuelve true con state valido (output != null)', () {
      final container = ProviderContainer(
        overrides: [
          calculatorNotifierProvider.overrideWith(_ValidNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final isValid = container.read(isValidProvider);
      expect(isValid, isTrue);
    });
  });

  group('stateToPartialDto', () {
    test('mapea campos correctos + isPartial = true', () {
      final state = CalculatorState(
        mode: CalculatorMode.express,
        printHours: '2',
        printMinutes: '30',
        discountPct: '10',
        weight: '100',
        filamentPrice: '120',
        filamentGrams: '1000',
        label: 'Vaso',
        materials: const [],
        output: null,
        quantity: 3,
      );

      final dto = CalculatorNotifier.stateToPartialDto(state);

      expect(dto.isPartial.value, isTrue);
      expect(dto.isSold.value, isFalse);
      expect(dto.isTemplate.value, isFalse);
      expect(dto.quantity.value, 3);
      // Contrato post-f40dda3: el label mapea a pieceName (no '' fijo);
      // clientName va absent — CalculatorState no tiene fuente de cliente y
      // el autosave nunca debe pisar el cliente ya guardado en la fila.
      expect(dto.pieceName.value, 'Vaso');
      expect(dto.clientName.present, isFalse);
      expect(dto.discountPercentage.value, closeTo(10, 0.01));
      expect(dto.totalHours.value, closeTo(2.5, 0.01));
      expect(dto.printMinutes.value, 30);
    });

    test('mapea output cuando existe', () {
      final state = CalculatorState(
        mode: CalculatorMode.express,
        printHours: '1',
        printMinutes: '',
        discountPct: '0',
        weight: '50',
        filamentPrice: '100',
        filamentGrams: '1000',
        label: '',
        materials: const [],
        output: _fakeOutput(),
        quantity: 1,
      );

      final dto = CalculatorNotifier.stateToPartialDto(state);

      expect(dto.isPartial.value, isTrue);
      expect(dto.pieceName.present, isFalse); // label vacío -> absent
      expect(dto.totalPriceSnapshot.value, isNotNull);
      expect(dto.materialCostSnapshot.value, isNotNull);
    });
  });
}

class _StubNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState.initial();
}

class _ValidNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState(
    mode: CalculatorMode.express,
    printHours: '2',
    printMinutes: '',
    discountPct: '0',
    weight: '100',
    filamentPrice: '120',
    filamentGrams: '1000',
    label: '',
    materials: const [],
    output: _fakeOutput(),
    quantity: 1,
  );
}

CalculationOutput _fakeOutput() => CalculationOutput(
  materialCost: Decimal.fromInt(12),
  electricCost: Decimal.zero,
  amortizationCost: Decimal.zero,
  laborCost: Decimal.zero,
  postProcessCost: Decimal.zero,
  baseCost: Decimal.fromInt(12),
  costWithFailure: Decimal.fromInt(12),
  failureCost: Decimal.zero,
  markupCost: Decimal.zero,
  totalBeforeProfit: Decimal.fromInt(12),
  profitAmount: Decimal.zero,
  totalFinal: Decimal.fromInt(12),
  totalPrice: Decimal.fromInt(12),
  discountAmount: Decimal.zero,
);
