// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/shared/widgets/brand_selector_field.dart';
import 'package:tresdcal/shared/widgets/k3d_brands.dart';

/// Helper: monta un `BrandSelectorField` aislado en un container nuevo
/// con DB en memoria.
Future<({ProviderContainer container, TextEditingController ctrl})> _pump(
  WidgetTester tester, {
  required BrandDomain domain,
  String initial = '',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  final ctrl = TextEditingController(text: initial);
  addTearDown(ctrl.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: BrandSelectorField(domain: domain, controller: ctrl),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, ctrl: ctrl);
}

/// Abre el dropdown del `BrandSelectorField`.
Future<void> _openDropdown(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
}

/// Busca un texto dentro del menu del dropdown (incluye items fuera del
/// viewport scrolleable, que viven como offstage en el overlay).
Finder _inMenu(String text) => find.text(text, skipOffstage: false);

void main() {
  group('BrandSelectorField — domain: filament', () {
    testWidgets('dropdown contiene marcas de filamentos (incluye duales) y '
        'NO las exclusive de impresoras', (tester) async {
      await _pump(tester, domain: BrandDomain.filament);

      // El dropdown se renderiza como DropdownButtonFormField.
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await _openDropdown(tester);

      // Marcas exclusive de filamento: presentes.
      for (final filamentBrand in <String>['Hatchbox', 'Sunlu', 'Prusament']) {
        expect(
          _inMenu(filamentBrand),
          findsWidgets,
          reason: '$filamentBrand (filamento) debe estar en el dropdown',
        );
      }

      // Marcas duales (venden filamento y fabrican impresoras): presentes.
      for (final dual in <String>['Creality', 'Bambu Lab', 'Anycubic']) {
        expect(
          _inMenu(dual),
          findsWidgets,
          reason: '$dual (dual) debe estar en el dropdown de filamentos',
        );
      }

      // Marcas exclusive de impresoras: ausentes.
      for (final printerOnly in <String>[
        'Artillery',
        'FLSun',
        'MakerBot',
        'Ultimaker',
        'Voron',
      ]) {
        expect(
          _inMenu(printerOnly),
          findsNothing,
          reason: '$printerOnly (impresora) NO debe estar en filament dropdown',
        );
      }
    });

    testWidgets('dropdown ofrece la opcion "Otro..."', (tester) async {
      await _pump(tester, domain: BrandDomain.filament);
      await _openDropdown(tester);
      expect(find.text('Otro...', skipOffstage: false), findsWidgets);
    });
  });

  group('BrandSelectorField — domain: printer', () {
    testWidgets('dropdown contiene marcas de impresoras y NO de filamentos', (
      tester,
    ) async {
      await _pump(tester, domain: BrandDomain.printer);

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await _openDropdown(tester);

      // Marcas de impresoras: presentes.
      for (final printerBrand in <String>[
        'Voron',
        'Creality',
        'Bambu Lab',
        'Anycubic',
        'Geeetech',
        'MakerBot',
        'FLSun',
      ]) {
        expect(
          _inMenu(printerBrand),
          findsWidgets,
          reason: '$printerBrand (impresora) debe estar en el dropdown',
        );
      }

      // Marcas de filamentos: ausentes.
      for (final filamentOnly in <String>[
        'Hatchbox',
        'Polymaker',
        'Prusament',
        'Sunlu',
        'Eryone',
        'Kingroon',
      ]) {
        expect(
          _inMenu(filamentOnly),
          findsNothing,
          reason: '$filamentOnly (filamento) NO debe estar en printer dropdown',
        );
      }
    });

    testWidgets('dropdown ofrece la opcion "Otro..."', (tester) async {
      await _pump(tester, domain: BrandDomain.printer);
      await _openDropdown(tester);
      expect(find.text('Otro...', skipOffstage: false), findsWidgets);
    });
  });

  group('BrandSelectorField — modo manual (Otro...)', () {
    testWidgets(
      'valor del controller NO esta en la lista -> renderiza TextFormField',
      (tester) async {
        // "MakerBot" esta en kKnownPrinterBrands pero NO en kKnownFilamentBrands.
        await _pump(tester, domain: BrandDomain.filament, initial: 'MakerBot');

        // El widget debe mostrar un TextFormField, no un Dropdown.
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        // El valor del controller es visible.
        expect(find.text('MakerBot'), findsOneWidget);
      },
    );

    testWidgets('elegir "Otro..." del dropdown activa TextFormField manual', (
      tester,
    ) async {
      // Superficie alta: con 23 marcas el item "Otro..." (el ultimo) queda
      // fuera del viewport del menu scrolleable en una superficie pequena.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, domain: BrandDomain.filament);

      // Toca el dropdown y elige "Otro...".
      await _openDropdown(tester);
      await tester.tap(find.text('Otro...').last);
      await tester.pumpAndSettle();

      // Ahora hay un TextFormField manual, no Dropdown.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });
  });
}
