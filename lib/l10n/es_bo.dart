/// Strings en espanol (es_BO).
///
/// [EsBO] es la API publica — todas las call sites existentes siguen usando
/// `EsBO.xxx`. Internamente delega a la implementacion del locale activo.
library;

import 'app_strings.dart';

// ─── API publica (sin cambios en call sites) ─────

class EsBO {
  EsBO._();

  static AppStrings _impl = EsImpl();

  /// Actualiza la implementacion activa. Llamado por el sistema de locale.
  // ignore: use_setters_to_change_properties
  static void setImpl(AppStrings impl) {
    _impl = impl;
  }

  // === App ===
  static String get appName => _impl.appName;

  // === Common verbs ===
  static String get commonSave => _impl.commonSave;
  static String get commonCancel => _impl.commonCancel;
  static String get commonDelete => _impl.commonDelete;
  static String get commonRetry => _impl.commonRetry;
  static String get commonEdit => _impl.commonEdit;
  static String get commonNew => _impl.commonNew;
  static String get commonRequired => _impl.commonRequired;
  static String get commonInvalidNumber => _impl.commonInvalidNumber;
  static String get commonLoading => _impl.commonLoading;
  static String get commonErrorGeneric => _impl.commonErrorGeneric;

  // === Navigation ===
  static String get navHome => _impl.navHome;
  static String get navHistory => _impl.navHistory;
  static String get navDashboard => _impl.navDashboard;
  static String get navSettings => _impl.navSettings;

  // === Settings ===
  static String get settingsTitle => _impl.settingsTitle;
  static String get settingsGlobalParams => _impl.settingsGlobalParams;
  static String get settingsProfitBase => _impl.settingsProfitBase;
  static String get settingsProfitBaseHelper =>
      _impl.settingsProfitBaseHelper;
  static String settingsKwhRate(String symbol) =>
      _impl.settingsKwhRate(symbol);
  static String get settingsKwhRateHelper => _impl.settingsKwhRateHelper;
  static String get settingsCatalogos => _impl.settingsCatalogos;
  static String get settingsFilamentos => _impl.settingsFilamentos;
  static String get settingsImpresoras => _impl.settingsImpresoras;
  static String get settingsAbout => _impl.settingsAbout;
  static String get settingsPrivacy => _impl.settingsPrivacy;
  static String get settingsSaved => _impl.settingsSaved;
  static String get settingsAppearance => _impl.settingsAppearance;
  static String get settingsTheme => _impl.settingsTheme;
  static String get settingsManageFilaments => _impl.settingsManageFilaments;
  static String get settingsManagePrinters => _impl.settingsManagePrinters;

  // === F1: Labor + Post-process ===
  static String get settingsLaborPost => _impl.settingsLaborPost;
  static String settingsLaborRate(String symbol) =>
      _impl.settingsLaborRate(symbol);
  static String get settingsLaborRateHelper => _impl.settingsLaborRateHelper;
  static String get settingsPostProcessRate => _impl.settingsPostProcessRate;
  static String get settingsPostProcessRateHelper =>
      _impl.settingsPostProcessRateHelper;
  static String get settingsFailureRate => _impl.settingsFailureRate;
  static String get settingsFailureRateHelper =>
      _impl.settingsFailureRateHelper;
  static String settingsMinimumCharge(String symbol) =>
      _impl.settingsMinimumCharge(symbol);
  static String get settingsMinimumChargeHelper =>
      _impl.settingsMinimumChargeHelper;
  static String get settingsMarkupOnMaterials =>
      _impl.settingsMarkupOnMaterials;
  static String get settingsMarkupOnMaterialsHelper =>
      _impl.settingsMarkupOnMaterialsHelper;

  // === F4: Currency ===
  static String get settingsCurrency => _impl.settingsCurrency;
  static String get settingsCurrencyHelper => _impl.settingsCurrencyHelper;

