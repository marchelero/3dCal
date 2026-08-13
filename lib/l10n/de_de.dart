/// Deutsche Zeichenketten (de_DE).
library;
// ignore_for_file: public_member_api_docs

import 'app_strings.dart';

class DeImpl implements AppStrings {
  const DeImpl();

  @override
  String get appName => '3dCalc';

  @override
  String get commonSave => 'Speichern';
  @override
  String get commonCancel => 'Abbrechen';
  @override
  String get commonDelete => 'Löschen';
  @override
  String get commonRetry => 'Erneut versuchen';
  @override
  String get commonEdit => 'Bearbeiten';
  @override
  String get commonNew => 'Neu';
  @override
  String get commonRequired => 'Erforderlich';
  @override
  String get commonInvalidNumber => 'Ungültige Zahl';
  @override
  String get commonLoading => 'Wird geladen...';
  @override
  String get commonErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get navHome => 'Startseite';
  @override
  String get navHistory => 'Verlauf';
  @override
  String get navDashboard => 'Übersicht';
  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';
  @override
  String get settingsGlobalParams => 'Globale Parameter';
  @override
  String get settingsProfitBase => 'Grundgewinn (%)';
  @override
  String get settingsProfitBaseHelper =>
      'Aufschlag auf die Grundkosten. 0-1000';
  @override
  String settingsKwhRate(String symbol) => 'Stromtarif ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper =>
      'Typischer Haushaltsbereich in Bolivien: 0,10-5,00';
  @override
  String get settingsCatalogos => 'Kataloge';
  @override
  String get settingsFilamentos => 'Filamente';
  @override
  String get settingsImpresoras => 'Drucker';
  @override
  String get settingsAbout => 'Über';
  @override
  String get settingsPrivacy => 'Datenschutz und Daten';
  @override
  String get settingsSaved => 'Gespeichert';
  @override
  String get settingsAppearance => 'Darstellung';
  @override
  String get settingsTheme => 'Design';
  @override
  String get settingsManageFilaments => 'Filamente verwalten';
  @override
  String get settingsManagePrinters => 'Drucker registrieren';

  @override
  String get settingsLaborPost => 'Arbeitszeit und Nachbearbeitung';
  @override
  String settingsLaborRate(String symbol) => 'Stundensatz ($symbol/Stunde)';
  @override
  String get settingsLaborRateHelper =>
      'Kosten für Bediener oder Techniker pro Druckstunde. 0 = deaktiviert';
  @override
  String get settingsPostProcessRate => 'Nachbearbeitung (%)';
  @override
  String get settingsPostProcessRateHelper =>
      '% der Materialkosten. Z. B. 10 = +10 % für Endbearbeitung, Schleifen oder Lackieren';
  @override
  String get settingsFailureRate => 'Fehlerquote (%)';
  @override
  String get settingsFailureRateHelper =>
      '% der Grundkosten zum Ausgleich fehlgeschlagener Drucke. 0 = deaktiviert';
  @override
  String settingsMinimumCharge(String symbol) => 'Mindestbetrag ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Angebote unter diesem Betrag werden automatisch angepasst';
  @override
  String get settingsMarkupOnMaterials =>
      'Materialaufschlag für Verschnitt (%)';
  @override
  String get settingsMarkupOnMaterialsHelper =>
      '% zusätzlich auf die Materialkosten für Verschnitt und Verschleiß';

  @override
  String get settingsCurrency => 'Währung';
  @override
  String get settingsCurrencyHelper =>
      'Legt die Währung für Preise, Angebote und die Übersicht fest. Keine automatische Umrechnung.';

  @override
  String get settingsCompany => 'Unternehmen';
  @override
  String get settingsCompanyName => 'Unternehmensname';
  @override
  String get settingsCompanyNameHelper =>
      'Wird auf dem Angebot angezeigt. Standard: 3dCalc';
  @override
  String get settingsCompanyLogo => 'Logo';
  @override
  String get settingsCompanyLogoPick => 'Bild auswählen';
  @override
  String get settingsCompanyLogoRemove => 'Logo entfernen';
  @override
  String get settingsCompanyLogoError => 'Fehler beim Laden des Bildes';

  @override
  String get settingsBrandingLockedBody =>
      'Schalten Sie Pro frei, um Ihre Marke anzupassen';
  @override
  String get settingsGoProAction => 'PRO freischalten';
  @override
  String get settingsProTitle => '3D Cal PRO';
  @override
  String get settingsProActive => 'PRO aktiv';
  @override
  String get settingsProPurchaseType => 'Einmaliger Kauf';
  @override
  String get settingsProRestorePurchase => 'Kauf wiederherstellen';

  @override
  String get settingsRestorePurchases => 'Käufe wiederherstellen';
  @override
  String get settingsRestoreSuccess => 'Käufe erfolgreich wiederhergestellt!';
  @override
  String get settingsRestoreEmpty => 'Keine früheren Käufe gefunden';
  @override
  String get settingsRestoreError =>
      'Käufe konnten nicht wiederhergestellt werden.';

  @override
  String get settingsBackupTitle => 'Sicherung';

  @override
  String get settingsBackupExport => 'Sicherung exportieren';

  @override
  String get settingsBackupImport => 'Sicherung importieren';

  @override
  String get settingsBackupHelper =>
      'Speichern oder wiederherstellen aller Daten (Filamente, Drucker, Angebote). Regelmäßige Sicherungen werden empfohlen.';

