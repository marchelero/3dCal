// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/shared/widgets/filament_color_palette.dart';

void main() {
  group('hexFromColor / colorFromHex', () {
    test('hexFromColor normaliza a mayusculas con #', () {
      expect(hexFromColor(const Color(0xFFE53935)), '#E53935');
      expect(hexFromColor(const Color(0xFF1E88E5)), '#1E88E5');
      expect(hexFromColor(const Color(0xFF000000)), '#000000');
      expect(hexFromColor(const Color(0xFFFFFFFF)), '#FFFFFF');
    });

    test('colorFromHex parsea con y sin #', () {
      expect(colorFromHex('#E53935'), const Color(0xFFE53935));
      expect(colorFromHex('e53935'), const Color(0xFFE53935));
      expect(colorFromHex('#E53935'), isNotNull);
    });

    test('colorFromHex acepta shorthand #RGB', () {
      expect(colorFromHex('#FFF'), const Color(0xFFFFFFFF));
      expect(colorFromHex('#000'), const Color(0xFF000000));
    });

    test('colorFromHex devuelve null para entrada invalida', () {
      expect(colorFromHex(null), isNull);
      expect(colorFromHex(''), isNull);
      expect(colorFromHex('#GGGGGG'), isNull);
      expect(colorFromHex('#12345'), isNull);
      expect(colorFromHex('#1234567'), isNull);
      expect(colorFromHex('not-a-color'), isNull);
    });

    test('round-trip hexFromColor(colorFromHex(x)) == x (mayusculas)', () {
      for (final entry in kFilamentPalette) {
        final hex = hexFromColor(entry.color);
        expect(colorFromHex(hex), entry.color);
      }
    });
  });

  group('nameKeyFromHex', () {
    test('match exacto contra la paleta devuelve la clave del set', () {
      expect(nameKeyFromHex('#E53935'), 'red');
      expect(nameKeyFromHex('#FB8C00'), 'orange');
      expect(nameKeyFromHex('#FFB300'), 'amber');
      expect(nameKeyFromHex('#FDD835'), 'yellow');
      expect(nameKeyFromHex('#1E88E5'), 'blue');
      expect(nameKeyFromHex('#8E24AA'), 'purple');
      expect(nameKeyFromHex('#000000'), 'black');
      expect(nameKeyFromHex('#FFFFFF'), 'white');
    });

    test('color custom cae en bucket por hue', () {
      // Hue ~5° = bucket rojo.
      expect(nameKeyFromHex('#FF0500'), 'red');
      // Hue ~25° = bucket naranja (limite estricto: < 30).
      expect(nameKeyFromHex('#FF7000'), 'orange');
      // Hue ~40° = bucket ambar.
      expect(nameKeyFromHex('#FFAA00'), 'amber');
      // Hue ~55° = bucket amarillo.
      expect(nameKeyFromHex('#FFE000'), 'yellow');
      // Hue ~75° = bucket lima.
      expect(nameKeyFromHex('#B0FF00'), 'lime');
      // Hue ~120° = bucket verde.
      expect(nameKeyFromHex('#00FF00'), 'green');
      // Hue ~170° = bucket verde azulado (teal).
      expect(nameKeyFromHex('#00FFD4'), 'teal');
      // Hue ~190° = bucket cian.
      expect(nameKeyFromHex('#00D0FF'), 'cyan');
      // Hue ~220° = bucket azul.
      expect(nameKeyFromHex('#0080FF'), 'blue');
      // Hue ~270° = bucket indigo.
      expect(nameKeyFromHex('#4040FF'), 'indigo');
      // Hue ~290° = bucket purpura.
      expect(nameKeyFromHex('#A000FF'), 'purple');
    });

    test('color invalido devuelve null', () {
      expect(nameKeyFromHex(null), isNull);
      expect(nameKeyFromHex('#GGGGGG'), isNull);
    });
  });

  group('isPaletteHex', () {
    test('true para entradas del set canonico', () {
      expect(isPaletteHex('#E53935'), isTrue);
      expect(isPaletteHex('#FB8C00'), isTrue);
      expect(isPaletteHex('#FFFFFF'), isTrue);
    });

    test('false para custom hex', () {
      expect(isPaletteHex('#FF00FF'), isFalse);
      expect(isPaletteHex('#FF0007'), isFalse);
      expect(isPaletteHex(null), isFalse);
      expect(isPaletteHex('invalid'), isFalse);
    });
  });
}
