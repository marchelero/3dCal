// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/presentation/pages/calculator_page.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/result_sheet.dart';

/// Tests del cotizador-wizard (scroll continuo 2026-09, 3 secciones).
///
/// Secciones: Pieza (1) | Impresion (2) | Otros (3). El resultado NO es una
/// seccion: la [ResultBottomBar] vive fija abajo y muestra el total
/// live (o el hint de validacion). La navegacion es por scroll continuo
/// con auto-step en el step bar.
Future<void> _pumpPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: CalculatorPage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desmonta la pagina DENTRO del test y deja que fakeAsync absorba el
/// `Timer(0)` de `drift` que el unmount programa (flaky pre-existente).
Future<void> _bye(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

/// Salta a una seccion del wizard tocando su chip en el step bar.
/// Usa find.textContaining para manejar el caso donde el label aparece
/// tanto en el step bar como en el header de la seccion.
Future<void> _goToStep(WidgetTester tester, String label) async {
  // Tocar el primer matching text (que es el del step bar, arriba).
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

/// Llena peso + precio (seccion 1) y horas (seccion 2) hasta un caso valido.
Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Peso'), '100');
  await tester.enterText(
    find.widgetWithText(TextField, 'Precio bobina'),
    '120',
  );
  await tester.pumpAndSettle();
  await _goToStep(tester, 'Impresión');
  await tester.enterText(find.widgetWithText(TextField, 'Horas'), '2');
  await tester.pumpAndSettle();
}

void main() {
  group('CalculatorPage wizard (3 pasos)', () {
    testWidgets('paso 1 renderiza chrome + campos hero; sin paso Resultado', (
      tester,
    ) async {
      await _pumpPage(tester);

      expect(find.text('Cotización'), findsOneWidget);
      // Step bar: labels en minusculas (Pieza, Impresión, Otros).
      // Los headers internos usan toUpperCase() por lo que aparecen como
      // "PIEZA", "TIEMPO DE IMPRESIÓN", etc. — no se duplican.
      expect(find.text('Pieza'), findsOneWidget);
      expect(find.text('Impresión'), findsOneWidget);
      expect(find.text('Otros'), findsOneWidget);
      expect(find.text('Resultado'), findsNothing);

      // Campos del paso 1 (regla del 95%: los 3 inputs hero a la vista).
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Precio bobina'), findsOneWidget);
      expect(find.text('Gramos / bobina'), findsOneWidget);

      // En scroll continuo, todos los pasos estan montados (no IndexedStack).
      // Impresion y otros son visibles al hacer scroll.
      expect(find.text('Horas'), findsOneWidget);
      expect(find.text('IMPRESORA'), findsOneWidget);

      // La barra de total vive fija abajo, con hint (form incompleto).
      expect(find.byType(ResultBottomBar), findsOneWidget);
      expect(find.textContaining('Completa peso'), findsOneWidget);

      await _bye(tester);
    });

    testWidgets('navegar con chips: impresion muestra tiempo + impresora', (
      tester,
    ) async {
      await _pumpPage(tester);
      await _goToStep(tester, 'Impresión');

      expect(find.text('Horas'), findsOneWidget);
      expect(find.text('Minutos'), findsOneWidget);
      expect(find.text('IMPRESORA'), findsOneWidget);

      await _goToStep(tester, 'Otros');
      expect(find.text('CANTIDAD'), findsOneWidget);
      expect(find.text('Descuento'), findsOneWidget);

      await _bye(tester);
    });

    testWidgets('total live aparece en la barra de abajo al completar', (
      tester,
    ) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      // El total sube al paso visible y sigue en la barra fija de abajo.
      expect(find.text(r'$ 12,00'), findsWidgets);
      expect(find.byType(ResultBottomBar), findsOneWidget);
      // El desglose detallado no se pinta hasta abrir el sheet.
      expect(find.text('Costo material'), findsNothing);

      await _bye(tester);
    });

    testWidgets('tap en la barra de total abre el desglose (sheet)', (
      tester,
    ) async {
      await _pumpPage(tester);
      await _fillValid(tester);

      await tester.tap(find.byType(ResultBottomBar));
      await tester.pumpAndSettle();
      // El sheet de resultado tiene el boton de guardar (tooltip).
      expect(find.byTooltip('Guardar cotización'), findsOneWidget);

      await _bye(tester);
    });

    testWidgets('output desaparece al borrar weight', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.textContaining(r'$ '), findsWidgets);

      await _goToStep(tester, 'Pieza');
      await tester.enterText(find.widgetWithText(TextField, 'Peso'), '');
      await tester.pumpAndSettle();

      expect(find.textContaining(r'$ 12,00'), findsNothing);
      expect(find.textContaining('Completa peso'), findsOneWidget);

      await _bye(tester);
    });

    testWidgets('descuento desde el paso Otros reduce el total', (
      tester,
    ) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.text(r'$ 12,00'), findsWidgets);

      await _goToStep(tester, 'Otros');
      await tester.enterText(find.widgetWithText(TextField, 'Descuento'), '25');
      await tester.pumpAndSettle();

      // 12 - 25% = 9. La barra de total lo refleja.
      expect(find.text(r'$ 9,00'), findsWidgets);

      await _bye(tester);
    });

    testWidgets('boton reset restaura defaults', (tester) async {
      await _pumpPage(tester);
      await _fillValid(tester);
      expect(find.textContaining(r'$ '), findsWidgets);

      await tester.tap(find.byTooltip('Restablecer'));
      await tester.pumpAndSettle();

      // Tras el reset el wizard vuelve al inicio con el hint activo.
      expect(find.textContaining('Completa peso'), findsOneWidget);
      expect(find.textContaining(r'$ 12,00'), findsNothing);

      await _bye(tester);
    });
  });
}