  @override
  String get settingsBackupExportSuccess => 'Sicherung erfolgreich exportiert';

  @override
  String get settingsBackupExportError =>
      'Fehler beim Exportieren der Sicherung';

  @override
  String settingsBackupImportSuccess(int calcs, int filaments, int printers) =>
      'Sicherung wiederhergestellt: $calcs Angebote, $filaments Filamente, $printers Drucker';

  @override
  String get settingsBackupImportError =>
      'Fehler beim Importieren der Sicherung';

  @override
  String get settingsBackupImportConfirmTitle => 'Sicherung wiederherstellen?';

  @override
  String settingsBackupImportConfirmBody(String summary) =>
      'ALLE aktuellen Daten werden ersetzt durch:\n$summary\n\nDiese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get settingsBackupImportConfirm => 'Wiederherstellen';

  @override
  String get settingsBackupImportCancel => 'Abbrechen';

  @override
  String get settingsBackupImportSizeError =>
      'Die Sicherungsdatei überschreitet die maximal zulässige Größe.';

  @override
  String get settingsBackupImportInvalidFile =>
      'Die ausgewählte Datei ist kein gültiges Backup.';

  @override
  String get settingsBackupImportFutureVersion =>
      'Dieses Backup wurde mit einer zukünftigen Version der App erstellt. '
      'Aktualisiere 3dCalc und versuche es erneut.';

  @override
  String get settingsBackupLockedBody => 'Backups sind eine Pro-Funktion.';

  @override
  String get dashboardTitle => 'Übersicht';
  @override
  String get dashboardErrorLoad => 'Fehler beim Laden der Übersicht';
  @override
  String get dashboardEmpty => 'Noch keine Angebote';
  @override
  String get dashboardEmptyCta => 'Zur Startseite';
  @override
  String get dashboardStatQuotations => 'Angebote';
  @override
  String get dashboardStatSold => 'Verkauft';
  @override
  String get dashboardStatConversion => 'Konversion';
  @override
  String get dashboardTotalQuoted => 'Gesamt angeboten';
  @override
  String get dashboardTotalSold => 'Gesamt verkauft';
  @override
  String get dashboardChartTitle => 'Angeboten gegenüber verdient';
  @override
  String get dashboardChartQuoted => 'Angeboten';
  @override
  String get dashboardChartSold => 'Verdient';
  @override
  String get dashboardProTeaserTitle => 'Pro-Analysen freischalten';
  @override
  String get dashboardProTeaserBody =>
      'Erhalten Sie die vollständige Übersicht mit Kostentrends, Materialaufteilungen und mehr.';
  @override
  String get dashboardGoProAction => 'PRO freischalten';

  @override
  String get homeActionNewCalc => 'Neues Angebot';
  @override
  String get homeActionNewCalcSub => 'Druckpreis berechnen';
  @override
  String get homeActionHistory => 'Verlauf';
  @override
  String get homeActionHistorySub => 'Gespeicherte Angebote';
  @override
  String get homeActionDashboard => 'Übersicht';
  @override
  String get homeActionDashboardSub => 'Statistiken und Diagramme';
  @override
  String get homeQuickAccess => 'Schnellzugriff';
  @override
  String get homeErrorLoadStats => 'Fehler beim Laden der Statistiken';
  @override
  String get homeEmptyQuotations => 'Noch keine Angebote';
  @override
  String get homeSummary => 'Zusammenfassung';
  @override
  String get homeSeeAll => 'Alle anzeigen';

  @override
  String get calcSectionPiece => 'Teil';
  @override
  String get calcSectionWeight => 'Teilgewicht';
  @override
  String get calcSectionFilament => 'Filament';
  @override
  String get calcSectionTime => 'Druckzeit';
  @override
  String get calcSectionDiscount => 'Rabatt';
  @override
  String get calcLabelOptional => 'Bezeichnung (optional)';
  @override
  String get calcLabelOptionalHelper => 'Z. B.: Wandhalterung, PETG-Zahnrad';
  @override
  String get calcLabelWeight => 'Stückgewicht';
  @override
  String get calcLabelWeightHelper => 'Gramm des Modells';
  @override
  String get calcLabelHours => 'Stunden';
  @override
  String get calcLabelHoursHelper => '0-24';
  @override
  String get calcLabelMinutes => 'Minuten';
  @override
  String get calcLabelMinutesHelper => '0-59';
  @override
  String get calcLabelDiscount => 'Rabatt';
  @override
  String get calcLabelDiscountHelper => 'Prozentualer Abzug vom Endbetrag';
  @override
  String get calcBtnSave => 'Angebot speichern';
  @override
  String get calcBtnReset => 'Werte zurücksetzen';
  @override
  String get calcToggleShowDetail => 'Details anzeigen';
  @override
  String get calcToggleHideDetail => 'Details ausblenden';
  @override
  String get calcTotalWithDiscount => 'Gesamtbetrag mit Rabatt';
  @override
  String get calcTotalFinal => 'Gesamtbetrag';
  @override
  String get calcDetailMaterial => 'Materialkosten';
  @override
  String get calcDetailEnergy => 'Energiekosten';
  @override
  String get calcDetailLabor => 'Arbeitszeit';
  @override
  String get calcDetailPostProcess => 'Nachbearbeitung';
  @override
  String get calcDetailBase => 'Grundkosten';
  @override
  String get calcDetailFailure => 'Fehlerquote';
  @override
  String get calcDetailMarkup => 'Abfallaufschlag';
  @override
  String get calcDetailProfit => 'Gewinn';
  @override
  String get calcDetailMinimumCharge => 'Mindestbetrag';
  @override
  String get calcDetailTotal => 'Gesamtbetrag';
  @override
  String get calcEmptyHint =>
      'Geben Sie Gewicht, Filament und Zeit ein, um den Preis zu sehen';
  @override
  String get calcSectionMaterials => 'Materialien';
  @override
  String get calcSectionPrinter => 'Drucker';
  @override
  String get calcNoPrinter => 'Kein Drucker registriert';
  @override
  String get calcPrinterEmptyCta => 'Drucker registrieren';
  @override
  String get calcPrinterEmptyHint =>
      'Berechnung ohne Energiekosten. Registrieren Sie einen Drucker, um diese hinzuzufügen.';
  @override
  String get calcNoMaterials => 'Keine Materialien.';

