/// Interfaz de strings localizados.
///
/// [EsBO] delega a una implementacion concreta segun el locale activo.
library;

abstract class AppStrings {
  const AppStrings();

  // === App ===
  String get appName;

  // === Common verbs ===
  String get commonSave;
  String get commonCancel;
  String get commonDelete;
  String get commonRetry;
  String get commonEdit;
  String get commonNew;
  String get commonRequired;
  String get commonInvalidNumber;
  String get commonLoading;
  String get commonErrorGeneric;

  // === Navigation ===
  String get navHome;
  String get navHistory;
  String get navDashboard;
  String get navSettings;

  // === Settings ===
  String get settingsTitle;
  String get settingsGlobalParams;
  String get settingsProfitBase;
  String get settingsProfitBaseHelper;
  String settingsKwhRate(String symbol);
  String get settingsKwhRateHelper;
  String get settingsCatalogos;
  String get settingsFilamentos;
  String get settingsImpresoras;
  String get settingsAbout;
  String get settingsPrivacy;
  String get settingsSaved;
  String get settingsAppearance;
  String get settingsTheme;
  String get settingsManageFilaments;
  String get settingsManagePrinters;

  // === F1: Labor + Post-process ===
  String get settingsLaborPost;
  String settingsLaborRate(String symbol);
  String get settingsLaborRateHelper;
  String get settingsPostProcessRate;
  String get settingsPostProcessRateHelper;
  String get settingsFailureRate;
  String get settingsFailureRateHelper;
  String settingsMinimumCharge(String symbol);
  String get settingsMinimumChargeHelper;
  String get settingsMarkupOnMaterials;
  String get settingsMarkupOnMaterialsHelper;

  // === F4: Currency ===
  String get settingsCurrency;
  String get settingsCurrencyHelper;

  // === Company settings ===
  String get settingsCompany;
  String get settingsCompanyName;
  String get settingsCompanyNameHelper;
  String get settingsCompanyLogo;
  String get settingsCompanyLogoPick;
  String get settingsCompanyLogoRemove;
  String get settingsCompanyLogoError;

  // === Dashboard ===
  String get dashboardTitle;
  String get dashboardErrorLoad;
  String get dashboardEmpty;
  String get dashboardEmptyCta;
  String get dashboardStatQuotations;
  String get dashboardStatSold;
  String get dashboardStatConversion;
  String get dashboardTotalQuoted;
  String get dashboardTotalSold;
  String get dashboardChartTitle;
  String get dashboardChartQuoted;
  String get dashboardChartSold;

  // === Home / Quick actions ===
  String get homeActionNewCalc;
  String get homeActionNewCalcSub;
  String get homeActionHistory;
  String get homeActionHistorySub;
  String get homeActionDashboard;
  String get homeActionDashboardSub;
  String get homeQuickAccess;
  String get homeErrorLoadStats;
  String get homeEmptyQuotations;
  String get homeSummary;
  String get homeSeeAll;

  // === Calculator sections + fields ===
  String get calcSectionPiece;
  String get calcSectionFilament;
  String get calcSectionTime;
  String get calcSectionDiscount;
  String get calcLabelOptional;
  String get calcLabelOptionalHelper;
  String get calcLabelWeight;
  String get calcLabelWeightHelper;
  String get calcLabelHours;
  String get calcLabelHoursHelper;
  String get calcLabelMinutes;
  String get calcLabelMinutesHelper;
  String get calcLabelDiscount;
  String get calcLabelDiscountHelper;
  String get calcBtnSave;
  String get calcBtnReset;
  String get calcToggleShowDetail;
  String get calcToggleHideDetail;
  String get calcTotalWithDiscount;
  String get calcTotalFinal;
  String get calcDetailMaterial;
  String get calcDetailEnergy;
  String get calcDetailLabor;
  String get calcDetailPostProcess;
  String get calcDetailBase;
  String get calcDetailFailure;
  String get calcDetailMarkup;
  String get calcDetailProfit;
  String get calcDetailMinimumCharge;
  String get calcDetailTotal;
  String get calcSectionMaterials;
  String get calcSectionPrinter;
  String get calcNoPrinter;
  String get calcNoMaterials;
  String get calcEmptyHint;

  // === Dynamic empty hint ===
  String get calcEmptyHintPrefix;
  String get calcEmptyHintSuffix;
  String get calcFieldWeightShort;
  String get calcFieldPriceShort;
  String get calcFieldTimeShort;
  String get calcFieldMaterialShort;

  // === Summary card meta ===
  String get calcMetaSeparator;

  // === Result sheet / sticky bar ===
  String get calcResultBarTapHint;
  String get calcResultBarEmptyHint;
  String get calcSheetTitle;
  String get calcBtnShare;
  String get calcBtnShareTooltip;
  String get calcShareError;
  String get calcShareSubject;
  String get calcShareText;
  String get calcSheetActionsLabel;

  // === Filaments / Printers forms ===
  String get filamentTitle;
  String get filamentNew;
  String get filamentEdit;
  String get filamentName;
  String get filamentNameHelper;
  String get filamentBrand;
  String get filamentBrandHelper;
  String filamentPrice(String symbol);
  String get filamentPriceHelper;
  String get filamentGrams;
  String get filamentGramsHelper;
  String get filamentDefaultToggle;
  String get filamentDefaultSubtitle;
  String get filamentNewTooltip;
  String get filamentDeleteTitle;
  String get filamentErrorSave;
  String get filamentMustBePositive;
  String get filamentMustBeInteger;
  String get filamentMax100;

  String get printerTitle;
  String get printerNew;
  String get printerEdit;
  String get printerModel;
  String get printerModelHelper;
  String get printerBrandHelper;
  String get printerWatts;
  String get printerWattsHelper;
  String get printerDefaultSubtitle;
  String get printerNewTooltip;
  String get printerDeleteTitle;
  String get printerMustBeNonNegative;

  // === Calculator output + notifier labels ===
  String get calcNotifFilament;
  String get calcNotifMaterial;

  // === Calculation detail page ===
  String get calcDetailTitle;
  String get calcDetailDelete;
  String get calcDetailDeleteTitle;
  String get calcDetailDeleteConfirm;
  String get calcDetailNoName;
  String get calcDetailSold;
  String get calcDetailReuse;
  String get calcDetailMarkSold;
  String get calcDetailMarkPending;

  // === History / Calculations list ===
  String get historyTitle;
  String get historyErrorLoad;
  String get historyEmpty;

  // === Locale ===
  String get localeLabel;
  String get localeEs;
  String get localeEn;
}