  // === Company ===
  static String get settingsCompany => _impl.settingsCompany;
  static String get settingsCompanyName => _impl.settingsCompanyName;
  static String get settingsCompanyNameHelper =>
      _impl.settingsCompanyNameHelper;
  static String get settingsCompanyLogo => _impl.settingsCompanyLogo;
  static String get settingsCompanyLogoPick => _impl.settingsCompanyLogoPick;
  static String get settingsCompanyLogoRemove =>
      _impl.settingsCompanyLogoRemove;
  static String get settingsCompanyLogoError =>
      _impl.settingsCompanyLogoError;

  // === Dashboard ===
  static String get dashboardTitle => _impl.dashboardTitle;
  static String get dashboardErrorLoad => _impl.dashboardErrorLoad;
  static String get dashboardEmpty => _impl.dashboardEmpty;
  static String get dashboardEmptyCta => _impl.dashboardEmptyCta;
  static String get dashboardStatQuotations => _impl.dashboardStatQuotations;
  static String get dashboardStatSold => _impl.dashboardStatSold;
  static String get dashboardStatConversion => _impl.dashboardStatConversion;
  static String get dashboardTotalQuoted => _impl.dashboardTotalQuoted;
  static String get dashboardTotalSold => _impl.dashboardTotalSold;
  static String get dashboardChartTitle => _impl.dashboardChartTitle;
  static String get dashboardChartQuoted => _impl.dashboardChartQuoted;
  static String get dashboardChartSold => _impl.dashboardChartSold;

  // === Home ===
  static String get homeActionNewCalc => _impl.homeActionNewCalc;
  static String get homeActionNewCalcSub => _impl.homeActionNewCalcSub;
  static String get homeActionHistory => _impl.homeActionHistory;
  static String get homeActionHistorySub => _impl.homeActionHistorySub;
  static String get homeActionDashboard => _impl.homeActionDashboard;
  static String get homeActionDashboardSub => _impl.homeActionDashboardSub;
  static String get homeQuickAccess => _impl.homeQuickAccess;
  static String get homeErrorLoadStats => _impl.homeErrorLoadStats;
  static String get homeEmptyQuotations => _impl.homeEmptyQuotations;
  static String get homeSummary => _impl.homeSummary;
  static String get homeSeeAll => _impl.homeSeeAll;

  // === Calculator ===
  static String get calcSectionPiece => _impl.calcSectionPiece;
  static String get calcSectionFilament => _impl.calcSectionFilament;
  static String get calcSectionTime => _impl.calcSectionTime;
  static String get calcSectionDiscount => _impl.calcSectionDiscount;
  static String get calcLabelOptional => _impl.calcLabelOptional;
  static String get calcLabelOptionalHelper => _impl.calcLabelOptionalHelper;
  static String get calcLabelWeight => _impl.calcLabelWeight;
  static String get calcLabelWeightHelper => _impl.calcLabelWeightHelper;
  static String get calcLabelHours => _impl.calcLabelHours;
  static String get calcLabelHoursHelper => _impl.calcLabelHoursHelper;
  static String get calcLabelMinutes => _impl.calcLabelMinutes;
  static String get calcLabelMinutesHelper => _impl.calcLabelMinutesHelper;
  static String get calcLabelDiscount => _impl.calcLabelDiscount;
  static String get calcLabelDiscountHelper => _impl.calcLabelDiscountHelper;
  static String get calcBtnSave => _impl.calcBtnSave;
  static String get calcBtnReset => _impl.calcBtnReset;
  static String get calcToggleShowDetail => _impl.calcToggleShowDetail;
  static String get calcToggleHideDetail => _impl.calcToggleHideDetail;
  static String get calcTotalWithDiscount => _impl.calcTotalWithDiscount;
  static String get calcTotalFinal => _impl.calcTotalFinal;
  static String get calcDetailMaterial => _impl.calcDetailMaterial;
  static String get calcDetailEnergy => _impl.calcDetailEnergy;
  static String get calcDetailLabor => _impl.calcDetailLabor;
  static String get calcDetailPostProcess => _impl.calcDetailPostProcess;
  static String get calcDetailBase => _impl.calcDetailBase;
  static String get calcDetailFailure => _impl.calcDetailFailure;
  static String get calcDetailMarkup => _impl.calcDetailMarkup;
  static String get calcDetailProfit => _impl.calcDetailProfit;
  static String get calcDetailMinimumCharge => _impl.calcDetailMinimumCharge;
  static String get calcDetailTotal => _impl.calcDetailTotal;
  static String get calcEmptyHint => _impl.calcEmptyHint;
  static String get calcSectionMaterials => _impl.calcSectionMaterials;
  static String get calcSectionPrinter => _impl.calcSectionPrinter;
  static String get calcNoPrinter => _impl.calcNoPrinter;
  static String get calcNoMaterials => _impl.calcNoMaterials;

