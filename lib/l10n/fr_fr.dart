// ignore_for_file: public_member_api_docs
import 'app_strings.dart';

/// Chaînes localisées en français (fr_FR).
class FrImpl implements AppStrings {
  const FrImpl();

  @override
  String get appName => '3dCalc';
  @override
  String get commonSave => 'Enregistrer';
  @override
  String get commonCancel => 'Annuler';
  @override
  String get commonDelete => 'Supprimer';
  @override
  String get commonRetry => 'Réessayer';
  @override
  String get commonEdit => 'Modifier';
  @override
  String get commonNew => 'Nouveau';
  @override
  String get commonRequired => 'Obligatoire';
  @override
  String get commonInvalidNumber => 'Nombre invalide';
  @override
  String get commonLoading => 'Chargement...';
  @override
  String get commonErrorGeneric => 'Une erreur est survenue. Réessayez.';
  @override
  String get navHome => 'Accueil';
  @override
  String get navHistory => 'Historique';
  @override
  String get navDashboard => 'Tableau de bord';
  @override
  String get navSettings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres';
  @override
  String get settingsGlobalParams => 'Paramètres généraux';
  @override
  String get settingsProfitBase => 'Marge de base (%)';
  @override
  String get settingsProfitBaseHelper => 'Marge sur le coût de base. 0-1000';
  @override
  String settingsKwhRate(String symbol) => 'Tarif d’électricité ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper =>
      'Fourchette résidentielle en Bolivie : 0,10-5,00';
  @override
  String get settingsCatalogos => 'Catalogues';
  @override
  String get settingsFilamentos => 'Filaments';
  @override
  String get settingsImpresoras => 'Imprimantes';
  @override
  String get settingsAbout => 'À propos';
  @override
  String get settingsPrivacy => 'Confidentialité et données';
  @override
  String get settingsSaved => 'Enregistré';
  @override
  String get settingsAppearance => 'Apparence';
  @override
  String get settingsTheme => 'Thème';
  @override
  String get settingsManageFilaments => 'Gérer vos filaments';
  @override
  String get settingsManagePrinters => 'Enregistrer vos imprimantes';
  @override
  String get settingsLaborPost => 'Main-d’œuvre et post-traitement';
  @override
  String settingsLaborRate(String symbol) =>
      'Tarif de main-d’œuvre ($symbol/heure)';
  @override
  String get settingsLaborRateHelper =>
      'Coût de l’opérateur par heure d’impression. 0 = désactivé';
  @override
  String get settingsPostProcessRate => 'Post-traitement (%)';
  @override
  String get settingsPostProcessRateHelper =>
      '% du coût des matériaux. Ex. 10 = +10 % de finition';
  @override
  String get settingsFailureRate => 'Taux d’échec (%)';
  @override
  String get settingsFailureRateHelper =>
      '% du coût de base pour couvrir les échecs. 0 = désactivé';
  @override
  String settingsMinimumCharge(String symbol) => 'Montant minimum ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Les devis d’un montant inférieur sont automatiquement ajustés';
  @override
  String get settingsMarkupOnMaterials => 'Majoration liée aux déchets (%)';
  @override
  String get settingsMarkupOnMaterialsHelper =>
      'Pourcentage ajouté au coût des matériaux pour couvrir les déchets';
  @override
  String get settingsCurrency => 'Devise';
  @override
  String get settingsCurrencyHelper =>
      'Devise affichée dans les prix, devis et tableau de bord. Aucune conversion automatique.';
  @override
  String get settingsCompany => 'Entreprise';
  @override
  String get settingsCompanyName => 'Nom de l’entreprise';
  @override
  String get settingsCompanyNameHelper =>
      'Apparaît sur le devis. Par défaut : 3dCalc';
  @override
  String get settingsCompanyLogo => 'Logo';
  @override
  String get settingsCompanyLogoPick => 'Choisir une image';
  @override
  String get settingsCompanyLogoRemove => 'Supprimer le logo';
  @override
  String get settingsCompanyLogoError => 'Erreur lors du chargement de l’image';
  @override
  String get settingsBrandingLockedBody =>
      'Passez à la version Pro pour personnaliser votre marque';
  @override
  String get settingsGoProAction => 'Débloquer PRO';
  @override
  String get settingsProTitle => '3D Cal PRO';
  @override
  String get settingsProActive => 'PRO actif';
  @override
  String get settingsProUnlocked =>
      'Toutes les fonctionnalités PRO sont débloquées';
  @override
  String get settingsProNoAdditionalPurchase =>
      'Aucun autre achat n’est nécessaire';
  @override
  String get settingsProFutureUpdates =>
      'Votre achat inclut les futures améliorations PRO sans frais supplémentaires.';
  @override
  String get settingsProRestorePurchase => 'Restaurer l’achat';
  @override
  String get settingsRestorePurchases => 'Restaurer les achats';
  @override
  String get settingsRestoreSuccess => 'Achats restaurés avec succès !';
  @override
  String get settingsRestoreEmpty => 'Aucun achat précédent trouvé';
  @override
  String get settingsRestoreError => 'Impossible de restaurer les achats.';
  @override
  String get settingsBackupTitle => 'Sauvegarde';
  @override
  String get settingsBackupExport => 'Exporter la sauvegarde';
  @override
  String get settingsBackupImport => 'Importer une sauvegarde';
  @override
  String get settingsBackupHelper =>
      'Enregistrez ou restaurez toutes vos données (filaments, imprimantes, devis). Des sauvegardes périodiques sont recommandées.';
  @override
  String get settingsBackupExportSuccess => 'Sauvegarde exportée avec succès';
  @override
  String get settingsBackupExportError =>
      'Erreur lors de l’exportation de la sauvegarde';
  @override
  String settingsBackupImportSuccess(int calcs, int filaments, int printers) =>
      'Sauvegarde restaurée : $calcs devis, $filaments filaments, $printers imprimantes';
  @override
  String get settingsBackupImportError =>
      'Erreur lors de l’importation de la sauvegarde';
  @override
  String get settingsBackupImportConfirmTitle => 'Restaurer la sauvegarde ?';
  @override
  String settingsBackupImportConfirmBody(String summary) =>
      'Toutes les données actuelles seront remplacées par :\n$summary\n\nCette action est irréversible.';
  @override
  String get settingsBackupImportConfirm => 'Restaurer';
  @override
  String get settingsBackupImportCancel => 'Annuler';

