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

  // === Common verbs (shared across pages) ===
  static const String commonSave = 'Guardar';
  static const String commonCancel = 'Cancelar';
  static const String commonDelete = 'Eliminar';
  static const String commonRetry = 'Reintentar';
  static const String commonEdit = 'Editar';
  static const String commonNew = 'Nuevo';
  static const String commonRequired = 'Requerido';
  static const String commonInvalidNumber = 'Numero invalido';
  static const String commonLoading = 'Cargando...';
  static const String commonErrorGeneric = 'Algo salio mal. Intenta de nuevo.';

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
  static const String settingsAppearance = 'Apariencia';
  static const String settingsTheme = 'Tema';
  static const String settingsManageFilaments = 'Gestiona tus filamentos';
  static const String settingsManagePrinters = 'Registra tus impresoras';

  // === Dashboard ===
  static const String dashboardTitle = 'Dashboard';
  static const String dashboardErrorLoad = 'Error al cargar el dashboard';
  static const String dashboardEmpty = 'Aun no cotizaste nada';
  static const String dashboardEmptyCta = 'Ir a Home';
  static const String dashboardStatQuotations = 'Cotizaciones';
  static const String dashboardStatSold = 'Vendidas';
  static const String dashboardStatConversion = 'Conversion';
  static const String dashboardTotalQuoted = 'Total cotizado';
  static const String dashboardTotalSold = 'Total vendido';
  static const String dashboardChartTitle = 'Cotizado vs Ganado';
  static const String dashboardChartQuoted = 'Cotizado';
  static const String dashboardChartSold = 'Ganado';

  // === Home / Quick actions ===
  static const String homeActionNewCalc = 'Nueva cotizacion';
  static const String homeActionNewCalcSub = 'Calcula precio de impresion';
  static const String homeActionHistory = 'Historial';
  static const String homeActionHistorySub = 'Cotizaciones guardadas';
  static const String homeActionDashboard = 'Dashboard';
  static const String homeActionDashboardSub = 'Estadisticas y graficos';
  static const String homeQuickAccess = 'Acceso rapido';
  static const String homeErrorLoadStats = 'Error cargando stats';
  static const String homeEmptyQuotations = 'Todavia no hay cotizaciones';
  static const String homeSummary = 'Resumen';
  static const String homeSeeAll = 'Ver todo';
}