  // === Dynamic empty hint ===
  static String get calcEmptyHintPrefix => _impl.calcEmptyHintPrefix;
  static String get calcEmptyHintSuffix => _impl.calcEmptyHintSuffix;
  static String get calcFieldWeightShort => _impl.calcFieldWeightShort;
  static String get calcFieldPriceShort => _impl.calcFieldPriceShort;
  static String get calcFieldTimeShort => _impl.calcFieldTimeShort;
  static String get calcFieldMaterialShort => _impl.calcFieldMaterialShort;

  // === Summary card meta ===
  static String get calcMetaSeparator => _impl.calcMetaSeparator;

  // === Result sheet ===
  static String get calcResultBarTapHint => _impl.calcResultBarTapHint;
  static String get calcResultBarEmptyHint => _impl.calcResultBarEmptyHint;
  static String get calcSheetTitle => _impl.calcSheetTitle;
  static String get calcBtnShare => _impl.calcBtnShare;
  static String get calcBtnShareTooltip => _impl.calcBtnShareTooltip;
  static String get calcShareError => _impl.calcShareError;
  static String get calcShareSubject => _impl.calcShareSubject;
  static String get calcShareText => _impl.calcShareText;
  static String get calcSheetActionsLabel => _impl.calcSheetActionsLabel;

  // === Filaments / Printers ===
  static String get filamentTitle => _impl.filamentTitle;
  static String get filamentNew => _impl.filamentNew;
  static String get filamentEdit => _impl.filamentEdit;
  static String get filamentName => _impl.filamentName;
  static String get filamentNameHelper => _impl.filamentNameHelper;
  static String get filamentBrand => _impl.filamentBrand;
  static String get filamentBrandHelper => _impl.filamentBrandHelper;
  static String filamentPrice(String symbol) => _impl.filamentPrice(symbol);
  static String get filamentPriceHelper => _impl.filamentPriceHelper;
  static String get filamentGrams => _impl.filamentGrams;
  static String get filamentGramsHelper => _impl.filamentGramsHelper;
  static String get filamentDefaultToggle => _impl.filamentDefaultToggle;
  static String get filamentDefaultSubtitle => _impl.filamentDefaultSubtitle;
  static String get filamentNewTooltip => _impl.filamentNewTooltip;
  static String get filamentDeleteTitle => _impl.filamentDeleteTitle;
  static String get filamentErrorSave => _impl.filamentErrorSave;
  static String get filamentMustBePositive => _impl.filamentMustBePositive;
  static String get filamentMustBeInteger => _impl.filamentMustBeInteger;
  static String get filamentMax100 => _impl.filamentMax100;

  static String get printerTitle => _impl.printerTitle;
  static String get printerNew => _impl.printerNew;
  static String get printerEdit => _impl.printerEdit;
  static String get printerModel => _impl.printerModel;
  static String get printerModelHelper => _impl.printerModelHelper;
  static String get printerBrandHelper => _impl.printerBrandHelper;
  static String get printerWatts => _impl.printerWatts;
  static String get printerWattsHelper => _impl.printerWattsHelper;
  static String get printerDefaultSubtitle => _impl.printerDefaultSubtitle;
  static String get printerNewTooltip => _impl.printerNewTooltip;
  static String get printerDeleteTitle => _impl.printerDeleteTitle;
  static String get printerMustBeNonNegative =>
      _impl.printerMustBeNonNegative;