  @override
  String get settingsBackupImportSizeError =>
      'Le fichier de sauvegarde dépasse la taille maximale autorisée.';

  @override
  String get settingsBackupImportInvalidFile =>
      'Le fichier sélectionné n\'est pas une sauvegarde valide.';

  @override
  String get settingsBackupImportFutureVersion =>
      'Cette sauvegarde a été créée avec une version future de l\'application. '
      'Mettez à jour 3dCalc et réessayez.';

  @override
  String get settingsBackupLockedBody =>
      'Les sauvegardes sont une fonctionnalité Pro.';

  @override
  String get dashboardTitle => 'Tableau de bord';
  @override
  String get dashboardErrorLoad =>
      'Erreur lors du chargement du tableau de bord';
  @override
  String get dashboardEmpty => 'Aucun devis pour le moment';
  @override
  String get dashboardEmptyCta => 'Aller à l’accueil';
  @override
  String get dashboardStatQuotations => 'Devis';
  @override
  String get dashboardStatSold => 'Vendus';
  @override
  String get dashboardStatConversion => 'Conversion';
  @override
  String get dashboardTotalQuoted => 'Total des devis';
  @override
  String get dashboardTotalSold => 'Total des ventes';
  @override
  String get dashboardChartTitle => 'Devis et revenus';
  @override
  String get dashboardChartQuoted => 'Devis';
  @override
  String get dashboardChartSold => 'Revenus';
  @override
  String get dashboardProTeaserTitle =>
      'Débloquer les analyses de la version Pro';
  @override
  String get dashboardProTeaserBody =>
      'Obtenez le tableau de bord complet avec tendances des coûts, ventilation des matériaux et plus encore.';
  @override
  String get dashboardGoProAction => 'Débloquer PRO';
  @override
  String get homeActionNewCalc => 'Nouveau devis';
  @override
  String get homeActionNewCalcSub => 'Calculer le prix d’impression';
  @override
  String get homeActionHistory => 'Historique';
  @override
  String get homeActionHistorySub => 'Devis enregistrés';
  @override
  String get homeActionDashboard => 'Tableau de bord';
  @override
  String get homeActionDashboardSub => 'Statistiques et graphiques';
  @override
  String get homeQuickAccess => 'Accès rapide';
  @override
  String get homeErrorLoadStats => 'Erreur lors du chargement des statistiques';
  @override
  String get homeEmptyQuotations => 'Aucun devis pour le moment';
  @override
  String get homeSummary => 'Résumé';
  @override
  String get homeSeeAll => 'Tout afficher';

