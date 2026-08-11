// ignore_for_file: public_member_api_docs
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

  /// Label del boton "Restaurar compras" en settings.
  String get settingsRestorePurchases;

  /// Mensaje de exito tras un restore que encontro compras previas.
  String get settingsRestoreSuccess;

  /// Mensaje tras un restore que no encontro compras previas o dio error.
  String get settingsRestoreEmpty;

  // === Backup / Restore (datos locales) ===

  /// Titulo de la seccion de backup en settings.
  String get settingsBackupTitle;

  /// Boton para exportar un backup.
  String get settingsBackupExport;

  /// Boton para importar un backup.
  String get settingsBackupImport;

  /// Helper text de la seccion backup.
  String get settingsBackupHelper;

  /// Mensaje de exito al exportar backup.
  String get settingsBackupExportSuccess;

  /// Mensaje de error al exportar backup.
  String get settingsBackupExportError;

  /// Mensaje de exito al importar backup.
  String settingsBackupImportSuccess(int calcs, int filaments, int printers);

  /// Mensaje de error al importar backup.
  String get settingsBackupImportError;

  /// Titulo del dialog de confirmacion de import.
  String get settingsBackupImportConfirmTitle;

  /// Cuerpo del dialog de confirmacion de import.
  String settingsBackupImportConfirmBody(String summary);

  /// Accion de confirmar import (boton positivo).
  String get settingsBackupImportConfirm;

  /// Accion de cancelar import (boton negativo).
  String get settingsBackupImportCancel;

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
  String get calcSectionWeight;
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
  String get calcPrinterEmptyCta;
  String get calcPrinterEmptyHint;
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

  // === Quote image (foto de la pieza) ===
  /// "Agregar imagen" / "Add image".
  String get quoteImageAdd;

  /// "Galería" / "Gallery".
  String get quoteImageGallery;

  /// "Cámara" / "Camera".
  String get quoteImageCamera;

  /// "Cambiar" / "Change".
  String get quoteImageChange;

  /// "Quitar" / "Remove".
  String get quoteImageRemove;

  /// Imagen > 5 MB y no se adjuntó.
  String get quoteImageTooLarge;

  /// Formato no decodificable (solo JPEG/PNG/WebP).
  String get quoteImageInvalidFormat;

  /// Error genérico al obtener la imagen.
  String get quoteImageError;

  // === Filaments / Printers forms ===
  String get filamentTitle;
  String get filamentNew;
  String get filamentEdit;
  String get filamentName;
  String get filamentNameHelper;
  String get filamentBrand;
  String get filamentBrandHelper;

  /// "Otro..." — opcion del selector de marca que activa el ingreso manual.
  String get brandSelectorOther;

  /// Hint del selector de marca cuando aun no hay valor.
  String get brandSelectorHint;

  /// Helper del campo manual de marca (modo "Otro...").
  String get brandSelectorManualHelper;
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
  String get localePtBr;
  String get localeDe;
  String get localeFr;

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

  // === Initial config stepper ===
  /// Titulos de los 3 pasos del stepper de configuracion inicial.
  String get configStep1Title;
  String get configStep2Title;
  String get configStep3Title;
  String get configBack;
  String get configFinish;

  /// Subtitulo de cada paso (microcopy "por que" del paso).
  String get configStepSubtitle1;
  String get configStepSubtitle2;
  String get configStepSubtitle3;

  /// Contador del paso: "Paso $step de $total".
  String configStepCounter(int step, int total);

  /// Microcopy: elegible post-config.
  String get configLanguageHelper;

  /// Microcopy: no convierte valores.
  String get configCurrencyHelper;

  /// Microcopy: "para que" de la impresora (costo de energia).
  String get configPrinterSectionHelper;

  /// Microcopy: el filamento es opcional.
  String get configFilamentSectionHelper;

  /// Microcopy: ganancia (200% duplica, rango tipico).
  String get configProfitHelper;

  /// Microcopy: kWh (para que + rango tipico Bolivia).
  String get configKwhHelper;

  /// Tag "Típico" junto a valores por defecto.
  String get settingsDefaultTypical;

  /// Estado "sin filamento" tras el skip.
  String get configFilamentSkipStatus;

  /// Accion de agregar filamento desde el estado skip.
  String get configFilamentAddAction;

  /// Boton final del ultimo paso: "Empezar a cotizar".
  String get configStartButton;

  /// Titulo del bloque Resumen del paso 3.
  String get configSummaryTitle;

  /// Intro del Resumen: "Tu próxima cotización:".
  String get configSummaryImprint;

  String get configPrinterRequired;
  String get configFilamentOptional;
  String get configAddFilament;
  String get configFilamentLater;
  String get configFilamentSkipHint;
  String get configPrinterSaved;
  String get configFilamentSaved;

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

  // === Pro badge / locked visuals (UX) ===
  /// Label del badge "PRO" que marca controles gateados (modo advanced,
  /// export CSV, branding). Mismo texto en ambos idiomas.
  String get proBadgeLabel;

  /// Tooltip / semantics del badge "PRO" (accesibilidad).
  String get proLockedTooltip;

  /// Tooltip del boton export CSV cuando esta locked (free): indica que
  /// la accion es Pro en vez de describir la accion habilitada.
  String get csvExportTooltipLocked;

  /// Contador de uso del historial free: "$used/$cap cotizaciones".
  /// Singular para used == 1. [used] = cantidad actual de cotizaciones,
  /// [cap] = limite free ([kFreeHistoryCap]). Solo visible free.
  String historyUsageCounter(int used, int cap);

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

  String get legalPrivacyDocument;
  String get legalTermsDocument;

  // === i18n consistency (hardcoded → l10n) ===
  /// Generic "Error" label (ej: "Error: `<detalle>`").
  String get commonError;

  /// "Sin resultados" / "No results" para busquedas.
  String get commonNoResults;

  /// "Predeterminado" / "Default".
  String get commonDefault;

  /// "Deshacer" / "Undo".
  String get commonUndo;

  /// "Guardar imagen" / "Save image".
  String get commonSaveImage;

  /// "Exportar PDF" / "Export PDF".
  String get commonExportPdf;

  /// "Compartir PDF" / "Share PDF".
  String get commonSharePdf;

  /// "Imprimir" / "Print".
  String get commonPrint;

  /// "Imagen descargada" / "Image downloaded".
  String get commonImageDownloaded;

  /// "Imagen guardada en galería" / "Image saved to gallery".
  String get commonImageSavedGallery;

  /// "Error al exportar PDF" / "Error exporting PDF" (sin ": `<e>`").
  String get commonPdfExportError;

  /// "Error al imprimir" / "Error printing" (sin ": `<e>`").
  String get commonPrintError;

  /// " (default)" / " (default)" — sufijo de items default.
  String get commonDefaultSuffix;

  /// "Exportar CSV" / "Export CSV" — tooltip del export en Historial.
  String get historyExportCsv;

  /// CTA del empty state de Historial (invita a crear desde la calculadora).
  String get historyEmptyCta;

  /// "Otros" / "Others" — seccion colapsable de la calculadora.
  String get calcSectionOthers;

  /// "Rango: 0-1000" / "Range: 0-1000" — validacion de ganancia base.
  String get settingsProfitBaseRange;

  /// "Rango: 0.10-5.00" / "Range: 0.10-5.00" — validacion de tarifa kWh.
  String get settingsKwhRateRange;

  /// Share: el resumen aun no se renderizo.
  String get shareErrorNotRendered;

  /// Share: no se encontro la region capturable del resumen.
  String get shareErrorNoRegion;

  /// Share: no se pudo codificar la imagen PNG.
  String get shareErrorEncode;

  /// Share: no se pudo guardar la imagen en la galeria.
  String get shareErrorSaveGallery;

  /// Share: no se pudo guardar la imagen (con mensaje del plugin).
  String shareErrorSaveWithMessage(String msg);

  /// Hero tagline de la home.
  String get homeHeroTagline;

  /// Warning al intentar guardar con el form incompleto.
  String get calcFormIncompleteWarning;

  /// Error al guardar la cotizacion.
  String get calcSaveFailed;

  /// Confirmacion de guardado con id: "Cotización #$id guardada."
  String calcSavedWithId(int id);

  /// "Agregar material" / "Add material".
  String get calcAddMaterial;

  /// Prefijo de la Semantics label de la impresora activa.
  String get calcPrinterPrefix;

  /// "Cambiar impresora" / "Change printer".
  String get calcChangePrinter;

  /// "Buscar impresora..." / "Search printer...".
  String get calcSearchPrinter;

  /// "Seleccionar filamento" / "Select filament".
  String get calcSelectFilament;

  /// "Buscar filamento..." / "Search filament...".
  String get calcSearchFilament;

  /// "Desglose" / "Breakdown".
  String get detailBreakdown;

  /// "Descuento ($pct%)" / "Discount ($pct%)".
  String detailDiscountPct(int pct);

  /// "Vista previa" / "Preview".
  String get detailPreview;

  /// "Sin descuento" / "No discount".
  String get quoteNoDiscount;

  /// "Descuento $pct%" / "Discount $pct%".
  String quoteDiscountPct(int pct);

  /// "Detalle" / "Details" (bloque de la quote image).
  String get quoteDetail;

  /// "Generado con 3dCalc" / "Generated with 3dCalc".
  String get quoteGeneratedWith;

  /// Nombre de archivo del PDF exportado.
  String get pdfFileName;

  /// Subject al compartir el PDF.
  String get pdfShareSubject;

  /// "Fecha: " / "Date: ".
  String get pdfDatePrefix;

  /// "Costo materiales" / "Material costs".
  String get pdfMaterialCosts;

  /// "Electricidad" / "Electricity".
  String get pdfElectricity;

  /// "TOTAL" / "TOTAL".
  String get pdfTotalUpper;

  /// "Horas: " / "Hours: ".
  String get pdfHoursPrefix;

  /// "Descuento: $pct%" / "Discount: $pct%".
  String pdfDiscountPct(int pct);

  /// Empty state del dashboard (subtitulo).
  String get dashboardEmptySubtitle;

  /// "Tendencia mensual" / "Monthly trend".
  String get dashboardMonthlyTrend;

  /// "Materiales más usados" / "Most used materials".
  String get dashboardTopMaterials;

  /// Hint de busqueda del historial.
  String get historySearchHint;

  /// Filtro "Todas" / "All".
  String get historyFilterAll;

  /// Filtro "Vendidas" / "Sold".
  String get historyFilterSold;

  /// Filtro "Pendientes" / "Pending".
  String get historyFilterPending;

  /// Snackbar "No hay cotizaciones para exportar".
  String get historyNoQuotesToExport;

  /// "Sin datos mensuales" / "No monthly data".
  String get chartNoMonthlyData;

  /// Abreviaturas de mes cortas (12).
  List<String> get chartShortMonths;

  /// "Buscar filamentos..." / "Search filaments...".
  String get filamentSearchHint;

  /// '"$name" eliminado' / '"$name" deleted'.
  String filamentDeleted(String name);

  /// "Buscar impresoras..." / "Search printers...".
  String get printerSearchHint;

  /// '"$name" eliminada' / '"$name" deleted'.
  String printerDeleted(String name);

  /// "Error guardando" / "Error saving" (impresora).
  String get printerErrorSave;

  /// "Error cargando ajustes" / "Error loading settings".
  String get settingsErrorLoad;

  /// Hint de busqueda de moneda.
  String get settingsCurrencySearchHint;

  /// "Sin resultados para \"$query\"" / "No results for \"$query\"".
  String settingsCurrencyNoResults(String query);

  /// "Símbolo: " / "Symbol: ".
  String get settingsCurrencySymbolPrefix;

  /// "Página no encontrada" / "Page not found".
  String get routeNotFound;

  /// "Volver a Inicio" / "Back to Home".
  String get routeBackHome;

  /// Labels del selector de tema.
  String get themeModeSystem;
  String get themeModeLight;
  String get themeModeDark;

  /// Semantics label del logo de splash.
  String get splashLogo;

  /// "Página $page de $total" / "Page $page of $total".
  String onboardingPageCounter(int page, int total);

  /// "Sin resultados para \"$query\"" / "No results for \"$query\"" (búsquedas).
  String commonNoResultsFor(String query);

  /// "Prueba con otro término." / "Try another term.".
  String get historyEmptySearchHint;

  /// Catálogo de filamentos: errores, estados vacíos y confirmaciones.
  String get filamentErrorLoad;

  /// "Ningún filamento coincide con \"$query\"" / "No filaments match \"$query\"".
  String filamentNoResults(String query);

  /// "Sin filamentos. Toca + para crear el primero." / "No filaments. Tap + to create the first one.".
  String get filamentEmptyList;

  /// "¿Eliminar \"$name\"?" / "Delete \"$name\"?".
  String filamentDeleteConfirm(String name);

  /// Catálogo de impresoras: errores, estados vacíos y confirmaciones.
  String get printerErrorLoad;

  /// "Ninguna impresora coincide con \"$query\"" / "No printers match \"$query\"".
  String printerNoResults(String query);

  /// "Sin impresoras. Toca + para registrar la primera." / "No printers. Tap + to register the first one.".
  String get printerEmptyList;

  /// "¿Eliminar \"$name\"?" / "Delete \"$name\"?".
  String printerDeleteConfirm(String name);
}