  @override
  String get calcKeyWeightHint =>
      'Wichtig: für die Angebotsberechnung erforderlich';
  @override
  String get calcKeyHoursHint =>
      'Wichtig: bestimmt Arbeitszeit und Energiekosten';
  @override
  String get calcKeyMinutesHint => 'Wichtig: tatsächliche Druckzeit eingeben';

  @override
  String calcMaterialTitle(int index) => 'Material $index';
  @override
  String calcMaterialRemove(int index) => 'Material $index entfernen';
  @override
  String get calcMaterialCatalog => 'Katalog';
  @override
  String calcMaterialUse(String filamentName) => '$filamentName verwenden';
  @override
  String get calcFieldLabel => 'Label';
  @override
  String get calcFieldLabelHelper => 'Optional (z. B.: PLA-Basis)';
  @override
  String get calcFieldFilament => 'Filament';
  @override
  String get calcFieldWeight => 'Gewicht';
  @override
  String get calcFieldSpoolPrice => 'Spulenpreis';
  @override
  String get calcFieldSpoolGrams => 'Gramm / Spule';

  @override
  String get calcFieldLabor => 'Arbeitszeit';
  @override
  String get calcFieldLaborHelper => 'Stundensatz';
  @override
  String get calcFieldPostProcess => 'Nachbearbeitung';
  @override
  String get calcFieldPostProcessHelper => '% der Materialkosten';
  @override
  String get calcFieldFailure => 'Fehlerquote';
  @override
  String get calcFieldFailureHelper => '% der Grundkosten';
  @override
  String get calcFieldWaste => 'Verschnitt';
  @override
  String get calcFieldWasteHelper => '% Aufschlag für Verschnitt';

  @override
  String get costHelpTitle => 'So kalibrieren Sie Ihre Kosten';

  @override
  String get costHelpEnergyTitle => 'Energiekosten';

  @override
  String get costHelpEnergyBody =>
      'Energie beim Drucken: Druckstunden × Leistung (kW) × Tarif (\$/kWh). '
      'Z. B.: 6 h × 0,15 kW × 1,2 \$/kWh ≈ 1,08 \$. Nur wenn der Drucker eine '
      'Wattzahl hat.';

  @override
  String get costHelpLaborTitle => 'Arbeitszeit';

  @override
  String get costHelpLaborBody =>
      'Ihre Zeit: Arbeitsstunden × Stundensatz (\$/h). Inklusive '
      'Vorbereitung, Überwachung und Endbearbeitung.';

  @override
  String get costHelpPostTitle => 'Nachbearbeitung';

  @override
  String get costHelpPostBody =>
      'Zusätzlicher Prozentsatz auf Materialkosten für Schleifen, Lackieren, '
      'Kleben oder andere Oberflächen.';

  @override
  String get costHelpFailureTitle => 'Fehlerquote';

  @override
  String get costHelpFailureBody =>
      'Prozentsatz der Basiskosten für fehlgeschlagene Teile. Wenn 1 von 10 '
      'Teilen fehlschlägt, werden diese 10 % auf die 9 verkauften verteilt.';

  @override
  String get costHelpWasteTitle => 'Verschnitt & Verschleiß';

  @override
  String get costHelpWasteBody =>
      'Zusätzlicher Prozentsatz auf Materialien: Stützen, Düsenreinigung, '
      'Testfilament und Abnutzung des Druckers.';

  @override
  String get costHelpMinimumChargeTitle => 'Mindestbetrag';

  @override
  String get costHelpMinimumChargeBody =>
      'Preisuntergrenze. Liegt der berechnete Gesamtbetrag darunter, wird '
      'dieser Mindestbetrag berechnet. Ideal für kleine Teile, die trotzdem '
      'Vorbereitung brauchen.';

  @override
  String get costHelpMarginTitle => 'Gewinn (Marge)';

  @override
  String get costHelpMarginBody =>
      'Prozentsatz, der zum Gesamtkostenpreis für Ihren Gewinn addiert wird: '
      'Gesamt × (1 + Marge/100). Einstellbar unter Globale Parameter.';

  @override
  String get calcCloseAction => 'Schließen und zum Menü zurückkehren';

  @override
  String get calcModeExpress => 'Express';
  @override
  String get calcModeAdvanced => 'Erweitert';
  @override
  String calcSemanticMode(String mode) => 'Berechnungsmodus: $mode';