  @override
  String get calcSectionPiece => 'Pièce';
  @override
  String get calcSectionWeight => 'Poids de la pièce';
  @override
  String get calcSectionFilament => 'Filament';
  @override
  String get calcSectionTime => 'Durée d’impression';
  @override
  String get calcSectionDiscount => 'Remise';
  @override
  String get calcLabelOptional => 'Libellé (facultatif)';
  @override
  String get calcLabelOptionalHelper => 'Ex. : support mural, engrenage PETG';
  @override
  String get calcLabelWeight => 'Poids de la pièce';
  @override
  String get calcLabelWeightHelper => 'Grammes du modèle';
  @override
  String get calcLabelHours => 'Heures';
  @override
  String get calcLabelHoursHelper => '0-24';
  @override
  String get calcLabelMinutes => 'Minutes';
  @override
  String get calcLabelMinutesHelper => '0-59';
  @override
  String get calcLabelDiscount => 'Remise';
  @override
  String get calcLabelDiscountHelper => 'Pourcentage retiré du total final';
  @override
  String get calcBtnSave => 'Enregistrer le devis';
  @override
  String get calcBtnReset => 'Réinitialiser les valeurs';
  @override
  String get calcToggleShowDetail => 'Afficher les détails';
  @override
  String get calcToggleHideDetail => 'Masquer les détails';
  @override
  String get calcTotalWithDiscount => 'Total avec remise';
  @override
  String get calcTotalFinal => 'Total';
  @override
  String get calcDetailMaterial => 'Coût des matériaux';
  @override
  String get calcDetailEnergy => 'Coût de l’énergie';
  @override
  String get calcDetailLabor => 'Main-d’œuvre';
  @override
  String get calcDetailPostProcess => 'Post-traitement';
  @override
  String get calcDetailBase => 'Coût de base';
  @override
  String get calcDetailFailure => 'Taux d’échec';
  @override
  String get calcDetailMarkup => 'Majoration des déchets';
  @override
  String get calcDetailProfit => 'Bénéfice';
  @override
  String get calcDetailMinimumCharge => 'Montant minimum';
  @override
  String get calcDetailTotal => 'Total';
  @override
  String get detailQuantityLabel => 'Quantité de pièces';
  @override
  String get detailQuantitySubtitle => 'Coter par lot / volume';
  @override
  String get resultQuantityLabel => 'Quantité';
  @override
  String get calcSectionMaterials => 'Matériaux';
  @override
  String get calcSectionPrinter => 'Imprimante';
  @override
  String get calcNoPrinter => 'Aucune imprimante enregistrée';
  @override
  String get calcPrinterEmptyCta => 'Enregistrer une imprimante';
  @override
  String get calcPrinterEmptyHint =>
      'Calcul sans coût d’énergie. Enregistrez-en une pour l’inclure.';
  @override
  String get calcNoMaterials => 'Aucun matériau.';
  @override
  String get calcEmptyHint =>
      'Renseignez le poids, le filament et la durée pour voir le prix';
  @override
  String get calcKeyWeightHint => 'Indispensable pour calculer le devis';
  @override
  String get calcKeyHoursHint =>
      'Détermine les coûts de main-d’œuvre et d’énergie';
  @override
  String get calcKeyMinutesHint => 'Saisissez la durée réelle d’impression';
  @override
  String calcMaterialTitle(int index) => 'Matériau $index';
  @override
  String calcMaterialRemove(int index) => 'Supprimer le matériau $index';
  @override
  String get calcMaterialCatalog => 'Catalogue';
  @override
  String calcMaterialUse(String filamentName) => 'Utiliser $filamentName';
  @override
  String get calcFieldLabel => 'Libellé';
  @override
  String get calcFieldLabelHelper => 'Facultatif (ex. : base PLA)';
  @override
  String get calcFieldFilament => 'Filament';
  @override
  String get calcFieldWeight => 'Poids';
  @override
  String get calcFieldSpoolPrice => 'Prix de la bobine';
  @override
  String get calcFieldSpoolGrams => 'Grammes / bobine';
  @override
  String get calcFieldLabor => 'Main-d’œuvre';
  @override
  String get calcFieldLaborHelper => 'Tarif horaire';
  @override
  String get calcFieldPostProcess => 'Post-traitement';
  @override
  String get calcFieldPostProcessHelper => '% du coût des matériaux';
  @override
  String get calcFieldFailure => 'Taux d’échec';
  @override
  String get calcFieldFailureHelper => '% du coût de base';
  @override
  String get calcFieldWaste => 'Déchets';
  @override
  String get calcFieldWasteHelper => '% de majoration des déchets';

  @override
  String get costHelpTitle => 'Comment calibrer vos coûts';

  @override
  String get costHelpEnergyTitle => 'Coût de l’énergie';

  @override
  String get costHelpEnergyBody =>
      'Énergie utilisée à l’impression : heures d’impression × puissance '
      '(kW) × tarif (\$/kWh). Ex. : 6 h × 0,15 kW × 1,2 \$/kWh ≈ 1,08 \$. '
      'Ajouté seulement si l’imprimante a une puissance enregistrée.';

  @override
  String get costHelpLaborTitle => 'Main-d’œuvre';

  @override
  String get costHelpLaborBody =>
      'Votre temps : heures de travail × taux horaire (\$/h). Inclut la '
      'préparation de l’imprimante, le suivi et la finition.';

  @override
  String get costHelpPostTitle => 'Post-traitement';

  @override
  String get costHelpPostBody =>
      'Pourcentage supplémentaire sur le coût des matériaux pour ponçage, '
      'peinture, colle ou autres finitions.';

  @override
  String get costHelpFailureTitle => 'Taux d’échec';

  @override
  String get costHelpFailureBody =>
      'Pourcentage du coût de base réservé aux pièces ratées. Si 1 pièce sur '
      '10 échoue, ces 10 % se répartissent sur les 9 vendues.';

  @override
  String get costHelpWasteTitle => 'Déchets et usure';

  @override
  String get costHelpWasteBody =>
      'Pourcentage supplémentaire sur les matériaux : supports, purge de '
      'buse, filament de test et usure de l’imprimante.';

  @override
  String get costHelpMinimumChargeTitle => 'Montant minimum';

  @override
  String get costHelpMinimumChargeBody =>
      'Prix plancher. Si le total calculé est inférieur, ce montant minimum '
      'est facturé. Idéal pour les petites pièces qui demandent quand même '
      'la préparation de l’imprimante.';

  @override
  String get costHelpMarginTitle => 'Marge (profit)';

