// ignore_for_file: public_member_api_docs
/// Strings en espanol (es_BO).
///
/// [EsBO] es la API publica — todas las call sites existentes siguen usando
/// `EsBO.xxx`. Internamente delega a la implementacion del locale activo.
library;

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';

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
  static String get commonCreateNew => _impl.commonCreateNew;
  static String get commonAddToCatalog => _impl.commonAddToCatalog;
  static String get commonRequired => _impl.commonRequired;
  static String get commonInvalidNumber => _impl.commonInvalidNumber;
  static String get commonLoading => _impl.commonLoading;
  static String get commonErrorGeneric => _impl.commonErrorGeneric;

  // === Navigation ===
  static String get navHome => _impl.navHome;
  static String get navHistory => _impl.navHistory;
  static String get navPrint => _impl.navPrint;
  static String get navDashboard => _impl.navDashboard;
  static String get navSettings => _impl.navSettings;

  // === Settings ===
  static String get settingsTitle => _impl.settingsTitle;
  static String get settingsGlobalParams => _impl.settingsGlobalParams;
  static String get settingsProfitBase => _impl.settingsProfitBase;
  static String get settingsProfitBaseHelper => _impl.settingsProfitBaseHelper;
  static String get settingsProfitBaseInfo => _impl.settingsProfitBaseInfo;
  static String settingsKwhRate(String symbol) => _impl.settingsKwhRate(symbol);
  static String get settingsKwhRateHelper => _impl.settingsKwhRateHelper;
  static String get settingsKwhRateInfo => _impl.settingsKwhRateInfo;
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

  // === Print settings page ===
  static String get settingsPrintConfigTitle =>
      _impl.settingsPrintConfigTitle;
  static String get settingsPrintConfigSubtitle =>
      _impl.settingsPrintConfigSubtitle;

  // === Settings page section group labels (uppercase headers) ===
  static String get settingsGroupCatalogs => _impl.settingsGroupCatalogs;
  static String get settingsGroupCurrencyAndLanguage =>
      _impl.settingsGroupCurrencyAndLanguage;
  static String get settingsGroupAppearance => _impl.settingsGroupAppearance;
  static String get settingsGroupYourData => _impl.settingsGroupYourData;
  static String get settingsGroupAccount => _impl.settingsGroupAccount;
  static String get settingsGroupAbout => _impl.settingsGroupAbout;

  // === Hito 1: lotes y reorganización (T-H1) ===
  static String get calcSectionPieceCosts => _impl.calcSectionPieceCosts;
  static String get calcSectionTarifas => _impl.calcSectionTarifas;
  static String get settingsGroupEnergy => _impl.settingsGroupEnergy;
  static String get settingsGroupPrintingCosts =>
      _impl.settingsGroupPrintingCosts;
  static String get settingsGroupDiscountTiers =>
      _impl.settingsGroupDiscountTiers;
  static String get discountTierAdd => _impl.discountTierAdd;
  static String get discountTierEdit => _impl.discountTierEdit;
  static String get discountTierDelete => _impl.discountTierDelete;
  static String get discountTierEmpty => _impl.discountTierEmpty;
  static String get discountTierHeaderMinQty => _impl.discountTierHeaderMinQty;
  static String get discountTierHeaderPercent =>
      _impl.discountTierHeaderPercent;
  static String get discountTierMinQty => _impl.discountTierMinQty;
  static String get discountTierPercent => _impl.discountTierPercent;
  static String get discountTierValidationMinQty =>
      _impl.discountTierValidationMinQty;
  static String get discountTierValidationPercent =>
      _impl.discountTierValidationPercent;
  static String get discountTierCapHint => _impl.discountTierCapHint;
  static String calcDetailBatchDiscount(int pct) =>
      _impl.calcDetailBatchDiscount(pct);
  static String get calcSubtotal => _impl.calcSubtotal;
  static String calcDetailManualDiscount(int pct) =>
      _impl.calcDetailManualDiscount(pct);
  static String calcQuantityBatchHint(int pct, int minQty) =>
      _impl.calcQuantityBatchHint(pct, minQty);
  static String get calcQuantityNoTiers => _impl.calcQuantityNoTiers;
  static String get calcQuantityTiersTitle => _impl.calcQuantityTiersTitle;
  static String get calcQuantityFrom => _impl.calcQuantityFrom;
  static String get calcQuantityUnits => _impl.calcQuantityUnits;
  static String quoteBatchDiscountPct(int pct) =>
      _impl.quoteBatchDiscountPct(pct);
  static String pdfBatchDiscountPct(int pct) => _impl.pdfBatchDiscountPct(pct);

  static String settingsFilamentsCount(int count) =>
      _impl.settingsFilamentsCount(count);
  static String settingsPrintersCount(int count) =>
      _impl.settingsPrintersCount(count);
  static String get settingsGainMultiplierSuffix =>
      _impl.settingsGainMultiplierSuffix;

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
  static String get settingsCompanyLogoError => _impl.settingsCompanyLogoError;

  // === Branding gate (T12) ===
  static String get settingsBrandingLockedBody =>
      _impl.settingsBrandingLockedBody;
  static String get settingsGoProAction => _impl.settingsGoProAction;
  static String get settingsProTitle => _impl.settingsProTitle;
  static String get settingsProUnlocked => _impl.settingsProUnlocked;
  static String get settingsProNoAdditionalPurchase =>
      _impl.settingsProNoAdditionalPurchase;
  static String get settingsProFutureUpdates => _impl.settingsProFutureUpdates;
  static String get settingsProRestorePurchase =>
      _impl.settingsProRestorePurchase;

  static String get settingsRestorePurchases => _impl.settingsRestorePurchases;
  static String get settingsRestoreSuccess => _impl.settingsRestoreSuccess;
  static String get settingsRestoreEmpty => _impl.settingsRestoreEmpty;
  static String get settingsRestoreError => _impl.settingsRestoreError;

  // === Backup ===
  static String get settingsBackupTitle => _impl.settingsBackupTitle;
  static String get settingsBackupExport => _impl.settingsBackupExport;
  static String get settingsBackupImport => _impl.settingsBackupImport;
  static String get settingsBackupHelper => _impl.settingsBackupHelper;
  static String get settingsBackupExportSuccess =>
      _impl.settingsBackupExportSuccess;
  static String get settingsBackupExportError =>
      _impl.settingsBackupExportError;
  static String settingsBackupImportSuccess(
    int calcs,
    int filaments,
    int printers,
  ) => _impl.settingsBackupImportSuccess(calcs, filaments, printers);
  static String get settingsBackupImportError =>
      _impl.settingsBackupImportError;
  static String get settingsBackupImportConfirmTitle =>
      _impl.settingsBackupImportConfirmTitle;
  static String settingsBackupImportConfirmBody(String summary) =>
      _impl.settingsBackupImportConfirmBody(summary);
  static String get settingsBackupImportConfirm =>
      _impl.settingsBackupImportConfirm;
  static String get settingsBackupImportCancel =>
      _impl.settingsBackupImportCancel;
  static String get settingsBackupImportSizeError =>
      _impl.settingsBackupImportSizeError;
  static String get settingsBackupImportInvalidFile =>
      _impl.settingsBackupImportInvalidFile;
  static String get settingsBackupImportFutureVersion =>
      _impl.settingsBackupImportFutureVersion;
  static String get settingsBackupLockedBody => _impl.settingsBackupLockedBody;

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
  // T17
  static String get dashboardProTeaserTitle => _impl.dashboardProTeaserTitle;
  static String get dashboardProTeaserBody => _impl.dashboardProTeaserBody;
  static String get dashboardGoProAction => _impl.dashboardGoProAction;

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
  static String get homeRecentTitle => _impl.homeRecentTitle;
  static String get homeEmptyCta => _impl.homeEmptyCta;
  static String get homeDraftTitle => _impl.homeDraftTitle;
  static String get homeDraftBody => _impl.homeDraftBody;
  static String get homeDraftContinue => _impl.homeDraftContinue;
  static String get homeCatalogsTitle => _impl.homeCatalogsTitle;

  // === Calculator ===
  static String get calcSectionPiece => _impl.calcSectionPiece;
  static String get calcSectionWeight => _impl.calcSectionWeight;
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
  static String get calcWizardStepPrint => _impl.calcWizardStepPrint;
  static String get calcWizardStepAdjust => _impl.calcWizardStepAdjust;
  static String get calcWizardFullBreakdown => _impl.calcWizardFullBreakdown;
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
  static String get detailQuantityLabel => _impl.detailQuantityLabel;
  static String get detailQuantitySubtitle => _impl.detailQuantitySubtitle;
  static String get resultQuantityLabel => _impl.resultQuantityLabel;
  static String get calcEmptyHint => _impl.calcEmptyHint;
  static String get calcSectionMaterials => _impl.calcSectionMaterials;
  static String get calcSectionPrinter => _impl.calcSectionPrinter;
  static String get calcNoPrinter => _impl.calcNoPrinter;
  static String get calcPrinterEmptyCta => _impl.calcPrinterEmptyCta;
  static String get calcPrinterEmptyHint => _impl.calcPrinterEmptyHint;
  static String get calcNoMaterials => _impl.calcNoMaterials;

  // === Key field hints (campos indispensables) ===
  static String get calcKeyWeightHint => _impl.calcKeyWeightHint;
  static String get calcKeyHoursHint => _impl.calcKeyHoursHint;
  static String get calcKeyMinutesHint => _impl.calcKeyMinutesHint;

  // === Material row (Advanced / Express calculator) ===
  static String calcMaterialTitle(int index) => _impl.calcMaterialTitle(index);
  static String calcMaterialRemove(int index) =>
      _impl.calcMaterialRemove(index);
  static String get calcMaterialCatalog => _impl.calcMaterialCatalog;
  static String calcMaterialUse(String filamentName) =>
      _impl.calcMaterialUse(filamentName);
  static String get calcFieldLabel => _impl.calcFieldLabel;
  static String get calcFieldLabelHelper => _impl.calcFieldLabelHelper;
  static String get calcFieldFilament => _impl.calcFieldFilament;
  static String get calcFieldWeight => _impl.calcFieldWeight;
  static String get calcFieldSpoolPrice => _impl.calcFieldSpoolPrice;
  static String get calcFieldSpoolGrams => _impl.calcFieldSpoolGrams;

  // === Otros / extras (seccion final) ===
  static String get calcFieldLabor => _impl.calcFieldLabor;
  static String get calcFieldLaborHelper => _impl.calcFieldLaborHelper;
  static String get calcFieldPostProcess => _impl.calcFieldPostProcess;
  static String get calcFieldPostProcessHelper =>
      _impl.calcFieldPostProcessHelper;
  static String get calcFieldFailure => _impl.calcFieldFailure;
  static String get calcFieldFailureHelper => _impl.calcFieldFailureHelper;
  static String get calcFieldWaste => _impl.calcFieldWaste;
  static String get calcFieldWasteHelper => _impl.calcFieldWasteHelper;

  // === Cost calibration help ===
  static String get costHelpTitle => _impl.costHelpTitle;
  static String get costHelpEnergyTitle => _impl.costHelpEnergyTitle;
  static String get costHelpEnergyBody => _impl.costHelpEnergyBody;
  static String get costHelpLaborTitle => _impl.costHelpLaborTitle;
  static String get costHelpLaborBody => _impl.costHelpLaborBody;
  static String get costHelpPostTitle => _impl.costHelpPostTitle;
  static String get costHelpPostBody => _impl.costHelpPostBody;
  static String get costHelpFailureTitle => _impl.costHelpFailureTitle;
  static String get costHelpFailureBody => _impl.costHelpFailureBody;
  static String get costHelpWasteTitle => _impl.costHelpWasteTitle;
  static String get costHelpWasteBody => _impl.costHelpWasteBody;
  static String get costHelpMinimumChargeTitle =>
      _impl.costHelpMinimumChargeTitle;
  static String get costHelpMinimumChargeBody =>
      _impl.costHelpMinimumChargeBody;
  static String get costHelpMarginTitle => _impl.costHelpMarginTitle;
  static String get costHelpMarginBody => _impl.costHelpMarginBody;

  // === Quote guide (guia paso a paso de la cotizacion) ===
  static String get quoteGuideTitle => _impl.quoteGuideTitle;
  static String get quoteGuideMenuLabel => _impl.quoteGuideMenuLabel;
  static String get quoteGuideStep1Title => _impl.quoteGuideStep1Title;
  static String get quoteGuideStep1Body => _impl.quoteGuideStep1Body;
  static String get quoteGuideStep2Title => _impl.quoteGuideStep2Title;
  static String get quoteGuideStep2Body => _impl.quoteGuideStep2Body;
  static String get quoteGuideStep3Title => _impl.quoteGuideStep3Title;
  static String get quoteGuideStep3Body => _impl.quoteGuideStep3Body;
  static String get quoteGuideStep4Title => _impl.quoteGuideStep4Title;
  static String get quoteGuideStep4Body => _impl.quoteGuideStep4Body;
  static String get quoteGuideStep5Title => _impl.quoteGuideStep5Title;
  static String get quoteGuideStep5Body => _impl.quoteGuideStep5Body;
  static String get quoteGuideStep6Title => _impl.quoteGuideStep6Title;
  static String get quoteGuideStep6Body => _impl.quoteGuideStep6Body;
  static String get quoteGuideNext => _impl.quoteGuideNext;
  static String get quoteGuideClose => _impl.quoteGuideClose;
  static String quoteGuidePageCounter(int page, int total) =>
      _impl.quoteGuidePageCounter(page, total);
  static String get commonMoreActions => _impl.commonMoreActions;
  static String get calcCloseAction => _impl.calcCloseAction;

  // === Calculator modes ===
  static String get calcModeExpress => _impl.calcModeExpress;
  static String get calcModeAdvanced => _impl.calcModeAdvanced;
  static String calcSemanticMode(String mode) => _impl.calcSemanticMode(mode);

  // === Action labels ===
  static String get calcActionReset => _impl.calcActionReset;

  // === Save dialog ===
  static String get calcDialogClient => _impl.calcDialogClient;
  static String get calcDialogClientHelper => _impl.calcDialogClientHelper;
  static String get calcDialogRecentClients => _impl.calcDialogRecentClients;
  static String get calcDialogNotes => _impl.calcDialogNotes;
  static String get calcDialogNotesHelper => _impl.calcDialogNotesHelper;
  static String get calcDialogConditions => _impl.calcDialogConditions;
  static String get calcDialogConditionsHelper =>
      _impl.calcDialogConditionsHelper;
  static String get calcDialogSaveAsTemplate => _impl.calcDialogSaveAsTemplate;
  static String get calcDialogSaveSubtitle => _impl.calcDialogSaveSubtitle;
  static String get calcDialogDetails => _impl.calcDialogDetails;

  // === Plantillas de trabajo frecuente ===
  static String get calcTemplatesTitle => _impl.calcTemplatesTitle;
  static String get calcTemplateSaveAsAction => _impl.calcTemplateSaveAsAction;
  static String get calcTemplateSaveSuccess => _impl.calcTemplateSaveSuccess;
  static String get calcTemplateSaveError => _impl.calcTemplateSaveError;
  static String get calcTemplateApplySuccess => _impl.calcTemplateApplySuccess;
  static String get calcTemplateApplyError => _impl.calcTemplateApplyError;
  static String get calcTemplateEmpty => _impl.calcTemplateEmpty;
  static String get calcTemplateUntitled => _impl.calcTemplateUntitled;
  static String get calcTemplateDeleteError => _impl.calcTemplateDeleteError;

  // === Dynamic empty hint ===
  static String get calcEmptyHintPrefix => _impl.calcEmptyHintPrefix;
  static String get calcEmptyHintSuffix => _impl.calcEmptyHintSuffix;
  static String get calcEmptyHintConnector => _impl.calcEmptyHintConnector;
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
  static String get calcBtnShareSave => _impl.calcBtnShareSave;
  static String get calcShareError => _impl.calcShareError;
  static String get calcShareSubject => _impl.calcShareSubject;
  static String get calcShareText => _impl.calcShareText;
  static String get calcSheetActionsLabel => _impl.calcSheetActionsLabel;

  // === Quote image (foto de la pieza) ===
  static String get quoteImageAdd => _impl.quoteImageAdd;
  static String get quoteImageGallery => _impl.quoteImageGallery;
  static String get quoteImageCamera => _impl.quoteImageCamera;
  static String get quoteImageChange => _impl.quoteImageChange;
  static String get quoteImageRemove => _impl.quoteImageRemove;
  static String get quoteImageTooLarge => _impl.quoteImageTooLarge;
  static String get quoteImageInvalidFormat => _impl.quoteImageInvalidFormat;
  static String get quoteImageError => _impl.quoteImageError;
  static String get quoteImageEditToolbar => _impl.quoteImageEditToolbar;

  // === Filaments / Printers ===
  static String get filamentTitle => _impl.filamentTitle;
  static String get filamentNew => _impl.filamentNew;
  static String get filamentEdit => _impl.filamentEdit;
  static String get filamentName => _impl.filamentName;
  static String get filamentNameHelper => _impl.filamentNameHelper;
  static String get filamentBrand => _impl.filamentBrand;
  static String get filamentBrandHelper => _impl.filamentBrandHelper;
  static String get brandSelectorOther => _impl.brandSelectorOther;
  static String get brandSelectorHint => _impl.brandSelectorHint;
  static String get brandSelectorManualHelper =>
      _impl.brandSelectorManualHelper;
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
  static String get filamentColorLabel => _impl.filamentColorLabel;
  static String get filamentColorHelper => _impl.filamentColorHelper;
  static String get filamentColorCustom => _impl.filamentColorCustom;
  static String get filamentColorClear => _impl.filamentColorClear;
  static String get filamentColorPickerTitle => _impl.filamentColorPickerTitle;
  static String get filamentColorHexLabel => _impl.filamentColorHexLabel;
  static String get filamentColorHexHelper => _impl.filamentColorHexHelper;
  static String get filamentColorInvalid => _impl.filamentColorInvalid;

  static String get printerTitle => _impl.printerTitle;
  static String get printerNew => _impl.printerNew;
  static String get printerEdit => _impl.printerEdit;
  static String get printerModel => _impl.printerModel;
  static String get printerModelHelper => _impl.printerModelHelper;
  static String get printerBrandHelper => _impl.printerBrandHelper;
  static String get printerWatts => _impl.printerWatts;
  static String get printerWattsHelper => _impl.printerWattsHelper;
  static String get printerDefaultSubtitle => _impl.printerDefaultSubtitle;
  static String get printerCatalogBrandHint => _impl.printerCatalogBrandHint;
  static String get printerCatalogModelHint => _impl.printerCatalogModelHint;
  static String get printerCatalogNoModels => _impl.printerCatalogNoModels;
  static String get printerCatalogSelectModel =>
      _impl.printerCatalogSelectModel;
  static String get printerWattsAutoHelper => _impl.printerWattsAutoHelper;
  static String get printerWattsEstimated => _impl.printerWattsEstimated;
  static String get printerNewTooltip => _impl.printerNewTooltip;
  static String get printerDeleteTitle => _impl.printerDeleteTitle;
  static String get printerMustBeNonNegative => _impl.printerMustBeNonNegative;

  // === F5: Amortizacion de impresora ===
  static String get printerPurchaseCost => _impl.printerPurchaseCost;
  static String get printerPurchaseCostHelper =>
      _impl.printerPurchaseCostHelper;
  static String get printerUsefulLifeHours => _impl.printerUsefulLifeHours;
  static String get printerUsefulLifeHoursHelper =>
      _impl.printerUsefulLifeHoursHelper;
  static String get printerCurrentHours => _impl.printerCurrentHours;
  static String get printerCurrentHoursHelper =>
      _impl.printerCurrentHoursHelper;
  static String get printerLifePositiveIfCost =>
      _impl.printerLifePositiveIfCost;
  static String get calcDetailAmortization => _impl.calcDetailAmortization;

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

  // === Duplicar cotizacion ===
  static String get calcDuplicateAction => _impl.calcDuplicateAction;
  static String get calcDuplicateSuffix => _impl.calcDuplicateSuffix;
  static String get calcDuplicateSuccess => _impl.calcDuplicateSuccess;
  static String get calcDuplicateError => _impl.calcDuplicateError;

  // === History ===
  static String get historyTitle => _impl.historyTitle;
  static String get historyErrorLoad => _impl.historyErrorLoad;
  static String get historyEmpty => _impl.historyEmpty;

  // === CSV export gate (T16) ===
  static String get csvExportLockedBody => _impl.csvExportLockedBody;
  static String get csvGoProAction => _impl.csvGoProAction;
  static List<String> get csvExportHeader => _impl.csvExportHeader;
  static String get csvValueYes => _impl.csvValueYes;
  static String get csvValueNo => _impl.csvValueNo;
  static String get csvFileName => _impl.csvFileName;

  // === Locale ===
  static String get localeLabel => _impl.localeLabel;
  static String get localeEs => _impl.localeEs;
  static String get localeEn => _impl.localeEn;
  static String get localePtBr => _impl.localePtBr;
  static String get localeDe => _impl.localeDe;
  static String get localeFr => _impl.localeFr;

  // === Language selection (primera ejecución) ===
  static String get languagePageTitle => _impl.languagePageTitle;
  static String get languagePageSubtitle => _impl.languagePageSubtitle;

  // === Onboarding ===
  static String get onboardingTitle1 => _impl.onboardingTitle1;
  static String get onboardingDesc1 => _impl.onboardingDesc1;
  static String get onboardingTitle2 => _impl.onboardingTitle2;
  static String get onboardingDesc2 => _impl.onboardingDesc2;
  static String get onboardingTitle3 => _impl.onboardingTitle3;
  static String get onboardingDesc3 => _impl.onboardingDesc3;
  static String get onboardingTitle4 => _impl.onboardingTitle4;
  static String get onboardingDesc4 => _impl.onboardingDesc4;
  static String get onboardingTitle5 => _impl.onboardingTitle5;
  static String get onboardingDesc5 => _impl.onboardingDesc5;
  static String get onboardingNext => _impl.onboardingNext;
  static String get onboardingStart => _impl.onboardingStart;
  static String get onboardingConfigure => _impl.onboardingConfigure;

  // === Initial config ===
  static String get configTitle => _impl.configTitle;
  static String get configTheme => _impl.configTheme;
  static String get configCurrency => _impl.configCurrency;
  static String get configContinue => _impl.configContinue;

  // === Initial config stepper ===
  static String get configStep1Title => _impl.configStep1Title;
  static String get configStep2Title => _impl.configStep2Title;
  static String get configStep3Title => _impl.configStep3Title;
  static String get configBack => _impl.configBack;
  static String get configFinish => _impl.configFinish;
  static String get configStepSubtitle1 => _impl.configStepSubtitle1;
  static String get configStepSubtitle2 => _impl.configStepSubtitle2;
  static String get configStepSubtitle3 => _impl.configStepSubtitle3;
  static String configStepCounter(int step, int total) =>
      _impl.configStepCounter(step, total);
  static String get configCurrencyHelper => _impl.configCurrencyHelper;
  static String get configPrinterSectionHelper =>
      _impl.configPrinterSectionHelper;
  static String get configFilamentSectionHelper =>
      _impl.configFilamentSectionHelper;
  static String get configProfitHelper => _impl.configProfitHelper;
  static String get configKwhHelper => _impl.configKwhHelper;
  static String get settingsDefaultTypical => _impl.settingsDefaultTypical;
  static String get configFilamentSkipStatus => _impl.configFilamentSkipStatus;
  static String get configFilamentAddAction => _impl.configFilamentAddAction;
  static String get configStartButton => _impl.configStartButton;
  static String get configSummaryTitle => _impl.configSummaryTitle;
  static String get configSummaryImprint => _impl.configSummaryImprint;
  static String get configPrinterRequired => _impl.configPrinterRequired;
  static String get configFilamentOptional => _impl.configFilamentOptional;
  static String get configAddFilament => _impl.configAddFilament;
  static String get configFilamentLater => _impl.configFilamentLater;
  static String get configFilamentSkipHint => _impl.configFilamentSkipHint;
  static String get configPrinterSaved => _impl.configPrinterSaved;
  static String get configFilamentSaved => _impl.configFilamentSaved;
  static String get configRequirementPending => _impl.configRequirementPending;
  static String get configRequirementDone => _impl.configRequirementDone;

  // === Feature gates (T14) ===
  static String get calculatorAdvancedLockedBody =>
      _impl.calculatorAdvancedLockedBody;
  static String get calculatorGoProAction => _impl.calculatorGoProAction;

  // === History cap gate (T15) ===
  static String get historyCapReachedBody => _impl.historyCapReachedBody;
  static String freePrintersLimitHint(int current, int limit) =>
      _impl.freePrintersLimitHint(current, limit);
  static String freeFilamentsLimitHint(int current, int limit) =>
      _impl.freeFilamentsLimitHint(current, limit);
  static String filamentLimitReachedTooltip(int limit) =>
      _impl.filamentLimitReachedTooltip(limit);
  static String filamentLimitReachedBody(int limit) =>
      _impl.filamentLimitReachedBody(limit);
  static String printerLimitReachedTooltip(int limit) =>
      _impl.printerLimitReachedTooltip(limit);
  static String printerLimitReachedBody(int limit) =>
      _impl.printerLimitReachedBody(limit);

  // === Pro badge / locked visuals (UX) ===
  static String get proBadgeLabel => _impl.proBadgeLabel;
  static String get proLockedTooltip => _impl.proLockedTooltip;
  static String get csvExportTooltipLocked => _impl.csvExportTooltipLocked;
  static String historyUsageCounter(int used, int cap) =>
      _impl.historyUsageCounter(used, cap);

  // === Paywall (T10) ===
  static String get paywallTitle => _impl.paywallTitle;
  static String get paywallSubtitle => _impl.paywallSubtitle;
  static String get paywallPrice => _impl.paywallPrice;
  static List<String> get paywallFeatures => _impl.paywallFeatures;
  static String paywallUnlockButton(String price) =>
      _impl.paywallUnlockButton(price);
  static String get paywallRestoreButton => _impl.paywallRestoreButton;
  static String get paywallErrorGeneric => _impl.paywallErrorGeneric;
  static String get paywallUnavailable => _impl.paywallUnavailable;
  static String get paywallAlreadyPro => _impl.paywallAlreadyPro;
  static String get paywallClose => _impl.paywallClose;

  // T22 — Store compliance
  static String get paywallPrivacyPolicy => _impl.paywallPrivacyPolicy;
  static String get paywallTermsOfService => _impl.paywallTermsOfService;
  static String get settingsLegal => _impl.settingsLegal;
  static String get legalPrivacyDocument => _impl.legalPrivacyDocument;
  static String get legalTermsDocument => _impl.legalTermsDocument;

  // === i18n consistency (hardcoded → l10n) ===
  static String get commonError => _impl.commonError;
  static String get commonNoResults => _impl.commonNoResults;
  static String get commonDefault => _impl.commonDefault;
  static String get commonUndo => _impl.commonUndo;
  static String get commonSaveImage => _impl.commonSaveImage;
  static String get commonExportPdf => _impl.commonExportPdf;
  static String get commonSharePdf => _impl.commonSharePdf;
  static String get commonPrint => _impl.commonPrint;
  static String get commonImageDownloaded => _impl.commonImageDownloaded;
  static String get commonImageSavedGallery => _impl.commonImageSavedGallery;
  static String get commonPdfExportError => _impl.commonPdfExportError;
  static String get commonPrintError => _impl.commonPrintError;
  static String get commonDefaultSuffix => _impl.commonDefaultSuffix;
  static String get historyExportCsv => _impl.historyExportCsv;
  static String get historyEmptyCta => _impl.historyEmptyCta;
  @Deprecated('Use calcSectionPieceCosts instead')
  static String get calcSectionOthers => _impl.calcSectionOthers;
  static String get settingsProfitBaseRange => _impl.settingsProfitBaseRange;
  static String get settingsKwhRateRange => _impl.settingsKwhRateRange;
  static String get shareErrorNotRendered => _impl.shareErrorNotRendered;
  static String get shareErrorNoRegion => _impl.shareErrorNoRegion;
  static String get shareErrorEncode => _impl.shareErrorEncode;
  static String get shareErrorSaveGallery => _impl.shareErrorSaveGallery;
  static String shareErrorSaveWithMessage(String msg) =>
      _impl.shareErrorSaveWithMessage(msg);
  static String get shareWebUnavailable => _impl.shareWebUnavailable;

  static String get homeHeroTagline => _impl.homeHeroTagline;
  static String get homeHeroSemanticsSuffix => _impl.homeHeroSemanticsSuffix;

  static String get calcFormIncompleteWarning =>
      _impl.calcFormIncompleteWarning;
  static String get calcSaveFailed => _impl.calcSaveFailed;
  static String calcSavedWithId(int id) => _impl.calcSavedWithId(id);
  static String get calcSavedViewAction => _impl.calcSavedViewAction;
  static String get calcAddMaterial => _impl.calcAddMaterial;
  static String get calcPrinterPrefix => _impl.calcPrinterPrefix;
  static String get calcChangePrinter => _impl.calcChangePrinter;
  static String get calcSearchPrinter => _impl.calcSearchPrinter;
  static String get calcSelectFilament => _impl.calcSelectFilament;
  static String get calcSearchFilament => _impl.calcSearchFilament;

  static String get detailBreakdown => _impl.detailBreakdown;
  static String detailDiscountPct(int pct) => _impl.detailDiscountPct(pct);
  static String get detailPreview => _impl.detailPreview;

  static String get quoteNoDiscount => _impl.quoteNoDiscount;
  static String quoteDiscountPct(int pct) => _impl.quoteDiscountPct(pct);
  static String get quoteDetail => _impl.quoteDetail;
  static String get quoteGeneratedWith => _impl.quoteGeneratedWith;

  static String get pdfFileName => _impl.pdfFileName;
  static String get pdfShareSubject => _impl.pdfShareSubject;
  static String get pdfDatePrefix => _impl.pdfDatePrefix;
  static String get pdfQuoteNumber => _impl.pdfQuoteNumber;
  static String get pdfValidUntilPrefix => _impl.pdfValidUntilPrefix;
  static String get pdfClientPrefix => _impl.pdfClientPrefix;
  static String get pdfNotesTitle => _impl.pdfNotesTitle;
  static String get pdfConditionsTitle => _impl.pdfConditionsTitle;
  static String get pdfMaterialCosts => _impl.pdfMaterialCosts;
  static String get pdfElectricity => _impl.pdfElectricity;
  static String get pdfTotalUpper => _impl.pdfTotalUpper;
  static String get pdfHoursPrefix => _impl.pdfHoursPrefix;
  static String pdfDiscountPct(int pct) => _impl.pdfDiscountPct(pct);

  static String get pdfWeight => _impl.pdfWeight;
  static String get pdfPrintTime => _impl.pdfPrintTime;
  static String get pdfTechnicalData => _impl.pdfTechnicalData;
  static String get pdfMaterialsSection => _impl.pdfMaterialsSection;

  static String get dashboardEmptySubtitle => _impl.dashboardEmptySubtitle;
  static String get dashboardMonthlyTrend => _impl.dashboardMonthlyTrend;
  static String get dashboardTopMaterials => _impl.dashboardTopMaterials;

  // === Dashboard Pro analytics ===
  static String get dashboardProfitTitle => _impl.dashboardProfitTitle;
  static String get dashboardStatEstimatedProfit =>
      _impl.dashboardStatEstimatedProfit;
  static String get dashboardMarginLabel => _impl.dashboardMarginLabel;
  static String get dashboardAvgTicketTitle => _impl.dashboardAvgTicketTitle;
  static String get dashboardAvgTicketQuoted => _impl.dashboardAvgTicketQuoted;
  static String get dashboardAvgTicketSold => _impl.dashboardAvgTicketSold;
  static String get dashboardTopClients => _impl.dashboardTopClients;
  static String get dashboardOperationalTitle =>
      _impl.dashboardOperationalTitle;
  static String get dashboardPrintHours => _impl.dashboardPrintHours;
  static String get dashboardFilament => _impl.dashboardFilament;
  static String get dashboardPrinterNoLifeData =>
      _impl.dashboardPrinterNoLifeData;
  static String get dashboardPrinterRemaining =>
      _impl.dashboardPrinterRemaining;
  static String get dashboardPrinterLifeEnd => _impl.dashboardPrinterLifeEnd;
  static String get dashboardInsightsTitle => _impl.dashboardInsightsTitle;
  static String get dashboardRange7d => _impl.dashboardRange7d;
  static String get dashboardRange30d => _impl.dashboardRange30d;
  static String get dashboardRange90d => _impl.dashboardRange90d;
  static String get dashboardRangeYtd => _impl.dashboardRangeYtd;
  static String get dashboardRangeAll => _impl.dashboardRangeAll;
  static String insightConversion(int sold, int total, int pct) =>
      _impl.insightConversion(sold, total, pct);
  static String insightAvgTicketSold(String amount) =>
      _impl.insightAvgTicketSold(amount);
  static String insightBestMonth(String month, String amount) =>
      _impl.insightBestMonth(month, amount);
  static String insightTopClient(String name, String amount) =>
      _impl.insightTopClient(name, amount);
  static String insightFilament(String amount) => _impl.insightFilament(amount);

  static String get historyFilterAll => _impl.historyFilterAll;
  static String get historyFilterSold => _impl.historyFilterSold;
  static String get historyFilterPending => _impl.historyFilterPending;
  static String get historyNoQuotesToExport => _impl.historyNoQuotesToExport;

  static String get historyFilterDate => _impl.historyFilterDate;
  static String get historyDatePresetToday => _impl.historyDatePresetToday;
  static String get historyDatePreset7d => _impl.historyDatePreset7d;
  static String get historyDatePreset30d => _impl.historyDatePreset30d;
  static String get historyDatePresetMonth => _impl.historyDatePresetMonth;
  static String get historyDatePresetYear => _impl.historyDatePresetYear;
  static String get historyDatePresetAll => _impl.historyDatePresetAll;
  static String get historyDatePresetCustom => _impl.historyDatePresetCustom;
  static String historyDateRangeLabel(DateTimeRange range) =>
      _impl.historyDateRangeLabel(range);
  static String get historySortTitle => _impl.historySortTitle;
  static String get historySortDateNewest => _impl.historySortDateNewest;
  static String get historySortDateOldest => _impl.historySortDateOldest;
  static String get historySortPriceHigh => _impl.historySortPriceHigh;
  static String get historySortPriceLow => _impl.historySortPriceLow;
  static String get historySortClientAz => _impl.historySortClientAz;
  static String historyClientFilterChip(String name) =>
      _impl.historyClientFilterChip(name);
  static String historyFilterSummary(int count, String total) =>
      _impl.historyFilterSummary(count, total);
  static String get historySearchMaterialsHint =>
      _impl.historySearchMaterialsHint;

  static String get chartNoMonthlyData => _impl.chartNoMonthlyData;
  static List<String> get chartShortMonths => _impl.chartShortMonths;

  static String get filamentSearchHint => _impl.filamentSearchHint;
  static String filamentDeleted(String name) => _impl.filamentDeleted(name);
  static String get printerSearchHint => _impl.printerSearchHint;
  static String printerDeleted(String name) => _impl.printerDeleted(name);
  static String get printerErrorSave => _impl.printerErrorSave;

  static String get settingsErrorLoad => _impl.settingsErrorLoad;
  static String get settingsCurrencySearchHint =>
      _impl.settingsCurrencySearchHint;
  static String settingsCurrencyNoResults(String query) =>
      _impl.settingsCurrencyNoResults(query);
  static String get settingsCurrencySymbolPrefix =>
      _impl.settingsCurrencySymbolPrefix;

  static String get routeNotFound => _impl.routeNotFound;
  static String get routeBackHome => _impl.routeBackHome;

  static String get themeModeSystem => _impl.themeModeSystem;
  static String get themeModeLight => _impl.themeModeLight;
  static String get themeModeDark => _impl.themeModeDark;

  static String get splashLogo => _impl.splashLogo;
  static String onboardingPageCounter(int page, int total) =>
      _impl.onboardingPageCounter(page, total);
  static String commonNoResultsFor(String query) =>
      _impl.commonNoResultsFor(query);
  static String get historyEmptySearchHint => _impl.historyEmptySearchHint;

  static String get filamentErrorLoad => _impl.filamentErrorLoad;
  static String filamentNoResults(String query) =>
      _impl.filamentNoResults(query);
  static String get filamentEmptyList => _impl.filamentEmptyList;
  static String filamentDeleteConfirm(String name) =>
      _impl.filamentDeleteConfirm(name);

  // Nombres de colores (paleta de filamentos).
  static String get colorNameRed => _impl.colorNameRed;
  static String get colorNameOrange => _impl.colorNameOrange;
  static String get colorNameAmber => _impl.colorNameAmber;
  static String get colorNameYellow => _impl.colorNameYellow;
  static String get colorNameLime => _impl.colorNameLime;
  static String get colorNameGreen => _impl.colorNameGreen;
  static String get colorNameTeal => _impl.colorNameTeal;
  static String get colorNameCyan => _impl.colorNameCyan;
  static String get colorNameBlue => _impl.colorNameBlue;
  static String get colorNameIndigo => _impl.colorNameIndigo;
  static String get colorNamePurple => _impl.colorNamePurple;
  static String get colorNameMagenta => _impl.colorNameMagenta;
  static String get colorNamePink => _impl.colorNamePink;
  static String get colorNameBrown => _impl.colorNameBrown;
  static String get colorNameGray => _impl.colorNameGray;
  static String get colorNameBlack => _impl.colorNameBlack;
  static String get colorNameWhite => _impl.colorNameWhite;

  static String get commonApply => _impl.commonApply;

  static String get printerErrorLoad => _impl.printerErrorLoad;
  static String printerNoResults(String query) => _impl.printerNoResults(query);
  static String get printerEmptyList => _impl.printerEmptyList;
  static String printerDeleteConfirm(String name) =>
      _impl.printerDeleteConfirm(name);
}