  @override
  String get calcActionReset => 'Zurücksetzen';

  @override
  String get calcDialogClient => 'Kunde';
  @override
  String get calcDialogClientHelper => 'Optional';
  @override
  String get calcDialogRecentClients => 'Letzte Kunden';
  @override
  String get calcDialogNotes => 'Notizen (optional)';
  @override
  String get calcDialogNotesHelper => 'Details, Fristen, Lieferung\u2026';
  @override
  String get calcDialogConditions => 'Gesch\u00e4ftsbedingungen (optional)';
  @override
  String get calcDialogConditionsHelper =>
      'G\u00fcltigkeit, Zahlung, Garantie\u2026';

  @override
  String get calcTemplatesTitle => 'Vorlagen';
  @override
  String get calcTemplateSaveAsAction => 'Als Vorlage speichern';
  @override
  String get calcTemplateSaveSuccess => 'Vorlage gespeichert';
  @override
  String get calcTemplateSaveError => 'Vorlage konnte nicht gespeichert werden';
  @override
  String get calcTemplateApplySuccess => 'Vorlage auf das Formular angewendet';
  @override
  String get calcTemplateApplyError => 'Vorlage konnte nicht geladen werden';
  @override
  String get calcTemplateEmpty =>
      'Noch keine Vorlagen.\nSpeichere einen h\u00e4ufigen Auftrag als Vorlage, um ihn wiederzuverwenden.';
  @override
  String get calcTemplateUntitled => 'Ohne Namen';
  @override
  String get calcTemplateDeleteError =>
      'Vorlage konnte nicht gel\u00f6scht werden';

  @override
  String get calcEmptyHintPrefix => 'Geben Sie';
  @override
  String get calcEmptyHintSuffix => 'ein, um das Angebot zu sehen';
  @override
  String get calcFieldWeightShort => 'Stückgewicht';
  @override
  String get calcFieldPriceShort => 'Filamentpreis';
  @override
  String get calcFieldTimeShort => 'Druckzeit';
  @override
  String get calcFieldMaterialShort => 'mindestens ein Material';

  @override
  String get calcMetaSeparator => ' · ';

  @override
  String get calcResultBarTapHint => 'Angebot anzeigen';
  @override
  String get calcResultBarEmptyHint => 'Unvollständig';
  @override
  String get calcSheetTitle => 'Angebot';
  @override
  String get calcBtnShare => 'Bild teilen';
  @override
  String get calcBtnShareTooltip => 'Erzeugt ein Bild zum Teilen';
  @override
  String get calcShareError => 'Das Bild konnte nicht erzeugt werden';
  @override
  String get calcShareSubject => '3D-Angebot';
  @override
  String get calcShareText => 'Angebot mit 3dCalc erstellt';
  @override
  String get calcSheetActionsLabel => 'Aktionen';

  // === Quote image (part photo) ===
  @override
  String get quoteImageAdd => 'Bild hinzufügen';
  @override
  String get quoteImageGallery => 'Galerie';
  @override
  String get quoteImageCamera => 'Kamera';
  @override
  String get quoteImageChange => 'Ändern';
  @override
  String get quoteImageRemove => 'Entfernen';
  @override
  String get quoteImageTooLarge =>
      'Das Bild überschreitet 5 MB und wurde nicht angehängt.';
  @override
  String get quoteImageInvalidFormat =>
      'Ungültiges Bildformat (nur JPEG, PNG oder WebP).';
  @override
  String get quoteImageError => 'Das Bild konnte nicht abgerufen werden';

  @override
  String get filamentTitle => 'Filamente';
  @override
  String get filamentNew => 'Neues Filament';
  @override
  String get filamentEdit => 'Filament bearbeiten';
  @override
  String get filamentName => 'Name';
  @override
  String get filamentNameHelper => 'Z. B.: PLA Schwarz';
  @override
  String get filamentBrand => 'Marke';
  @override
  String get filamentBrandHelper => 'Optional';
  @override
  String get brandSelectorOther => 'Andere ...';
  @override
  String get brandSelectorHint =>
      'Marke auswählen oder Andere wählen, um sie einzugeben';
  @override
  String get brandSelectorManualHelper => 'Markennamen eingeben';
  @override
  String filamentPrice(String symbol) => 'Filamentpreis ($symbol)';
  @override
  String get filamentPriceHelper => 'Vollständige Spulenkosten';
  @override
  String get filamentGrams => 'Gramm pro Spule';
  @override
  String get filamentGramsHelper => 'Typischerweise 1000';
  @override
  String get filamentDefaultToggle => 'Als Standard festlegen';
  @override
  String get filamentDefaultSubtitle =>
      'Wird in neuen Angeboten verwendet. Nur ein Filament kann Standard sein.';
  @override
  String get filamentNewTooltip => 'Neues Filament';
  @override
  String get filamentDeleteTitle => 'Filament löschen';
  @override
  String get filamentErrorSave => 'Fehler beim Speichern';
  @override
  String get filamentMustBePositive => 'Muss > 0 sein';
  @override
  String get filamentMustBeInteger => 'Muss eine ganze Zahl sein';
  @override
  String get filamentMax100 => 'Maximal 100 Zeichen';