  @override
  String get costHelpMarginBody =>
      'Pourcentage ajouté au coût total pour votre profit : total × (1 + '
      'marge/100). Réglable dans Paramètres globaux.';
  @override
  String get calcCloseAction => 'Fermer et retourner au menu';
  @override
  String get calcModeExpress => 'Express';
  @override
  String get calcModeAdvanced => 'Avancé';
  @override
  String calcSemanticMode(String mode) => 'Mode de calcul : $mode';
  @override
  String get calcActionReset => 'Réinitialiser';
  @override
  String get calcDialogClient => 'Client';
  @override
  String get calcDialogClientHelper => 'Facultatif';
  @override
  String get calcDialogRecentClients => 'Clients récents';
  @override
  String get calcDialogNotes => 'Notes (facultatif)';
  @override
  String get calcDialogNotesHelper =>
      'Sp\u00e9cifications, d\u00e9lais, livraison\u2026';
  @override
  String get calcDialogConditions => 'Conditions commerciales (facultatif)';
  @override
  String get calcDialogConditionsHelper =>
      'Validit\u00e9, paiement, garantie\u2026';

  @override
  String get calcTemplatesTitle => 'Mod\u00e8les';
  @override
  String get calcTemplateSaveAsAction => 'Enregistrer comme mod\u00e8le';
  @override
  String get calcTemplateSaveSuccess => 'Mod\u00e8le enregistr\u00e9';
  @override
  String get calcTemplateSaveError =>
      'Impossible d\u2019enregistrer le mod\u00e8le';
  @override
  String get calcTemplateApplySuccess =>
      'Mod\u00e8le appliqu\u00e9 au formulaire';
  @override
  String get calcTemplateApplyError => 'Impossible de charger le mod\u00e8le';
  @override
  String get calcTemplateEmpty =>
      'Aucun mod\u00e8le pour l\u2019instant.\nEnregistrez un travail fr\u00e9quent comme mod\u00e8le pour le r\u00e9utiliser.';
  @override
  String get calcTemplateUntitled => 'Sans nom';
  @override
  String get calcTemplateDeleteError =>
      'Impossible de supprimer le mod\u00e8le';
  @override
  String get calcEmptyHintPrefix => 'Renseignez';
  @override
  String get calcEmptyHintSuffix => 'pour voir le devis';
  @override
  String get calcFieldWeightShort => 'poids de la pièce';
  @override
  String get calcFieldPriceShort => 'prix du filament';
  @override
  String get calcFieldTimeShort => 'durée d’impression';
  @override
  String get calcFieldMaterialShort => 'au moins un matériau';
  @override
  String get calcMetaSeparator => ' · ';
  @override
  String get calcResultBarTapHint => 'Voir le devis';
  @override
  String get calcResultBarEmptyHint => 'Incomplet';
  @override
  String get calcSheetTitle => 'Devis';
  @override
  String get calcBtnShare => 'Partager l’image';
  @override
  String get calcBtnShareTooltip => 'Génère une image prête à partager';
  @override
  String get calcShareError => 'Impossible de générer l’image';
  @override
  String get calcShareSubject => 'Devis 3D';
  @override
  String get calcShareText => 'Devis généré avec 3dCalc';
  @override
  String get calcSheetActionsLabel => 'Actions';
  @override
  String get quoteImageAdd => 'Ajouter une image';
  @override
  String get quoteImageGallery => 'Galerie';
  @override
  String get quoteImageCamera => 'Appareil photo';
  @override
  String get quoteImageChange => 'Modifier';
  @override
  String get quoteImageRemove => 'Supprimer';
  @override
  String get quoteImageTooLarge =>
      'L’image dépasse 5 Mo et n’a pas été jointe.';
  @override
  String get quoteImageInvalidFormat =>
      'Format d’image invalide (JPEG, PNG ou WebP uniquement).';
  @override
  String get quoteImageError => 'Impossible d’obtenir l’image';

  @override
  String get filamentTitle => 'Filaments';
  @override
  String get filamentNew => 'Nouveau filament';
  @override
  String get filamentEdit => 'Modifier le filament';
  @override
  String get filamentName => 'Nom';
  @override
  String get filamentNameHelper => 'Ex. : PLA noir';
  @override
  String get filamentBrand => 'Marque';
  @override
  String get filamentBrandHelper => 'Facultatif';
  @override
  String get brandSelectorOther => 'Autre...';
  @override
  String get brandSelectorHint => 'Choisissez une marque ou sélectionnez Autre';
  @override
  String get brandSelectorManualHelper => 'Saisissez le nom de la marque';
  @override
  String filamentPrice(String symbol) => 'Prix du filament ($symbol)';
  @override
  String get filamentPriceHelper => 'Coût de la bobine complète';
  @override
  String get filamentGrams => 'Grammes par bobine';
  @override
  String get filamentGramsHelper => 'Généralement 1000';
  @override
  String get filamentDefaultToggle => 'Définir par défaut';
  @override
  String get filamentDefaultSubtitle =>
      'Utilisé dans les nouveaux devis. Un seul filament peut être par défaut.';
  @override
  String get filamentNewTooltip => 'Nouveau filament';
  @override
  String get filamentDeleteTitle => 'Supprimer le filament';
  @override
  String get filamentErrorSave => 'Erreur lors de l’enregistrement';
  @override
  String get filamentMustBePositive => 'Doit être > 0';
  @override
  String get filamentMustBeInteger => 'Doit être un entier';
  @override
  String get filamentMax100 => '100 caractères maximum';
  @override
  String get printerTitle => 'Imprimantes';
  @override
  String get printerNew => 'Nouvelle imprimante';
  @override
  String get printerEdit => 'Modifier l’imprimante';
  @override
  String get printerModel => 'Modèle';
  @override
  String get printerModelHelper => 'Ex. : Ender 3 V2';
  @override
  String get printerBrandHelper => 'Ex. : Creality, Anycubic';
  @override
  String get printerWatts => 'Consommation moyenne (W)';
  @override
  String get printerWattsHelper => 'Généralement 100-300 W';
  @override
  String get printerDefaultSubtitle =>
      'Utilisée dans les nouveaux devis. Une seule imprimante peut être par défaut.';
  @override
  String get printerNewTooltip => 'Nouvelle imprimante';
  @override
  String get printerDeleteTitle => 'Supprimer l’imprimante';
  @override
  String get printerMustBeNonNegative => 'Doit être >= 0';
  @override
  String get calcNotifFilament => 'Filament';
  @override
  String get calcNotifMaterial => 'Matériau';
  @override
  String get calcDetailTitle => 'Détail du devis';
  @override
  String get calcDetailDelete => 'Supprimer';
  @override
  String get calcDetailDeleteTitle => 'Supprimer le devis';
  @override
  String get calcDetailDeleteConfirm => 'Supprimer définitivement ?';
  @override
  String get calcDetailNoName => 'Sans nom';
  @override
  String get calcDetailSold => 'Vendu';
  @override
  String get calcDetailReuse => 'Réutiliser';
  @override
  String get calcDetailMarkSold => 'Marquer comme vendu';
  @override
  String get calcDetailMarkPending => 'Marquer comme en attente';