// ─── Implementacion espanol ─────────────────────

class EsImpl implements AppStrings {
  const EsImpl();

  @override
  String get appName => '3dCalc';

  @override
  String get commonSave => 'Guardar';
  @override
  String get commonCancel => 'Cancelar';
  @override
  String get commonApply => 'Aplicar';
  @override
  String get commonDelete => 'Eliminar';
  @override
  String get commonRetry => 'Reintentar';
  @override
  String get commonEdit => 'Editar';
  @override
  String get commonNew => 'Nuevo';
  @override
  String get commonCreateNew => 'Crear nuevo';
  @override
  String get commonAddToCatalog => 'Agregar al catálogo';
  @override
  String get commonRequired => 'Requerido';
  @override
  String get commonInvalidNumber => 'Numero invalido';
  @override
  String get commonLoading => 'Cargando...';
  @override
  String get commonErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get navHome => 'Inicio';
  @override
  String get navHistory => 'Historial';
  @override
  String get navPrint => 'Impresión';
  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get settingsGlobalParams => 'Parámetros globales';
  @override
  String get settingsProfitBase => 'Ganancia base (%)';
  @override
  String get settingsProfitBaseHelper => 'Margen sobre costo base. 0-1000';

  @override
  String get settingsProfitBaseInfo =>
      'Lo usual en el mundo es cobrar un margen del 200% sobre el costo. '
      'Si no sabes por dónde empezar, prueba con 200 y ajústalo según tu '
      'mercado.';