  @override
  String get printerTitle => 'Drucker';
  @override
  String get printerNew => 'Neuer Drucker';
  @override
  String get printerEdit => 'Drucker bearbeiten';
  @override
  String get printerModel => 'Modell';
  @override
  String get printerModelHelper => 'Z. B.: Ender 3 V2';
  @override
  String get printerBrandHelper => 'Z. B.: Creality, Anycubic';
  @override
  String get printerWatts => 'Durchschnittlicher Verbrauch (W)';
  @override
  String get printerWattsHelper => 'Typischerweise 100-300 W';
  @override
  String get printerDefaultSubtitle =>
      'Wird in neuen Angeboten verwendet. Nur ein Drucker kann Standard sein.';
  @override
  String get printerNewTooltip => 'Neuer Drucker';
  @override
  String get printerDeleteTitle => 'Drucker löschen';
  @override
  String get printerMustBeNonNegative => 'Muss >= 0 sein';

  @override
  String get calcNotifFilament => 'Filament';
  @override
  String get calcNotifMaterial => 'Material';

  @override
  String get calcDetailTitle => 'Angebotsdetails';
  @override
  String get calcDetailDelete => 'Löschen';
  @override
  String get calcDetailDeleteTitle => 'Angebot löschen';
  @override
  String get calcDetailDeleteConfirm => 'Dauerhaft löschen?';
  @override
  String get calcDetailNoName => 'Ohne Namen';
  @override
  String get calcDetailSold => 'Verkauft';
  @override
  String get calcDetailReuse => 'Wiederverwenden';
  @override
  String get calcDetailMarkSold => 'Als verkauft markieren';
  @override
  String get calcDetailMarkPending => 'Als offen markieren';

  @override
  String get calcDuplicateAction => 'Duplizieren';
  @override
  String get calcDuplicateSuffix => ' (Kopie)';
  @override
  String get calcDuplicateSuccess => 'Angebot dupliziert';
  @override
  String get calcDuplicateError => 'Angebot konnte nicht dupliziert werden';

  @override
  String get historyTitle => 'Angebote';
  @override
  String get historyErrorLoad => 'Fehler beim Laden der Angebote';
  @override
  String get historyEmpty => 'Keine gespeicherten Angebote';

  @override
  String get csvExportLockedBody => 'CSV-Export ist eine Pro-Funktion';
  @override
  String get csvGoProAction => 'PRO freischalten';

  @override
  String get localeLabel => 'Sprache';
  @override
  String get localeEs => 'Spanisch';
  @override
  String get localeEn => 'Englisch';
  @override
  String get localePtBr => 'Portugiesisch (Brasilien)';
  @override
  String get localeDe => 'Deutsch';
  @override
  String get localeFr => 'Französisch';
  @override
  String get onboardingTitle1 => 'Willkommen bei 3dCalc';
  @override
  String get onboardingDesc1 =>
      'Berechnen Sie Preise für 3D-Drucke sofort.\nMaterialien, Strom, Arbeitszeit und mehr.';
  @override
  String get onboardingTitle2 => 'Zwei Berechnungsmodi';
  @override
  String get onboardingDesc2 =>
      'Express: schnelle Berechnung mit einem Material.\nErweitert: mehrere Materialien, Rabatt und mehr.';
  @override
  String get onboardingTitle3 => 'Integrierter Katalog';
  @override
  String get onboardingDesc3 =>
      'Speichern Sie Ihre bevorzugten Filamente und Drucker.\nWählen Sie sie sofort aus dem Katalog aus.';
  @override
  String get onboardingTitle4 => 'Übersicht und mehr';
  @override
  String get onboardingDesc4 =>
      'Verfolgen Sie Angebote und monatliche Trends,\nexportieren Sie PDFs und durchsuchen Sie den Verlauf.';
  @override
  String get onboardingNext => 'Weiter';
  @override
  String get onboardingSkip => 'Überspringen';
  @override
  String get onboardingStart => 'Loslegen';
  @override
  String get onboardingStartQuote => 'Mein erstes Angebot erstellen';
  @override
  String get onboardingGoHome => 'Zum Menü';
  @override
  String get configTitle => 'Ersteinrichtung';
  @override
  String get configLanguage => 'Sprache';
  @override
  String get configCurrency => 'Währung';
  @override
  String get configContinue => 'Fortfahren';