  @override
  String get calcDuplicateAction => 'Dupliquer';
  @override
  String get calcDuplicateSuffix => ' (copie)';
  @override
  String get calcDuplicateSuccess => 'Devis dupliqué';
  @override
  String get calcDuplicateError => 'Impossible de dupliquer le devis';
  @override
  String get historyTitle => 'Devis';
  @override
  String get historyErrorLoad => 'Erreur lors du chargement des devis';
  @override
  String get historyEmpty => 'Aucun devis enregistré';
  @override
  String get csvExportLockedBody =>
      'L’exportation au format CSV est une fonction de la version Pro';
  @override
  String get csvGoProAction => 'Débloquer PRO';
  @override
  String get localeLabel => 'Langue';
  @override
  String get localeEs => 'Espagnol';
  @override
  String get localeEn => 'Anglais';
  @override
  String get localePtBr => 'Portugais (Brésil)';
  @override
  String get localeDe => 'Allemand';
  @override
  String get localeFr => 'Français';

  @override
  String get onboardingTitle1 => 'Bienvenue dans 3dCalc';
  @override
  String get onboardingDesc1 =>
      'Calculez instantanément le prix de vos impressions 3D.\nMatériaux, électricité, main-d’œuvre et plus.';
  @override
  String get onboardingTitle2 => 'Deux modes de calcul';
  @override
  String get onboardingDesc2 =>
      'Express : calcul rapide avec un matériau.\nAvancé : plusieurs matériaux, remise et plus.';
  @override
  String get onboardingTitle3 => 'Catalogue intégré';
  @override
  String get onboardingDesc3 =>
      'Enregistrez vos filaments et imprimantes préférés.\nSélectionnez-les instantanément dans le catalogue.';
  @override
  String get onboardingTitle4 => 'Tableau de bord et plus';
  @override
  String get onboardingDesc4 =>
      'Suivez les devis et les tendances mensuelles,\nexportez en PDF et recherchez dans l’historique.';
  @override
  String get onboardingNext => 'Suivant';
  @override
  String get onboardingSkip => 'Ignorer';
  @override
  String get onboardingStart => 'Commencer';
  @override
  String get onboardingStartQuote => 'Créer mon premier devis';
  @override
  String get onboardingGoHome => 'Aller au menu';
  @override
  String get configTitle => 'Configuration initiale';
  @override
  String get configLanguage => 'Langue';
  @override
  String get configCurrency => 'Devise';
  @override
  String get configContinue => 'Continuer';
  @override
  String get configStep1Title => 'Langue et devise';
  @override
  String get configStep2Title => 'Imprimante et filament';
  @override
  String get configStep3Title => 'Bénéfice et énergie';
  @override
  String get configBack => 'Retour';
  @override
  String get configFinish => 'Terminer';
  @override
  String get configStepSubtitle1 => 'Commençons par les bases.';
  @override
  String get configStepSubtitle2 =>
      'Commençons par ce que vous utilisez pour imprimer. L’imprimante est nécessaire pour le coût de l’énergie.';
  @override
  String get configStepSubtitle3 =>
      'Ces valeurs s’appliquent à chaque devis. Vous pourrez les modifier plus tard.';
  @override
  String configStepCounter(int step, int total) => 'Étape $step sur $total';
  @override
  String get configLanguageHelper =>
      'Choisissez la langue de l’application. Vous pourrez la modifier plus tard.';
  @override
  String get configCurrencyHelper =>
      'Devise utilisée pour les prix et devis. Les valeurs ne sont pas converties.';
  @override
  String get configPrinterSectionHelper =>
      'Elle est nécessaire pour calculer le coût énergétique de chaque impression.';
  @override
  String get configFilamentSectionHelper =>
      'Si vous avez la bobine sous la main, ajoutez-la maintenant. Sinon, ajoutez-la plus tard dans Paramètres → Catalogues.';
  @override
  String get configProfitHelper =>
      'Marge sur le coût de base. 200 % double le coût. Habituel : 100-300 %.';
  @override
  String get configKwhHelper =>
      'Tarif de votre facture d’électricité. Habituel : 0,5-1,5 BOB/kWh.';
  @override
  String get settingsDefaultTypical => 'Valeur habituelle';
  @override
  String get configFilamentSkipStatus => 'Aucun filament — ajouter plus tard';
  @override
  String get configFilamentAddAction => 'Ajouter un filament';
  @override
  String get configStartButton => 'Commencer les devis';
  @override
  String get configSummaryTitle => 'Résumé';
  @override
  String get configSummaryImprint => 'Votre prochain devis :';
  @override
  String get configPrinterRequired => 'Imprimante (obligatoire)';
  @override
  String get configFilamentOptional => 'Filament (facultatif)';
  @override
  String get configAddFilament => 'Ajouter un filament';
  @override
  String get configFilamentLater => 'Je l’ajouterai plus tard';
  @override
  String get configFilamentSkipHint =>
      'Vous pouvez ajouter des filaments à tout moment dans Paramètres → Catalogues.';
  @override
  String get configPrinterSaved => 'Imprimante enregistrée';
  @override
  String get configFilamentSaved => 'Filament ajouté';
  @override
  String get calculatorAdvancedLockedBody =>
      'Passez à la version Pro pour les calculs avec plusieurs matériaux';
  @override
  String get calculatorGoProAction => 'Débloquer PRO';
  @override
  String get historyCapReachedBody =>
      'Vous avez atteint la limite de l’historique gratuit. Passez à la version Pro pour un historique illimité.';
  @override
  String get proBadgeLabel => 'PRO';
  @override
  String get proLockedTooltip => 'Fonctionnalité de la version Pro';
  @override
  String get csvExportTooltipLocked => 'Exporter au format CSV (version Pro)';
  @override
  String historyUsageCounter(int used, int cap) =>
      used == 1 ? '1/$cap devis' : '$used/$cap devis';
  @override
  String get paywallTitle => 'Débloquer 3dCalc Pro';
  @override
  String get paywallSubtitle =>
      'Tirez le meilleur parti de votre calculateur de coûts d’impression 3D';
  @override
  String get paywallPrice => '\$4.99';
  @override
  List<String> get paywallFeatures => const [
    'Supprimer la marque sur les devis PDF',
    'Ventilation des coûts pour plusieurs matériaux',
    'Historique illimité',
    'Exporter en CSV',
    'Tableau de bord d’analyse avancé',
  ];
  @override
  String paywallUnlockButton(String price) => 'Débloquer pour $price';
  @override
  String get paywallRestoreButton => 'Restaurer l’achat';
  @override
  String get paywallErrorGeneric =>
      'Impossible de terminer l’achat. Réessayez.';
  @override
  String get paywallUnavailable =>
      'Les achats ne sont pas disponibles sur cette plateforme.';
  @override
  String get paywallAlreadyPro => 'Vous disposez déjà de Pro. Merci !';
  @override
  String get paywallClose => 'Fermer';
  @override
  String get paywallPrivacyPolicy => 'Politique de confidentialité';
  @override
  String get paywallTermsOfService => 'Conditions d’utilisation';
  @override
  String get settingsLegal => 'Mentions légales';
  @override
  String get legalPrivacyDocument => '''Dernière mise à jour : 11 août 2026

1. Champ d’application
Cette politique explique comment 3dCalc traite les informations lors de l’utilisation de l’application. L’opérateur responsable est Juan Marcelo Albis Ortiz, en Bolivie. Aucun compte n’est nécessaire pour les fonctions principales. L’application est destinée aux personnes âgées d’au moins 10 ans. Les mineurs doivent l’utiliser avec l’autorisation et sous la supervision d’un parent ou tuteur légal.

2. Informations stockées
Les informations que vous saisissez, comme les paramètres, catalogues et calculs, sont stockées sur votre appareil. Les sauvegardes sont enregistrées à l’emplacement que vous choisissez.

3. Achats
Les achats sont traités par Google Play. 3dCalc ne reçoit ni ne stocke les données complètes de votre carte. RevenueCat est utilisé comme fournisseur technique pour gérer les achats, restaurations et droits d’accès ; ces services peuvent traiter des identifiants techniques, données de transaction et données de produit selon leurs propres politiques.

4. Partage d’informations
Nous ne vendons pas vos données et ne partageons pas le contenu de vos calculs. La boutique et le fournisseur de traitement des achats peuvent recevoir les identifiants techniques et données de transaction nécessaires à la validation d’un achat selon leurs propres politiques.

5. Suppression et contrôle
Vous pouvez supprimer les données stockées depuis l’application ou en la désinstallant. Les sauvegardes exportées doivent être supprimées manuellement.

6. Modifications et contact
Nous pouvons mettre à jour cette politique lorsque l’application ou ses obligations légales évoluent. Pour toute question, contactez Juan Marcelo Albis Ortiz à marcheloalbis@gmail.com. Google Play et RevenueCat gèrent leurs propres données selon leurs politiques et procédures respectives.

Cette politique est informative et doit être examinée avec un conseiller juridique avant publication dans une juridiction donnée.''';
  @override
  String get legalTermsDocument => '''Dernière mise à jour : 11 août 2026

1. Acceptation
En installant ou en utilisant 3dCalc, vous acceptez ces conditions d’utilisation. Le fournisseur est Juan Marcelo Albis Ortiz, en Bolivie. Si vous n’acceptez pas ces conditions, n’utilisez pas l’application.

2. Utilisation autorisée
Vous pouvez utiliser 3dCalc pour effectuer des calculs et gérer des informations professionnelles à des fins personnelles ou commerciales. Vous devez avoir au moins 10 ans et respecter la loi applicable. Les mineurs doivent disposer de l’autorisation et de la supervision d’un parent ou tuteur légal.

3. Résultats et responsabilité
 Les résultats sont des estimations et des outils d’aide. Vérifiez les données, coûts, unités et résultats avant toute décision commerciale, technique ou de sécurité. Nous ne garantissons pas les résultats pour un cas particulier.

4. Achats et restauration
L’achat Pro est un achat unique, s’il est configuré ainsi dans Google Play, et non un abonnement automatique. Les achats, restaurations, prix, taxes et remboursements sont soumis à Google Play. RevenueCat fournit les services techniques de validation du statut d’achat.

5. Propriété intellectuelle
 L’application, sa conception et ses ressources appartiennent à leurs propriétaires respectifs. Vous ne pouvez pas copier, redistribuer, modifier ou faire de l’ingénierie inverse de l’application, sauf dans les limites autorisées par la loi.

6. Disponibilité et modifications
Nous pouvons mettre à jour, suspendre ou supprimer des fonctionnalités. Ces conditions peuvent également changer ; la date de mise à jour figurera au début. Pour toute question, contactez marcheloalbis@gmail.com.
''';

