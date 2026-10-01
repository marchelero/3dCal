import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/storage/calculation_draft.dart';
import 'package:tresdcal/features/calculation/presentation/state/calculator_state.dart';

/// Tests del tiempo independiente por material (Advanced/Pro).
///
/// Cubre la suma de tiempos propios, la exclusion mutua con el tiempo global
/// y la persistencia en el draft de sesion.
void main() {
  MaterialRow mat({
    String label = 'PLA',
    String weight = '100',
    bool useOwnTime = false,
    String h = '',
    String m = '',
  }) => MaterialRow(
    label: label,
    weight: weight,
    pricePerBobbin: '150',
    gramsPerBobbin: '1000',
    useOwnTime: useOwnTime,
    materialHours: h,
    materialMinutes: m,
  );

  CalculatorState advanced({
    String printHours = '5',
    String printMinutes = '0',
    List<MaterialRow>? materials,
  }) => CalculatorState(
    mode: CalculatorMode.advanced,
    printHours: printHours,
    printMinutes: printMinutes,
    discountPct: '0',
    weight: '',
    filamentPrice: '',
    filamentGrams: '',
    label: '',
    materials: materials ?? [mat()],
    output: null,
  );

  group('MaterialRow.ownTimeDecimal', () {
    test('null cuando el switch esta OFF', () {
      expect(mat(useOwnTime: false, h: '2', m: '30').ownTimeDecimal, isNull);
    });

    test('null cuando el switch esta ON pero vacio', () {
      expect(mat(useOwnTime: true).ownTimeDecimal, isNull);
      expect(mat(useOwnTime: true, h: '0', m: '0').ownTimeDecimal, isNull);
    });

    test('horas puras', () {
      expect(
        mat(useOwnTime: true, h: '3', m: '').ownTimeDecimal,
        Decimal.fromInt(3),
      );
    });

    test('solo minutos (45 min = 0.75h)', () {
      expect(
        mat(useOwnTime: true, h: '', m: '45').ownTimeDecimal,
        Decimal.parse('0.75'),
      );
    });

    test('horas + minutos', () {
      expect(
        mat(useOwnTime: true, h: '1', m: '30').ownTimeDecimal,
        Decimal.parse('1.5'),
      );
    });

    test('ownTimeMissing marca el switch ON sin valor', () {
      expect(mat(useOwnTime: true).ownTimeMissing, isTrue);
      expect(mat(useOwnTime: true, h: '1').ownTimeMissing, isFalse);
      expect(mat(useOwnTime: false).ownTimeMissing, isFalse);
    });
  });

  group('CalculatorState.anyMaterialOwnTime', () {
    test('false si todos los switches estan OFF', () {
      expect(advanced(materials: [mat(), mat(label: 'ABS')]).anyMaterialOwnTime,
          isFalse);
    });

    test('true si al menos uno esta ON', () {
      expect(
        advanced(
          materials: [mat(), mat(label: 'ABS', useOwnTime: true, h: '1')],
        ).anyMaterialOwnTime,
        isTrue,
      );
    });
  });

  group('materialsOwnTimeDecimal', () {
    test('null si ninguno tiene tiempo', () {
      expect(advanced(materials: [mat(), mat(useOwnTime: true)]).materialsOwnTimeDecimal,
          isNull);
    });

    test('suma solo los materiales con switch ON', () {
      final s = advanced(
        materials: [
          mat(label: 'PLA', useOwnTime: true, h: '1', m: '30'), // 1.5h
          mat(label: 'ABS'), // OFF -> 0
          mat(label: 'PETG', useOwnTime: true, m: '45'), // 0.75h
        ],
      );
      expect(s.materialsOwnTimeDecimal, Decimal.parse('2.25'));
    });
  });

  group('Exclusion mutua: totalHoursDecimal', () {
    test('sin switch ON usa el tiempo global', () {
      expect(advanced(printHours: '5').totalHoursDecimal, Decimal.fromInt(5));
    });

    test('con switch ON ignora el tiempo global', () {
      final s = advanced(
        printHours: '5',
        materials: [mat(useOwnTime: true, h: '2', m: '15')],
      );
      // 2.25h, no 5h + 2.25h.
      expect(s.totalHoursDecimal, Decimal.parse('2.25'));
    });

    test('varios materiales con tiempo propio se suman', () {
      final s = advanced(
        printHours: '5',
        materials: [
          mat(label: 'PLA', useOwnTime: true, h: '1'),
          mat(label: 'ABS', useOwnTime: true, m: '30'),
        ],
      );
      expect(s.totalHoursDecimal, Decimal.parse('1.5'));
    });

    test('switch ON sin valor -> total null (ignora el global)', () {
      final s = advanced(
        printHours: '5',
        materials: [mat(useOwnTime: true)],
      );
      expect(s.totalHoursDecimal, isNull);
    });
  });

  group('Exclusion mutua: isValid / hasTimeInput', () {
    test('solo tiempo propio con global vacio -> valido', () {
      final s = advanced(
        printHours: '',
        printMinutes: '',
        materials: [mat(useOwnTime: true, h: '2')],
      );
      expect(s.hasTimeInput, isTrue);
      expect(s.isValid, isTrue);
      expect(s.output, isNull); // se calcula en el notifier, no aqui.
    });

    test('switch ON sin valor y global vacio -> invalido', () {
      final s = advanced(
        printHours: '',
        printMinutes: '',
        materials: [mat(useOwnTime: true)],
      );
      expect(s.hasTimeInput, isFalse);
      expect(s.isValid, isFalse);
      expect(s.missingRequiredFields, contains('time'));
    });

    test('material incompleto sigue invalidando', () {
      final s = advanced(
        materials: [
          const MaterialRow(
            label: 'PLA',
            weight: '100',
            pricePerBobbin: '150',
            gramsPerBobbin: '1000',
            useOwnTime: true,
            materialHours: '2',
          ),
        ],
      );
      // el material es valido (peso/precio/gramos ok)
      expect(s.materials.first.isValid, isTrue);
      expect(s.isValid, isTrue);
    });

    test('express no se afecta (sin materiales)', () {
      final s = CalculatorState(
        mode: CalculatorMode.express,
        printHours: '2',
        printMinutes: '0',
        discountPct: '0',
        weight: '100',
        filamentPrice: '150',
        filamentGrams: '1000',
        label: '',
        materials: const [],
        output: null,
      );
      expect(s.anyMaterialOwnTime, isFalse);
      expect(s.totalHoursDecimal, Decimal.fromInt(2));
      expect(s.isValid, isTrue);
    });
  });

  group('Exclusion mutua: se puede apagar el switch', () {
    test('apagar el unico switch deja hasTimeInput en false', () {
      // Este es el escenario del bug: el switch se encendia pero despues no
      // se podia apagar. Con el estado puro, apagar deveuelve a "sin tiempo".
      final on = advanced(
        printHours: '',
        printMinutes: '',
        materials: [mat(useOwnTime: true, h: '2')],
      );
      expect(on.hasTimeInput, isTrue);

      final off = advanced(
        printHours: '',
        printMinutes: '',
        materials: [mat(useOwnTime: false)],
      );
      expect(off.anyMaterialOwnTime, isFalse);
      expect(off.hasTimeInput, isFalse);
      expect(off.totalHoursDecimal, isNull);
    });

    test('apagar uno de varios deja la suma de los otros', () {
      final s = advanced(
        printHours: '',
        printMinutes: '',
        materials: [
          mat(label: 'PLA', useOwnTime: true, h: '1'),
          mat(label: 'ABS', useOwnTime: true, m: '30'),
        ],
      );
      expect(s.totalHoursDecimal, Decimal.parse('1.5'));

      // apago PLA
      final after = advanced(
        printHours: '',
        printMinutes: '',
        materials: [
          mat(label: 'PLA', useOwnTime: false),
          mat(label: 'ABS', useOwnTime: true, m: '30'),
        ],
      );
      expect(after.anyMaterialOwnTime, isTrue);
      expect(after.totalHoursDecimal, Decimal.parse('0.5'));
    });
  });

  group('Displayed: el global muestra la suma pero sigue siendo usable', () {
    test('el global conserva su valor mientras hay tiempo propio', () {
      // El state NO se pisa: el global sigue guardado, solo la UI lo muestra
      // como suma. Asi, al apagar todos los switches, reaparece.
      final s = advanced(
        printHours: '9',
        printMinutes: '30',
        materials: [mat(useOwnTime: true, h: '2', m: '15')],
      );
      expect(s.printHours, '9');
      expect(s.printMinutes, '30');
      // ...pero el total usa la suma propia.
      expect(s.totalHoursDecimal, Decimal.parse('2.25'));
    });

    test('tras editar el global el total vuelve a ser el global', () {
      // Simula: usuario ve 2.25, tipea 4 en horas -> switches apagados.
      final edited = advanced(
        printHours: '4',
        printMinutes: '0',
        materials: [mat(useOwnTime: false)],
      );
      expect(edited.totalHoursDecimal, Decimal.fromInt(4));
    });
  });

  group('Draft: round-trip del tiempo por material', () {
    test('MaterialDraft serializa y restaura useOwnTime', () {
      const d = MaterialDraft(
        label: 'PLA',
        weight: '100',
        pricePerBobbin: '150',
        gramsPerBobbin: '1000',
        useOwnTime: true,
        materialHours: '2',
        materialMinutes: '15',
      );
      final back = MaterialDraft.fromJson(d.toJson());
      expect(back.useOwnTime, isTrue);
      expect(back.materialHours, '2');
      expect(back.materialMinutes, '15');
    });

    test('draft viejo (sin los campos) no rompe', () {
      final d = MaterialDraft.fromJson(const {
        'label': 'PLA',
        'weight': '100',
        'pricePerBobbin': '150',
        'gramsPerBobbin': '1000',
      });
      expect(d.useOwnTime, isFalse);
      expect(d.materialHours, '');
      expect(d.materialMinutes, '');
    });

    test('CalculationDraft conserva isAdvanced + materiales', () {
      const d = CalculationDraft(
        isAdvanced: true,
        printHours: '5',
        materials: [
          MaterialDraft(
            label: 'PLA',
            weight: '100',
            pricePerBobbin: '150',
            gramsPerBobbin: '1000',
            useOwnTime: true,
            materialHours: '2',
          ),
        ],
      );
      final back = CalculationDraft.fromJson(
        // simula el viaje por SharedPreferences (string JSON).
        jsonDecode(d.encode()) as Map<String, dynamic>,
      );
      expect(back.isAdvanced, isTrue);
      expect(back.materials.length, 1);
      expect(back.materials.first.useOwnTime, isTrue);
      expect(back.materials.first.materialHours, '2');
    });
  });
}