  // === Calculator output ===
  static String get calcNotifFilament => _impl.calcNotifFilament;
  static String get calcNotifMaterial => _impl.calcNotifMaterial;

  // === Detail page ===
  static String get calcDetailTitle => _impl.calcDetailTitle;
  static String get calcDetailDelete => _impl.calcDetailDelete;
  static String get calcDetailDeleteTitle => _impl.calcDetailDeleteTitle;
  static String get calcDetailDeleteConfirm => _impl.calcDetailDeleteConfirm;
  static String get calcDetailNoName => _impl.calcDetailNoName;
  static String get calcDetailSold => _impl.calcDetailSold;
  static String get calcDetailReuse => _impl.calcDetailReuse;
  static String get calcDetailMarkSold => _impl.calcDetailMarkSold;
  static String get calcDetailMarkPending => _impl.calcDetailMarkPending;

  // === History ===
  static String get historyTitle => _impl.historyTitle;
  static String get historyErrorLoad => _impl.historyErrorLoad;
  static String get historyEmpty => _impl.historyEmpty;

  // === Locale ===
  static String get localeLabel => _impl.localeLabel;
  static String get localeEs => _impl.localeEs;
  static String get localeEn => _impl.localeEn;

  // === Onboarding ===
  static String get onboardingTitle1 => _impl.onboardingTitle1;
  static String get onboardingDesc1 => _impl.onboardingDesc1;
  static String get onboardingTitle2 => _impl.onboardingTitle2;
  static String get onboardingDesc2 => _impl.onboardingDesc2;
  static String get onboardingTitle3 => _impl.onboardingTitle3;
  static String get onboardingDesc3 => _impl.onboardingDesc3;
  static String get onboardingTitle4 => _impl.onboardingTitle4;
  static String get onboardingDesc4 => _impl.onboardingDesc4;
  static String get onboardingNext => _impl.onboardingNext;
  static String get onboardingSkip => _impl.onboardingSkip;
  static String get onboardingStart => _impl.onboardingStart;

  // === Initial config ===
  static String get configTitle => _impl.configTitle;
  static String get configLanguage => _impl.configLanguage;
  static String get configCurrency => _impl.configCurrency;
  static String get configContinue => _impl.configContinue;
}

// ─── Implementacion espanol ─────────────────────

class EsImpl implements AppStrings {
  const EsImpl();

  @override
  String get appName => '3dcalc';

  @override
  String get commonSave => 'Guardar';
  @override
  String get commonCancel => 'Cancelar';
  @override
  String get commonDelete => 'Eliminar';
  @override
  String get commonRetry => 'Reintentar';
  @override
  String get commonEdit => 'Editar';
  @override
  String get commonNew => 'Nuevo';
  @override
  String get commonRequired => 'Requerido';
  @override
  String get commonInvalidNumber => 'Numero invalido';
  @override
  String get commonLoading => 'Cargando...';
  @override
  String get commonErrorGeneric =>
      'Algo salio mal. Intenta de nuevo.';

  @override
  String get navHome => 'Inicio';
  @override
  String get navHistory => 'Historial';
  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get settingsGlobalParams => 'Parametros globales';
  @override
  String get settingsProfitBase => 'Ganancia base (%)';
  @override
  String get settingsProfitBaseHelper =>
      'Margen sobre costo base. 0-1000';
  @override
  String settingsKwhRate(String symbol) =>
      'Tarifa electrica ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper =>
      'Rango residencial Bolivia: 0.10-5.00';
  @override
  String get settingsCatalogos => 'Catalogos';
  @override
  String get settingsFilamentos => 'Filamentos';
  @override
  String get settingsImpresoras => 'Impresoras';
  @override
  String get settingsAbout => 'Acerca de';
  @override
  String get settingsPrivacy =>
      'Privacidad: 100% local, sin telemetria';
  @override
  String get settingsSaved => 'Guardado';
  @override
  String get settingsAppearance => 'Apariencia';
  @override
  String get settingsTheme => 'Tema';
  @override
  String get settingsManageFilaments =>
      'Gestiona tus filamentos';
  @override
  String get settingsManagePrinters =>
      'Registra tus impresoras';