  @override
  String get configStep1Title => 'Sprache und Währung';
  @override
  String get configStep2Title => 'Drucker und Filament';
  @override
  String get configStep3Title => 'Gewinn und Energie';
  @override
  String get configBack => 'Zurück';
  @override
  String get configFinish => 'Fertig';
  @override
  String get configStepSubtitle1 => 'Beginnen wir mit den Grundlagen.';
  @override
  String get configStepSubtitle2 =>
      'Beginnen wir mit dem, was Sie zum Drucken verwenden. Der Drucker ist für '
      'die Energiekosten erforderlich.';
  @override
  String get configStepSubtitle3 =>
      'Diese Werte gelten für jedes Angebot. Sie können sie später ändern.';
  @override
  String configStepCounter(int step, int total) => 'Schritt $step von $total';
  @override
  String get configLanguageHelper =>
      'Wählen Sie die Sprache der App. Sie können sie später ändern.';
  @override
  String get configCurrencyHelper =>
      'Währung für Preise und Angebote. Werte werden nicht umgerechnet.';
  @override
  String get configPrinterSectionHelper =>
      'Wir benötigen ihn, um die Energiekosten jedes Drucks zu berechnen.';
  @override
  String get configFilamentSectionHelper =>
      'Wenn Sie die Spule zur Hand haben, fügen Sie sie jetzt hinzu. Andernfalls '
      'können Sie sie später unter Einstellungen → Kataloge hinzufügen.';
  @override
  String get configProfitHelper =>
      'Aufschlag auf die Grundkosten. 200 % verdoppeln die Kosten. Typisch: 100 %–300 %.';
  @override
  String get configKwhHelper => 'Ihr Stromtarif. Typisch: 0,5–1,5 BOB/kWh.';
  @override
  String get settingsDefaultTypical => 'Typisch';
  @override
  String get configFilamentSkipStatus => 'Kein Filament – später hinzufügen';
  @override
  String get configFilamentAddAction => 'Filament hinzufügen';
  @override
  String get configStartButton => 'Angebot erstellen';
  @override
  String get configSummaryTitle => 'Zusammenfassung';
  @override
  String get configSummaryImprint => 'Ihr nächstes Angebot:';
  @override
  String get configPrinterRequired => 'Drucker (erforderlich)';
  @override
  String get configFilamentOptional => 'Filament (optional)';
  @override
  String get configAddFilament => 'Filament hinzufügen';
  @override
  String get configFilamentLater => 'Ich füge es später hinzu';
  @override
  String get configFilamentSkipHint =>
      'Sie können jederzeit unter Einstellungen → Kataloge Filamente hinzufügen.';
  @override
  String get configPrinterSaved => 'Drucker registriert';
  @override
  String get configFilamentSaved => 'Filament hinzugefügt';

  // === Feature gates (T14) ===
  @override
  String get calculatorAdvancedLockedBody =>
      'Pro für Berechnungen mit mehreren Materialien freischalten';
  @override
  String get calculatorGoProAction => 'PRO freischalten';

  // === History cap gate (T15) ===
  @override
  String get historyCapReachedBody =>
      'Sie haben das kostenlose Verlaufslimit erreicht. Wechseln Sie zu Pro für einen unbegrenzten Verlauf.';

  // === Pro badge / locked visuals (UX) ===
  @override
  String get proBadgeLabel => 'PRO';
  @override
  String get proLockedTooltip => 'Pro-Funktion';
  @override
  String get csvExportTooltipLocked => 'CSV exportieren (Pro)';
  @override
  String historyUsageCounter(int used, int cap) =>
      used == 1 ? '1/$cap Angebot' : '$used/$cap Angebote';

  // === Paywall (T10) ===
  @override
  String get paywallTitle => '3dCalc Pro freischalten';
  @override
  String get paywallSubtitle =>
      'Holen Sie das Beste aus Ihrem 3D-Druckkostenrechner heraus';
  @override
  String get paywallPrice => '\$4.99';
  @override
  List<String> get paywallFeatures => const [
    'Markenaufdruck aus PDF-Angeboten entfernen',
    'Kostenaufteilung für mehrere Materialien',
    'Unbegrenzter Verlauf',
    'Als CSV exportieren',
    'Erweiterte Analyseübersicht',
  ];
  @override
  String paywallUnlockButton(String price) => 'Für $price freischalten';
  @override
  String get paywallRestoreButton => 'Kauf wiederherstellen';
  @override
  String get paywallErrorGeneric =>
      'Der Kauf konnte nicht abgeschlossen werden. Bitte versuchen Sie es erneut.';
  @override
  String get paywallUnavailable =>
      'Käufe sind auf dieser Plattform nicht verfügbar.';
  @override
  String get paywallAlreadyPro => 'Sie haben Pro bereits. Vielen Dank!';
  @override
  String get paywallClose => 'Schließen';

  @override
  String get paywallPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get paywallTermsOfService => 'Nutzungsbedingungen';

  @override
  String get settingsLegal => 'Rechtliches';

  @override
  String get legalPrivacyDocument => '''Zuletzt aktualisiert: 11. August 2026

1. Geltungsbereich
Diese Datenschutzerklärung erläutert, wie 3dCalc mit Informationen umgeht, wenn Sie die Anwendung verwenden. Verantwortlicher Betreiber ist Juan Marcelo Albis Ortiz mit Sitz in Bolivien. Für die Hauptfunktionen ist kein Konto erforderlich. Die Anwendung richtet sich an Personen ab 10 Jahren. Minderjährige müssen sie mit Zustimmung und unter Aufsicht eines Elternteils oder gesetzlichen Vormunds verwenden.

2. Gespeicherte Informationen
Von Ihnen eingegebene Informationen wie Einstellungen, Kataloge und Berechnungen werden auf Ihrem Gerät gespeichert. Sicherungsdateien werden am von Ihnen ausgewählten Speicherort abgelegt.

3. Käufe
Käufe werden über Google Play abgewickelt. 3dCalc erhält oder speichert keine vollständigen Kartendaten. Die Anwendung verwendet RevenueCat als technischen Dienstleister zur Verwaltung von Käufen, Wiederherstellungen und Zugriffsstatus; diese Dienste können gemäß ihren eigenen Richtlinien technische Kennungen, Transaktionsdaten und Produktdaten verarbeiten.

4. Weitergabe von Informationen
Wir verkaufen Ihre Daten nicht und geben keine Berechnungsinhalte weiter. Der App-Store und der Anbieter der Kaufabwicklung können gemäß ihren eigenen Richtlinien technische Kennungen und Transaktionsdaten erhalten, die zur Validierung eines Kaufs erforderlich sind.

5. Löschung und Kontrolle
Sie können gespeicherte Daten in der Anwendung oder durch Deinstallation löschen. Exportierte Sicherungsdateien müssen manuell gelöscht werden.

6. Änderungen und Kontakt
Wir können diese Richtlinie aktualisieren, wenn sich die Anwendung oder ihre rechtlichen Anforderungen ändern. Bei Fragen zum Datenschutz wenden Sie sich an Juan Marcelo Albis Ortiz unter marcheloalbis@gmail.com. Google Play und RevenueCat verwalten ihre eigenen Daten gemäß ihren jeweiligen Richtlinien und Verfahren.

Diese Richtlinie dient ausschließlich der Information und sollte vor der Veröffentlichung in einer bestimmten Rechtsordnung juristisch geprüft werden.''';