  @override
  String settingsKwhRate(String symbol) => 'Tarifa electrica ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper => 'Rango residencial Bolivia: 0.10-5.00';
  @override
  String get settingsKwhRateInfo =>
      'Es el costo de un kilovatio-hora segun tu factura de luz. '
      'En Bolivia el rango residencial va de 0.10 a 5.00 Bs./kWh. '
      'Revisa tu ultima factura para el valor exacto.';
  @override
  String get settingsCatalogos => 'Catálogos';
  @override
  String get settingsFilamentos => 'Filamentos';
  @override
  String get settingsImpresoras => 'Impresoras';
  @override
  String get settingsAbout => 'Acerca de';
  @override
  String get settingsPrivacy => 'Privacidad y datos';
  @override
  String get settingsSaved => 'Guardado';
  @override
  String get settingsAppearance => 'Apariencia';
  @override
  String get settingsTheme => 'Tema';
  @override
  String get settingsManageFilaments => 'Gestiona tus filamentos';
  @override
  String get settingsManagePrinters => 'Registra tus impresoras';

  // === Print settings page ===
  @override
  String get settingsPrintConfigTitle => 'Configuración de impresión';
  @override
  String get settingsPrintConfigSubtitle =>
      'Costos, energía, descuentos y catálogos';

  // === Settings page section group labels (uppercase headers) ===
  @override
  String get settingsGroupCatalogs => 'Catálogos';
  @override
  String get settingsGroupCurrencyAndLanguage => 'Moneda e idioma';
  @override
  String get settingsGroupAppearance => 'Apariencia';
  @override
  String get settingsGroupYourData => 'Tus datos';
  @override
  String get settingsGroupAccount => 'Cuenta';
  @override
  String get settingsGroupAbout => 'Acerca de';