  @override
  String get settingsLaborPost =>
      'Mano de obra y post-procesado';
  @override
  String settingsLaborRate(String symbol) =>
      'Mano de obra ($symbol/hora)';
  @override
  String get settingsLaborRateHelper =>
      'Costo operador/tecnico por hora de impresion. 0 = desactivado';
  @override
  String get settingsPostProcessRate => 'Post-procesado (%)';
  @override
  String get settingsPostProcessRateHelper =>
      '% del costo de materiales. Ej: 10 = +10% en acabado/lijado/pintura';
  @override
  String get settingsFailureRate => 'Tasa de falla (%)';
  @override
  String get settingsFailureRateHelper =>
      '% del costo base para cubrir impresiones fallidas. 0 = desactivado';
  @override
  String settingsMinimumCharge(String symbol) =>
      'Cargo minimo ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Cotizaciones por debajo de este monto se ajustan automaticamente';
  @override
  String get settingsMarkupOnMaterials =>
      'Markup desperdicio (%)';
  @override
  String get settingsMarkupOnMaterialsHelper =>
      '% extra sobre costo de materiales por desperdicio/desgaste';

  @override
  String get settingsCurrency => 'Moneda';
  @override
  String get settingsCurrencyHelper =>
      'Define la moneda que se muestra en precios, cotizaciones y dashboard. Sin conversion automatica.';

  @override
  String get settingsCompany => 'Empresa';
  @override
  String get settingsCompanyName => 'Nombre de la empresa';
  @override
  String get settingsCompanyNameHelper =>
      'Aparece en la cotizacion. Default: 3dCalc';
  @override
  String get settingsCompanyLogo => 'Logo';
  @override
  String get settingsCompanyLogoPick =>
      'Seleccionar imagen';
  @override
  String get settingsCompanyLogoRemove =>
      'Eliminar logo';
  @override
  String get settingsCompanyLogoError =>
      'Error al cargar la imagen';

  @override
  String get dashboardTitle => 'Dashboard';
  @override
  String get dashboardErrorLoad =>
      'Error al cargar el dashboard';
  @override
  String get dashboardEmpty => 'Aun no cotizaste nada';
  @override
  String get dashboardEmptyCta => 'Ir a Home';
  @override
  String get dashboardStatQuotations => 'Cotizaciones';
  @override
  String get dashboardStatSold => 'Vendidas';
  @override
  String get dashboardStatConversion => 'Conversion';
  @override
  String get dashboardTotalQuoted => 'Total cotizado';
  @override
  String get dashboardTotalSold => 'Total vendido';
  @override
  String get dashboardChartTitle => 'Cotizado vs Ganado';
  @override
  String get dashboardChartQuoted => 'Cotizado';
  @override
  String get dashboardChartSold => 'Ganado';

