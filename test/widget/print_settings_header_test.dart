// ignore_for_file: public_member_api_docs
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tresdcal/core/constants/app_constants.dart';
import 'package:tresdcal/core/database/app_database.dart';
import 'package:tresdcal/core/providers.dart';
import 'package:tresdcal/core/storage/draft_storage_providers.dart';
import 'package:tresdcal/features/calculation/data/calculation_repository.dart';
import 'package:tresdcal/features/calculation/presentation/notifiers/calculations_notifier.dart';
import 'package:tresdcal/features/settings/domain/settings.dart';
import 'package:tresdcal/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:tresdcal/features/settings/presentation/pages/print_settings_page.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/shared/widgets/page_header_card.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => Settings.defaults;
}

class _FakeCalculationsNotifier extends CalculationsNotifier {
  @override
  Future<List<CalculationListItem>> build() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPage(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          settingsNotifierProvider.overrideWith(_FakeSettingsNotifier.new),
          calculationsNotifierProvider.overrideWith(
            _FakeCalculationsNotifier.new,
          ),
        ],
        child: const MaterialApp(home: PrintSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Header estandar: card con titulo/subtitulo + badge de plan, '
    'sin version, privacidad ni flecha de retroceso',
    (tester) async {
      await pumpPage(tester);

      // Card generica estandar con su contenido localizado.
      expect(find.byType(PageHeaderCard), findsOneWidget);
      expect(find.text(EsBO.settingsPrintConfigTitle), findsOneWidget);
      expect(find.text(EsBO.settingsPrintConfigSubtitle), findsOneWidget);
      // Badge de plan (PRO/FREE) presente en la cabecera.
      expect(find.byType(PlanTierBadge), findsOneWidget);
      // Sin informacion inutil: version de la app, privacidad, candado
      // y flecha de retroceso (es un tab del shell, no una pagina empujada).
      expect(find.textContaining('v$kAppVersion'), findsNothing);
      expect(find.text(EsBO.settingsPrivacy), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    },
  );
}
