// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/export/quote_report_variant.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/state/detail_view_provider.dart';

/// T1-2: estado de vista del detalle (variante + cantidad) en Riverpod.
///
/// El provider arranca en `null` (sin editar) y la pantalla resuelve los
/// valores guardados con [initialDetailViewState]. Cubrimos:
/// - clamp de cantidad y derivacion de variante,
/// - materializacion perezosa en la primera edicion,
/// - limites de decrement/increment.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CalculationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    repo = container.read(calculationRepositoryProvider);
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  Future<Calculation> seed({int quantity = 1, bool advanced = false}) async {
    final id = await repo.create(
      CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA',
            weightGrams: Decimal.parse('100'),
            pricePerBobbin: Decimal.parse('120'),
            gramsPerBobbin: Decimal.parse('1000'),
          ),
        ],
        totalHours: Decimal.parse('5'),
        discountPercentage: Decimal.zero,
        output: CalculationOutput.simple(
          materialCost: Decimal.parse('12'),
          discountAmount: Decimal.zero,
          totalPrice: Decimal.parse('12'),
        ),
      ),
    );
    final row = (await repo.getById(id))!.copyWith(
      quantity: quantity,
      isAdvanced: advanced,
    );
    await db.update(db.calculations).replace(row);
    return (await repo.getById(id))!;
  }

  test('clampDetailQuantity respeta [1, kMaxQuantity]', () {
    expect(clampDetailQuantity(0), 1);
    expect(clampDetailQuantity(-10), 1);
    expect(clampDetailQuantity(1), 1);
    expect(clampDetailQuantity(7), 7);
    expect(clampDetailQuantity(kMaxQuantity), kMaxQuantity);
    expect(clampDetailQuantity(kMaxQuantity + 99), kMaxQuantity);
  });

  test('initialDetailViewState deriva variante y clampea cantidad', () async {
    final simple = await seed(quantity: 3);
    expect(initialDetailViewState(simple).variant, QuoteReportVariant.clientSimple);
    expect(initialDetailViewState(simple).quantity, 3);

    final advanced = await seed(quantity: 0, advanced: true);
    expect(
      initialDetailViewState(advanced).variant,
      QuoteReportVariant.clientAdvanced,
    );
    expect(initialDetailViewState(advanced).quantity, 1);
  });

  test('arranca en null y materializa el valor guardado en la primera edicion',
      () async {
    final calc = await seed(quantity: 5, advanced: true);
    final sub = container.listen(detailViewProvider, (_, _) {});
    addTearDown(sub.close);

    expect(container.read(detailViewProvider), isNull);

    container.read(detailViewProvider.notifier).increment(calc);
    expect(container.read(detailViewProvider)!.quantity, 6);
    expect(
      container.read(detailViewProvider)!.variant,
      QuoteReportVariant.clientAdvanced,
    );
  });

  test('setQuantity clampea y evita estados redundantes', () async {
    final calc = await seed(quantity: 3);
    final sub = container.listen(detailViewProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(detailViewProvider.notifier);

    notifier.setQuantity(calc, 0);
    expect(container.read(detailViewProvider)!.quantity, 1);

    notifier.setQuantity(calc, kMaxQuantity + 10);
    expect(container.read(detailViewProvider)!.quantity, kMaxQuantity);

    notifier.decrement(calc);
    expect(container.read(detailViewProvider)!.quantity, kMaxQuantity - 1);
  });

  test('setVariant cambia la variante del reporte', () async {
    final calc = await seed(advanced: true);
    final sub = container.listen(detailViewProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(detailViewProvider.notifier);

    notifier.setVariant(calc, QuoteReportVariant.clientSimple);
    expect(
      container.read(detailViewProvider)!.variant,
      QuoteReportVariant.clientSimple,
    );
  });
}
