// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/shared/widgets/app_scaffold.dart';

/// Mini app con StatefulShellRoute para instanciar [AppScaffold] de forma
/// realista (necesita un [navigationShell] del shell route).
Widget _shellTestApp(SharedPreferences prefs) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });

  final router = GoRouter(
    initialLocation: '/a',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a',
                builder: (_, _) => const Scaffold(body: Center(child: Text('A'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/b',
                builder: (_, _) => const Scaffold(body: Center(child: Text('B'))),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('mobile width (<600dp) → NavigationBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_shellTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('desktop width (>=1024dp) → NavigationRail', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_shellTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
