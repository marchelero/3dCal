// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';

import 'package:tresdcal/l10n/app_strings.dart';
import 'package:tresdcal/l10n/de_de.dart';
import 'package:tresdcal/l10n/en_us.dart';
import 'package:tresdcal/l10n/es_bo.dart';
import 'package:tresdcal/l10n/fr_fr.dart';
import 'package:tresdcal/l10n/pt_br.dart';

/// AC-005/006/007/009 (gap-remediation 2026-10-10): verificaciones SEMANTICAS
/// del copy en los 5 idiomas. La paridad mecánica de claves ya la cubre
/// `l10n_parity_test.dart`; aquí se valida que el SIGNIFICADO sea coherente.
void main() {
  const impls = <String, AppStrings>{
    'es': EsImpl(),
    'en': EnImpl(),
    'pt': PtBrImpl(),
    'fr': FrImpl(),
    'de': DeImpl(),
  };

  group('AC-005 — onboarding describe filamento/gramos como requerido', () {
    test('configFilamentOptional dice "requerido" en los 5 idiomas', () {
      final expected = <String, Pattern>{
        'es': RegExp('requerid[oa]'),
        'en': RegExp('required'),
        'pt': RegExp('obrigat[oó]ri[oa]'),
        'fr': RegExp('obligatoire'),
        'de': RegExp('erforderlich'),
      };
      for (final entry in impls.entries) {
        expect(
          entry.value.configFilamentOptional.toLowerCase(),
          matches(expected[entry.key]!),
          reason:
              '${entry.key}: el header de filamento debe dejar claro que '
              'es requerido.',
        );
      }
    });

    test('configFilamentSectionHelper exige al menos un filamento', () {
      final expected = <String, Pattern>{
        'es': RegExp('al menos uno|requerido|necesitamos'),
        'en': RegExp('at least one|required|we need'),
        'pt': RegExp('pelo menos um|necess?ário|precisamos'),
        'fr': RegExp('au moins un|obligatoire|besoin'),
        'de': RegExp('mindestens|benöt|erforderlich'),
      };
      for (final entry in impls.entries) {
        expect(
          entry.value.configFilamentSectionHelper.toLowerCase(),
          matches(expected[entry.key]!),
          reason:
              '${entry.key}: el helper debe pedir registrar al menos un '
              'filamento.',
        );
      }
    });
  });

  group(
    'AC-006 — disclosure de backup (manual, sin sync, sin cifrar, HMAC)',
    () {
      test(
        'los 5 idiomas explican backup manual + no cifrado + HMAC integridad',
        () {
          final checks = <String, Map<String, Pattern>>{
            'es': {
              'manual': RegExp('manual'),
              'no-sync': RegExp('no se sincroniza'),
              'no-cifrado': RegExp('no está cifrado'),
              'hmac': RegExp('HMAC'),
              'integridad': RegExp('integridad'),
            },
            'en': {
              'manual': RegExp('manual'),
              'no-sync': RegExp('not synced'),
              'no-cifrado': RegExp('not encrypted'),
              'hmac': RegExp('HMAC'),
              'integridad': RegExp('integrity'),
            },
            'pt': {
              'manual': RegExp('manual'),
              'no-sync': RegExp('não é sincronizado'),
              'no-cifrado': RegExp('não é criptografado'),
              'hmac': RegExp('HMAC'),
              'integridad': RegExp('integridade'),
            },
            'fr': {
              'manual': RegExp('manuelle'),
              'no-sync': RegExp('synchronisation automatique'),
              'no-cifrado': RegExp('pas chiffré'),
              'hmac': RegExp('HMAC'),
              'integridad': RegExp('intégrité'),
            },
            'de': {
              'manual': RegExp('manuell'),
              'no-sync': RegExp('Synchronisierung'),
              'no-cifrado': RegExp('nicht verschlüsselt'),
              'hmac': RegExp('HMAC'),
              'integridad': RegExp('Integrität'),
            },
          };
          for (final entry in impls.entries) {
            final text = entry.value.settingsBackupDisclosure;
            for (final check in checks[entry.key]!.entries) {
              expect(
                text,
                matches(check.value),
                reason:
                    '${entry.key} settingsBackupDisclosure debe cubrir '
                    '"${check.key}".',
              );
            }
          }
        },
      );
    },
  );

  group('AC-007 — privacidad coherente con borrado local', () {
    test('los 5 docs de privacidad dicen que los backups exportados se '
        'eliminan manualmente', () {
      final expected = <String, Pattern>{
        'es': RegExp('eliminarse manualmente'),
        'en': RegExp('deleted manually'),
        'pt': RegExp('excluídos manualmente|excluidos manualmente'),
        'fr': RegExp('supprimées manuellement'),
        'de': RegExp('manuell gelöscht'),
      };
      for (final entry in impls.entries) {
        expect(
          entry.value.legalPrivacyDocument,
          matches(expected[entry.key]!),
          reason:
              '${entry.key}: la política de privacidad no debe implicar que '
              'la app borra archivos exportados.',
        );
      }
    });
  });

  group('AC-009 — ayuda de moneda: display-only, sin conversión ni tasas', () {
    test('los 5 idiomas niegan conversión automática y tasas de cambio', () {
      final checks = <String, Map<String, Pattern>>{
        'es': {
          'conversion': RegExp('conversión'),
          'tasas': RegExp('tasas de cambio'),
        },
        'en': {
          'conversion': RegExp('converts|conversion'),
          'tasas': RegExp('exchange rates'),
        },
        'pt': {
          'conversion': RegExp('conversão'),
          'tasas': RegExp('taxas de câmbio'),
        },
        'fr': {
          'conversion': RegExp('conversion'),
          'tasas': RegExp('taux de change'),
        },
        'de': {
          'conversion': RegExp('Umrechnung'),
          'tasas': RegExp('Wechselkurse'),
        },
      };
      for (final entry in impls.entries) {
        final text = entry.value.settingsCurrencyHelper;
        for (final check in checks[entry.key]!.entries) {
          expect(
            text,
            matches(check.value),
            reason:
                '${entry.key} settingsCurrencyHelper debe negar '
                '"${check.key}".',
          );
        }
      }
    });
  });
}