  @override
  String get commonError => 'Erreur';
  @override
  String get commonNoResults => 'Aucun résultat';
  @override
  String get commonDefault => 'Par défaut';
  @override
  String get commonUndo => 'Annuler';
  @override
  String get commonSaveImage => 'Enregistrer l’image';
  @override
  String get commonExportPdf => 'Exporter en PDF';
  @override
  String get commonSharePdf => 'Partager au format PDF';
  @override
  String get commonPrint => 'Imprimer';
  @override
  String get commonImageDownloaded => 'Image téléchargée';
  @override
  String get commonImageSavedGallery => 'Image enregistrée dans la galerie';
  @override
  String get commonPdfExportError => 'Erreur lors de l’exportation du PDF';
  @override
  String get commonPrintError => 'Erreur lors de l’impression';
  @override
  String get commonDefaultSuffix => ' (par défaut)';
  @override
  String get historyExportCsv => 'Exporter au format CSV';
  @override
  String get historyEmptyCta =>
      'Créez-en un dans la calculatrice et appuyez sur Enregistrer.';
  @override
  String get calcSectionOthers => 'Autres';
  @override
  String get settingsProfitBaseRange => 'Plage : 0-1000';
  @override
  String get settingsKwhRateRange => 'Plage : 0,10-5,00';
  @override
  String get shareErrorNotRendered =>
      'Le résumé n’est pas encore affiché. Réessayez dans un instant.';
  @override
  String get shareErrorNoRegion =>
      'La zone du résumé pouvant être capturée est introuvable.';
  @override
  String get shareErrorEncode => 'Impossible d’encoder l’image PNG.';
  @override
  String get shareErrorSaveGallery =>
      'Impossible d’enregistrer l’image dans la galerie.';
  @override
  String shareErrorSaveWithMessage(String msg) =>
      'Impossible d’enregistrer l’image : $msg';
  @override
  String get homeHeroTagline =>
      'Devis 3D · Rapide · Précis · Toujours à portée de main';
  @override
  String get calcFormIncompleteWarning =>
      'Complétez le formulaire avant de l’enregistrer.';
  @override
  String get calcSaveFailed => 'Impossible d’enregistrer.';
  @override
  String calcSavedWithId(int id) => 'Devis n° $id enregistré.';
  @override
  String get calcSavedViewAction => 'Voir';
  @override
  String get calcAddMaterial => 'Ajouter un matériau';
  @override
  String get calcPrinterPrefix => 'Imprimante : ';
  @override
  String get calcChangePrinter => 'Changer d’imprimante';
  @override
  String get calcSearchPrinter => 'Rechercher une imprimante...';
  @override
  String get calcSelectFilament => 'Sélectionner un filament';
  @override
  String get calcSearchFilament => 'Rechercher un filament...';
  @override
  String get detailBreakdown => 'Ventilation';
  @override
  String detailDiscountPct(int pct) => 'Remise ($pct %)';
  @override
  String get detailPreview => 'Aperçu';
  @override
  String get quoteNoDiscount => 'Aucune remise';
  @override
  String quoteDiscountPct(int pct) => 'Remise de $pct %';
  @override
  String get quoteDetail => 'Détails';
  @override
  String get quoteGeneratedWith => 'Généré avec 3dCalc';
  @override
  String get pdfFileName => 'devis_3dcalc.pdf';
  @override
  String get pdfShareSubject => 'Devis 3dCalc';
  @override
  String get pdfDatePrefix => 'Date : ';
  @override
  String get pdfQuoteNumber => 'N\u00ba ';
  @override
  String get pdfValidUntilPrefix => 'Valable jusqu\u2019au : ';
  @override
  String get pdfClientPrefix => 'Client : ';
  @override
  String get pdfNotesTitle => 'Notes';
  @override
  String get pdfConditionsTitle => 'Conditions';
  @override
  String get pdfMaterialCosts => 'Coût des matériaux';
  @override
  String get pdfElectricity => 'Électricité';
  @override
  String get pdfTotalUpper => 'TOTAL';
  @override
  String get pdfHoursPrefix => 'Heures : ';
  @override
  String pdfDiscountPct(int pct) => 'Remise : $pct %';
  @override
  String get dashboardEmptySubtitle =>
      'Créez votre premier devis à partir de zéro.';
  @override
  String get dashboardMonthlyTrend => 'Tendance mensuelle';
  @override
  String get dashboardTopMaterials => 'Matériaux les plus utilisés';

