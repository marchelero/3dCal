/// Design tokens para spacing consistente en la app.
///
/// **Por que existe**: docenas de `SizedBox(height: 16)` / `EdgeInsets.all(20)`
/// regados por todo el codigo hacen imposible cambiar la densidad visual sin
/// buscar-y-reemplazar 50+ ocurrencias. Centralizando en tokens semanticos:
///
///   - Cambiar `AppSpacing.lg` de 16 a 18 actualiza toda la app de una vez.
///   - El nombre (`md`, `lg`) comunica intencion, no solo el valor.
///
/// **Escala** (basada en 4dp grid, estandar Material 3):
/// ```
/// xxs  2   -  gap minimo entre elementos muy cercanos
/// xs   4   -  gap entre texto e icono inline
/// sm   8   -  gap entre elementos de la misma seccion
/// md  12   -  gap entre cards o bloques chicos
/// lg  16   -  padding standard de cards / gap entre secciones
/// xl  20   -  padding generoso para CTAs y dialogs
/// xxl 24   -  padding de hero cards / pantallas compactas
/// xxxl 32 -  separacion entre zonas visuales distintas
/// ```
library;

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Presets de EdgeInsets para los casos mas comunes.

  /// Padding standard para el interior de un `Card` o `SectionCard`.
  static const cardPadding = 16.0;
}
