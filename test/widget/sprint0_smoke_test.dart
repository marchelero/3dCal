import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/app.dart';

void main() {
  testWidgets('Sprint 0: app arranca y muestra 3dcal en appbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: TresdcalApp()),
    );

    // Pump inicial + settle para que cualquier animacion termine.
    await tester.pumpAndSettle();

    expect(find.text('3dcal'), findsOneWidget);
    expect(find.text('Sprint 0 listo'), findsOneWidget);
  });

  testWidgets('Sprint 0: smoke test formateador BOB en placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: TresdcalApp()),
    );
    await tester.pumpAndSettle();

    // Bs. 1.234,00 — formato es_BO.
    expect(find.textContaining('Bs.'), findsWidgets);
  });
}
