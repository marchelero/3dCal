/// Strings en ingles (en_US).
library;
// ignore_for_file: public_member_api_docs

import 'app_strings.dart';

class EnImpl implements AppStrings {
  const EnImpl();

  @override
  String get appName => '3dCalc';

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
  String get commonErrorGeneric => 'Something went wrong. Please try again.';

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
  String get settingsProfitBaseHelper => 'Margin over base cost. 0-1000';
  @override
  String settingsKwhRate(String symbol) => 'Electricity rate ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper => 'Residential range Bolivia: 0.10-5.00';
  @override
  String get settingsCatalogos => 'Catalogs';
  @override
  String get settingsFilamentos => 'Filaments';
  @override
  String get settingsImpresoras => 'Printers';
  @override
  String get settingsAbout => 'About';
  @override
  String get settingsPrivacy => 'Privacy and data';
  @override
  String get settingsSaved => 'Saved';
  @override
  String get settingsAppearance => 'Appearance';
  @override
  String get settingsTheme => 'Theme';
  @override
  String get settingsManageFilaments => 'Manage your filaments';
  @override
  String get settingsManagePrinters => 'Register your printers';

  @override
  String get settingsLaborPost => 'Labor and post-processing';
  @override
  String settingsLaborRate(String symbol) => 'Labor rate ($symbol/hour)';
  @override
  String get settingsLaborRateHelper =>
      'Operator/technician cost per print hour. 0 = disabled';
  @override
  String get settingsPostProcessRate => 'Post-process (%)';
  @override
  String get settingsPostProcessRateHelper =>
      '% of material cost. E.g. 10 = +10% finishing/sanding/painting';
  @override
  String get settingsFailureRate => 'Failure rate (%)';
  @override
  String get settingsFailureRateHelper =>
      '% of base cost to cover failed prints. 0 = disabled';
  @override
  String settingsMinimumCharge(String symbol) => 'Minimum charge ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Quotes below this amount are automatically adjusted';
  @override
  String get settingsMarkupOnMaterials => 'Waste markup (%)';
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
  String get settingsCompanyLogoPick => 'Pick image';
  @override
  String get settingsCompanyLogoRemove => 'Remove logo';
  @override
  String get settingsCompanyLogoError => 'Error loading image';

  @override
  String get settingsBrandingLockedBody => 'Unlock Pro to customize your brand';
  @override
  String get settingsGoProAction => 'Unlock PRO';
  @override
  String get settingsProTitle => '3D Cal PRO';
  @override
  String get settingsProActive => 'PRO active';
  @override
  String get settingsProUnlocked => 'You have all PRO features unlocked';
  @override
  String get settingsProNoAdditionalPurchase =>
      'You do not need to make another purchase';
  @override
  String get settingsProFutureUpdates =>
      'Your purchase includes future PRO improvements at no additional cost.';
  @override
  String get settingsProRestorePurchase => 'Restore purchase';

  @override
  String get settingsRestorePurchases => 'Restore purchases';
  @override
  String get settingsRestoreSuccess => 'Purchases restored successfully!';
  @override
  String get settingsRestoreEmpty => 'No previous purchases found';
  @override
  String get settingsRestoreError => 'Could not restore purchases.';

  @override
  String get settingsBackupTitle => 'Backup';

  @override
  String get settingsBackupExport => 'Export backup';

  @override
  String get settingsBackupImport => 'Import backup';

  @override
  String get settingsBackupHelper =>
      'Save or restore all your data (filaments, printers, quotes). It is recommended to make periodic backups.';

  @override
  String get settingsBackupExportSuccess => 'Backup exported successfully';

  @override
  String get settingsBackupExportError => 'Error exporting backup';

  @override
  String settingsBackupImportSuccess(int calcs, int filaments, int printers) =>
      'Backup restored: $calcs quotes, $filaments filaments, $printers printers';

  @override
  String get settingsBackupImportError => 'Error importing backup';

  @override
  String get settingsBackupImportConfirmTitle => 'Restore backup?';

  @override
  String settingsBackupImportConfirmBody(String summary) =>
      'ALL current data will be replaced with:\n$summary\n\nThis action cannot be undone.';