  // === Hito 1: lotes y reorganización (T-H1) ===
  @override
  String get calcSectionPieceCosts => 'Costos de la pieza';
  @override
  String get calcSectionTarifas => 'Tarifas';
  @override
  String get settingsGroupEnergy => 'Energía';
  @override
  String get settingsGroupPrintingCosts => 'Costos de impresión';
  @override
  String get settingsGroupDiscountTiers => 'Descuentos por cantidad';
  @override
  String get discountTierAdd => 'Agregar escalón';
  @override
  String get discountTierEdit => 'Editar escalón';
  @override
  String get discountTierDelete => 'Eliminar escalón';
  @override
  String get discountTierEmpty =>
      'Aún no hay descuentos por cantidad. Agrega el primero para ofrecer '
      'precio mayorista.';
  @override
  String get discountTierHeaderMinQty => 'Cantidad mínima';
  @override
  String get discountTierHeaderPercent => '%';
  @override
  String get discountTierMinQty => 'Cantidad mínima';
  @override
  String get discountTierPercent => 'Descuento (%)';
  @override
  String get discountTierValidationMinQty =>
      'La cantidad mínima debe ser de al menos 2 unidades';
  @override
  String get discountTierValidationPercent =>
      'El descuento debe estar entre 1 y 100 %';
  @override
  String get discountTierCapHint => 'Máximo 10 escalones por configuración';
  @override
  String calcDetailBatchDiscount(int pct) => 'Descuento por cantidad ($pct%)';
  @override
  String get calcSubtotal => 'Subtotal';
  @override
  String calcDetailManualDiscount(int pct) => 'Descuento manual ($pct%)';
  @override
  String calcQuantityBatchHint(int pct, int minQty) =>
      '$pct % desde $minQty u.';
  @override
  String get calcQuantityNoTiers => 'Sin descuentos por cantidad configurados';
  @override
  String get calcQuantityTiersTitle => 'Descuentos por cantidad:';
  @override
  String get calcQuantityFrom => 'desde';
  @override
  String get calcQuantityUnits => 'u.';
  @override
  String quoteBatchDiscountPct(int pct) => 'Descuento por cantidad $pct%';
  @override
  String pdfBatchDiscountPct(int pct) => 'Descuento por cantidad: $pct%';

  @override
  String settingsFilamentsCount(int count) =>
      count == 1 ? '1 filamento' : '$count filamentos';
  @override
  String settingsPrintersCount(int count) =>
      count == 1 ? '1 impresora' : '$count impresoras';
  @override
  String get settingsGainMultiplierSuffix => 'sobre costo';

  @override
  String get settingsLaborPost => 'Mano de obra y post-procesado';
  @override
  String settingsLaborRate(String symbol) => 'Mano de obra ($symbol/hora)';
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
  String settingsMinimumCharge(String symbol) => 'Cargo minimo ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Cotizaciones por debajo de este monto se ajustan automaticamente';
  @override
  String get settingsMarkupOnMaterials => 'Margen por desperdicio (%)';
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
      'Aparece en la cotización. Default: 3dCalc';
  @override
  String get settingsCompanyLogo => 'Logo';
  @override
  String get settingsCompanyLogoPick => 'Seleccionar imagen';
  @override
  String get settingsCompanyLogoRemove => 'Eliminar logo';
  @override
  String get settingsCompanyLogoError => 'Error al cargar la imagen';