  @override
  String get homeActionNewCalc => 'Nueva cotizacion';
  @override
  String get homeActionNewCalcSub =>
      'Calcula precio de impresion';
  @override
  String get homeActionHistory => 'Historial';
  @override
  String get homeActionHistorySub =>
      'Cotizaciones guardadas';
  @override
  String get homeActionDashboard => 'Dashboard';
  @override
  String get homeActionDashboardSub =>
      'Estadisticas y graficos';
  @override
  String get homeQuickAccess => 'Acceso rapido';
  @override
  String get homeErrorLoadStats =>
      'Error cargando stats';
  @override
  String get homeEmptyQuotations =>
      'Todavia no hay cotizaciones';
  @override
  String get homeSummary => 'Resumen';
  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String get calcSectionPiece => 'Pieza';
  @override
  String get calcSectionFilament => 'Filamento';
  @override
  String get calcSectionTime => 'Tiempo de impresion';
  @override
  String get calcSectionDiscount => 'Descuento';
  @override
  String get calcLabelOptional => 'Etiqueta (opcional)';
  @override
  String get calcLabelOptionalHelper =>
      'Ej: Soporte pared, Engranaje PETG';
  @override
  String get calcLabelWeight => 'Peso de la pieza';
  @override
  String get calcLabelWeightHelper =>
      'Gramos del modelo';
  @override
  String get calcLabelHours => 'Horas';
  @override
  String get calcLabelHoursHelper => '0-24';
  @override
  String get calcLabelMinutes => 'Minutos';
  @override
  String get calcLabelMinutesHelper => '0-59';
  @override
  String get calcLabelDiscount => 'Descuento';
  @override
  String get calcLabelDiscountHelper =>
      'Porcentaje sobre el total final';
  @override
  String get calcBtnSave => 'Guardar cotizacion';
  @override
  String get calcBtnReset => 'Restablecer valores';
  @override
  String get calcToggleShowDetail => 'Ver detalle';
  @override
  String get calcToggleHideDetail => 'Ocultar detalle';
  @override
  String get calcTotalWithDiscount =>
      'Total con descuento';
  @override
  String get calcTotalFinal => 'Total';
  @override
  String get calcDetailMaterial => 'Costo material';
  @override
  String get calcDetailEnergy => 'Costo energia';
  @override
  String get calcDetailLabor => 'Mano de obra';
  @override
  String get calcDetailPostProcess =>
      'Post-procesado';
  @override
  String get calcDetailBase => 'Costo base';
  @override
  String get calcDetailFailure => 'Tasa falla';
  @override
  String get calcDetailMarkup => 'Markup desperdicio';
  @override
  String get calcDetailProfit => 'Ganancia';
  @override
  String get calcDetailMinimumCharge =>
      'Cargo minimo';
  @override
  String get calcDetailTotal => 'Total';
  @override
  String get calcEmptyHint =>
      'Completa peso, filamento y horas para ver el precio';
  @override
  String get calcSectionMaterials => 'Materiales';
  @override
  String get calcSectionPrinter => 'Impresora';
  @override
  String get calcNoPrinter => 'Sin impresora registrada';
  @override
  String get calcNoMaterials => 'Sin materiales.';

  @override
  String get calcEmptyHintPrefix => 'Completa';
  @override
  String get calcEmptyHintSuffix =>
      'para ver la cotizacion';
  @override
  String get calcFieldWeightShort =>
      'peso de la pieza';
  @override
  String get calcFieldPriceShort =>
      'precio del filamento';
  @override
  String get calcFieldTimeShort =>
      'tiempo de impresion';
  @override
  String get calcFieldMaterialShort =>
      'al menos un material';

  @override
  String get calcMetaSeparator => ' · ';

  @override
  String get calcResultBarTapHint => 'Ver cotizacion';
  @override
  String get calcResultBarEmptyHint =>
      'Falta completar';
  @override
  String get calcSheetTitle => 'Cotizacion';
  @override
  String get calcBtnShare => 'Compartir imagen';
  @override
  String get calcBtnShareTooltip =>
      'Genera una imagen lista para enviar';
  @override
  String get calcShareError =>
      'No se pudo generar la imagen';
  @override
  String get calcShareSubject => 'Cotizacion 3D';
  @override
  String get calcShareText =>
      'Cotizacion generada en 3dCalc';
  @override
  String get calcSheetActionsLabel => 'Acciones';

  @override
  String get filamentTitle => 'Filamentos';
  @override
  String get filamentNew => 'Nuevo filamento';
  @override
  String get filamentEdit => 'Editar filamento';
  @override
  String get filamentName => 'Nombre';
  @override
  String get filamentNameHelper => 'Ej: PLA Negro';
  @override
  String get filamentBrand => 'Marca';
  @override
  String get filamentBrandHelper => 'Opcional';
  @override
  String filamentPrice(String symbol) =>
      'Precio filamento ($symbol)';
  @override
  String get filamentPriceHelper =>
      'Costo del rollo completo';
  @override
  String get filamentGrams => 'Gramos por rollo';
  @override
  String get filamentGramsHelper =>
      'Tipico 1000';
  @override
  String get filamentDefaultToggle =>
      'Marcar como default';
  @override
  String get filamentDefaultSubtitle =>
      'Se usara en nuevas cotizaciones. Solo un filamento puede ser default.';
  @override
  String get filamentNewTooltip => 'Nuevo filamento';
  @override
  String get filamentDeleteTitle =>
      'Eliminar filamento';
  @override
  String get filamentErrorSave => 'Error guardando';
  @override
  String get filamentMustBePositive =>
      'Debe ser > 0';
  @override
  String get filamentMustBeInteger =>
      'Debe ser entero';
  @override
  String get filamentMax100 =>
      'Maximo 100 caracteres';

