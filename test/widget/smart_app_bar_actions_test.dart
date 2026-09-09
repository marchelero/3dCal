// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/shared/widgets/smart_app_bar_actions.dart';

/// Helper: monta un [SmartAppBarActions] dentro de un AppBar real con un
/// ancho de pantalla dado (viewport). Retorna el tester listo.
Future<void> _pumpApp(
  WidgetTester tester, {
  required double width,
  required List<Widget> priority,
  required List<SmartAppBarMenuAction> menuActions,
  String overflowTooltip = 'Más acciones',
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cotización'),
          actions: [
            SmartAppBarActions(
              priority: priority,
              menuActions: menuActions,
              overflowTooltip: overflowTooltip,
            ),
          ],
        ),
        body: const SizedBox.expand(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Priority tipico: un chip de total ancho similar al de la calculadora.
Widget _totalChip(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    ),
  );
}

List<SmartAppBarMenuAction> _fiveActions(List<int> log) => [
  (
    icon: const Icon(Icons.help_outline_rounded),
    label: 'Ayuda',
    onTap: () => log.add(0),
  ),
  (
    icon: const Icon(Icons.folder_copy_rounded),
    label: 'Plantillas',
    onTap: () => log.add(1),
  ),
  (
    icon: const Icon(Icons.menu_book_rounded),
    label: 'Guía',
    onTap: () => log.add(2),
  ),
  (
    icon: const Icon(Icons.refresh_rounded),
    label: 'Restablecer',
    onTap: () => log.add(3),
  ),
  (
    icon: const Icon(Icons.settings_outlined),
    label: 'Ajustes',
    onTap: () => log.add(4),
  ),
];

void main() {
  group('SmartAppBarActions', () {
    testWidgets('ancho amplio: iconos directos, sin menu overflow', (
      tester,
    ) async {
      final log = <int>[];
      await _pumpApp(
        tester,
        width: 800,
        priority: [_totalChip('Bs. 1.234,56')],
        menuActions: _fiveActions(log),
      );

      expect(tester.takeException(), isNull);
      // Iconos directos con sus tooltips.
      for (final label in [
        'Ayuda',
        'Plantillas',
        'Guía',
        'Restablecer',
        'Ajustes',
      ]) {
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
      // El chip de total se ve directo.
      expect(find.text('Bs. 1.234,56'), findsOneWidget);
      // Sin boton de overflow.
      expect(find.byType(PopupMenuButton<VoidCallback>), findsNothing);
    });

    testWidgets('ancho amplio: tap en icono directo ejecuta la accion', (
      tester,
    ) async {
      final log = <int>[];
      await _pumpApp(
        tester,
        width: 800,
        priority: [_totalChip('Bs. 1.234,56')],
        menuActions: _fiveActions(log),
      );

      await tester.tap(find.byTooltip('Guía'));
      await tester.pumpAndSettle();
      expect(log, [2]);
    });

    testWidgets('320dp angosto: colapsa a menu y las acciones son accesibles', (
      tester,
    ) async {
      final log = <int>[];
      await _pumpApp(
        tester,
        width: 320,
        priority: [_totalChip('Bs. 1.234,56')],
        menuActions: _fiveActions(log),
      );

      // Sin overflow.
      expect(tester.takeException(), isNull);
      // Chip siempre directo.
      expect(find.text('Bs. 1.234,56'), findsOneWidget);
      // No hay iconos directos de las acciones secundarias.
      expect(find.byTooltip('Guía'), findsNothing);
      // Hay un boton de overflow.
      expect(find.byType(PopupMenuButton<VoidCallback>), findsOneWidget);

      // Abrir el menu y verificar items.
      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();
      for (final label in [
        'Ayuda',
        'Plantillas',
        'Guía',
        'Restablecer',
        'Ajustes',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // Tap en "Guía" dispara su callback.
      await tester.tap(find.text('Guía'));
      await tester.pumpAndSettle();
      expect(log, [2]);
    });

    testWidgets('320dp sin total: solo menu, sin overflow', (tester) async {
      final log = <int>[];
      await _pumpApp(
        tester,
        width: 320,
        priority: const [],
        menuActions: _fiveActions(log),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PopupMenuButton<VoidCallback>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();
      expect(find.text('Guía'), findsOneWidget);
      await tester.tap(find.text('Guía'));
      await tester.pumpAndSettle();
      expect(log, [2]);
    });

    testWidgets('320dp con chip muy ancho: no hay RenderFlex overflow', (
      tester,
    ) async {
      final log = <int>[];
      await _pumpApp(
        tester,
        width: 320,
        priority: [_totalChip('Bs. 123.456.789,00')],
        menuActions: _fiveActions(log),
      );

      expect(tester.takeException(), isNull);
      // El menu sigue presente y operable.
      expect(find.byType(PopupMenuButton<VoidCallback>), findsOneWidget);
    });
  });
}
