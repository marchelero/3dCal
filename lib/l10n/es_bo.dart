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

  // === Calculator (sections + fields) ===
  static const String calcSectionPiece = 'Pieza';
  static const String calcSectionFilament = 'Filamento';
  static const String calcSectionTime = 'Tiempo de impresion';
  static const String calcSectionDiscount = 'Descuento';
  static const String calcLabelOptional = 'Etiqueta (opcional)';
  static const String calcLabelOptionalHelper =
      'Ej: Soporte pared, Engranaje PETG';
  static const String calcLabelWeight = 'Peso de la pieza';
  static const String calcLabelWeightHelper = 'Gramos del modelo';
  static const String calcLabelHours = 'Horas';
  static const String calcLabelMinutes = 'Minutos';
  static const String calcLabelMinutesHelper = '0-59';
  static const String calcLabelDiscount = 'Descuento';
  static const String calcLabelDiscountHelper =
      'Porcentaje sobre el total final';
  static const String calcBtnSave = 'Guardar cotizacion';
  static const String calcBtnReset = 'Restablecer valores';
  static const String calcToggleShowDetail = 'Ver detalle';
  static const String calcToggleHideDetail = 'Ocultar detalle';
  static const String calcTotalWithDiscount = 'Total con descuento';
  static const String calcTotalFinal = 'Total final';
  static const String calcDetailMaterial = 'Costo material';
  static const String calcDetailEnergy = 'Costo energia';
  static const String calcDetailBase = 'Costo base';
  static const String calcDetailProfit = 'Ganancia';
  static const String calcDetailTotal = 'Costo total final';
  static const String calcEmptyHint =
      'Completa peso, filamento y horas para ver el precio';

  // === Filaments / Printers forms ===
  static const String filamentTitle = 'Filamentos';
  static const String filamentNew = 'Nuevo filamento';
  static const String filamentEdit = 'Editar filamento';
  static const String filamentName = 'Nombre';
  static const String filamentNameHelper = 'Ej: PLA Negro';
  static const String filamentBrand = 'Marca';
  static const String filamentBrandHelper = 'Opcional';
  static const String filamentPrice = 'Precio bobina (BOB)';
  static const String filamentPriceHelper = 'Costo del rollo completo';
  static const String filamentGrams = 'Gramos por bobina';
  static const String filamentGramsHelper = 'Tipico 1000';
  static const String filamentDefaultToggle = 'Marcar como default';
  static const String filamentDefaultSubtitle =
      'Se usara en nuevas cotizaciones. Solo un filamento puede ser default.';
  static const String filamentNewTooltip = 'Nuevo filamento';
  static const String filamentDeleteTitle = 'Eliminar filamento';
  static const String filamentErrorSave = 'Error guardando';
  static const String filamentMustBePositive = 'Debe ser > 0';
  static const String filamentMustBeInteger = 'Debe ser entero';
  static const String filamentMax100 = 'Maximo 100 caracteres';

  static const String printerTitle = 'Impresoras';
  static const String printerNew = 'Nueva impresora';
  static const String printerEdit = 'Editar impresora';
  static const String printerModel = 'Modelo';
  static const String printerModelHelper = 'Ej: Ender 3 V2';
  static const String printerBrandHelper = 'Ej: Creality, Anycubic';
  static const String printerWatts = 'Consumo promedio (W)';
  static const String printerWattsHelper = 'Tipico 100-300 W';
  static const String printerDefaultSubtitle =
      'Se usara en nuevas cotizaciones. Solo una impresora puede ser default.';
  static const String printerNewTooltip = 'Nueva impresora';
  static const String printerDeleteTitle = 'Eliminar impresora';
  static const String printerMustBeNonNegative = 'Debe ser >= 0';

  // === Calculator output + notifier labels ===
  static const String calcNotifFilament = 'Filamento';
  static const String calcNotifMaterial = 'Material';

  // === Calculation detail page ===
  static const String calcDetailTitle = 'Detalle cotizacion';
  static const String calcDetailDelete = 'Eliminar';
  static const String calcDetailDeleteTitle = 'Eliminar cotizacion';
  static const String calcDetailDeleteConfirm = '¿Eliminar definitivamente?';
  static const String calcDetailNoName = 'Sin nombre';
  static const String calcDetailSold = 'Vendida';
  static const String calcDetailReuse = 'Reusar';
  static const String calcDetailMarkSold = 'Marcar vendida';
  static const String calcDetailMarkPending = 'Marcar pendiente';

  // === History / Calculations list ===
  static const String historyTitle = 'Cotizaciones';
  static const String historyErrorLoad = 'Error cargando cotizaciones';
  static const String historyEmpty = 'Sin cotizaciones guardadas';
}