  @override
  String get settingsBrandingLockedBody =>
      'Desbloquea Pro para personalizar tu marca';
  @override
  String get settingsGoProAction => 'Desbloquear PRO';
  @override
  String get settingsProTitle => '3D Cal PRO';
  @override
  String get settingsProUnlocked =>
      'Ya tienes todas las funciones PRO desbloqueadas';
  @override
  String get settingsProNoAdditionalPurchase =>
      'No necesitas realizar otra compra';
  @override
  String get settingsProFutureUpdates =>
      'Tu compra incluye las mejoras futuras de PRO sin costo adicional.';
  @override
  String get settingsProRestorePurchase => 'Restaurar compra';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';
  @override
  String get settingsRestoreSuccess => 'Compras restauradas correctamente!';
  @override
  String get settingsRestoreEmpty => 'No se encontraron compras previas';
  @override
  String get settingsRestoreError => 'No se pudieron restaurar las compras.';

  @override
  String get settingsBackupTitle => 'Copia de seguridad';

  @override
  String get settingsBackupExport => 'Exportar backup';

  @override
  String get settingsBackupImport => 'Importar backup';

  @override
  String get settingsBackupHelper =>
      'Guarda o restaura todos tus datos (filamentos, impresoras, cotizaciones). Se recomienda hacer backups periodicamente.';

  @override
  String get settingsBackupExportSuccess => 'Backup exportado correctamente';

  @override
  String get settingsBackupExportError => 'Error al exportar el backup';

  @override
  String settingsBackupImportSuccess(int calcs, int filaments, int printers) =>
      'Backup restaurado: $calcs cotizaciones, $filaments filamentos, $printers impresoras';

  @override
  String get settingsBackupImportError => 'Error al importar el backup';

  @override
  String get settingsBackupImportConfirmTitle => '¿Restaurar backup?';

  @override
  String settingsBackupImportConfirmBody(String summary) =>
      'Se reemplazaran TODOS los datos actuales con:\n$summary\n\nEsta accion no se puede deshacer.';

  @override
  String get settingsBackupImportConfirm => 'Restaurar';

  @override
  String get settingsBackupImportCancel => 'Cancelar';

  @override
  String get settingsBackupImportSizeError =>
      'El archivo de backup supera el tamaño permitido.';

  @override
  String get settingsBackupImportInvalidFile =>
      'El archivo seleccionado no es un backup valido.';

  @override
  String get settingsBackupImportFutureVersion =>
      'Este backup fue creado con una versión futura de la app. '
      'Actualiza 3dCalc e intenta de nuevo.';

  @override
  String get settingsBackupLockedBody =>
      'Hacer copias de seguridad es una función Pro.';

  @override
  String get dashboardTitle => 'Dashboard';
  @override
  String get dashboardErrorLoad => 'Error al cargar el dashboard';
  @override
  String get dashboardEmpty => 'Aun no cotizaste nada';
  @override
  String get dashboardEmptyCta => 'Ir a Inicio';
  @override
  String get dashboardStatQuotations => 'Cotizaciones';
  @override
  String get dashboardStatSold => 'Vendidas';
  @override
  String get dashboardStatConversion => 'Conversión';
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
  String get dashboardProTeaserTitle => 'Desbloquea Pro Analytics';
  @override
  String get dashboardProTeaserBody =>
      'Obtén el dashboard completo con tendencias de costos, desglose de materiales y más.';
  @override
  String get dashboardGoProAction => 'Hazte Pro';

  @override
  String get homeActionNewCalc => 'Nueva cotización';
  @override
  String get homeActionNewCalcSub => 'Calcula precio de impresion';
  @override
  String get homeActionHistory => 'Historial';
  @override
  String get homeActionHistorySub => 'Cotizaciones guardadas';
  @override
  String get homeActionDashboard => 'Dashboard';
  @override
  String get homeActionDashboardSub => 'Estadisticas y graficos';
  @override
  String get homeQuickAccess => 'Acceso rápido';
  @override
  String get homeErrorLoadStats => 'Error cargando stats';
  @override
  String get homeEmptyQuotations => 'Todavia no hay cotizaciones';
  @override
  String get homeSummary => 'Resumen';
  @override
  String get homeSeeAll => 'Ver todo';
  @override
  String get homeRecentTitle => 'Últimas cotizaciones';
  @override
  String get homeEmptyCta => 'Empezar a cotizar';
  @override
  String get homeDraftTitle => 'Cotización en curso';
  @override
  String get homeDraftBody => 'Continuá donde quedaste';
  @override
  String get homeDraftContinue => 'Continuar';
  @override
  String get homeCatalogsTitle => 'Mis catálogos';

  @override
  String get calcSectionPiece => 'Pieza';
  @override
  String get calcSectionWeight => 'Peso de la pieza';
  @override
  String get calcSectionFilament => 'Filamento';
  @override
  String get calcSectionTime => 'Tiempo de impresion';
  @override
  String get calcSectionDiscount => 'Descuento';
  @override
  String get calcLabelOptional => 'Etiqueta (opcional)';
  @override
  String get calcLabelOptionalHelper => 'Ej: Soporte pared, Engranaje PETG';
  @override
  String get calcLabelWeight => 'Peso de la pieza';
  @override
  String get calcLabelWeightHelper => 'Gramos del modelo';
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
  String get calcLabelDiscountHelper => 'Porcentaje sobre el total final';
  @override
  String get calcWizardStepPrint => 'Impresión';
  @override
@override
  String get calcWizardStepAdjust => 'Otros';
  @override
  @override
  String get calcWizardFullBreakdown => 'Ver desglose completo';
  @override
  String get calcBtnSave => 'Guardar cotización';
  @override
  String get calcBtnReset => 'Restablecer valores';
  @override
  String get calcToggleShowDetail => 'Ver detalle';
  @override
  String get calcToggleHideDetail => 'Ocultar detalle';
  @override
  String get calcTotalWithDiscount => 'Total con descuento';
  @override
  String get calcTotalFinal => 'Total';
  @override
  String get calcDetailMaterial => 'Costo material';
  @override
  String get calcDetailEnergy => 'Costo energia';
  @override
  String get calcDetailLabor => 'Mano de obra';
  @override
  String get calcDetailPostProcess => 'Post-procesado';
  @override
  String get calcDetailBase => 'Costo base';
  @override
  String get calcDetailFailure => 'Tasa de falla';
  @override
  String get calcDetailMarkup => 'Margen por desperdicio';
  @override
  String get calcDetailProfit => 'Ganancia';
  @override
  String get calcDetailMinimumCharge => 'Cargo minimo';
  @override
  String get calcDetailTotal => 'Total';
  @override
  String get detailQuantityLabel => 'Cantidad de Piezas';
  @override
  String get detailQuantitySubtitle => 'Cotizar por lote / volumen';
  @override
  String get resultQuantityLabel => 'Cantidad';
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
  String get calcPrinterEmptyCta => 'Registrar impresora';
  @override
  String get calcPrinterEmptyHint =>
      'Se calcula sin costo de energía. Registra una para sumarlo.';
  @override
  String get calcNoMaterials => 'Sin materiales.';

  @override
  String get calcKeyWeightHint => 'Clave: sin este dato no se puede cotizar';
  @override
  String get calcKeyHoursHint =>
      'Clave: define el costo de mano de obra y energia';
  @override
  String get calcKeyMinutesHint =>
      'Clave: completa el tiempo real de impresion';

  @override
  String calcMaterialTitle(int index) => 'Material $index';
  @override
  String calcMaterialRemove(int index) => 'Quitar material $index';
  @override
  String get calcMaterialCatalog => 'Catálogo';
  @override
  String calcMaterialUse(String filamentName) => 'Usar $filamentName';
  @override
  String get calcFieldLabel => 'Etiqueta';
  @override
  String get calcFieldLabelHelper => 'Opcional (ej: PLA base)';
  @override
  String get calcFieldFilament => 'Filamento';
  @override
  String get calcFieldWeight => 'Peso';
  @override
  String get calcFieldSpoolPrice => 'Precio bobina';
  @override
  String get calcFieldSpoolGrams => 'Gramos / bobina';

  @override
  String get calcFieldLabor => 'Mano de obra';
  @override
  String get calcFieldLaborHelper => 'Tarifa por hora';
  @override
  String get calcFieldPostProcess => 'Post-procesado';
  @override
  String get calcFieldPostProcessHelper => '% del costo mat.';
  @override
  String get calcFieldFailure => 'Tasa de falla';
  @override
  String get calcFieldFailureHelper => '% del costo base';
  @override
  String get calcFieldWaste => 'Desperdicio';
  @override
  String get calcFieldWasteHelper => '% markup desperdicio';

  @override
  String get costHelpTitle => 'Cómo calibrar tus costos';

  @override
  String get costHelpEnergyTitle => 'Costo de energía';

  @override
  String get costHelpEnergyBody =>
      'Energía consumida al imprimir: horas de impresión × potencia (kW) × '
      'tarifa (\$/kWh). Ej.: 6 h × 0,15 kW × 1,2 \$/kWh ≈ 1,08 \$. Solo se '
      'suma si la impresora tiene potencia registrada.';

  @override
  String get costHelpLaborTitle => 'Mano de obra';

  @override
  String get costHelpLaborBody =>
      'Tu tiempo: horas de trabajo × tarifa horaria (\$/h). Incluye preparar '
      'la impresora, supervisar la pieza y el acabado final.';

  @override
  String get costHelpPostTitle => 'Post-procesado';

  @override
  String get costHelpPostBody =>
      'Porcentaje extra sobre el costo de materiales por lijado, pintura, '
      'pegamento u otros acabados.';

  @override
  String get costHelpFailureTitle => 'Tasa de falla';

  @override
  String get costHelpFailureBody =>
      'Porcentaje del costo base reservado para piezas fallidas. Si falla 1 de '
      'cada 10 piezas, ese 10% se reparte entre las 9 que sí vendes.';

  @override
  String get costHelpWasteTitle => 'Desperdicio y desgaste';

  @override
  String get costHelpWasteBody =>
      'Porcentaje extra sobre materiales: soportes, purga de boquilla, '
      'filamento de pruebas y desgaste de la impresora.';

  @override
  String get costHelpMinimumChargeTitle => 'Cargo mínimo';

  @override
  String get costHelpMinimumChargeBody =>
      'Piso del precio final. Si el total calculado queda por debajo, se cobra '
      'este monto. Ideal para piezas pequeñas que igual requieren preparar la '
      'impresora.';

  @override
  String get costHelpMarginTitle => 'Ganancia (margen)';

  @override
  String get costHelpMarginBody =>
      'Porcentaje que se agrega al costo total para tu ganancia: total × '
      '(1 + margen/100). Se ajusta en Parámetros globales.';

  @override
  String get calcCloseAction => 'Cerrar y volver al menú';

  @override
  String get calcModeExpress => 'Express';
  @override
  String get calcModeAdvanced => 'Avanzado';
  @override
  String calcSemanticMode(String mode) => 'Modo de calculo: $mode';