  @override
  String get settingsBackupImportConfirm => 'Restore';

  @override
  String get settingsBackupImportCancel => 'Cancel';

  @override
  String get settingsBackupImportSizeError =>
      'The backup file exceeds the maximum allowed size.';

  @override
  String get settingsBackupImportInvalidFile =>
      'The selected file is not a valid backup.';

  @override
  String get settingsBackupImportFutureVersion =>
      'This backup was created with a future version of the app. '
      'Update 3dCalc and try again.';

  @override
  String get settingsBackupLockedBody => 'Backups are a Pro feature.';

  @override
  String get dashboardTitle => 'Dashboard';
  @override
  String get dashboardErrorLoad => 'Error loading dashboard';
  @override
  String get dashboardEmpty => 'No quotes yet';
  @override
  String get dashboardEmptyCta => 'Go to Home';
  @override
  String get dashboardStatQuotations => 'Quotations';
  @override
  String get dashboardStatSold => 'Sold';
  @override
  String get dashboardStatConversion => 'Conversion';
  @override
  String get dashboardTotalQuoted => 'Total quoted';
  @override
  String get dashboardTotalSold => 'Total sold';
  @override
  String get dashboardChartTitle => 'Quoted vs Earned';
  @override
  String get dashboardChartQuoted => 'Quoted';
  @override
  String get dashboardChartSold => 'Earned';
  @override
  String get dashboardProTeaserTitle => 'Unlock Pro Analytics';
  @override
  String get dashboardProTeaserBody =>
      'Get the complete dashboard with cost trends, material breakdowns, and more.';
  @override
  String get dashboardGoProAction => 'Unlock PRO';

  @override
  String get homeActionNewCalc => 'New quotation';
  @override
  String get homeActionNewCalcSub => 'Calculate print price';
  @override
  String get homeActionHistory => 'History';
  @override
  String get homeActionHistorySub => 'Saved quotations';
  @override
  String get homeActionDashboard => 'Dashboard';
  @override
  String get homeActionDashboardSub => 'Stats and charts';
  @override
  String get homeQuickAccess => 'Quick access';
  @override
  String get homeErrorLoadStats => 'Error loading stats';
  @override
  String get homeEmptyQuotations => 'No quotations yet';
  @override
  String get homeSummary => 'Summary';
  @override
  String get homeSeeAll => 'See all';

  @override
  String get calcSectionPiece => 'Piece';
  @override
  String get calcSectionWeight => 'Part weight';
  @override
  String get calcSectionFilament => 'Filament';
  @override
  String get calcSectionTime => 'Print time';
  @override
  String get calcSectionDiscount => 'Discount';
  @override
  String get calcLabelOptional => 'Label (optional)';
  @override
  String get calcLabelOptionalHelper => 'E.g.: Wall bracket, PETG Gear';
  @override
  String get calcLabelWeight => 'Piece weight';
  @override
  String get calcLabelWeightHelper => 'Grams of the model';
  @override
  String get calcLabelHours => 'Hours';
  @override
  String get calcLabelHoursHelper => '0-24';
  @override
  String get calcLabelMinutes => 'Minutes';
  @override
  String get calcLabelMinutesHelper => '0-59';
  @override
  String get calcLabelDiscount => 'Discount';
  @override
  String get calcLabelDiscountHelper => 'Percentage off the final total';
  @override
  String get calcBtnSave => 'Save quotation';
  @override
  String get calcBtnReset => 'Reset values';
  @override
  String get calcToggleShowDetail => 'Show detail';
  @override
  String get calcToggleHideDetail => 'Hide detail';
  @override
  String get calcTotalWithDiscount => 'Total with discount';
  @override
  String get calcTotalFinal => 'Total';
  @override
  String get calcDetailMaterial => 'Material cost';
  @override
  String get calcDetailEnergy => 'Energy cost';
  @override
  String get calcDetailLabor => 'Labor';
  @override
  String get calcDetailPostProcess => 'Post-process';
  @override
  String get calcDetailBase => 'Base cost';
  @override
  String get calcDetailFailure => 'Failure rate';
  @override
  String get calcDetailMarkup => 'Waste markup';
  @override
  String get calcDetailProfit => 'Profit';
  @override
  String get calcDetailMinimumCharge => 'Minimum charge';
  @override
  String get calcDetailTotal => 'Total';
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
  String get calcPrinterEmptyCta => 'Register printer';
  @override
  String get calcPrinterEmptyHint =>
      'Calculates without energy cost. Register one to add it.';
  @override
  String get calcNoMaterials => 'No materials.';

