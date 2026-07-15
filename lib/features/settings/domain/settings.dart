// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';

/// Snapshot de los settings globales.
///
/// **Inmutable**. Inicializa con defaults del repositorio. Se persiste en
/// la tabla `settings` via [SettingsRepository].
class Settings {
  const Settings({
    required this.profitBase,
    required this.kwhRate,
  });

  /// Ganancia base global en porcentaje. Default 200%.
  final Decimal profitBase;

  /// Tarifa electrica en BOB/kWh. Default 0.7.
  final Decimal kwhRate;

  Settings copyWith({Decimal? profitBase, Decimal? kwhRate}) {
    return Settings(
      profitBase: profitBase ?? this.profitBase,
      kwhRate: kwhRate ?? this.kwhRate,
    );
  }

  /// Defaults del MVP. Usado cuando la tabla `settings` esta vacia.
  static final Settings defaults = Settings(
    profitBase: Decimal.fromInt(200),
    kwhRate: Decimal.parse('0.7'),
  );
}
