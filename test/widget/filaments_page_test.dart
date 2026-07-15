// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import 'package:tresdcal/features/catalog/filaments/presentation/pages/filaments_page.dart';

/// Helper: monta [FilamentsPage] dentro de un [ProviderScope] con DB in-memory.
///
/// **Sprint 7**: el page usa `context.push` de go_router, asi que necesita
/// un `MaterialApp.router` con un [GoRouter] que tenga las rutas de form.
/// Para los tests de "tap en X navega a Y" solo necesitamos la ruta destino.
Future<ProviderContainer> _pumpPage(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  final router = GoRouter(
    initialLocation: '/settings/filaments',
    routes: [
      GoRoute(
        path: '/settings/filaments',
        builder: (_, _) => const FilamentsPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => const _ScaffoldWithText(
              title: 'Nuevo filamento',
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, _) => const _ScaffoldWithText(
              title: 'Editar filamento',
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  // Esperar a que el AsyncNotifier resuelva.
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('FilamentsPage', () {
    testWidgets('muestra appbar con titulo y boton agregar', (tester) async {
      await _pumpPage(tester);
      expect(find.text('Filamentos'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('estado vacio: muestra hint para crear el primero',
        (tester) async {
      await _pumpPage(tester);
      expect(
        find.textContaining('Sin filamentos'),
        findsOneWidget,
      );
    });

    testWidgets('lista filamentos con nombre y marca', (tester) async {
      final container = await _pumpPage(tester);
      await container.read(filamentRepositoryProvider).create(
            name: 'PLA',
            brand: 'eSun',
            pricePerBobbin: Decimal.parse('150'),
            gramsPerBobbin: Decimal.parse('1000'),
          );
      await container.read(filamentsNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.text('PLA'), findsOneWidget);
      expect(find.textContaining('eSun'), findsOneWidget);
    });

    testWidgets('default muestra estrella amarilla', (tester) async {
      final container = await _pumpPage(tester);
      await container.read(filamentRepositoryProvider).create(
            name: 'PETG',
            pricePerBobbin: Decimal.parse('200'),
            gramsPerBobbin: Decimal.parse('1000'),
            asDefault: true,
          );
      await container.read(filamentsNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();

      // El IconButton "+" del AppBar es un Icon(Icons.add).
      // El star del default tiene color amarillo.
      final stars = find.byIcon(Icons.star);
      expect(stars, findsOneWidget);
      final star = tester.widget<Icon>(stars);
      expect(star.color, Colors.amber);
    });

    testWidgets('tap en "+" navega a FilamentFormPage', (tester) async {
      await _pumpPage(tester);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      // El form page tiene "Nuevo filamento" en su AppBar.
      expect(find.text('Nuevo filamento'), findsOneWidget);
    });

    testWidgets('tap en row navega a FilamentFormPage en modo edicion',
        (tester) async {
      final container = await _pumpPage(tester);
      await container.read(filamentRepositoryProvider).create(
            name: 'PLA Editable',
            pricePerBobbin: Decimal.parse('100'),
            gramsPerBobbin: Decimal.parse('1000'),
          );
      await container.read(filamentsNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();

      await tester.tap(find.text('PLA Editable'));
      await tester.pumpAndSettle();
      expect(find.text('Editar filamento'), findsOneWidget);
    });
  });
}

/// Stub para destinos de navegacion en tests: solo necesitamos el titulo
/// para verificar que la navegacion llego a la ruta correcta.
class _ScaffoldWithText extends StatelessWidget {
  const _ScaffoldWithText({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}
