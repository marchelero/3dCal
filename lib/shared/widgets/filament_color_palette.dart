// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

/// Paleta rápida de colores para filamentos.
///
/// **17 swatches** curados (incluye blanco y negro ademas de los acentos
/// Material). Cada entrada mapea un color Flutter a su nombre legible para
/// busqueda/subtitulos.
///
/// Formato de almacenamiento: hex en mayusculas `#RRGGBB`. La funcion
/// [hexFromColor] normaliza cualquier [Color] al formato canonico; la funcion
/// [colorFromHex] parsea y devuelve `null` si el formato es invalido.
///
/// El nombre legible ([nameKey]) es la clave de i18n que el UI resuelve
/// contra el locale activo (`EsBO.colorNameRed`, etc.).
class FilamentPaletteEntry {
  const FilamentPaletteEntry({
    required this.color,
    required this.nameKey,
  });

  final Color color;
  final String nameKey;
}

/// Paleta ordenada: pasa por el espectro + neutros al final.
const List<FilamentPaletteEntry> kFilamentPalette = [
  FilamentPaletteEntry(color: Color(0xFFE53935), nameKey: 'red'),
  FilamentPaletteEntry(color: Color(0xFFFB8C00), nameKey: 'orange'),
  FilamentPaletteEntry(color: Color(0xFFFFB300), nameKey: 'amber'),
  FilamentPaletteEntry(color: Color(0xFFFDD835), nameKey: 'yellow'),
  FilamentPaletteEntry(color: Color(0xFFC0CA33), nameKey: 'lime'),
  FilamentPaletteEntry(color: Color(0xFF43A047), nameKey: 'green'),
  FilamentPaletteEntry(color: Color(0xFF00897B), nameKey: 'teal'),
  FilamentPaletteEntry(color: Color(0xFF00ACC1), nameKey: 'cyan'),
  FilamentPaletteEntry(color: Color(0xFF1E88E5), nameKey: 'blue'),
  FilamentPaletteEntry(color: Color(0xFF3949AB), nameKey: 'indigo'),
  FilamentPaletteEntry(color: Color(0xFF8E24AA), nameKey: 'purple'),
  FilamentPaletteEntry(color: Color(0xFFD81B60), nameKey: 'magenta'),
  FilamentPaletteEntry(color: Color(0xFFEC407A), nameKey: 'pink'),
  FilamentPaletteEntry(color: Color(0xFF6D4C41), nameKey: 'brown'),
  FilamentPaletteEntry(color: Color(0xFF757575), nameKey: 'gray'),
  FilamentPaletteEntry(color: Color(0xFF000000), nameKey: 'black'),
  FilamentPaletteEntry(color: Color(0xFFFFFFFF), nameKey: 'white'),
];

/// Hex canonico del color (mayusculas, formato `#RRGGBB`). Alpha se descarta
/// (siempre FF en almacenamiento).
String hexFromColor(Color color) {
  final r = (color.r * 255.0).round() & 0xFF;
  final g = (color.g * 255.0).round() & 0xFF;
  final b = (color.b * 255.0).round() & 0xFF;
  return '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';
}

String _hex2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();

/// Parsea un hex `#RRGGBB` (con o sin `#`, mayusculas o minusculas). Devuelve
/// `null` si el formato no es valido. Acepta tambien `#RGB` shorthand y lo
/// expande a `#RRGGBB`.
Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) {
    s = s.split('').map((c) => '$c$c').join();
  }
  if (s.length != 6) return null;
  final r = int.tryParse(s.substring(0, 2), radix: 16);
  final g = int.tryParse(s.substring(2, 4), radix: 16);
  final b = int.tryParse(s.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return null;
  return Color(0xFF000000 | (r << 16) | (g << 8) | b);
}

/// Regex de validacion de hex `#RRGGBB` (con o sin `#`).
final RegExp kHexPattern = RegExp(r'^#?[0-9A-Fa-f]{6}$');

/// Nombre legible (clave i18n) de un color a partir de su hex.
///
/// - Si el hex coincide exactamente con una entrada de [kFilamentPalette],
///   devuelve esa `nameKey` (palabras exactas del set).
/// - Si NO coincide (color custom del slider HSV), devuelve la clave del
///   color de paleta mas cercano por hue (mismo bucket). Asi un slider en
///   tono 15° cae en `orange` aunque no sea un naranja puro.
/// - `null` si el hex es invalido.
String? nameKeyFromHex(String? hex) {
  final color = colorFromHex(hex);
  if (color == null) return null;
  // 1) Match exacto contra la paleta (compara hex normalizado).
  final canonical = hexFromColor(color);
  for (final entry in kFilamentPalette) {
    if (hexFromColor(entry.color) == canonical) return entry.nameKey;
  }
  // 2) Match por hue bucket (H del HSV, 0-360).
  final h = HSVColor.fromColor(color).hue;
  return _hueBucketNameKey(h);
}

/// Bucket por hue para mapear un color custom al nombre de paleta mas
/// cercano. Rangos en grados: rojo cubre el wrap 330°-360° + 0°-15°.
String _hueBucketNameKey(double h) {
  if (h >= 330 || h < 15) return 'red';
  if (h < 30) return 'orange';
  if (h < 50) return 'amber';
  if (h < 70) return 'yellow';
  if (h < 85) return 'lime';
  if (h < 155) return 'green';
  if (h < 180) return 'teal';
  if (h < 200) return 'cyan';
  if (h < 240) return 'blue';
  if (h < 275) return 'indigo';
  if (h < 310) return 'purple';
  if (h < 330) return 'magenta';
  return 'pink';
}

/// True si el hex dado matchea el set canonico de la paleta (no custom).
bool isPaletteHex(String? hex) {
  if (hex == null) return false;
  final color = colorFromHex(hex);
  if (color == null) return false;
  final canonical = hexFromColor(color);
  for (final entry in kFilamentPalette) {
    if (hexFromColor(entry.color) == canonical) return true;
  }
  return false;
}

