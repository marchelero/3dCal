// ignore_for_file: public_member_api_docs

/// Strings centralizados de la app (es_BO).
///
/// **Scope (Sprint 7)**: solo los strings que se referencian desde el shell
/// de navegacion y la Settings page. Los strings inline de paginas existentes
/// se mantienen como literales — refactor global queda para Sprint 8 (a11y/l10n).
library;

class EsBO {
  const EsBO._();

  // === App ===
  static const String appName = '3dcal';

  // === Navegacion (4 destinations) ===
  static const String navHome = 'Inicio';
  static const String navHistory = 'Historial';
  static const String navDashboard = 'Dashboard';
  static const String navSettings = 'Ajustes';

  // === Settings page ===
  static const String settingsTitle = 'Ajustes';
  static const String settingsGlobalParams = 'Parametros globales';
  static const String settingsProfitBase = 'Ganancia base (%)';
  static const String settingsProfitBaseHelper = 'Margen sobre costo base. 0-1000';
  static const String settingsKwhRate = 'Tarifa electrica (BOB/kWh)';
  static const String settingsKwhRateHelper = 'Rango residencial Bolivia: 0.10-5.00';
  static const String settingsCatalogos = 'Catalogos';
  static const String settingsFilamentos = 'Filamentos';
  static const String settingsImpresoras = 'Impresoras';
  static const String settingsAbout = 'Acerca de';
  static const String settingsPrivacy = 'Privacidad: 100% local, sin telemetria';
  static const String settingsSaved = 'Guardado';
}