  @override
  String get legalTermsDocument => '''Zuletzt aktualisiert: 11. August 2026

1. Zustimmung
Durch die Installation oder Nutzung von 3dCalc stimmen Sie diesen Nutzungsbedingungen zu. Anbieter ist Juan Marcelo Albis Ortiz, Bolivien. Wenn Sie nicht zustimmen, dürfen Sie die Anwendung nicht verwenden.

2. Zulässige Nutzung
Sie dürfen 3dCalc für Berechnungen und zur Verwaltung arbeitsbezogener Informationen zu persönlichen oder gewerblichen Zwecken verwenden. Sie müssen mindestens 10 Jahre alt sein und die Anwendung im Einklang mit dem geltenden Recht nutzen. Minderjährige benötigen die Zustimmung und Aufsicht eines Elternteils oder gesetzlichen Vormunds.

3. Ergebnisse und Haftung
Ergebnisse sind Schätzungen und Hilfsmittel. Überprüfen Sie Eingaben, Kosten, Einheiten und Ergebnisse, bevor Sie geschäftliche, technische oder sicherheitsrelevante Entscheidungen treffen. Wir garantieren keine Ergebnisse für einen bestimmten Fall.

4. Käufe und Wiederherstellung
Der Pro-Kauf ist, sofern in Google Play entsprechend eingerichtet, ein einmaliger Kauf und kein automatisches Abonnement. Käufe, Wiederherstellungen, Preise, Steuern und Erstattungen unterliegen Google Play. RevenueCat stellt technische Dienste zur Validierung des Kaufstatus bereit.

5. Geistiges Eigentum
Die Anwendung, ihr Design und ihre Ressourcen gehören ihren jeweiligen Eigentümern. Sie dürfen die Anwendung nicht kopieren, weiterverbreiten, verändern oder zurückentwickeln, außer soweit dies gesetzlich zulässig ist.

6. Verfügbarkeit und Änderungen
Wir können Funktionen der Anwendung aktualisieren, aussetzen oder entfernen. Auch diese Bedingungen können geändert werden; das Aktualisierungsdatum wird am Anfang angezeigt. Bei Fragen wenden Sie sich an marcheloalbis@gmail.com.

''';

  // === i18n consistency (hardcoded → l10n) ===
  @override
  String get commonError => 'Fehler';
  @override
  String get commonNoResults => 'Keine Ergebnisse';
  @override
  String get commonDefault => 'Standard';
  @override
  String get commonUndo => 'Rückgängig';
  @override
  String get commonSaveImage => 'Bild speichern';
  @override
  String get commonExportPdf => 'PDF exportieren';
  @override
  String get commonSharePdf => 'PDF teilen';
  @override
  String get commonPrint => 'Drucken';
  @override
  String get commonImageDownloaded => 'Bild heruntergeladen';
  @override
  String get commonImageSavedGallery => 'Bild in der Galerie gespeichert';
  @override
  String get commonPdfExportError => 'Fehler beim Exportieren des PDFs';
  @override
  String get commonPrintError => 'Fehler beim Drucken';
  @override
  String get commonDefaultSuffix => ' (Standard)';
  @override
  String get historyExportCsv => 'CSV exportieren';
  @override
  String get historyEmptyCta =>
      'Erstellen Sie eines im Rechner und tippen Sie auf Speichern.';
  @override
  String get calcSectionOthers => 'Sonstiges';
  @override
  String get settingsProfitBaseRange => 'Bereich: 0-1000';
  @override
  String get settingsKwhRateRange => 'Bereich: 0,10-5,00';
  @override
  String get shareErrorNotRendered =>
      'Die Zusammenfassung wurde noch nicht dargestellt. Versuchen Sie es gleich erneut.';
  @override
  String get shareErrorNoRegion =>
      'Der aufnehmbare Bereich der Zusammenfassung wurde nicht gefunden.';
  @override
  String get shareErrorEncode => 'Das PNG-Bild konnte nicht codiert werden.';
  @override
  String get shareErrorSaveGallery =>
      'Das Bild konnte nicht in der Galerie gespeichert werden.';
  @override
  String shareErrorSaveWithMessage(String msg) =>
      'Das Bild konnte nicht gespeichert werden: $msg';

  @override
  String get homeHeroTagline => '3D-Angebote · Schnell · Präzise · Offline';