  @override
  String get dashboardProfitTitle => 'Rentabilité';
  @override
  String get dashboardStatEstimatedProfit => 'Profit estimé';
  @override
  String get dashboardMarginLabel => 'Marge moyenne';
  @override
  String get dashboardAvgTicketTitle => 'Ticket moyen';
  @override
  String get dashboardAvgTicketQuoted => 'Ticket moyen (devisé)';
  @override
  String get dashboardAvgTicketSold => 'Ticket moyen (vendu)';
  @override
  String get dashboardTopClients => 'Top clients';
  @override
  String get dashboardOperationalTitle => 'Métriques opérationnelles';
  @override
  String get dashboardPrintHours => 'Heures d\'impression';
  @override
  String get dashboardFilament => 'Filament';
  @override
  String get dashboardInsightsTitle => 'Insights';
  @override
  String get dashboardRange7d => '7j';
  @override
  String get dashboardRange30d => '30j';
  @override
  String get dashboardRange90d => '90j';
  @override
  String get dashboardRangeYtd => 'YTD';
  @override
  String get dashboardRangeAll => 'Tout';
  @override
  String insightConversion(int sold, int total, int pct) =>
      'Vous avez vendu $sold sur $total devis ($pct%)';
  @override
  String insightAvgTicketSold(String amount) => 'Ticket moyen vendu : $amount';
  @override
  String insightBestMonth(String month, String amount) =>
      'Meilleur mois : $month ($amount)';
  @override
  String insightTopClient(String name, String amount) =>
      'Client top : $name ($amount)';
  @override
  String insightFilament(String amount) =>
      'Vous avez devisé $amount de filament';
  @override
  String get historySearchHint => 'Rechercher par nom ou client...';
  @override
  String get historyFilterAll => 'Tous';
  @override
  String get historyFilterSold => 'Vendus';
  @override
  String get historyFilterPending => 'En attente';
  @override
  String get historyNoQuotesToExport => 'Aucun devis à exporter';
  @override
  String get chartNoMonthlyData => 'Aucune donnée mensuelle';
  @override
  List<String> get chartShortMonths => const [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  @override
  String get filamentSearchHint => 'Rechercher des filaments...';
  @override
  String filamentDeleted(String name) => '« $name » supprimé';
  @override
  String get printerSearchHint => 'Rechercher des imprimantes...';
  @override
  String printerDeleted(String name) => '« $name » supprimée';
  @override
  String get printerErrorSave => 'Erreur lors de l’enregistrement';
  @override
  String get settingsErrorLoad => 'Erreur lors du chargement des paramètres';
  @override
  String get settingsCurrencySearchHint =>
      'Rechercher une devise par code ou nom...';
  @override
  String settingsCurrencyNoResults(String query) =>
      'Aucun résultat pour « $query »';
  @override
  String get settingsCurrencySymbolPrefix => 'Symbole : ';
  @override
  String get routeNotFound => 'Page introuvable';
  @override
  String get routeBackHome => 'Retour à l’accueil';
  @override
  String get themeModeSystem => 'Système';
  @override
  String get themeModeLight => 'Clair';
  @override
  String get themeModeDark => 'Sombre';
  @override
  String get splashLogo => 'Logo 3dCalc';
  @override
  String onboardingPageCounter(int page, int total) => 'Page $page sur $total';
  @override
  String commonNoResultsFor(String query) => 'Aucun résultat pour « $query »';
  @override
  String get historyEmptySearchHint => 'Essayez un autre terme.';
  @override
  String get filamentErrorLoad => 'Erreur lors du chargement des filaments';
  @override
  String filamentNoResults(String query) =>
      'Aucun filament ne correspond à « $query »';
  @override
  String get filamentEmptyList =>
      'Aucun filament. Appuyez sur + pour créer le premier.';
  @override
  String filamentDeleteConfirm(String name) => 'Supprimer « $name » ?';
  @override
  String get printerErrorLoad => 'Erreur lors du chargement des imprimantes';
  @override
  String printerNoResults(String query) =>
      'Aucune imprimante ne correspond à « $query »';
  @override
  String get printerEmptyList =>
      'Aucune imprimante. Appuyez sur + pour enregistrer la première.';
  @override
  String printerDeleteConfirm(String name) => 'Supprimer « $name » ?';
}
