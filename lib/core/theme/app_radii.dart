/// Design tokens para border-radius consistente.
///
/// **Escala** (alineada con Material 3 shape system):
/// ```
/// xs    4   - chips pequenos, badges
/// sm    8   - inputs chicos, icon containers
/// md   10   - leading icons en list tiles
/// lg   12   - inputs, alert dialogs
/// xl   14   - medium cards, leading avatars
/// xxl  16   - cards standard, navigation buttons
/// xxxl 20   - hero cards, summary cards
/// pill  999  - circular (chips, FAB extended)
/// ```
library;

class AppRadii {
  const AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double xxl = 16;
  static const double xxxl = 20;

  /// Radio circular. Usar para chips y elementos pill.
  static const double pill = 999;
}