  @override
  String get calcKeyWeightHint => 'Key: required to calculate the quotation';
  @override
  String get calcKeyHoursHint => 'Key: drives labor and energy costs';
  @override
  String get calcKeyMinutesHint => 'Key: enter the actual print time';

  @override
  String calcMaterialTitle(int index) => 'Material $index';
  @override
  String calcMaterialRemove(int index) => 'Remove material $index';
  @override
  String get calcMaterialCatalog => 'Catalog';
  @override
  String calcMaterialUse(String filamentName) => 'Use $filamentName';
  @override
  String get calcFieldLabel => 'Label';
  @override
  String get calcFieldLabelHelper => 'Optional (e.g.: PLA base)';
  @override
  String get calcFieldFilament => 'Filament';
  @override
  String get calcFieldWeight => 'Weight';
  @override
  String get calcFieldSpoolPrice => 'Spool price';
  @override
  String get calcFieldSpoolGrams => 'Grams / spool';

  @override
  String get calcFieldLabor => 'Labor';
  @override
  String get calcFieldLaborHelper => 'Hourly rate';
  @override
  String get calcFieldPostProcess => 'Post-processing';
  @override
  String get calcFieldPostProcessHelper => '% of material cost';
  @override
  String get calcFieldFailure => 'Failure rate';
  @override
  String get calcFieldFailureHelper => '% of base cost';
  @override
  String get calcFieldWaste => 'Waste';
  @override
  String get calcFieldWasteHelper => '% waste markup';

  @override
  String get costHelpTitle => 'How to calibrate your costs';

  @override
  String get costHelpEnergyTitle => 'Energy cost';

  @override
  String get costHelpEnergyBody =>
      'Energy used while printing: print hours × power (kW) × rate (\$/kWh). '
      'E.g.: 6 h × 0.15 kW × 1.2 \$/kWh ≈ \$1.08. Only added if the printer '
      'has a registered wattage.';

  @override
  String get costHelpLaborTitle => 'Labor';

  @override
  String get costHelpLaborBody =>
      'Your time: work hours × hourly rate (\$/h). Includes prepping the '
      'printer, supervising the print, and final finishing.';

  @override
  String get costHelpPostTitle => 'Post-processing';

  @override
  String get costHelpPostBody =>
      'Extra percentage on material cost for sanding, painting, glue, or '
      'other finishes.';

  @override
  String get costHelpFailureTitle => 'Failure rate';

  @override
  String get costHelpFailureBody =>
      'Percentage of the base cost reserved for failed prints. If 1 in 10 '
      'prints fails, that 10% is spread over the 9 you actually sell.';

  @override
  String get costHelpWasteTitle => 'Waste & wear';

  @override
  String get costHelpWasteBody =>
      'Extra percentage on materials: supports, nozzle purge, test filament, '
      'and printer wear.';

  @override
  String get costHelpMinimumChargeTitle => 'Minimum charge';

  @override
  String get costHelpMinimumChargeBody =>
      'Price floor. If the calculated total is below this amount, this '
      'minimum is charged. Ideal for small parts that still need printer '
      'setup.';

  @override
  String get costHelpMarginTitle => 'Profit (margin)';

  @override
  String get costHelpMarginBody =>
      'Percentage added to the total cost for your profit: total × '
      '(1 + margin/100). Adjusted under Global parameters.';

  @override
  String get calcCloseAction => 'Close and return to menu';

  @override
  String get calcModeExpress => 'Express';
  @override
  String get calcModeAdvanced => 'Advanced';
  @override
  String calcSemanticMode(String mode) => 'Calculation mode: $mode';

  @override
  String get calcActionReset => 'Reset';

