import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/settings/domain/discount_tier.dart';
import 'package:tresdcal/features/settings/presentation/widgets/discount_tiers_section.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget buildTest({List<DiscountTier>? tiers}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 800, child: const DiscountTiersSection()),
          ),
        ),
      ),
    );
  }

  group('DiscountTiersSection', () {
    testWidgets('muestra empty state cuando no hay escalones', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTest());
      await tester.pumpAndSettle();

      expect(find.textContaining('descuentos por cantidad'), findsOneWidget);
    });

    testWidgets('muestra escalones después de insertar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = container.read(discountTiersRepositoryProvider);
      await repo.upsert(
        DiscountTier.create(minQty: 10, percent: Decimal.parse('10')),
      );

      await tester.pumpWidget(buildTest());
      await tester.pumpAndSettle();

      expect(find.text('10'), findsWidgets);
    });

    testWidgets('validación: min_qty 1 rechazada', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTest());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Agregar'));
      await tester.pumpAndSettle();

      final minQtyField = find.widgetWithText(TextFormField, 'Cantidad mínima');
      await tester.enterText(minQtyField, '1');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('al menos 2'), findsOneWidget);
    });

    testWidgets('validación: % 0 rechazada', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTest());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Agregar'));
      await tester.pumpAndSettle();

      final percentField = find.widgetWithText(TextFormField, 'Descuento (%)');
      await tester.enterText(percentField, '0');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('entre 1 y 100'), findsOneWidget);
    });

    testWidgets('validación: % 101 rechazada', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTest());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Agregar'));
      await tester.pumpAndSettle();

      final percentField = find.widgetWithText(TextFormField, 'Descuento (%)');
      await tester.enterText(percentField, '101');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('entre 1 y 100'), findsOneWidget);
    });

    testWidgets('MED-1: coma decimal se normaliza y guarda 12,5 → 12.5', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTest());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Agregar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cantidad mínima'),
        '5',
      );
      // Locale es_BO: el usuario escribe la coma decimal. Sin la
      // normalización, Decimal.tryParse('12,5') fallaba y el save lanzaba.
      final percentField = find.widgetWithText(TextFormField, 'Descuento (%)');
      await tester.enterText(percentField, '12,5');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget, reason: 'fila del escalón');
      final tiers = await container
          .read(discountTiersRepositoryProvider)
          .listAll();
      expect(tiers, hasLength(1));
      expect(tiers.single.minQty, 5);
      expect(
        tiers.single.percent,
        Decimal.parse('12.5'),
        reason: 'la coma decimal debe persistir como 12.5',
      );
    });
  });
}
