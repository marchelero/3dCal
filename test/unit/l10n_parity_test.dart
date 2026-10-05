// ignore_for_file: public_member_api_docs
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// MED-12 fix (auditoría 2026-10-04): paridad mecánica de los 5 impls de
/// [AppStrings]. Sin test así, una clave nueva agregada a `app_strings.dart`
/// y a un impl pero no a los otros 4 solo se detecta al compilar en la
/// plataforma del impl faltante (o nunca, porque todos viven en el mismo
/// compile). Este test parsea los archivos fuente y compara SETS de
/// miembros — sin analyzer ni build_runner.
///
/// **Qué valida**:
/// 1. Cada impl (es/en/pt/fr/de) define exactamente los mismos nombres de
///    miembros (getters `String get x =>` / métodos `String x(...) =>`).
/// 2. Todo miembro abstracto de `app_strings.dart` aparece en los 5 impls.
///    (Los impls pueden tener extras de infraestructura — ver _IGNORED.)
void main() {
  const implFiles = [
    'lib/l10n/es_bo.dart',
    'lib/l10n/en_us.dart',
    'lib/l10n/pt_br.dart',
    'lib/l10n/fr_fr.dart',
    'lib/l10n/de_de.dart',
  ];

  // Miembros de infraestructura del facade EsBO (no forman parte del
  // contrato de AppStrings).
  const ignoredMembers = {'setImpl'};

  Set<String> membersOf(String path) {
    var src = File(path).readAsStringSync();
    // Eliminar bloques raw string '''...''' (textos legales largos que
    // contienen puntos y comas y generan falsos positivos de "miembro").
    src = src.replaceAll(RegExp("'''.*?'''", dotAll: true), '');
    // `Tipo nombre(...)` / `Tipo get nombre` seguido de `=>` o `;`.
    // Group 1 exige espacio ANTES del nombre para no tragar `EsBO.foo;`.
    final pattern = RegExp(
      r'^\s*(?:static\s+)?'
      r'([A-Z][\w<>, .?]*?)\s+'
      r'(?:get\s+)?(\w+)\s*'
      r'(?:\([^;{]*?\))?\s*'
      r'(?:=>|;|\{)',
      multiLine: true,
    );
    final out = <String>{};
    for (final m in pattern.allMatches(src)) {
      final name = m.group(2)!;
      if (ignoredMembers.contains(name)) continue;
      out.add(name);
    }
    return out;
  }

  final implSets = {for (final f in implFiles) f: membersOf(f)};
  final abstractSet = membersOf('lib/l10n/app_strings.dart').difference(
    ignoredMembers,
  );

  test('app_strings.dart declara miembros (no se rompe el parser)', () {
    expect(abstractSet.length, greaterThan(600));
  });

  for (final file in implFiles) {
    test('$file implementa TODAS las claves de app_strings.dart', () {
      final missing = abstractSet.difference(implSets[file]!);
      expect(
        missing,
        isEmpty,
        reason: 'Claves declaradas pero no implementadas en $file: $missing',
      );
    });
  }

  test('los 5 impls tienen exactamente los mismos miembros (paridad)', () {
    final reference = implSets[implFiles.first]!;
    for (final file in implFiles.skip(1)) {
      final other = implSets[file]!;
      final onlyInRef = reference.difference(other);
      final onlyInOther = other.difference(reference);
      expect(
        onlyInRef,
        isEmpty,
        reason: '$implFiles.first tiene en $file faltante: $onlyInRef',
      );
      expect(onlyInOther, isEmpty, reason: '$file tiene extra vs ref: $onlyInOther');
    }
  });

  test('csvExportHeader tiene 13 columnas en los 5 idiomas (HIGH-01)', () {
    // El writer de `calculations_list_page.dart` emite exactamente 13 celdas
    // (ver assert del writer). Antes el header traía una columna "Materiales"
    // que el writer nunca emitía y TODAS las celdas quedaban corridas.
    final headerPattern = RegExp(
      r'csvExportHeader\s*=>\s*const\s*\[(.*?)\];',
      dotAll: true,
    );
    final cellPattern = RegExp("'[^']*'");
    for (final file in implFiles) {
      final match = headerPattern.firstMatch(File(file).readAsStringSync());
      expect(match, isNotNull, reason: 'csvExportHeader no hallada en $file');
      final cells = cellPattern.allMatches(match!.group(1)!).length;
      expect(cells, 13, reason: '$file declara $cells columnas; el writer emite 13');
    }
  });
}