  @override
  String get calcDialogClient => 'Client';
  @override
  String get calcDialogClientHelper => 'Optional';
  @override
  String get calcDialogRecentClients => 'Recent clients';
  @override
  String get calcDialogNotes => 'Notes (optional)';
  @override
  String get calcDialogNotesHelper => 'Specs, deadlines, delivery\u2026';
  @override
  String get calcDialogConditions => 'Business conditions (optional)';
  @override
  String get calcDialogConditionsHelper => 'Validity, payment, warranty\u2026';
  @override
  String get calcTemplatesTitle => 'Templates';
  @override
  String get calcTemplateSaveAsAction => 'Save as template';
  @override
  String get calcTemplateSaveSuccess => 'Template saved';
  @override
  String get calcTemplateSaveError => 'Could not save the template';
  @override
  String get calcTemplateApplySuccess => 'Template applied to the form';
  @override
  String get calcTemplateApplyError => 'Could not load the template';
  @override
  String get calcTemplateEmpty =>
      'No templates yet.\nSave a frequent job as a template to reuse it.';
  @override
  String get calcTemplateUntitled => 'Untitled';
  @override
  String get calcTemplateDeleteError => 'Could not delete the template';

  @override
  String get calcEmptyHintPrefix => 'Fill in';
  @override
  String get calcEmptyHintSuffix => 'to see the quotation';
  @override
  String get calcFieldWeightShort => 'piece weight';
  @override
  String get calcFieldPriceShort => 'filament price';
  @override
  String get calcFieldTimeShort => 'print time';
  @override
  String get calcFieldMaterialShort => 'at least one material';

  @override
  String get calcMetaSeparator => ' · ';

  @override
  String get calcResultBarTapHint => 'View quotation';
  @override
  String get calcResultBarEmptyHint => 'Incomplete';
  @override
  String get calcSheetTitle => 'Quotation';
  @override
  String get calcBtnShare => 'Share image';
  @override
  String get calcBtnShareTooltip => 'Generates a ready-to-share image';
  @override
  String get calcShareError => 'Could not generate the image';
  @override
  String get calcShareSubject => '3D Quotation';
  @override
  String get calcShareText => 'Quotation generated in 3dCalc';
  @override
  String get calcSheetActionsLabel => 'Actions';

  // === Quote image (part photo) ===
  @override
  String get quoteImageAdd => 'Add image';
  @override
  String get quoteImageGallery => 'Gallery';
  @override
  String get quoteImageCamera => 'Camera';
  @override
  String get quoteImageChange => 'Change';
  @override
  String get quoteImageRemove => 'Remove';
  @override
  String get quoteImageTooLarge => 'Image exceeds 5 MB and was not attached.';
  @override
  String get quoteImageInvalidFormat =>
      'Invalid image format (JPEG, PNG or WebP only).';
  @override
  String get quoteImageError => 'Could not get the image';

  @override
  String get filamentTitle => 'Filaments';
  @override
  String get filamentNew => 'New filament';
  @override
  String get filamentEdit => 'Edit filament';
  @override
  String get filamentName => 'Name';
  @override
  String get filamentNameHelper => 'E.g.: PLA Black';
  @override
  String get filamentBrand => 'Brand';
  @override
  String get filamentBrandHelper => 'Optional';
  @override
  String get brandSelectorOther => 'Other...';
  @override
  String get brandSelectorHint => 'Choose a brand or select Other to type it';
  @override
  String get brandSelectorManualHelper => 'Type the brand name';
  @override
  String filamentPrice(String symbol) => 'Filament price ($symbol)';
  @override
  String get filamentPriceHelper => 'Full spool cost';
  @override
  String get filamentGrams => 'Grams per spool';
  @override
  String get filamentGramsHelper => 'Typically 1000';
  @override
  String get filamentDefaultToggle => 'Set as default';
  @override
  String get filamentDefaultSubtitle =>
      'Will be used in new quotations. Only one filament can be default.';
  @override
  String get filamentNewTooltip => 'New filament';
  @override
  String get filamentDeleteTitle => 'Delete filament';
  @override
  String get filamentErrorSave => 'Error saving';
  @override
  String get filamentMustBePositive => 'Must be > 0';
  @override
  String get filamentMustBeInteger => 'Must be integer';
  @override
  String get filamentMax100 => 'Max 100 characters';

