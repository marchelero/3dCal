// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/domain/entities/calculation_output.dart';
import 'package:tresdcal/features/calculation/domain/entities/material_input.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculation_detail_page.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Regresion: el detalle de un borrador (partial) renderiza sin excepciones.
///
/// El boton "Editar" del banner usaba un [FilledButton] dentro de un [Row].
/// El theme define `minimumSize = Size(double.infinity, 52)` (full-width), y en
/// un Row (ancho libre) eso resolvia `w=Infinity` y rompia el layout. Este test
/// cubre ese caso (solo se veia en runtime, no en `dart analyze`).
void main() {
  testWidgets('detail de borrador renderiza y muestra Editar', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(calculationRepositoryProvider);
    final id = await repo.create(
      CalculationDraft(
        materials: [
          MaterialInput(
            label: 'PLA Test',
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

    // Convertir en borrador: sin nombre/cliente, isPartial = true.
    final row = await repo.getById(id);
    await db
        .update(db.calculations)
        .replace(
          row!.copyWith(
            isPartial: true,
            pieceName: const Value(''),
            clientName: const Value(''),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CalculationDetailPage(calcId: id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(EsBO.calcEditAction), findsOneWidget);
  });
}
