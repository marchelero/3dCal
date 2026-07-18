/// Strings en ingles (en_US).
library;

import 'app_strings.dart';

class EnImpl implements AppStrings {
  const EnImpl();

  @override
  String get appName => '3dcalc';

  @override
  String get commonSave => 'Save';
  @override
  String get commonCancel => 'Cancel';
  @override
  String get commonDelete => 'Delete';
  @override
  String get commonRetry => 'Retry';
  @override
  String get commonEdit => 'Edit';
  @override
  String get commonNew => 'New';
  @override
  String get commonRequired => 'Required';
  @override
  String get commonInvalidNumber => 'Invalid number';
  @override
  String get commonLoading => 'Loading...';
  @override
  String get commonErrorGeneric =>
      'Something went wrong. Please try again.';

  @override
  String get navHome => 'Home';
  @override
  String get navHistory => 'History';
  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsGlobalParams => 'Global parameters';
  @override
  String get settingsProfitBase => 'Base profit (%)';
  @override
  String get settingsProfitBaseHelper =>
      'Margin over base cost. 0-1000';
  @override
  String settingsKwhRate(String symbol) =>
      'Electricity rate ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper =>
      'Residential range Bolivia: 0.10-5.00';
  @override
  String get settingsCatalogos => 'Catalogs';
  @override
  String get settingsFilamentos => 'Filaments';
  @override
  String get settingsImpresoras => 'Printers';
  @override
  String get settingsAbout => 'About';
  @override
  String get settingsPrivacy =>
      'Privacy: 100% local, no telemetry';
  @override
  String get settingsSaved => 'Saved';
  @override
  String get settingsAppearance => 'Appearance';
  @override
  String get settingsTheme => 'Theme';
  @override
  String get settingsManageFilaments =>
      'Manage your filaments';
  @override
  String get settingsManagePrinters =>
      'Register your printers';

  @override
  String get settingsLaborPost =>
      'Labor and post-processing';
  @override
  String settingsLaborRate(String symbol) =>
      'Labor rate ($symbol/hour)';
  @override
  String get settingsLaborRateHelper =>
      'Operator/technician cost per print hour. 0 = disabled';
  @override
  String get settingsPostProcessRate =>
      'Post-process (%)';
  @override
  String get settingsPostProcessRateHelper =>
      '% of material cost. E.g. 10 = +10% finishing/sanding/painting';
  @override
  String get settingsFailureRate =>
      'Failure rate (%)';
  @override
  String get settingsFailureRateHelper =>
      '% of base cost to cover failed prints. 0 = disabled';
  @override
  String settingsMinimumCharge(String symbol) =>
      'Minimum charge ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Quotes below this amount are automatically adjusted';
  @override
  String get settingsMarkupOnMaterials =>
      'Waste markup (%)';
  @override
  String get settingsMarkupOnMaterialsHelper =>
      '% extra on material cost for waste/wear';

  @override
  String get settingsCurrency => 'Currency';
  @override
  String get settingsCurrencyHelper =>
      'Sets the currency shown in prices, quotes and dashboard. No automatic conversion.';

  @override
  String get settingsCompany => 'Company';
  @override
  String get settingsCompanyName => 'Company name';
  @override
  String get settingsCompanyNameHelper =>
      'Appears on the quote. Default: 3dCalc';
  @override
  String get settingsCompanyLogo => 'Logo';
  @override
  String get settingsCompanyLogoPick =>
      'Pick image';
  @override
  String get settingsCompanyLogoRemove =>
      'Remove logo';
  @override
  String get settingsCompanyLogoError =>
      'Error loading image';

  @override
  String get dashboardTitle => 'Dashboard';
  @override
  String get dashboardErrorLoad =>
      'Error loading dashboard';
  @override
  String get dashboardEmpty =>
      'No quotes yet';
  @override
  String get dashboardEmptyCta => 'Go to Home';
  @override
  String get dashboardStatQuotations =>
      'Quotations';
  @override
  String get dashboardStatSold => 'Sold';
  @override
  String get dashboardStatConversion =>
      'Conversion';
  @override
  String get dashboardTotalQuoted =>
      'Total quoted';
  @override
  String get dashboardTotalSold =>
      'Total sold';
  @override
  String get dashboardChartTitle =>
      'Quoted vs Earned';
  @override
  String get dashboardChartQuoted => 'Quoted';
  @override
  String get dashboardChartSold => 'Earned';