  @override
  String get printerTitle => 'Printers';
  @override
  String get printerNew => 'New printer';
  @override
  String get printerEdit => 'Edit printer';
  @override
  String get printerModel => 'Model';
  @override
  String get printerModelHelper => 'E.g.: Ender 3 V2';
  @override
  String get printerBrandHelper => 'E.g.: Creality, Anycubic';
  @override
  String get printerWatts => 'Average consumption (W)';
  @override
  String get printerWattsHelper => 'Typically 100-300 W';
  @override
  String get printerDefaultSubtitle =>
      'Will be used in new quotations. Only one printer can be default.';
  @override
  String get printerNewTooltip => 'New printer';
  @override
  String get printerDeleteTitle => 'Delete printer';
  @override
  String get printerMustBeNonNegative => 'Must be >= 0';

  @override
  String get calcNotifFilament => 'Filament';
  @override
  String get calcNotifMaterial => 'Material';

  @override
  String get calcDetailTitle => 'Quotation detail';
  @override
  String get calcDetailDelete => 'Delete';
  @override
  String get calcDetailDeleteTitle => 'Delete quotation';
  @override
  String get calcDetailDeleteConfirm => 'Delete permanently?';
  @override
  String get calcDetailNoName => 'Unnamed';
  @override
  String get calcDetailSold => 'Sold';
  @override
  String get calcDetailReuse => 'Reuse';
  @override
  String get calcDetailMarkSold => 'Mark as sold';
  @override
  String get calcDetailMarkPending => 'Mark as pending';

  @override
  String get calcDuplicateAction => 'Duplicate';
  @override
  String get calcDuplicateSuffix => ' (copy)';
  @override
  String get calcDuplicateSuccess => 'Quote duplicated';
  @override
  String get calcDuplicateError => 'Could not duplicate the quote';

  @override
  String get historyTitle => 'Quotations';
  @override
  String get historyErrorLoad => 'Error loading quotations';
  @override
  String get historyEmpty => 'No saved quotations';

  @override
  String get csvExportLockedBody => 'CSV export is a Pro feature';
  @override
  String get csvGoProAction => 'Unlock PRO';

  @override
  String get localeLabel => 'Language';
  @override
  String get localeEs => 'Spanish';
  @override
  String get localeEn => 'English';
  @override
  String get localePtBr => 'Portuguese (Brazil)';
  @override
  String get localeDe => 'German';
  @override
  String get localeFr => 'French';
  @override
  String get onboardingTitle1 => 'Welcome to 3dCalc';
  @override
  String get onboardingDesc1 =>
      'Calculate 3D print pricing instantly.\nMaterials, electricity, labor and more.';
  @override
  String get onboardingTitle2 => 'Two calculation modes';
  @override
  String get onboardingDesc2 =>
      'Express: quick calculation with one material.\nAdvanced: multiple materials, discount and more.';
  @override
  String get onboardingTitle3 => 'Built-in catalog';
  @override
  String get onboardingDesc3 =>
      'Save your favorite filaments and printers.\nPick them instantly from the catalog.';
  @override
  String get onboardingTitle4 => 'Dashboard & more';
  @override
  String get onboardingDesc4 =>
      'Track quotations, monthly trends,\nPDF export and search history.';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingStart => 'Get Started';
  @override
  String get onboardingStartQuote => 'Create my first quote';
  @override
  String get onboardingGoHome => 'Go to menu';
  @override
  String get configTitle => 'Initial Setup';
  @override
  String get configLanguage => 'Language';
  @override
  String get configCurrency => 'Currency';
  @override
  String get configContinue => 'Continue';