  @override
  String get calcFormIncompleteWarning =>
      'Vervollständigen Sie das Formular vor dem Speichern.';
  @override
  String get calcSaveFailed => 'Speichern nicht möglich.';
  @override
  String calcSavedWithId(int id) => 'Angebot Nr. $id gespeichert.';
  @override
  String get calcSavedViewAction => 'Ansehen';
  @override
  String get calcAddMaterial => 'Material hinzufügen';
  @override
  String get calcPrinterPrefix => 'Drucker: ';
  @override
  String get calcChangePrinter => 'Drucker ändern';
  @override
  String get calcSearchPrinter => 'Drucker suchen ...';
  @override
  String get calcSelectFilament => 'Filament auswählen';
  @override
  String get calcSearchFilament => 'Filament suchen ...';

  @override
  String get detailBreakdown => 'Aufschlüsselung';
  @override
  String detailDiscountPct(int pct) => 'Rabatt ($pct %)';
  @override
  String get detailPreview => 'Vorschau';

  @override
  String get quoteNoDiscount => 'Kein Rabatt';
  @override
  String quoteDiscountPct(int pct) => 'Rabatt $pct %';
  @override
  String get quoteDetail => 'Details';
  @override
  String get quoteGeneratedWith => 'Erstellt mit 3dCalc';

  @override
  String get pdfFileName => 'quote_3dcalc.pdf';
  @override
  String get pdfShareSubject => '3dCalc-Angebot';
  @override
  String get pdfDatePrefix => 'Datum: ';
  @override
  String get pdfQuoteNumber => 'Nr. ';
  @override
  String get pdfValidUntilPrefix => 'G\u00fcltig bis: ';
  @override
  String get pdfClientPrefix => 'Kunde: ';
  @override
  String get pdfNotesTitle => 'Notizen';
  @override
  String get pdfConditionsTitle => 'Bedingungen';
  @override
  String get pdfMaterialCosts => 'Materialkosten';
  @override
  String get pdfElectricity => 'Strom';
  @override
  String get pdfTotalUpper => 'GESAMT';
  @override
  String get pdfHoursPrefix => 'Stunden: ';
  @override
  String pdfDiscountPct(int pct) => 'Rabatt: $pct %';

  @override
  String get dashboardEmptySubtitle =>
      'Erstellen Sie Ihr erstes Angebot von Grund auf.';
  @override
  String get dashboardMonthlyTrend => 'Monatlicher Trend';
  @override
  String get dashboardTopMaterials => 'Am häufigsten verwendete Materialien';

  @override
  String get historySearchHint => 'Nach Name oder Kunde suchen ...';
  @override
  String get historyFilterAll => 'Alle';
  @override
  String get historyFilterSold => 'Verkauft';
  @override
  String get historyFilterPending => 'Offen';
  @override
  String get historyNoQuotesToExport => 'Keine Angebote zum Exportieren';

  @override
  String get chartNoMonthlyData => 'Keine Monatsdaten';
  @override
  List<String> get chartShortMonths => const [
    'Jan',
    'Feb',
    'Mär',
    'Apr',
    'Mai',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Okt',
    'Nov',
    'Dez',
  ];

  @override
  String get filamentSearchHint => 'Filamente suchen ...';
  @override
  String filamentDeleted(String name) => '"$name" gelöscht';
  @override
  String get printerSearchHint => 'Drucker suchen ...';
  @override
  String printerDeleted(String name) => '"$name" gelöscht';
  @override
  String get printerErrorSave => 'Fehler beim Speichern';

  @override
  String get settingsErrorLoad => 'Fehler beim Laden der Einstellungen';
  @override
  String get settingsCurrencySearchHint =>
      'Währung nach Code oder Name suchen ...';
  @override
  String settingsCurrencyNoResults(String query) =>
      'Keine Ergebnisse für "$query"';
  @override
  String get settingsCurrencySymbolPrefix => 'Symbol: ';

  @override
  String get routeNotFound => 'Seite nicht gefunden';
  @override
  String get routeBackHome => 'Zur Startseite';

  @override
  String get themeModeSystem => 'Systemstandard';
  @override
  String get themeModeLight => 'Hell';
  @override
  String get themeModeDark => 'Dunkel';

  @override
  String get splashLogo => '3dCalc-Logo';
  @override
  String onboardingPageCounter(int page, int total) => 'Seite $page von $total';
  @override
  String commonNoResultsFor(String query) => 'Keine Ergebnisse für "$query"';
  @override
  String get historyEmptySearchHint =>
      'Versuchen Sie einen anderen Suchbegriff.';

  @override
  String get filamentErrorLoad => 'Fehler beim Laden der Filamente';
  @override
  String filamentNoResults(String query) =>
      'Keine Filamente entsprechen "$query"';
  @override
  String get filamentEmptyList =>
      'Keine Filamente. Tippen Sie auf +, um das erste zu erstellen.';
  @override
  String filamentDeleteConfirm(String name) => '"$name" löschen?';

  @override
  String get printerErrorLoad => 'Fehler beim Laden der Drucker';
  @override
  String printerNoResults(String query) => 'Keine Drucker entsprechen "$query"';
  @override
  String get printerEmptyList =>
      'Keine Drucker. Tippen Sie auf +, um den ersten zu registrieren.';
  @override
  String printerDeleteConfirm(String name) => '"$name" löschen?';
}
