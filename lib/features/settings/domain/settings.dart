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
    required this.companyName,
    this.companyLogoBase64,
    required this.laborRate,
    required this.postProcessRate,
    required this.failureRate,
    required this.minimumCharge,
    required this.markupOnMaterials,
  });

  /// Ganancia base global en porcentaje. Default 200%.
  final Decimal profitBase;

  /// Tarifa electrica en BOB/kWh. Default 0.7.
  final Decimal kwhRate;

  /// Nombre de la empresa/negocio para la cotizacion.
  final String companyName;

  /// Logo de la empresa en base64 (PNG). Null si no configurado.
  final String? companyLogoBase64;

  /// Tarifa de mano de obra (BOB/hora).
  final Decimal laborRate;

  /// Tasa de post-procesado (% del costo de materiales).
  final Decimal postProcessRate;

  /// Tasa de falla (% del costo base).
  final Decimal failureRate;

  /// Cargo minimo por cotizacion (BOB).
  final Decimal minimumCharge;

  /// Markup por desperdicio de materiales (% del costo de materiales).
  final Decimal markupOnMaterials;

  Settings copyWith({
    Decimal? profitBase,
    Decimal? kwhRate,
    String? companyName,
    String? companyLogoBase64,
    bool clearLogo = false,
    Decimal? laborRate,
    Decimal? postProcessRate,
    Decimal? failureRate,
    Decimal? minimumCharge,
    Decimal? markupOnMaterials,
  }) {
    return Settings(
      profitBase: profitBase ?? this.profitBase,
      kwhRate: kwhRate ?? this.kwhRate,
      companyName: companyName ?? this.companyName,
      companyLogoBase64: clearLogo
          ? null
          : (companyLogoBase64 ?? this.companyLogoBase64),
      laborRate: laborRate ?? this.laborRate,
      postProcessRate: postProcessRate ?? this.postProcessRate,
      failureRate: failureRate ?? this.failureRate,
      minimumCharge: minimumCharge ?? this.minimumCharge,
      markupOnMaterials: markupOnMaterials ?? this.markupOnMaterials,
    );
  }

  /// Defaults del MVP. Usado cuando la tabla `settings` esta vacia.
  static final Settings defaults = Settings(
    profitBase: Decimal.fromInt(200),
    kwhRate: Decimal.parse('0.7'),
    companyName: '3dCalc',
    companyLogoBase64: null,
    laborRate: Decimal.zero,
    postProcessRate: Decimal.zero,
    failureRate: Decimal.zero,
    minimumCharge: Decimal.zero,
    markupOnMaterials: Decimal.zero,
  );
}