  @override
  String get homeActionNewCalc =>
      'New quotation';
  @override
  String get homeActionNewCalcSub =>
      'Calculate print price';
  @override
  String get homeActionHistory => 'History';
  @override
  String get homeActionHistorySub =>
      'Saved quotations';
  @override
  String get homeActionDashboard =>
      'Dashboard';
  @override
  String get homeActionDashboardSub =>
      'Stats and charts';
  @override
  String get homeQuickAccess => 'Quick access';
  @override
  String get homeErrorLoadStats =>
      'Error loading stats';
  @override
  String get homeEmptyQuotations =>
      'No quotations yet';
  @override
  String get homeSummary => 'Summary';
  @override
  String get homeSeeAll => 'See all';

  @override
  String get calcSectionPiece => 'Piece';
  @override
  String get calcSectionFilament => 'Filament';
  @override
  String get calcSectionTime =>
      'Print time';
  @override
  String get calcSectionDiscount =>
      'Discount';
  @override
  String get calcLabelOptional =>
      'Label (optional)';
  @override
  String get calcLabelOptionalHelper =>
      'E.g.: Wall bracket, PETG Gear';
  @override
  String get calcLabelWeight =>
      'Piece weight';
  @override
  String get calcLabelWeightHelper =>
      'Grams of the model';
  @override
  String get calcLabelHours => 'Hours';
  @override
  String get calcLabelHoursHelper =>
      '0-24';
  @override
  String get calcLabelMinutes => 'Minutes';
  @override
  String get calcLabelMinutesHelper =>
      '0-59';
  @override
  String get calcLabelDiscount =>
      'Discount';
  @override
  String get calcLabelDiscountHelper =>
      'Percentage off the final total';
  @override
  String get calcBtnSave =>
      'Save quotation';
  @override
  String get calcBtnReset =>
      'Reset values';
  @override
  String get calcToggleShowDetail =>
      'Show detail';
  @override
  String get calcToggleHideDetail =>
      'Hide detail';
  @override
  String get calcTotalWithDiscount =>
      'Total with discount';
  @override
  String get calcTotalFinal =>
      'Final total';
  @override
  String get calcDetailMaterial =>
      'Material cost';
  @override
  String get calcDetailEnergy =>
      'Energy cost';
  @override
  String get calcDetailLabor =>
      'Labor';
  @override
  String get calcDetailPostProcess =>
      'Post-process';
  @override
  String get calcDetailBase =>
      'Base cost';
  @override
  String get calcDetailFailure =>
      'Failure rate';
  @override
  String get calcDetailMarkup =>
      'Waste markup';
  @override
  String get calcDetailProfit => 'Profit';
  @override
  String get calcDetailMinimumCharge =>
      'Minimum charge';
  @override
  String get calcDetailTotal =>
      'Final total';
  @override
  String get calcEmptyHint =>
      'Fill in weight, filament and time to see the price';
  @override
  String get calcSectionMaterials => 'Materials';
  @override
  String get calcSectionPrinter => 'Printer';
  @override
  String get calcNoPrinter => 'No printer registered';
  @override
  String get calcNoMaterials => 'No materials.';

  @override
  String get calcEmptyHintPrefix => 'Fill in';
  @override
  String get calcEmptyHintSuffix =>
      'to see the quotation';
  @override
  String get calcFieldWeightShort =>
      'piece weight';
  @override
  String get calcFieldPriceShort =>
      'filament price';
  @override
  String get calcFieldTimeShort =>
      'print time';
  @override
  String get calcFieldMaterialShort =>
      'at least one material';

  @override
  String get calcMetaSeparator => ' · ';

  @override
  String get calcResultBarTapHint =>
      'View quotation';
  @override
  String get calcResultBarEmptyHint =>
      'Incomplete';
  @override
  String get calcSheetTitle =>
      'Quotation';
  @override
  String get calcBtnShare =>
      'Share image';
  @override
  String get calcBtnShareTooltip =>
      'Generates a ready-to-share image';
  @override
  String get calcShareError =>
      'Could not generate the image';
  @override
  String get calcShareSubject =>
      '3D Quotation';
  @override
  String get calcShareText =>
      'Quotation generated in 3dCalc';
  @override
  String get calcSheetActionsLabel =>
      'Actions';