  @override
  String get calcActionReset => 'Restablecer';

  @override
  String get calcDialogClient => 'Cliente';
  @override
  String get calcDialogClientHelper => 'Opcional';
  @override
  String get calcDialogRecentClients => 'Clientes recientes';
  @override
  String get calcDialogNotes => 'Notas (opcional)';
  @override
  String get calcDialogNotesHelper =>
      'Especificaciones, plazos, entregas\u2026';
  @override
  String get calcDialogConditions => 'Condiciones comerciales (opcional)';
  @override
  String get calcDialogConditionsHelper => 'Validez, pago, garant\u00eda\u2026';
  @override
  String get calcDialogSaveAsTemplate =>
      'Guardar también como plantilla para reutilizar';
  @override
  String get calcDialogSaveSubtitle =>
      'Completa los datos opcionales para tu cotización.';
  @override
  String get calcDialogDetails => 'Detalles de la cotización';

  @override
  String get calcTemplatesTitle => 'Plantillas';
  @override
  String get calcTemplateSaveAsAction => 'Guardar como plantilla';
  @override
  String get calcTemplateSaveSuccess => 'Plantilla guardada';
  @override
  String get calcTemplateSaveError => 'No se pudo guardar la plantilla';
  @override
  String get calcTemplateApplySuccess => 'Plantilla aplicada al formulario';
  @override
  String get calcTemplateApplyError => 'No se pudo cargar la plantilla';
  @override
  String get calcTemplateEmpty =>
      'A\u00fan no tienes plantillas.\nGuarda un trabajo frecuente como plantilla para reusarlo.';
  @override
  String get calcTemplateUntitled => 'Sin nombre';
  @override
  String get calcTemplateDeleteError => 'No se pudo eliminar la plantilla';

  @override
  String get calcEmptyHintPrefix => 'Completa';
  @override
  String get calcEmptyHintSuffix => 'para ver la cotización';
  @override
  String get calcEmptyHintConnector => 'y';
  @override
  String get calcFieldWeightShort => 'peso de la pieza';
  @override
  String get calcFieldPriceShort => 'precio del filamento';
  @override
  String get calcFieldTimeShort => 'tiempo de impresion';
  @override
  String get calcFieldMaterialShort => 'al menos un material';

  @override
  String get calcMetaSeparator => ' · ';

  @override
  String get calcResultBarTapHint => 'Ver cotización';
  @override
  String get calcResultBarEmptyHint => 'Falta completar';
  @override
  String get calcSheetTitle => 'Cotización';
  @override
  String get calcBtnShare => 'Compartir imagen';
  @override
  String get calcBtnShareTooltip => 'Genera una imagen lista para enviar';
  @override
  String get calcBtnShareSave => 'Compartir y guardar';
  @override
  String get calcShareError => 'No se pudo generar la imagen';
  @override
  String get calcShareSubject => 'Cotización 3D';
  @override
  String get calcShareText => 'Cotización generada en 3dCalc';
  @override
  String get calcSheetActionsLabel => 'Acciones';

  // === Quote image (foto de la pieza) ===
  @override
  String get quoteImageAdd => 'Agregar imagen';
  @override
  String get quoteImageGallery => 'Galería';
  @override
  String get quoteImageCamera => 'Cámara';
  @override
  String get quoteImageChange => 'Cambiar';
  @override
  String get quoteImageRemove => 'Quitar';
  @override
  String get quoteImageTooLarge => 'La imagen supera los 5 MB y no se adjuntó.';
  @override
  String get quoteImageInvalidFormat =>
      'Formato de imagen no válido (se admiten JPEG, PNG o WebP).';
  @override
  String get quoteImageError => 'No se pudo obtener la imagen';
  @override
  String get quoteImageEditToolbar => 'Editar imagen';

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
  String get brandSelectorOther => 'Otro...';
  @override
  String get brandSelectorHint => 'Selecciona una marca';
  @override
  String get brandSelectorManualHelper => 'Escribe el nombre de la marca';
  @override
  String filamentPrice(String symbol) => 'Precio filamento ($symbol)';
  @override
  String get filamentPriceHelper => 'Costo del rollo completo';
  @override
  String get filamentGrams => 'Gramos por rollo';
  @override
  String get filamentGramsHelper => 'Tipico 1000';
  @override
  String get filamentDefaultToggle => 'Marcar como default';
  @override
  String get filamentDefaultSubtitle =>
      'Se usará en nuevas cotizaciones. Solo un filamento puede ser predeterminado.';
  @override
  String get filamentNewTooltip => 'Nuevo filamento';
  @override
  String get filamentDeleteTitle => 'Eliminar filamento';
  @override
  String get filamentErrorSave => 'Error guardando';
  @override
  String get filamentMustBePositive => 'Debe ser > 0';
  @override
  String get filamentMustBeInteger => 'Debe ser entero';
  @override
  String get filamentMax100 => 'Maximo 100 caracteres';
  @override
  String get filamentColorLabel => 'Color';
  @override
  String get filamentColorHelper =>
      'Opcional. Identifica visualmente el filamento.';
  @override
  String get filamentColorCustom => 'Personalizado...';
  @override
  String get filamentColorClear => 'Quitar color';
  @override
  String get filamentColorPickerTitle => 'Elegir color';
  @override
  String get filamentColorHexLabel => 'Hex';
  @override
  String get filamentColorHexHelper => 'Formato #RRGGBB';
  @override
  String get filamentColorInvalid => 'Color inválido, formato #RRGGBB';

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
  String get printerBrandHelper => 'Ej: Creality, Anycubic';
  @override
  String get printerWatts => 'Consumo promedio (W)';
  @override
  String get printerWattsHelper => 'Tipico 100-300 W';
  @override
  String get printerCatalogBrandHint => 'Elige la marca de tu impresora';
  @override
  String get printerCatalogModelHint => 'Elige el modelo';
  @override
  String get printerCatalogNoModels => 'Sin modelos para esta marca';
  @override
  String get printerCatalogSelectModel => 'Selecciona un modelo';
  @override
  String get printerWattsAutoHelper =>
      'Consumo promedio cargado del catálogo — puedes editarlo';
  @override
  String get printerWattsEstimated => ' (estimado)';
  @override
  String get printerDefaultSubtitle =>
      'Se usará en nuevas cotizaciones. Solo una impresora puede ser predeterminada.';
  @override
  String get printerNewTooltip => 'Nueva impresora';
  @override
  String get printerDeleteTitle => 'Eliminar impresora';
  @override
  String get printerMustBeNonNegative => 'Debe ser >= 0';

  @override
  String get printerPurchaseCost => 'Costo (Bs)';

  @override
  String get printerPurchaseCostHelper =>
      'Precio de compra. Se amortiza por hora de uso.';

  @override
  String get printerUsefulLifeHours => 'Vida útil (horas)';

  @override
  String get printerUsefulLifeHoursHelper =>
      'Ej: 6000. Se auto-carga del catálogo al seleccionar modelo.';

  @override
  String get printerCurrentHours => 'Horas acumuladas';

  @override
  String get printerCurrentHoursHelper =>
      'Horas de uso registradas. Se actualiza al validar cotizaciones.';

  @override
  String get printerLifePositiveIfCost =>
      'La vida útil debe ser ≥ 1 si hay costo';

  @override
  String get calcDetailAmortization => 'Amortización máquina';

  @override
  String get calcNotifFilament => 'Filamento';
  @override
  String get calcNotifMaterial => 'Material';

  @override
  String get calcDetailTitle => 'Detalle de cotización';
  @override
  String get calcDetailDelete => 'Eliminar';
  @override
  String get calcDetailDeleteTitle => 'Eliminar cotización';
  @override
  String get calcDetailDeleteConfirm => '¿Eliminar definitivamente?';
  @override
  String get calcDetailNoName => 'Sin nombre';
  @override
  String get calcDetailSold => 'Vendida';
  @override
  String get calcDetailReuse => 'Reusar';
  @override
  String get calcDetailMarkSold => 'Marcar vendida';
  @override
  String get calcDetailMarkPending => 'Marcar pendiente';

  @override
  String get calcDuplicateAction => 'Duplicar';
  @override
  String get calcDuplicateSuffix => ' (copia)';
  @override
  String get calcDuplicateSuccess => 'Cotización duplicada';
  @override
  String get calcDuplicateError => 'No se pudo duplicar la cotización';

  @override
  String get historyTitle => 'Cotizaciones';
  @override
  String get historyErrorLoad => 'Error cargando cotizaciones';
  @override
  String get historyEmpty => 'Sin cotizaciones guardadas';

  @override
  String get csvExportLockedBody => 'Exportar CSV es una función Pro';
  @override
  String get csvGoProAction => 'Hazte Pro';

  @override
  List<String> get csvExportHeader => const [
    'Fecha',
    'Pieza',
    'Cliente',
    'Cantidad',
    'Total',
    'Vendido',
    'Materiales',
    'Horas',
    'Descuento',
    'DescLote%',
    'DescLote',
    'CostoMat',
    'Elect',
    'Ganancia',
  ];
  @override
  String get csvValueYes => 'Sí';
  @override
  String get csvValueNo => 'No';
  @override
  String get csvFileName => 'cotizaciones_3dcalc.csv';

  @override
  String get localeLabel => 'Idioma';
  @override
  String get localeEs => 'Español';
  @override
  String get localeEn => 'Inglés';
  @override
  String get localePtBr => 'Portugués (Brasil)';
  @override
  String get localeDe => 'Alemán';
  @override
  String get localeFr => 'Francés';
  @override
  String get languagePageTitle => 'Elige tu idioma';
  @override
  String get languagePageSubtitle =>
      'Se aplica a toda la aplicación. Puedes cambiarlo después en Ajustes.';
  @override
  String get onboardingTitle1 => 'Bienvenido a 3dCalc';
  @override
  String get onboardingDesc1 =>
      'Calcula el precio de impresiones 3D al instante.\nMateriales, electricidad, mano de obra y mas.';
  @override
  String get onboardingTitle2 => 'Dos modos de calculo';
  @override
  String get onboardingDesc2 =>
      'Express: cálculo rápido con un solo material.\nAvanzado: múltiples materiales, descuento y más parámetros.';
  @override
  String get onboardingTitle3 => 'Catálogo integrado';
  @override
  String get onboardingDesc3 =>
      'Guarda tus filamentos e impresoras favoritos.\n Selecciónalos al instante desde el catálogo.';
  @override
  String get onboardingTitle4 => 'Dashboard & mas';
  @override
  String get onboardingDesc4 =>
      'Seguimiento de cotizaciones, tendencias mensuales,\nexportación a PDF e historial con búsqueda.';
  @override
  String get onboardingTitle5 => 'Configuración fácil';
  @override
  String get onboardingDesc5 =>
      'Define moneda, impresora, filamento, ganancia\ny costo de energía en unos pocos pasos. Todo listo para cotizar.';
  @override
  String get onboardingNext => 'Siguiente';
  @override
  String get onboardingStart => 'Comenzar';
  @override
  String get onboardingConfigure => 'Configurar';
  @override
  String get configTitle => 'Configuración inicial';
  @override
  String get configTheme => 'Tema';
  @override
  String get configCurrency => 'Moneda';
  @override
  String get configContinue => 'Continuar';