  @override
  String get printerTitle => 'Impresoras';
  @override
  String get printerNew => 'Nueva impresora';
  @override
  String get printerEdit => 'Editar impresora';
  @override
  String get printerModel => 'Modelo';
  @override
  String get printerModelHelper => 'Ej: Ender 3 V2';
  @override
  String get printerBrandHelper =>
      'Ej: Creality, Anycubic';
  @override
  String get printerWatts =>
      'Consumo promedio (W)';
  @override
  String get printerWattsHelper =>
      'Tipico 100-300 W';
  @override
  String get printerDefaultSubtitle =>
      'Se usara en nuevas cotizaciones. Solo una impresora puede ser default.';
  @override
  String get printerNewTooltip =>
      'Nueva impresora';
  @override
  String get printerDeleteTitle =>
      'Eliminar impresora';
  @override
  String get printerMustBeNonNegative =>
      'Debe ser >= 0';

  @override
  String get calcNotifFilament => 'Filamento';
  @override
  String get calcNotifMaterial => 'Material';

  @override
  String get calcDetailTitle =>
      'Detalle cotizacion';
  @override
  String get calcDetailDelete => 'Eliminar';
  @override
  String get calcDetailDeleteTitle =>
      'Eliminar cotizacion';
  @override
  String get calcDetailDeleteConfirm =>
      '�Eliminar definitivamente?';
  @override
  String get calcDetailNoName => 'Sin nombre';
  @override
  String get calcDetailSold => 'Vendida';
  @override
  String get calcDetailReuse => 'Reusar';
  @override
  String get calcDetailMarkSold =>
      'Marcar vendida';
  @override
  String get calcDetailMarkPending =>
      'Marcar pendiente';

  @override
  String get historyTitle => 'Cotizaciones';
  @override
  String get historyErrorLoad =>
      'Error cargando cotizaciones';
  @override
  String get historyEmpty =>
      'Sin cotizaciones guardadas';

  @override
  String get localeLabel => 'Idioma';
  @override
  String get localeEs => 'Espanol';
  @override
  String get localeEn => 'Ingles';
  @override
  String get onboardingTitle1 => 'Bienvenido a 3dCalc';
  @override
  String get onboardingDesc1 => 'Calcula el precio de impresiones 3D al instante.\nMateriales, electricidad, mano de obra y mas.';
  @override
  String get onboardingTitle2 => 'Dos modos de calculo';
  @override
  String get onboardingDesc2 => 'Express: calculo rapido con un solo material.\nAdvanced: multiple materiales, descuento y mas parametros.';
  @override
  String get onboardingTitle3 => 'Catalogo integrado';
  @override
  String get onboardingDesc3 => 'Guarda tus filamentos e impresoras favoritos.\nSeleccionalos al instante desde el catalogo.';
  @override
  String get onboardingTitle4 => 'Dashboard & mas';
  @override
  String get onboardingDesc4 => 'Seguimiento de cotizaciones, tendencias mensuales,\nexportacion a PDF e historial con busqueda.';
  @override
  String get onboardingNext => 'Siguiente';
  @override
  String get onboardingSkip => 'Saltar';
  @override
  String get onboardingStart => 'Comenzar';
  @override
  String get configTitle => 'Configuracion inicial';
  @override
  String get configLanguage => 'Idioma';
  @override
  String get configCurrency => 'Moneda';
  @override
  String get configContinue => 'Continuar';
}
