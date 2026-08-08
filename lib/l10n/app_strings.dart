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

  // === Branding gate (T12 — ver docs/plans/2026-07-22_1100-free-pro-monetization) ===
  /// Body del SnackBar que se muestra cuando un usuario Free intenta
  /// editar el nombre o logo de empresa. Acompana al [settingsGoProAction].
  String get settingsBrandingLockedBody;

  /// Label del action del SnackBar del gate de branding. Al tap, navega
  /// a `/paywall`.
  String get settingsGoProAction;

  /// Texto del badge "Pro" que aparece en la seccion Empresa para usuarios
  /// Free. Senal visual de que esa seccion esta gateada.
  String get settingsProBadge;

  /// Label del boton "Restaurar compras" en settings.
  String get settingsRestorePurchases;

  /// Mensaje de exito tras un restore que encontro compras previas.
  String get settingsRestoreSuccess;

  /// Mensaje tras un restore que no encontro compras previas o dio error.
  String get settingsRestoreEmpty;

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
  // T17
  String get dashboardProTeaserTitle;
  String get dashboardProTeaserBody;
  String get dashboardGoProAction;

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

  // === Key field hints (campos indispensables) ===
  String get calcKeyWeightHint;
  String get calcKeyHoursHint;
  String get calcKeyMinutesHint;

  // === Material row (Advanced / Express calculator) ===
  String calcMaterialTitle(int index);
  String calcMaterialRemove(int index);
  String get calcMaterialCatalog;
  String calcMaterialUse(String filamentName);
  String get calcFieldLabel;
  String get calcFieldLabelHelper;
  String get calcFieldWeight;
  String get calcFieldSpoolPrice;
  String get calcFieldSpoolGrams;

  // === Otros / extras (seccion final) ===
  String get calcFieldLabor;
  String get calcFieldLaborHelper;
  String get calcFieldPostProcess;
  String get calcFieldPostProcessHelper;
  String get calcFieldFailure;
  String get calcFieldFailureHelper;
  String get calcFieldWaste;
  String get calcFieldWasteHelper;

  // === Calculator modes ===
  String get calcModeExpress;
  String get calcModeAdvanced;
  String calcSemanticMode(String mode);

  // === Action labels ===
  String get calcActionReset;

  // === Save dialog ===
  String get calcDialogClient;
  String get calcDialogClientHelper;

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

  // === CSV export gate (T16 — ver docs/plans/2026-07-22_1100-free-pro-monetization) ===
  /// Body del SnackBar que se muestra cuando un usuario Free intenta
  /// exportar a CSV. Acompana al [csvGoProAction] en el action del SnackBar.
  String get csvExportLockedBody;

  /// Label del action del SnackBar del gate CSV. Al tap, navega a
  /// `/paywall` (no es required: las Apple/Google guidelines piden restore
  /// visible, no necesariamente un upsell — pero ayuda a la conversion).
  String get csvGoProAction;

  // === Locale ===
  String get localeLabel;
  String get localeEs;
  String get localeEn;

  // === Onboarding ===
  String get onboardingTitle1;
  String get onboardingDesc1;
  String get onboardingTitle2;
  String get onboardingDesc2;
  String get onboardingTitle3;
  String get onboardingDesc3;
  String get onboardingTitle4;
  String get onboardingDesc4;
  String get onboardingNext;
  String get onboardingSkip;
  String get onboardingStart;

  // === Initial config ===
  String get configTitle;
  String get configLanguage;
  String get configCurrency;
  String get configContinue;

  // === Feature gates (T14 — multi-material calculator gate) ===
  /// Body del SnackBar que se muestra cuando un Free user intenta
  /// cambiar a CalculatorMode.advanced.
  String get calculatorAdvancedLockedBody;
  /// Label de la accion del SnackBar — al tap, navega a /paywall.
  String get calculatorGoProAction;

  // === History cap gate (T15) ===
  /// Body del SnackBar cuando un Free user intenta guardar la cotizacion
  /// #11 (kFreeHistoryCap + 1). Accion navega a /paywall.
  String get historyCapReachedBody;

  // === Paywall (T10) ===
  /// Titulo del paywall. Hero del modal.
  String get paywallTitle;
  /// Subtitulo del paywall. Aparece debajo del titulo.
  String get paywallSubtitle;
  /// Precio displayed (ej: "\$4.99"). String estatico, no formateado por locale.
  String get paywallPrice;
  /// Lista de features Pro que muestra el paywall.
  List<String> get paywallFeatures;
  /// Label del CTA principal. [price] ya viene formateado.
  String paywallUnlockButton(String price);
  /// Label del CTA secundario. Abre el flow de restore.
  String get paywallRestoreButton;
  /// Mensaje de error generico si la compra falla.
  String get paywallErrorGeneric;
  /// Mensaje que ve un user Pro cuando abre el paywall.
  String get paywallAlreadyPro;
  /// Tooltip del icono de cerrar (AppBar action).
  String get paywallClose;

  // === Store compliance links (T22) ===
  /// Label del link a Privacy Policy en paywall y settings.
  String get paywallPrivacyPolicy;
  /// Label del link a Terms of Service en paywall y settings.
  String get paywallTermsOfService;
  /// Titulo de la seccion legal en settings page.
  String get settingsLegal;
}