  @override
  String get configStep1Title => 'Language & currency';
  @override
  String get configStep2Title => 'Printer & filament';
  @override
  String get configStep3Title => 'Profit & energy';
  @override
  String get configBack => 'Back';
  @override
  String get configFinish => 'Finish';
  @override
  String get configStepSubtitle1 => "Let's start with the basics.";
  @override
  String get configStepSubtitle2 =>
      "Let's start with what you use to print. The printer is required for "
      'energy cost.';
  @override
  String get configStepSubtitle3 =>
      'These values apply to every quote. You can change them later.';
  @override
  String configStepCounter(int step, int total) => 'Step $step of $total';
  @override
  String get configLanguageHelper =>
      'Choose the app language. You can change it later.';
  @override
  String get configCurrencyHelper =>
      'Currency used for prices and quotes. Does not convert values.';
  @override
  String get configPrinterSectionHelper =>
      'We need it to calculate the energy cost of each print.';
  @override
  String get configFilamentSectionHelper =>
      'If you have the spool handy, add it now. Otherwise, add it later from '
      'Settings → Catalogs.';
  @override
  String get configProfitHelper =>
      'Margin over base cost. 200% doubles the cost. Typical: 100%–300%.';
  @override
  String get configKwhHelper =>
      'Your electricity bill rate. Typical: 0.5–1.5 BOB/kWh.';
  @override
  String get settingsDefaultTypical => 'Typical';
  @override
  String get configFilamentSkipStatus => 'No filament — add later';
  @override
  String get configFilamentAddAction => 'Add filament';
  @override
  String get configStartButton => 'Start quoting';
  @override
  String get configSummaryTitle => 'Summary';
  @override
  String get configSummaryImprint => 'Your next quote:';
  @override
  String get configPrinterRequired => 'Printer (required)';
  @override
  String get configFilamentOptional => 'Filament (optional)';
  @override
  String get configAddFilament => 'Add filament';
  @override
  String get configFilamentLater => "I'll add it later";
  @override
  String get configFilamentSkipHint =>
      'You can add filaments anytime from Settings → Catalogs.';
  @override
  String get configPrinterSaved => 'Printer registered';
  @override
  String get configFilamentSaved => 'Filament added';

  // === Feature gates (T14) ===
  @override
  String get calculatorAdvancedLockedBody =>
      'Unlock Pro for multi-material calculations';
  @override
  String get calculatorGoProAction => 'Unlock PRO';

  // === History cap gate (T15) ===
  @override
  String get historyCapReachedBody =>
      "You've reached the free history limit. Upgrade to Pro for unlimited history.";

  // === Pro badge / locked visuals (UX) ===
  @override
  String get proBadgeLabel => 'PRO';
  @override
  String get proLockedTooltip => 'Pro feature';
  @override
  String get csvExportTooltipLocked => 'Export CSV (Pro)';
  @override
  String historyUsageCounter(int used, int cap) =>
      used == 1 ? '1/$cap quote' : '$used/$cap quotes';

  // === Paywall (T10) ===
  @override
  String get paywallTitle => 'Unlock 3dCalc Pro';
  @override
  String get paywallSubtitle =>
      'Get the most out of your 3D print cost calculator';
  @override
  String get paywallPrice => '\$4.99';
  @override
  List<String> get paywallFeatures => const [
    'Remove branding from PDF quotes',
    'Multi-material cost breakdown',
    'Unlimited history',
    'Export to CSV',
    'Advanced analytics dashboard',
  ];
  @override
  String paywallUnlockButton(String price) => 'Unlock for $price';
  @override
  String get paywallRestoreButton => 'Restore purchase';
  @override
  String get paywallErrorGeneric => 'Could not complete purchase. Try again.';
  @override
  String get paywallUnavailable =>
      'Purchases are not available on this platform.';
  @override
  String get paywallAlreadyPro => 'You already have Pro. Thank you!';
  @override
  String get paywallClose => 'Close';

  @override
  String get paywallPrivacyPolicy => 'Privacy Policy';

