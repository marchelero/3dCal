// ignore_for_file: public_member_api_docs
//
// El selector de variante del reporte.
//
// Lo que este test protege es una decision de producto, no un detalle de
// estilo: el control ofrece 2 opciones, no 4. Las 4 variantes existen, pero el
// modo de calculo ya decidio una dimension (express vs advanced) y lo unico
// que el usuario elige es A QUIEN se lo manda (Cliente / Detalle).
//
// Mostrar las 4 obligaba al usuario a decidir "cuanta complejidad" sin tener
// el contexto, y dejaba el caso frecuente (una sola persona, una sola
// cotizacion) con 4 botones donde 2 bastan.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/export/quote_report_variant.dart';
import 'package:tresdcal/features/calculation/presentation/widgets/report_variant_selector.dart';
import 'package:tresdcal/l10n/es_bo.dart';

Widget _host({
  required QuoteReportVariant selected,
  required bool isAdvanced,
  void Function(QuoteReportVariant)? onChanged,
}) => MaterialApp(
  home: Scaffold(
    body: ReportVariantSelector(
      selected: selected,
      isAdvanced: isAdvanced,
      onChanged: onChanged ?? (_) {},
    ),
  ),
);

void main() {
  group('ReportVariantSelector — 2 opciones por modo', () {
    testWidgets('express muestra Cliente | Detalle', (tester) async {
      await tester.pumpWidget(
        _host(selected: QuoteReportVariant.clientSimple, isAdvanced: false),
      );

      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Detalle'), findsOneWidget);
    });

    testWidgets('advanced muestra las MISMAS 2 etiquetas', (tester) async {
      await tester.pumpWidget(
        _host(selected: QuoteReportVariant.clientAdvanced, isAdvanced: true),
      );

      // El nombre del reporte no lleva sufijo "Av.": le diria al usuario mas
      // de lo que puede verificar en ese momento. Lo que hay por detras es
      // cosa del contenido, no del nombre.
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Detalle'), findsOneWidget);
      expect(find.textContaining('Av'), findsNothing);
    });

    testWidgets('no aparecen las 2 variantes del otro modo', (tester) async {
      await tester.pumpWidget(
        _host(selected: QuoteReportVariant.clientSimple, isAdvanced: false),
      );

      // 2 chips, no 4. Si esto falla, el selector volvio a ofrecer el eje
      // completo y el usuario tiene que decidir complejidad a ciegas.
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets('tap en Detalle emite internalDetail en express', (
      tester,
    ) async {
      final emitted = <QuoteReportVariant>[];
      await tester.pumpWidget(
        _host(
          selected: QuoteReportVariant.clientSimple,
          isAdvanced: false,
          onChanged: emitted.add,
        ),
      );

      await tester.tap(find.text('Detalle'));
      expect(emitted, [QuoteReportVariant.internalDetail]);
    });

    testWidgets('tap en Detalle emite internalAdvanced en advanced', (
      tester,
    ) async {
      final emitted = <QuoteReportVariant>[];
      await tester.pumpWidget(
        _host(
          selected: QuoteReportVariant.clientAdvanced,
          isAdvanced: true,
          onChanged: emitted.add,
        ),
      );

      await tester.tap(find.text('Detalle'));
      expect(emitted, [QuoteReportVariant.internalAdvanced]);
    });

    testWidgets('el aviso de confidencialidad solo sale en la interna', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(selected: QuoteReportVariant.clientSimple, isAdvanced: false),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      await tester.pumpWidget(
        _host(selected: QuoteReportVariant.internalDetail, isAdvanced: false),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('ReportVariantSelector — resolucion de labels', () {
    test('labelOf colapsa el eje advanced al mismo texto', () {
      expect(
        ReportVariantSelector.labelOf(QuoteReportVariant.clientSimple),
        ReportVariantSelector.labelOf(QuoteReportVariant.clientAdvanced),
      );
      expect(
        ReportVariantSelector.labelOf(QuoteReportVariant.internalDetail),
        ReportVariantSelector.labelOf(QuoteReportVariant.internalAdvanced),
      );
      expect(
        ReportVariantSelector.labelOf(QuoteReportVariant.clientSimple),
        EsBO.reportVariantClient,
      );
      expect(
        ReportVariantSelector.labelOf(QuoteReportVariant.internalAdvanced),
        EsBO.reportVariantInternal,
      );
    });

    test('iconOf: la interna se marca con candado', () {
      expect(
        ReportVariantSelector.iconOf(QuoteReportVariant.clientSimple),
        Icons.public_rounded,
      );
      expect(
        ReportVariantSelector.iconOf(QuoteReportVariant.clientAdvanced),
        Icons.public_rounded,
      );
      expect(
        ReportVariantSelector.iconOf(QuoteReportVariant.internalDetail),
        Icons.lock_rounded,
      );
      expect(
        ReportVariantSelector.iconOf(QuoteReportVariant.internalAdvanced),
        Icons.lock_rounded,
      );
    });
  });
}