  @override
  String get configStep1Title => 'Tema y moneda';
  @override
  String get configStep2Title => 'Impresora y filamento';
  @override
  String get configStep3Title => 'Ganancia y energía';
  @override
  String get configBack => 'Atrás';
  @override
  String get configFinish => 'Finalizar';
  @override
  String get configStepSubtitle1 => 'Empecemos por lo básico.';
  @override
  String get configStepSubtitle2 =>
      'Dinos qué imprimes y con qué material. '
      'Necesitamos al menos una impresora y un filamento.';
  @override
  String get configStepSubtitle3 =>
      'Estos valores se usan en cada cotización. Puedes cambiarlos después.';
  @override
  String configStepCounter(int step, int total) => 'Paso $step de $total';
  @override
  String get configCurrencyHelper =>
      'Moneda en que se muestran precios y cotizaciones. No convierte valores.';
  @override
  String get configPrinterSectionHelper =>
      'La necesitamos para calcular el costo de energía de cada impresión.';
  @override
  String get configFilamentSectionHelper =>
      'La necesitamos para calcular el costo del material de cada pieza. '
      'Registra al menos uno para poder cotizar.';
  @override
  String get configProfitHelper =>
      'Margen sobre el costo base. 200% duplica el costo. Típico: 100%–300%.';
  @override
  String get configKwhHelper =>
      'Tarifa de tu factura eléctrica. Típico: 0.5–1.5 BOB/kWh.';
  @override
  String get settingsDefaultTypical => 'Típico';
  @override
  String get configFilamentSkipStatus => 'Sin filamento — agregar después';
  @override
  String get configFilamentAddAction => 'Agregar filamento';
  @override
  String get configStartButton => 'Empezar a cotizar';
  @override
  String get configSummaryTitle => 'Resumen';
  @override
  String get configSummaryImprint => 'Tu próxima cotización:';
  @override
  String get configPrinterRequired => 'Impresora (requerida)';
  @override
  String get configFilamentOptional => 'Filamento (requerido)';
  @override
  String get configAddFilament => 'Agregar filamento';
  @override
  String get configFilamentLater => 'Lo agrego después';
  @override
  String get configFilamentSkipHint =>
      'Puedes agregar filamentos cuando quieras desde Ajustes → Catálogos.';
  @override
  String get configPrinterSaved => 'Impresora registrada';
  @override
  String get configFilamentSaved => 'Filamento agregado';
  @override
  String get configRequirementPending =>
      'Registra al menos una impresora y un filamento para continuar.';
  @override
  String get configRequirementDone =>
      'Listo. Impresora y filamento configurados.';

  // === Feature gates (T14) ===
  @override
  String get calculatorAdvancedLockedBody =>
      'Desbloquea Pro para cotizaciones multi-material';
  @override
  String get calculatorGoProAction => 'Desbloquear PRO';

  // === History cap gate (T15) ===
  @override
  String get historyCapReachedBody =>
      'Llegaste al limite del historial gratuito. Mejora a Pro para historial ilimitado.';

  // === Free-tier catalog gates ===
  @override
  String freePrintersLimitHint(int current, int limit) =>
      '$current/$limit impresoras — desbloquea Pro para más';
  @override
  String freeFilamentsLimitHint(int current, int limit) =>
      '$current/$limit filamentos — desbloquea Pro para más';
  @override
  String filamentLimitReachedTooltip(int limit) =>
      'Límite Free ($limit filamentos)';
  @override
  String filamentLimitReachedBody(int limit) =>
      'Límite de $limit filamentos en modo Free. '
      'Desbloquea Pro para agregar más.';
  @override
  String printerLimitReachedTooltip(int limit) =>
      'Límite Free ($limit impresoras)';
  @override
  String printerLimitReachedBody(int limit) =>
      'Límite de $limit impresoras en modo Free. '
      'Desbloquea Pro para agregar más.';

  // === Pro badge / locked visuals (UX) ===
  @override
  String get proBadgeLabel => 'PRO';
  @override
  String get proLockedTooltip => 'Funcion Pro';
  @override
  String get csvExportTooltipLocked => 'Exportar CSV (Pro)';
  @override
  String historyUsageCounter(int used, int cap) =>
      used == 1 ? '1/$cap cotización' : '$used/$cap cotizaciones';

  // === Paywall (T10) ===
  @override
  String get paywallTitle => 'Desbloquear 3dCalc Pro';
  @override
  String get paywallSubtitle =>
      'Saca el maximo provecho de tu calculadora de costos de impresion 3D';
  @override
  String get paywallPrice => '\$4,99';
  @override
  List<String> get paywallFeatures => const [
    'Elimina la marca de los PDF',
    'Cotizaciones multi-material',
    'Historial ilimitado',
    'Exportar a CSV',
    'Dashboard avanzado con analiticas',
  ];
  @override
  String paywallUnlockButton(String price) => 'Desbloquear por $price';
  @override
  String get paywallRestoreButton => 'Restaurar compras';
  @override
  String get paywallErrorGeneric =>
      'No se pudo completar la compra. Intenta de nuevo.';
  @override
  String get paywallUnavailable =>
      'Las compras no estan disponibles en esta plataforma.';
  @override
  String get paywallAlreadyPro => 'Ya tienes Pro. Gracias!';
  @override
  String get paywallClose => 'Cerrar';

  // T22 — Store compliance
  @override
  String get paywallPrivacyPolicy => 'Politica de Privacidad';
  @override
  String get paywallTermsOfService => 'Terminos del Servicio';
  @override
  String get settingsLegal => 'Legal';

  @override
  String get legalPrivacyDocument =>
      '''Última actualización: 11 de agosto de 2026

1. Alcance
Esta Política de Privacidad describe cómo 3dCalc trata la información cuando utilizas la aplicación. El responsable es Juan Marcelo Albis Ortiz, con domicilio en Bolivia. No necesitas crear una cuenta para utilizar sus funciones principales. La aplicación está destinada a personas de 10 años o más. Si eres menor de edad, debes utilizarla con autorización y supervisión de tu madre, padre o tutor.

2. Información almacenada
Los datos que introduces —como configuraciones, catálogos y cálculos— se almacenan en el dispositivo. Los archivos de respaldo se guardan en la ubicación que selecciones.

3. Compras
Las compras se procesan mediante Google Play. 3dCalc no recibe ni almacena los datos completos de tu tarjeta. La aplicación utiliza RevenueCat como proveedor técnico para gestionar compras, restauraciones y estados de acceso; estos servicios pueden tratar identificadores técnicos, datos de transacción y datos de producto según sus propias políticas.

4. Datos compartidos
No vendemos tus datos ni compartimos el contenido de tus cálculos. La tienda y el proveedor de procesamiento de compras pueden recibir identificadores técnicos y datos de transacción necesarios para validar una compra, conforme a sus políticas.

5. Eliminación y control
Puedes eliminar los datos guardados desde la aplicación o desinstalándola. Los archivos de respaldo exportados deben eliminarse manualmente.

6. Cambios y contacto
Podemos actualizar esta política cuando cambien la aplicación o sus requisitos legales. Para consultas sobre privacidad, contacta a Juan Marcelo Albis Ortiz en marcheloalbis@gmail.com. Google Play y RevenueCat gestionan sus propios datos conforme a sus políticas y procedimientos.

Esta política es informativa y debe revisarse con asesoría legal antes de publicar en una jurisdicción específica.''';

  @override
  String get legalTermsDocument => '''Última actualización: 11 de agosto de 2026

1. Aceptación
Al instalar o utilizar 3dCalc, aceptas estos Términos de Servicio. El proveedor es Juan Marcelo Albis Ortiz, Bolivia. Si no estás de acuerdo, no utilices la aplicación.

2. Uso permitido
Puedes utilizar 3dCalc para realizar cálculos y administrar información de trabajo con fines personales o comerciales. Debes tener al menos 10 años y utilizar la aplicación de acuerdo con la ley aplicable. Si eres menor de edad, necesitas autorización y supervisión de tu madre, padre o tutor.

3. Resultados y responsabilidad
Los resultados son estimaciones y herramientas de apoyo. Verifica entradas, costos, unidades y resultados antes de tomar decisiones comerciales, técnicas o de seguridad. No garantizamos resultados para un caso particular.

4. Compras y restauración
La compra Pro es una compra única, si así aparece configurada en Google Play, y no una suscripción automática. Las compras, restauraciones, precios, impuestos y reembolsos están sujetos a Google Play. RevenueCat proporciona servicios técnicos para validar el estado de la compra.

5. Propiedad intelectual
La aplicación, su diseño y sus recursos pertenecen a sus respectivos titulares. No puedes copiar, redistribuir, modificar ni realizar ingeniería inversa salvo cuando la ley lo permita.

6. Disponibilidad y cambios
Podemos actualizar, suspender o retirar funciones. Estos términos también pueden cambiar; la fecha de actualización se mostrará al inicio. Para consultas, contacta a marcheloalbis@gmail.com.

''';

  // === i18n consistency (hardcoded → l10n) ===
  @override
  String get commonError => 'Error';
  @override
  String get commonNoResults => 'Sin resultados';
  @override
  String get commonDefault => 'Predeterminado';
  @override
  String get commonUndo => 'Deshacer';
  @override
  String get commonSaveImage => 'Guardar imagen';
  @override
  String get commonExportPdf => 'Exportar PDF';
  @override
  String get commonSharePdf => 'Compartir PDF';
  @override
  String get commonPrint => 'Imprimir';
  @override
  String get commonImageDownloaded => 'Imagen descargada';
  @override
  String get commonImageSavedGallery => 'Imagen guardada en galería';
  @override
  String get commonPdfExportError => 'Error al exportar PDF';
  @override
  String get commonPrintError => 'Error al imprimir';
  @override
  String get commonDefaultSuffix => ' (default)';
  @override
  String get historyExportCsv => 'Exportar CSV';
  @override
  String get historyEmptyCta => 'Crea una desde la calculadora y toca Guardar.';
  @override
  @Deprecated('Use calcSectionPieceCosts instead')
  String get calcSectionOthers => 'Otros';
  @override
  String get settingsProfitBaseRange => 'Rango: 0-1000';
  @override
  String get settingsKwhRateRange => 'Rango: 0.10-5.00';
  @override
  String get shareErrorNotRendered =>
      'El resumen aun no se renderizo. Intenta de nuevo en un momento.';
  @override
  String get shareErrorNoRegion =>
      'No se encontro la region capturable del resumen.';
  @override
  String get shareErrorEncode => 'No se pudo codificar la imagen PNG.';
  @override
  String get shareErrorSaveGallery =>
      'No se pudo guardar la imagen en la galeria.';
  @override
  String shareErrorSaveWithMessage(String msg) =>
      'No se pudo guardar la imagen: $msg';
  @override
  String get shareWebUnavailable =>
      'Este navegador no permite abrir el menú de compartir. La imagen se guardó.';

  @override
  String get homeHeroTagline =>
      'Cotizaciones 3D · Rápido · Preciso · Siempre contigo';

  @override
  String get homeHeroSemanticsSuffix => 'Cotizaciones 3D';