  @override
  String get filamentTitle => 'Filaments';
  @override
  String get filamentNew => 'New filament';
  @override
  String get filamentEdit => 'Edit filament';
  @override
  String get filamentName => 'Name';
  @override
  String get filamentNameHelper =>
      'E.g.: PLA Black';
  @override
  String get filamentBrand => 'Brand';
  @override
  String get filamentBrandHelper =>
      'Optional';
  @override
  String filamentPrice(String symbol) =>
      'Filament price ($symbol)';
  @override
  String get filamentPriceHelper =>
      'Full spool cost';
  @override
  String get filamentGrams =>
      'Grams per spool';
  @override
  String get filamentGramsHelper =>
      'Typically 1000';
  @override
  String get filamentDefaultToggle =>
      'Set as default';
  @override
  String get filamentDefaultSubtitle =>
      'Will be used in new quotations. Only one filament can be default.';
  @override
  String get filamentNewTooltip =>
      'New filament';
  @override
  String get filamentDeleteTitle =>
      'Delete filament';
  @override
  String get filamentErrorSave =>
      'Error saving';
  @override
  String get filamentMustBePositive =>
      'Must be > 0';
  @override
  String get filamentMustBeInteger =>
      'Must be integer';
  @override
  String get filamentMax100 =>
      'Max 100 characters';

  @override
  String get printerTitle => 'Printers';
  @override
  String get printerNew => 'New printer';
  @override
  String get printerEdit => 'Edit printer';
  @override
  String get printerModel => 'Model';
  @override
  String get printerModelHelper =>
      'E.g.: Ender 3 V2';
  @override
  String get printerBrandHelper =>
      'E.g.: Creality, Anycubic';
  @override
  String get printerWatts =>
      'Average consumption (W)';
  @override
  String get printerWattsHelper =>
      'Typically 100-300 W';
  @override
  String get printerDefaultSubtitle =>
      'Will be used in new quotations. Only one printer can be default.';
  @override
  String get printerNewTooltip =>
      'New printer';
  @override
  String get printerDeleteTitle =>
      'Delete printer';
  @override
  String get printerMustBeNonNegative =>
      'Must be >= 0';

  @override
  String get calcNotifFilament =>
      'Filament';
  @override
  String get calcNotifMaterial =>
      'Material';

  @override
  String get calcDetailTitle =>
      'Quotation detail';
  @override
  String get calcDetailDelete => 'Delete';
  @override
  String get calcDetailDeleteTitle =>
      'Delete quotation';
  @override
  String get calcDetailDeleteConfirm =>
      'Delete permanently?';
  @override
  String get calcDetailNoName =>
      'Unnamed';
  @override
  String get calcDetailSold => 'Sold';
  @override
  String get calcDetailReuse => 'Reuse';
  @override
  String get calcDetailMarkSold =>
      'Mark as sold';
  @override
  String get calcDetailMarkPending =>
      'Mark as pending';

  @override
  String get historyTitle =>
      'Quotations';
  @override
  String get historyErrorLoad =>
      'Error loading quotations';
  @override
  String get historyEmpty =>
      'No saved quotations';

  @override
  String get localeLabel => 'Language';
  @override
  String get localeEs => 'Spanish';
  @override
  String get localeEn => 'English';
  @override
  String get onboardingTitle1 => 'Welcome to 3dCalc';
  @override
  String get onboardingDesc1 => 'Calculate 3D print pricing instantly.\nMaterials, electricity, labor and more.';
  @override
  String get onboardingTitle2 => 'Two calculation modes';
  @override
  String get onboardingDesc2 => 'Express: quick calculation with one material.\nAdvanced: multiple materials, discount and more.';
  @override
  String get onboardingTitle3 => 'Built-in catalog';
  @override
  String get onboardingDesc3 => 'Save your favorite filaments and printers.\nPick them instantly from the catalog.';
  @override
  String get onboardingTitle4 => 'Dashboard & more';
  @override
  String get onboardingDesc4 => 'Track quotations, monthly trends,\nPDF export and search history.';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingStart => 'Get Started';
  @override
  String get configTitle => 'Initial Setup';
  @override
  String get configLanguage => 'Language';
  @override
  String get configCurrency => 'Currency';
  @override
  String get configContinue => 'Continue';
}
