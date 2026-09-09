// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/quote_guide_dialog.dart';
import 'package:tresdcal/l10n/es_bo.dart';

/// Abre el modal de la guia y espera que se renderice.
Future<void> _openGuide(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Opener())));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(_Opener));
  await tester.pumpAndSettle();
}

/// Boton que dispara [showQuoteGuideDialog] para probar el modal completo.
class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () => showQuoteGuideDialog(context),
        child: const Text('abrir'),
      ),
    );
  }
}

void main() {
  group('QuoteGuideDialog', () {
    testWidgets('abre y muestra titulo + paso 1', (tester) async {
      await _openGuide(tester);

      expect(find.text(EsBO.quoteGuideTitle), findsOneWidget);
      expect(find.text(EsBO.quoteGuideStep1Title), findsOneWidget);
      expect(find.text(EsBO.quoteGuideStep1Body), findsOneWidget);
      // Boton Siguiente en el primer paso.
      expect(find.text(EsBO.quoteGuideNext), findsOneWidget);
      // El ultimo paso no se ve aun.
      expect(find.text(EsBO.quoteGuideStep6Title), findsNothing);
    });

    testWidgets('recorre los 6 pasos con el boton Siguiente', (tester) async {
      await _openGuide(tester);

      final steps = [
        EsBO.quoteGuideStep1Title,
        EsBO.quoteGuideStep2Title,
        EsBO.quoteGuideStep3Title,
        EsBO.quoteGuideStep4Title,
        EsBO.quoteGuideStep5Title,
        EsBO.quoteGuideStep6Title,
      ];

      for (final step in steps) {
        expect(find.text(step), findsOneWidget, reason: step);
        if (step != steps.last) {
          await tester.tap(find.text(EsBO.quoteGuideNext));
          await tester.pumpAndSettle();
        }
      }

      // En el ultimo paso: boton "Entendido" en vez de "Siguiente".
      expect(find.text(EsBO.quoteGuideClose), findsOneWidget);
      expect(find.text(EsBO.quoteGuideNext), findsNothing);
    });

    testWidgets('el contador de pagina se actualiza', (tester) async {
      await _openGuide(tester);

      Finder counter(String label) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      );

      // Paso 1 de 6 al inicio.
      expect(
        counter(EsBO.quoteGuidePageCounter(1, 6)),
        findsOneWidget,
      );

      await tester.tap(find.text(EsBO.quoteGuideNext));
      await tester.pumpAndSettle();
      expect(
        counter(EsBO.quoteGuidePageCounter(2, 6)),
        findsOneWidget,
      );
    });

    testWidgets('"Entendido" cierra el modal', (tester) async {
      await _openGuide(tester);

      // Avanzar hasta el ultimo paso.
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text(EsBO.quoteGuideNext));
        await tester.pumpAndSettle();
      }

      expect(find.text(EsBO.quoteGuideClose), findsOneWidget);
      await tester.tap(find.text(EsBO.quoteGuideClose));
      await tester.pumpAndSettle();

      // El modal se cerro.
      expect(find.byType(QuoteGuideDialog), findsNothing);
    });

    testWidgets('soporta swipe en el PageView', (tester) async {
      await _openGuide(tester);

      expect(find.text(EsBO.quoteGuideStep1Title), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(EsBO.quoteGuideStep2Title), findsOneWidget);
    });
  });
}