  @override
  String get calcFormIncompleteWarning =>
      'Completa el formulario antes de guardar.';
  @override
  String get calcSaveFailed => 'No se pudo guardar.';
  @override
  String calcSavedWithId(int id) => 'Cotización #$id guardada.';
  @override
  String get calcSavedViewAction => 'Ver';
  @override
  String get calcAddMaterial => 'Agregar material';
  @override
  String get calcPrinterPrefix => 'Impresora: ';
  @override
  String get calcChangePrinter => 'Impresora';
  @override
  String get calcSearchPrinter => 'Buscar impresora...';
  @override
  String get calcSelectFilament => 'Filamento';
  @override
  String get calcSearchFilament => 'Buscar filamento...';

  @override
  String get detailBreakdown => 'Desglose';
  @override
  String detailDiscountPct(int pct) => 'Descuento ($pct%)';
  @override
  String get detailPreview => 'Vista previa';

  @override
  String get quoteNoDiscount => 'Sin descuento';
  @override
  String quoteDiscountPct(int pct) => 'Descuento $pct%';
  @override
  String get quoteDetail => 'Detalle';
  @override
  String get quoteGeneratedWith => 'Generado con 3dCalc';

  @override
  String get pdfFileName => 'cotizacion_3dcalc.pdf';
  @override
  String get pdfShareSubject => 'Cotización 3dCalc';
  @override
  String get pdfDatePrefix => 'Fecha: ';
  @override
  String get pdfQuoteNumber => 'N\u00ba ';
  @override
  String get pdfValidUntilPrefix => 'V\u00e1lido hasta: ';
  @override
  String get pdfClientPrefix => 'Cliente: ';
  @override
  String get pdfNotesTitle => 'Notas';
  @override
  String get pdfConditionsTitle => 'Condiciones';
  @override
  String get pdfMaterialCosts => 'Costo materiales';
  @override
  String get pdfElectricity => 'Electricidad';
  @override
  String get pdfTotalUpper => 'TOTAL';
  @override
  String get pdfHoursPrefix => 'Horas: ';
  @override
  String pdfDiscountPct(int pct) => 'Descuento: $pct%';

  @override
  String get pdfWeight => 'Peso: ';
  @override
  String get pdfPrintTime => 'Tiempo impresion: ';
  @override
  String get pdfTechnicalData => 'Datos tecnicos';
  @override
  String get pdfMaterialsSection => 'Materiales';

  @override
  String get dashboardEmptySubtitle =>
      'Crea tu primera cotización desde el inicio.';
  @override
  String get dashboardMonthlyTrend => 'Tendencia mensual';
  @override
  String get dashboardTopMaterials => 'Materiales más usados';

  @override
  String get dashboardProfitTitle => 'Rentabilidad';
  @override
  String get dashboardStatEstimatedProfit => 'Ganancia estimada';
  @override
  String get dashboardMarginLabel => 'Margen promedio';
  @override
  String get dashboardAvgTicketTitle => 'Ticket promedio';
  @override
  String get dashboardAvgTicketQuoted => 'Ticket promedio (cotizado)';
  @override
  String get dashboardAvgTicketSold => 'Ticket promedio (vendido)';
  @override
  String get dashboardTopClients => 'Top clientes';
  @override
  String get dashboardOperationalTitle => 'Métricas operativas';
  @override
  String get dashboardPrintHours => 'Horas de impresión';
  @override
  String get dashboardFilament => 'Filamento';
  @override
  String get dashboardPrinterNoLifeData =>
      'Configura la vida util para ver el estado de la impresora';
  @override
  String get dashboardPrinterRemaining => 'restantes';
  @override
  String get dashboardPrinterLifeEnd => 'Vida util agotada';
  @override
  String get dashboardInsightsTitle => 'Insights';
  @override
  String get dashboardRange7d => '7d';
  @override
  String get dashboardRange30d => '30d';
  @override
  String get dashboardRange90d => '90d';
  @override
  String get dashboardRangeYtd => 'YTD';
  @override
  String get dashboardRangeAll => 'Todo';
  @override
  String insightConversion(int sold, int total, int pct) =>
      'Vendiste $sold de $total cotizaciones ($pct%)';
  @override
  String insightAvgTicketSold(String amount) =>
      'Ticket promedio vendido: $amount';
  @override
  String insightBestMonth(String month, String amount) =>
      'Mejor mes: $month ($amount)';
  @override
  String insightTopClient(String name, String amount) =>
      'Cliente top: $name ($amount)';
  @override
  String insightFilament(String amount) => 'Has cotizado $amount de filamento';

  @override
  String get historyFilterAll => 'Todas';
  @override
  String get historyFilterSold => 'Vendidas';
  @override
  String get historyFilterPending => 'Pendientes';
  @override
  String get historyNoQuotesToExport => 'No hay cotizaciones para exportar';

  @override
  String get historyFilterDate => 'Fechas';
  @override
  String get historyDatePresetToday => 'Hoy';
  @override
  String get historyDatePreset7d => '7 días';
  @override
  String get historyDatePreset30d => '30 días';
  @override
  String get historyDatePresetMonth => 'Este mes';
  @override
  String get historyDatePresetYear => 'Este año';
  @override
  String get historyDatePresetAll => 'Todo';
  @override
  String get historyDatePresetCustom => 'Personalizado';
  @override
  String historyDateRangeLabel(DateTimeRange range) {
    final from = DateFormat('dd/MM').format(range.start);
    final to = DateFormat('dd/MM').format(range.end);
    return '$from – $to';
  }

  @override
  String get historySortTitle => 'Orden';
  @override
  String get historySortDateNewest => 'Más recientes';
  @override
  String get historySortDateOldest => 'Más antiguos';
  @override
  String get historySortPriceHigh => 'Precio mayor';
  @override
  String get historySortPriceLow => 'Precio menor';
  @override
  String get historySortClientAz => 'Cliente A-Z';
  @override
  String historyClientFilterChip(String name) => 'Cliente: $name';
  @override
  String historyFilterSummary(int count, String total) =>
      count == 1 ? '1 cotización · $total' : '$count cotizaciones · $total';
  @override
  String get historySearchMaterialsHint =>
      'Buscar por pieza, cliente o material...';

  @override
  String get chartNoMonthlyData => 'Sin datos mensuales';
  @override
  List<String> get chartShortMonths => const [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  String get filamentSearchHint => 'Buscar filamentos...';
  @override
  String filamentDeleted(String name) => '"$name" eliminado';
  @override
  String get printerSearchHint => 'Buscar impresoras...';
  @override
  String printerDeleted(String name) => '"$name" eliminada';
  @override
  String get printerErrorSave => 'Error guardando';

  @override
  String get settingsErrorLoad => 'Error cargando ajustes';
  @override
  String get settingsCurrencySearchHint =>
      'Buscar moneda por código o nombre...';
  @override
  String settingsCurrencyNoResults(String query) =>
      'Sin resultados para "$query"';
  @override
  String get settingsCurrencySymbolPrefix => 'Símbolo: ';

  @override
  String get routeNotFound => 'Página no encontrada';
  @override
  String get routeBackHome => 'Volver a Inicio';

  @override
  String get themeModeSystem => 'Sistema';
  @override
  String get themeModeLight => 'Claro';
  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get splashLogo => '3dCalc logo';
  @override
  String onboardingPageCounter(int page, int total) => 'Página $page de $total';
  @override
  String commonNoResultsFor(String query) => 'Sin resultados para "$query"';
  @override
  String get historyEmptySearchHint => 'Prueba con otro término.';

  @override
  String get filamentErrorLoad => 'Error cargando filamentos';
  @override
  String filamentNoResults(String query) =>
      'Ningún filamento coincide con "$query"';
  @override
  String get filamentEmptyList =>
      'Sin filamentos. Toca + para crear el primero.';
  @override
  String filamentDeleteConfirm(String name) => '¿Eliminar "$name"?';

  @override
  String get printerErrorLoad => 'Error cargando impresoras';
  @override
  String printerNoResults(String query) =>
      'Ninguna impresora coincide con "$query"';
  @override
  String get printerEmptyList =>
      'Sin impresoras. Toca + para registrar la primera.';
  @override
  String printerDeleteConfirm(String name) => '¿Eliminar "$name"?';

  // === Color de filamento (PRD 2026-09-08) ===
  @override
  String get colorNameRed => 'Rojo';
  @override
  String get colorNameOrange => 'Naranja';
  @override
  String get colorNameAmber => 'Ámbar';
  @override
  String get colorNameYellow => 'Amarillo';
  @override
  String get colorNameLime => 'Lima';
  @override
  String get colorNameGreen => 'Verde';
  @override
  String get colorNameTeal => 'Verde azulado';
  @override
  String get colorNameCyan => 'Cian';
  @override
  String get colorNameBlue => 'Azul';
  @override
  String get colorNameIndigo => 'Índigo';
  @override
  String get colorNamePurple => 'Púrpura';
  @override
  String get colorNameMagenta => 'Magenta';
  @override
  String get colorNamePink => 'Rosa';
  @override
  String get colorNameBrown => 'Marrón';
  @override
  String get colorNameGray => 'Gris';
  @override
  String get colorNameBlack => 'Negro';
  @override
  String get colorNameWhite => 'Blanco';

  @override
  String get quoteGuideTitle => 'Cómo funciona la cotización';
  @override
  String get quoteGuideMenuLabel => 'Guía';
  @override
  String get quoteGuideStep1Title => 'Elige el modo';
  @override
  String get quoteGuideStep1Body =>
      'Modo Express: solo 3 campos (peso, horas y precio de bobina) para '
      'una cotización rápida. Modo Avanzado: control total de materiales, '
      'impresora y desglose.';
  @override
  String get quoteGuideStep2Title => 'Material';
  @override
  String get quoteGuideStep2Body =>
      'Elige un filamento del catálogo o ingresa precio y gramos de la '
      'bobina. Puedes usar varios materiales en modo Avanzado.';
  @override
  String get quoteGuideStep3Title => 'Impresora';
  @override
  String get quoteGuideStep3Body =>
      'Selecciona la impresora activa: con su potencia registrada la app '
      'calcula el costo de energía de la impresión.';
  @override
  String get quoteGuideStep4Title => 'Tiempo de impresión';
  @override
  String get quoteGuideStep4Body =>
      'Indica horas y minutos estimados de impresión. Es la base del costo '
      'de energía y de la mano de obra.';
  @override
  String get quoteGuideStep5Title => 'Extras opcionales';
  @override
  String get quoteGuideStep5Body =>
      'Mano de obra, post-procesado, tasa de fallas, cargo mínimo y markup '
      'sobre materiales. Se configuran en Ajustes y ajustan el precio final.';
  @override
  String get quoteGuideStep6Title => 'Resultado y guardado';
  @override
  String get quoteGuideStep6Body =>
      'El total se actualiza en vivo. Toca el total para ver el desglose, '
      'aplicar descuento y guardar. Luego puedes compartir/exportar y el '
      'historial alimenta tu dashboard.';
  @override
  String get quoteGuideNext => 'Siguiente';
  @override
  String get quoteGuideClose => 'Entendido';
  @override
  String quoteGuidePageCounter(int page, int total) => 'Paso $page de $total';
  @override
  String get commonMoreActions => 'Más acciones';
}