  @override
  String get paywallTermsOfService => 'Terms of Service';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get legalPrivacyDocument => '''Last updated: August 11, 2026

1. Scope
This Privacy Policy explains how 3dCalc handles information when you use the application. The responsible operator is Juan Marcelo Albis Ortiz, based in Bolivia. An account is not required for the main features. The application is intended for people aged 10 or older. If you are a minor, you must use it with the authorization and supervision of a parent or legal guardian.

2. Information stored
Information you enter —such as settings, catalogs, and calculations— is stored on your device. Backup files are stored in the location you select.

3. Purchases
Purchases are processed through Google Play. 3dCalc does not receive or store your full card details. The application uses RevenueCat as a technical provider to manage purchases, restorations, and access status; these services may process technical identifiers, transaction data, and product data under their own policies.

4. Information sharing
We do not sell your data or share calculation content. The app store and purchase-processing provider may receive technical identifiers and transaction data needed to validate a purchase under their own policies.

5. Deletion and control
You can delete stored data from the application or by uninstalling it. Exported backup files must be deleted manually.

6. Changes and contact
We may update this policy when the application or its legal requirements change. For privacy questions, contact Juan Marcelo Albis Ortiz at marcheloalbis@gmail.com. Google Play and RevenueCat manage their own data under their respective policies and procedures.

This policy is informational and should be reviewed with legal counsel before publishing in a specific jurisdiction.''';

  @override
  String get legalTermsDocument => '''Last updated: August 11, 2026

1. Acceptance
By installing or using 3dCalc, you agree to these Terms of Service. The provider is Juan Marcelo Albis Ortiz, Bolivia. If you do not agree, do not use the application.

2. Permitted use
You may use 3dCalc to perform calculations and manage work information for personal or commercial purposes. You must be at least 10 years old and use the application in accordance with applicable law. If you are a minor, you need the authorization and supervision of a parent or legal guardian.

3. Results and liability
Results are estimates and support tools. Verify inputs, costs, units, and results before making commercial, technical, or safety decisions. We do not guarantee results for a particular case.

4. Purchases and restoration
The Pro purchase is a one-time purchase, if configured that way in Google Play, and is not an automatic subscription. Purchases, restorations, prices, taxes, and refunds are subject to Google Play. RevenueCat provides technical services to validate purchase status.

5. Intellectual property
The application, its design, and its resources belong to their respective owners. You may not copy, redistribute, modify, or reverse engineer the application except where permitted by law.

6. Availability and changes
We may update, suspend, or remove application features. These terms may also change; the update date will be shown at the beginning. For questions, contact marcheloalbis@gmail.com.

''';

  // === i18n consistency (hardcoded → l10n) ===
  @override
  String get commonError => 'Error';
  @override
  String get commonNoResults => 'No results';
  @override
  String get commonDefault => 'Default';
  @override
  String get commonUndo => 'Undo';
  @override
  String get commonSaveImage => 'Save image';
  @override
  String get commonExportPdf => 'Export PDF';
  @override
  String get commonSharePdf => 'Share PDF';
  @override
  String get commonPrint => 'Print';
  @override
  String get commonImageDownloaded => 'Image downloaded';
  @override
  String get commonImageSavedGallery => 'Image saved to gallery';
  @override
  String get commonPdfExportError => 'Error exporting PDF';
  @override
  String get commonPrintError => 'Error printing';
  @override
  String get commonDefaultSuffix => ' (default)';
  @override
  String get historyExportCsv => 'Export CSV';
  @override
  String get historyEmptyCta => 'Create one from the calculator and tap Save.';
  @override
  String get calcSectionOthers => 'Others';
  @override
  String get settingsProfitBaseRange => 'Range: 0-1000';
  @override
  String get settingsKwhRateRange => 'Range: 0.10-5.00';
  @override
  String get shareErrorNotRendered =>
      'The summary has not rendered yet. Try again in a moment.';
  @override
  String get shareErrorNoRegion =>
      'The capturable region of the summary was not found.';
  @override
  String get shareErrorEncode => 'Could not encode the PNG image.';
  @override
  String get shareErrorSaveGallery =>
      'Could not save the image to the gallery.';
  @override
  String shareErrorSaveWithMessage(String msg) =>
      'Could not save the image: $msg';

  @override
  String get homeHeroTagline =>
      '3D Quotes · Fast · Accurate · Ready when you are';

  @override
  String get calcFormIncompleteWarning => 'Complete the form before saving.';
  @override
  String get calcSaveFailed => 'Could not save.';
  @override
  String calcSavedWithId(int id) => 'Quote #$id saved.';
  @override
  String get calcSavedViewAction => 'View';
  @override
  String get calcAddMaterial => 'Add material';
  @override
  String get calcPrinterPrefix => 'Printer: ';
  @override
  String get calcChangePrinter => 'Change printer';
  @override
  String get calcSearchPrinter => 'Search printer...';
  @override
  String get calcSelectFilament => 'Select filament';
  @override
  String get calcSearchFilament => 'Search filament...';

  @override
  String get detailBreakdown => 'Breakdown';
  @override
  String detailDiscountPct(int pct) => 'Discount ($pct%)';
  @override
  String get detailPreview => 'Preview';

  @override
  String get quoteNoDiscount => 'No discount';
  @override
  String quoteDiscountPct(int pct) => 'Discount $pct%';
  @override
  String get quoteDetail => 'Details';
  @override
  String get quoteGeneratedWith => 'Generated with 3dCalc';

  @override
  String get pdfFileName => 'quote_3dcalc.pdf';
  @override
  String get pdfShareSubject => '3dCalc quotation';
  @override
  String get pdfDatePrefix => 'Date: ';
  @override
  String get pdfQuoteNumber => 'No. ';
  @override
  String get pdfValidUntilPrefix => 'Valid until: ';
  @override
  String get pdfClientPrefix => 'Client: ';
  @override
  String get pdfNotesTitle => 'Notes';
  @override
  String get pdfConditionsTitle => 'Terms';
  @override
  String get pdfMaterialCosts => 'Material costs';
  @override
  String get pdfElectricity => 'Electricity';
  @override
  String get pdfTotalUpper => 'TOTAL';
  @override
  String get pdfHoursPrefix => 'Hours: ';
  @override
  String pdfDiscountPct(int pct) => 'Discount: $pct%';

  @override
  String get dashboardEmptySubtitle =>
      'Create your first quotation from scratch.';
  @override
  String get dashboardMonthlyTrend => 'Monthly trend';
  @override
  String get dashboardTopMaterials => 'Most used materials';

  @override
  String get historySearchHint => 'Search by name or customer...';
  @override
  String get historyFilterAll => 'All';
  @override
  String get historyFilterSold => 'Sold';
  @override
  String get historyFilterPending => 'Pending';
  @override
  String get historyNoQuotesToExport => 'No quotes to export';

  @override
  String get chartNoMonthlyData => 'No monthly data';
  @override
  List<String> get chartShortMonths => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  String get filamentSearchHint => 'Search filaments...';
  @override
  String filamentDeleted(String name) => '"$name" deleted';
  @override
  String get printerSearchHint => 'Search printers...';
  @override
  String printerDeleted(String name) => '"$name" deleted';
  @override
  String get printerErrorSave => 'Error saving';

  @override
  String get settingsErrorLoad => 'Error loading settings';
  @override
  String get settingsCurrencySearchHint => 'Search currency by code or name...';
  @override
  String settingsCurrencyNoResults(String query) => 'No results for "$query"';
  @override
  String get settingsCurrencySymbolPrefix => 'Symbol: ';

  @override
  String get routeNotFound => 'Page not found';
  @override
  String get routeBackHome => 'Back to Home';

  @override
  String get themeModeSystem => 'System';
  @override
  String get themeModeLight => 'Light';
  @override
  String get themeModeDark => 'Dark';

  @override
  String get splashLogo => '3dCalc logo';
  @override
  String onboardingPageCounter(int page, int total) => 'Page $page of $total';
  @override
  String commonNoResultsFor(String query) => 'No results for "$query"';
  @override
  String get historyEmptySearchHint => 'Try another term.';

  @override
  String get filamentErrorLoad => 'Error loading filaments';
  @override
  String filamentNoResults(String query) => 'No filaments match "$query"';
  @override
  String get filamentEmptyList =>
      'No filaments. Tap + to create the first one.';
  @override
  String filamentDeleteConfirm(String name) => 'Delete "$name"?';

  @override
  String get printerErrorLoad => 'Error loading printers';
  @override
  String printerNoResults(String query) => 'No printers match "$query"';
  @override
  String get printerEmptyList =>
      'No printers. Tap + to register the first one.';
  @override
  String printerDeleteConfirm(String name) => 'Delete "$name"?';
}
