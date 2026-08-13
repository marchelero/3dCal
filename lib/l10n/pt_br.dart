/// Strings em português do Brasil (pt_BR).
library;
// ignore_for_file: public_member_api_docs

import 'app_strings.dart';

class PtBrImpl implements AppStrings {
  const PtBrImpl();

  @override
  String get appName => '3dCalc';

  @override
  String get commonSave => 'Salvar';
  @override
  String get commonCancel => 'Cancelar';
  @override
  String get commonDelete => 'Excluir';
  @override
  String get commonRetry => 'Tentar novamente';
  @override
  String get commonEdit => 'Editar';
  @override
  String get commonNew => 'Novo';
  @override
  String get commonRequired => 'Obrigatório';
  @override
  String get commonInvalidNumber => 'Número inválido';
  @override
  String get commonLoading => 'Carregando...';
  @override
  String get commonErrorGeneric => 'Algo deu errado. Tente novamente.';

  @override
  String get navHome => 'Início';
  @override
  String get navHistory => 'Histórico';
  @override
  String get navDashboard => 'Painel';
  @override
  String get navSettings => 'Configurações';

  @override
  String get settingsTitle => 'Configurações';
  @override
  String get settingsGlobalParams => 'Parâmetros globais';
  @override
  String get settingsProfitBase => 'Lucro base (%)';
  @override
  String get settingsProfitBaseHelper => 'Margem sobre o custo base. 0-1000';
  @override
  String settingsKwhRate(String symbol) =>
      'Tarifa de eletricidade ($symbol/kWh)';
  @override
  String get settingsKwhRateHelper => 'Faixa residencial na Bolívia: 0.10-5.00';
  @override
  String get settingsCatalogos => 'Catálogos';
  @override
  String get settingsFilamentos => 'Filamentos';
  @override
  String get settingsImpresoras => 'Impressoras';
  @override
  String get settingsAbout => 'Sobre';
  @override
  String get settingsPrivacy => 'Privacidade e dados';
  @override
  String get settingsSaved => 'Salvo';
  @override
  String get settingsAppearance => 'Aparência';
  @override
  String get settingsTheme => 'Tema';
  @override
  String get settingsManageFilaments => 'Gerencie seus filamentos';
  @override
  String get settingsManagePrinters => 'Cadastre suas impressoras';

  @override
  String get settingsLaborPost => 'Mão de obra e pós-processamento';
  @override
  String settingsLaborRate(String symbol) =>
      'Taxa de mão de obra ($symbol/hora)';
  @override
  String get settingsLaborRateHelper =>
      'Custo do operador/técnico por hora de impressão. 0 = desativado';
  @override
  String get settingsPostProcessRate => 'Pós-processamento (%)';
  @override
  String get settingsPostProcessRateHelper =>
      'Percentual do custo do material. Ex.: 10 = +10% de acabamento, lixamento ou pintura';
  @override
  String get settingsFailureRate => 'Taxa de falha (%)';
  @override
  String get settingsFailureRateHelper =>
      'Percentual do custo base para cobrir impressões com falha. 0 = desativado';
  @override
  String settingsMinimumCharge(String symbol) => 'Cobrança mínima ($symbol)';
  @override
  String get settingsMinimumChargeHelper =>
      'Orçamentos abaixo desse valor são ajustados automaticamente';
  @override
  String get settingsMarkupOnMaterials => 'Margem de desperdício (%)';
  @override
  String get settingsMarkupOnMaterialsHelper =>
      'Percentual adicional sobre o custo do material para desperdício e desgaste';

  @override
  String get settingsCurrency => 'Moeda';
  @override
  String get settingsCurrencyHelper =>
      'Define a moeda exibida em preços, orçamentos e no painel. Não há conversão automática.';

  @override
  String get settingsCompany => 'Empresa';
  @override
  String get settingsCompanyName => 'Nome da empresa';
  @override
  String get settingsCompanyNameHelper =>
      'Aparece no orçamento. Padrão: 3dCalc';
  @override
  String get settingsCompanyLogo => 'Logo';
  @override
  String get settingsCompanyLogoPick => 'Escolher imagem';
  @override
  String get settingsCompanyLogoRemove => 'Remover logo';
  @override
  String get settingsCompanyLogoError => 'Erro ao carregar a imagem';

  @override
  String get settingsBrandingLockedBody =>
      'Desbloqueie o Pro para personalizar sua marca';
  @override
  String get settingsGoProAction => 'Desbloquear PRO';
  @override
  String get settingsProTitle => '3D Cal PRO';
  @override
  String get settingsProActive => 'PRO ativo';
  @override
  String get settingsProUnlocked =>
      'Você já tem todos os recursos PRO desbloqueados';
  @override
  String get settingsProNoAdditionalPurchase =>
      'Você não precisa fazer outra compra';
  @override
  String get settingsProFutureUpdates =>
      'Sua compra inclui futuras melhorias do PRO sem custo adicional.';
  @override
  String get settingsProRestorePurchase => 'Restaurar compra';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';
  @override
  String get settingsRestoreSuccess => 'Compras restauradas com sucesso!';
  @override
  String get settingsRestoreEmpty => 'Nenhuma compra anterior encontrada';
  @override
  String get settingsRestoreError => 'Não foi possível restaurar as compras.';

  @override
  String get settingsBackupTitle => 'Backup';

  @override
  String get settingsBackupExport => 'Exportar backup';

  @override
  String get settingsBackupImport => 'Importar backup';

  @override
  String get settingsBackupHelper =>
      'Salve ou restaure todos os seus dados (filamentos, impressoras e orçamentos). Recomenda-se fazer backups periódicos.';

  @override
  String get settingsBackupExportSuccess => 'Backup exportado com sucesso';

  @override
  String get settingsBackupExportError => 'Erro ao exportar o backup';

  @override
  String settingsBackupImportSuccess(int calcs, int filaments, int printers) =>
      'Backup restaurado: $calcs orçamentos, $filaments filamentos, $printers impressoras';

  @override
  String get settingsBackupImportError => 'Erro ao importar o backup';

  @override
  String get settingsBackupImportConfirmTitle => 'Restaurar backup?';

  @override
  String settingsBackupImportConfirmBody(String summary) =>
      'Todos os dados atuais serão substituídos por:\n$summary\n\nEsta ação não pode ser desfeita.';

  @override
  String get settingsBackupImportConfirm => 'Restaurar';

  @override
  String get settingsBackupImportCancel => 'Cancelar';

  @override
  String get settingsBackupImportSizeError =>
      'O arquivo de backup excede o tamanho máximo permitido.';

  @override
  String get settingsBackupImportInvalidFile =>
      'O arquivo selecionado não é um backup válido.';

  @override
  String get settingsBackupImportFutureVersion =>
      'Este backup foi criado com uma versão futura do aplicativo. '
      'Atualize o 3dCalc e tente novamente.';

  @override
  String get settingsBackupLockedBody => 'Fazer backups é um recurso Pro.';

  @override
  String get dashboardTitle => 'Painel';
  @override
  String get dashboardErrorLoad => 'Erro ao carregar o painel';
  @override
  String get dashboardEmpty => 'Nenhum orçamento ainda';
  @override
  String get dashboardEmptyCta => 'Ir para o início';
  @override
  String get dashboardStatQuotations => 'Orçamentos';
  @override
  String get dashboardStatSold => 'Vendidos';
  @override
  String get dashboardStatConversion => 'Conversão';
  @override
  String get dashboardTotalQuoted => 'Total orçado';
  @override
  String get dashboardTotalSold => 'Total vendido';
  @override
  String get dashboardChartTitle => 'Orçado x recebido';
  @override
  String get dashboardChartQuoted => 'Orçado';
  @override
  String get dashboardChartSold => 'Recebido';
  @override
  String get dashboardProTeaserTitle => 'Desbloqueie as análises Pro';
  @override
  String get dashboardProTeaserBody =>
      'Tenha acesso ao painel completo, com tendências de custos, detalhamento de materiais e muito mais.';
  @override
  String get dashboardGoProAction => 'Desbloquear PRO';

  @override
  String get homeActionNewCalc => 'Novo orçamento';
  @override
  String get homeActionNewCalcSub => 'Calcular preço da impressão';
  @override
  String get homeActionHistory => 'Histórico';
  @override
  String get homeActionHistorySub => 'Orçamentos salvos';
  @override
  String get homeActionDashboard => 'Painel';
  @override
  String get homeActionDashboardSub => 'Estatísticas e gráficos';
  @override
  String get homeQuickAccess => 'Acesso rápido';
  @override
  String get homeErrorLoadStats => 'Erro ao carregar estatísticas';
  @override
  String get homeEmptyQuotations => 'Nenhum orçamento ainda';
  @override
  String get homeSummary => 'Resumo';
  @override
  String get homeSeeAll => 'Ver tudo';

  @override
  String get calcSectionPiece => 'Peça';
  @override
  String get calcSectionWeight => 'Peso da peça';
  @override
  String get calcSectionFilament => 'Filamento';
  @override
  String get calcSectionTime => 'Tempo de impressão';
  @override
  String get calcSectionDiscount => 'Desconto';
  @override
  String get calcLabelOptional => 'Rótulo (opcional)';
  @override
  String get calcLabelOptionalHelper =>
      'Ex.: suporte de parede, engrenagem de PETG';
  @override
  String get calcLabelWeight => 'Peso da peça';
  @override
  String get calcLabelWeightHelper => 'Gramas do modelo';
  @override
  String get calcLabelHours => 'Horas';
  @override
  String get calcLabelHoursHelper => '0-24';
  @override
  String get calcLabelMinutes => 'Minutos';
  @override
  String get calcLabelMinutesHelper => '0-59';
  @override
  String get calcLabelDiscount => 'Desconto';
  @override
  String get calcLabelDiscountHelper =>
      'Percentual de desconto sobre o total final';
  @override
  String get calcBtnSave => 'Salvar orçamento';
  @override
  String get calcBtnReset => 'Redefinir valores';
  @override
  String get calcToggleShowDetail => 'Mostrar detalhes';
  @override
  String get calcToggleHideDetail => 'Ocultar detalhes';
  @override
  String get calcTotalWithDiscount => 'Total com desconto';
  @override
  String get calcTotalFinal => 'Total';
  @override
  String get calcDetailMaterial => 'Custo do material';
  @override
  String get calcDetailEnergy => 'Custo de energia';
  @override
  String get calcDetailLabor => 'Mão de obra';
  @override
  String get calcDetailPostProcess => 'Pós-processamento';
  @override
  String get calcDetailBase => 'Custo base';
  @override
  String get calcDetailFailure => 'Taxa de falha';
  @override
  String get calcDetailMarkup => 'Margem de desperdício';
  @override
  String get calcDetailProfit => 'Lucro';
  @override
  String get calcDetailMinimumCharge => 'Cobrança mínima';
  @override
  String get calcDetailTotal => 'Total';
  @override
  String get calcEmptyHint =>
      'Preencha peso, filamento e tempo para ver o preço';
  @override
  String get calcSectionMaterials => 'Materiais';
  @override
  String get calcSectionPrinter => 'Impressora';
  @override
  String get calcNoPrinter => 'Nenhuma impressora cadastrada';
  @override
  String get calcPrinterEmptyCta => 'Cadastrar impressora';
  @override
  String get calcPrinterEmptyHint =>
      'Calcule sem custo de energia. Cadastre uma para adicioná-lo.';
  @override
  String get calcNoMaterials => 'Nenhum material.';

  @override
  String get calcKeyWeightHint =>
      'Essencial: necessário para calcular o orçamento';
  @override
  String get calcKeyHoursHint =>
      'Essencial: define os custos de mão de obra e energia';
  @override
  String get calcKeyMinutesHint =>
      'Essencial: informa o tempo real de impressão';

  @override
  String calcMaterialTitle(int index) => 'Material $index';
  @override
  String calcMaterialRemove(int index) => 'Remover material $index';
  @override
  String get calcMaterialCatalog => 'Catálogo';
  @override
  String calcMaterialUse(String filamentName) => 'Usar $filamentName';
  @override
  String get calcFieldLabel => 'Rótulo';
  @override
  String get calcFieldLabelHelper => 'Opcional (ex.: PLA base)';
  @override
  String get calcFieldFilament => 'Filamento';
  @override
  String get calcFieldWeight => 'Peso';
  @override
  String get calcFieldSpoolPrice => 'Preço da bobina';
  @override
  String get calcFieldSpoolGrams => 'Gramas / bobina';

  @override
  String get calcFieldLabor => 'Mão de obra';
  @override
  String get calcFieldLaborHelper => 'Taxa por hora';
  @override
  String get calcFieldPostProcess => 'Pós-processamento';
  @override
  String get calcFieldPostProcessHelper => '% do custo do material';
  @override
  String get calcFieldFailure => 'Taxa de falha';
  @override
  String get calcFieldFailureHelper => '% do custo base';
  @override
  String get calcFieldWaste => 'Desperdício';
  @override
  String get calcFieldWasteHelper => '% de margem de desperdício';

  @override
  String get costHelpTitle => 'Como calibrar seus custos';

  @override
  String get costHelpEnergyTitle => 'Custo de energia';

  @override
  String get costHelpEnergyBody =>
      'Energia usada na impressão: horas de impressão × potência (kW) × '
      'tarifa (\$/kWh). Ex.: 6 h × 0,15 kW × 1,2 \$/kWh ≈ \$1,08. Só entra se '
      'a impressora tiver potência cadastrada.';

  @override
  String get costHelpLaborTitle => 'Mão de obra';

  @override
  String get costHelpLaborBody =>
      'Seu tempo: horas de trabalho × tarifa horária (\$/h). Inclui preparar '
      'a impressora, acompanhar a peça e o acabamento final.';

  @override
  String get costHelpPostTitle => 'Pós-processamento';

  @override
  String get costHelpPostBody =>
      'Percentual extra sobre o custo de materiais para lixamento, pintura, '
      'cola ou outros acabamentos.';

  @override
  String get costHelpFailureTitle => 'Taxa de falha';

  @override
  String get costHelpFailureBody =>
      'Percentual do custo base reservado para peças com falha. Se 1 em cada '
      '10 falha, esses 10% se distribuem entre as 9 que você vende.';

  @override
  String get costHelpWasteTitle => 'Desperdício e desgaste';

  @override
  String get costHelpWasteBody =>
      'Percentual extra sobre materiais: suportes, purga do bico, filamento '
      'de teste e desgaste da impressora.';

  @override
  String get costHelpMinimumChargeTitle => 'Cobrança mínima';

  @override
  String get costHelpMinimumChargeBody =>
      'Piso do preço final. Se o total calculado ficar abaixo, cobra-se esse '
      'mínimo. Ideal para peças pequenas que ainda exigem preparar a '
      'impressora.';

  @override
  String get costHelpMarginTitle => 'Lucro (margem)';

  @override
  String get costHelpMarginBody =>
      'Percentual somado ao custo total para o seu lucro: total × (1 + '
      'margem/100). Ajustado em Parâmetros globais.';

  @override
  String get calcCloseAction => 'Fechar e voltar ao menu';

  @override
  String get calcModeExpress => 'Express';
  @override
  String get calcModeAdvanced => 'Avançado';
  @override
  String calcSemanticMode(String mode) => 'Modo de cálculo: $mode';

  @override
  String get calcActionReset => 'Redefinir';

  @override
  String get calcDialogClient => 'Cliente';
  @override
  String get calcDialogClientHelper => 'Opcional';
  @override
  String get calcDialogRecentClients => 'Clientes recentes';
  @override
  String get calcDialogNotes => 'Notas (opcional)';
  @override
  String get calcDialogNotesHelper =>
      'Especifica\u00e7\u00f5es, prazos, entregas\u2026';
  @override
  String get calcDialogConditions =>
      'Condi\u00e7\u00f5es comerciais (opcional)';
  @override
  String get calcDialogConditionsHelper =>
      'Validade, pagamento, garantia\u2026';

  @override
  String get calcTemplatesTitle => 'Modelos';
  @override
  String get calcTemplateSaveAsAction => 'Salvar como modelo';
  @override
  String get calcTemplateSaveSuccess => 'Modelo salvo';
  @override
  String get calcTemplateSaveError =>
      'N\u00e3o foi poss\u00edvel salvar o modelo';
  @override
  String get calcTemplateApplySuccess => 'Modelo aplicado ao formul\u00e1rio';
  @override
  String get calcTemplateApplyError =>
      'N\u00e3o foi poss\u00edvel carregar o modelo';
  @override
  String get calcTemplateEmpty =>
      'Voc\u00ea ainda n\u00e3o tem modelos.\nSalve um trabalho frequente como modelo para reutiliz\u00e1-lo.';
  @override
  String get calcTemplateUntitled => 'Sem nome';
  @override
  String get calcTemplateDeleteError =>
      'N\u00e3o foi poss\u00edvel excluir o modelo';

  @override
  String get calcEmptyHintPrefix => 'Preencha';
  @override
  String get calcEmptyHintSuffix => 'para ver o orçamento';
  @override
  String get calcFieldWeightShort => 'peso da peça';
  @override
  String get calcFieldPriceShort => 'preço do filamento';
  @override
  String get calcFieldTimeShort => 'tempo de impressão';
  @override
  String get calcFieldMaterialShort => 'pelo menos um material';

  @override
  String get calcMetaSeparator => ' · ';

  @override
  String get calcResultBarTapHint => 'Ver orçamento';
  @override
  String get calcResultBarEmptyHint => 'Incompleto';
  @override
  String get calcSheetTitle => 'Orçamento';
  @override
  String get calcBtnShare => 'Compartilhar imagem';
  @override
  String get calcBtnShareTooltip => 'Gera uma imagem pronta para compartilhar';
  @override
  String get calcShareError => 'Não foi possível gerar a imagem';
  @override
  String get calcShareSubject => 'Orçamento 3D';
  @override
  String get calcShareText => 'Orçamento gerado no 3dCalc';
  @override
  String get calcSheetActionsLabel => 'Ações';

  // === Imagem do orçamento (foto da peça) ===
  @override
  String get quoteImageAdd => 'Adicionar imagem';
  @override
  String get quoteImageGallery => 'Galeria';
  @override
  String get quoteImageCamera => 'Câmera';
  @override
  String get quoteImageChange => 'Alterar';
  @override
  String get quoteImageRemove => 'Remover';
  @override
  String get quoteImageTooLarge => 'A imagem excede 5 MB e não foi anexada.';
  @override
  String get quoteImageInvalidFormat =>
      'Formato de imagem inválido (somente JPEG, PNG ou WebP).';
  @override
  String get quoteImageError => 'Não foi possível obter a imagem';

  @override
  String get filamentTitle => 'Filamentos';
  @override
  String get filamentNew => 'Novo filamento';
  @override
  String get filamentEdit => 'Editar filamento';
  @override
  String get filamentName => 'Nome';
  @override
  String get filamentNameHelper => 'Ex.: PLA preto';
  @override
  String get filamentBrand => 'Marca';
  @override
  String get filamentBrandHelper => 'Opcional';
  @override
  String get brandSelectorOther => 'Outro...';
  @override
  String get brandSelectorHint =>
      'Escolha uma marca ou selecione Outro para digitá-la';
  @override
  String get brandSelectorManualHelper => 'Digite o nome da marca';
  @override
  String filamentPrice(String symbol) => 'Preço do filamento ($symbol)';
  @override
  String get filamentPriceHelper => 'Custo da bobina completa';
  @override
  String get filamentGrams => 'Gramas por bobina';
  @override
  String get filamentGramsHelper => 'Normalmente 1000';
  @override
  String get filamentDefaultToggle => 'Definir como padrão';
  @override
  String get filamentDefaultSubtitle =>
      'Será usado em novos orçamentos. Apenas um filamento pode ser padrão.';
  @override
  String get filamentNewTooltip => 'Novo filamento';
  @override
  String get filamentDeleteTitle => 'Excluir filamento';
  @override
  String get filamentErrorSave => 'Erro ao salvar';
  @override
  String get filamentMustBePositive => 'Deve ser > 0';
  @override
  String get filamentMustBeInteger => 'Deve ser um número inteiro';
  @override
  String get filamentMax100 => 'Máximo de 100 caracteres';

  @override
  String get printerTitle => 'Impressoras';
  @override
  String get printerNew => 'Nova impressora';
  @override
  String get printerEdit => 'Editar impressora';
  @override
  String get printerModel => 'Modelo';
  @override
  String get printerModelHelper => 'Ex.: Ender 3 V2';
  @override
  String get printerBrandHelper => 'Ex.: Creality, Anycubic';
  @override
  String get printerWatts => 'Consumo médio (W)';
  @override
  String get printerWattsHelper => 'Normalmente 100-300 W';
  @override
  String get printerDefaultSubtitle =>
      'Será usada em novos orçamentos. Apenas uma impressora pode ser padrão.';
  @override
  String get printerNewTooltip => 'Nova impressora';
  @override
  String get printerDeleteTitle => 'Excluir impressora';
  @override
  String get printerMustBeNonNegative => 'Deve ser >= 0';

  @override
  String get calcNotifFilament => 'Filamento';
  @override
  String get calcNotifMaterial => 'Material';

  @override
  String get calcDetailTitle => 'Detalhes do orçamento';
  @override
  String get calcDetailDelete => 'Excluir';
  @override
  String get calcDetailDeleteTitle => 'Excluir orçamento';
  @override
  String get calcDetailDeleteConfirm => 'Excluir permanentemente?';
  @override
  String get calcDetailNoName => 'Sem nome';
  @override
  String get calcDetailSold => 'Vendidos';
  @override
  String get calcDetailReuse => 'Reutilizar';
  @override
  String get calcDetailMarkSold => 'Marcar como vendido';
  @override
  String get calcDetailMarkPending => 'Marcar como pendente';

  @override
  String get calcDuplicateAction => 'Duplicar';
  @override
  String get calcDuplicateSuffix => ' (cópia)';
  @override
  String get calcDuplicateSuccess => 'Cotação duplicada';
  @override
  String get calcDuplicateError => 'Não foi possível duplicar a cotação';

  @override
  String get historyTitle => 'Orçamentos';
  @override
  String get historyErrorLoad => 'Erro ao carregar orçamentos';
  @override
  String get historyEmpty => 'Nenhum orçamento salvo';

  @override
  String get csvExportLockedBody => 'A exportação CSV é um recurso Pro';
  @override
  String get csvGoProAction => 'Desbloquear PRO';

  @override
  String get localeLabel => 'Idioma';
  @override
  String get localeEs => 'Espanhol';
  @override
  String get localeEn => 'Inglês';
  @override
  String get localePtBr => 'Português (Brasil)';
  @override
  String get localeDe => 'Alemão';
  @override
  String get localeFr => 'Francês';
  @override
  String get onboardingTitle1 => 'Boas-vindas ao 3dCalc';
  @override
  String get onboardingDesc1 =>
      'Calcule preços de impressão 3D instantaneamente.\nMateriais, eletricidade, mão de obra e muito mais.';
  @override
  String get onboardingTitle2 => 'Dois modos de cálculo';
  @override
  String get onboardingDesc2 =>
      'Express: cálculo rápido com um material.\nAvançado: vários materiais, desconto e muito mais.';
  @override
  String get onboardingTitle3 => 'Catálogo integrado';
  @override
  String get onboardingDesc3 =>
      'Salve seus filamentos e impressoras favoritos.\nSelecione-os instantaneamente no catálogo.';
  @override
  String get onboardingTitle4 => 'Painel e muito mais';
  @override
  String get onboardingDesc4 =>
      'Acompanhe orçamentos, tendências mensais,\nexportação em PDF e pesquisa no histórico.';
  @override
  String get onboardingNext => 'Avançar';
  @override
  String get onboardingSkip => 'Pular';
  @override
  String get onboardingStart => 'Começar';
  @override
  String get onboardingStartQuote => 'Criar minha primeira cotação';
  @override
  String get onboardingGoHome => 'Ir ao menu';
  @override
  String get configTitle => 'Configuração inicial';
  @override
  String get configLanguage => 'Idioma';
  @override
  String get configCurrency => 'Moeda';
  @override
  String get configContinue => 'Continuar';

  @override
  String get configStep1Title => 'Idioma e moeda';
  @override
  String get configStep2Title => 'Impressora e filamento';
  @override
  String get configStep3Title => 'Lucro e energia';
  @override
  String get configBack => 'Voltar';
  @override
  String get configFinish => 'Concluir';
  @override
  String get configStepSubtitle1 => 'Vamos começar pelo básico.';
  @override
  String get configStepSubtitle2 =>
      'Comece pelo que você usa para imprimir. A impressora é necessária para '
      'calcular o custo de energia.';
  @override
  String get configStepSubtitle3 =>
      'Esses valores se aplicam a todos os orçamentos. Você pode alterá-los depois.';
  @override
  String configStepCounter(int step, int total) => 'Etapa $step de $total';
  @override
  String get configLanguageHelper =>
      'Escolha o idioma do aplicativo. Você pode alterá-lo depois.';
  @override
  String get configCurrencyHelper =>
      'Moeda usada para preços e orçamentos. Não converte valores.';
  @override
  String get configPrinterSectionHelper =>
      'Precisamos dela para calcular o custo de energia de cada impressão.';
  @override
  String get configFilamentSectionHelper =>
      'Se você tiver uma bobina, adicione-a agora. Caso contrário, adicione-a depois em '
      'Configurações → Catálogos.';
  @override
  String get configProfitHelper =>
      'Margem sobre o custo base. 200% dobra o custo. Típico: 100%–300%.';
  @override
  String get configKwhHelper =>
      'Tarifa da sua conta de eletricidade. Típico: 0,5–1,5 BOB/kWh.';
  @override
  String get settingsDefaultTypical => 'Típico';
  @override
  String get configFilamentSkipStatus => 'Nenhum filamento, adicionar depois';
  @override
  String get configFilamentAddAction => 'Adicionar filamento';
  @override
  String get configStartButton => 'Começar a criar orçamentos';
  @override
  String get configSummaryTitle => 'Resumo';
  @override
  String get configSummaryImprint => 'Seu próximo orçamento:';
  @override
  String get configPrinterRequired => 'Impressora (obrigatória)';
  @override
  String get configFilamentOptional => 'Filamento (opcional)';
  @override
  String get configAddFilament => 'Adicionar filamento';
  @override
  String get configFilamentLater => 'Vou adicionar depois';
  @override
  String get configFilamentSkipHint =>
      'Você pode adicionar filamentos a qualquer momento em Configurações → Catálogos.';
  @override
  String get configPrinterSaved => 'Impressora cadastrada';
  @override
  String get configFilamentSaved => 'Filamento adicionado';

  // === Feature gates (T14) ===
  @override
  String get calculatorAdvancedLockedBody =>
      'Desbloqueie o Pro para cálculos com vários materiais';
  @override
  String get calculatorGoProAction => 'Desbloquear PRO';

  // === Histórico cap gate (T15) ===
  @override
  String get historyCapReachedBody =>
      'Você atingiu o limite do histórico gratuito. Faça upgrade para o Pro e tenha histórico ilimitado.';

  // === Pro badge / locked visuals (UX) ===
  @override
  String get proBadgeLabel => 'PRO';
  @override
  String get proLockedTooltip => 'Recurso Pro';
  @override
  String get csvExportTooltipLocked => 'Exportar CSV (Pro)';
  @override
  String historyUsageCounter(int used, int cap) =>
      used == 1 ? '1/$cap orçamento' : '$used/$cap orçamentos';

  // === Paywall (T10) ===
  @override
  String get paywallTitle => 'Desbloqueie o 3dCalc Pro';
  @override
  String get paywallSubtitle =>
      'Aproveite ao máximo sua calculadora de custos de impressão 3D';
  @override
  String get paywallPrice => '\$4.99';
  @override
  List<String> get paywallFeatures => const [
    'Remover a marca dos orçamentos em PDF',
    'Detalhamento de custos para vários materiais',
    'Histórico ilimitado',
    'Exportar para CSV',
    'Painel avançado de análises',
  ];
  @override
  String paywallUnlockButton(String price) => 'Desbloquear por $price';
  @override
  String get paywallRestoreButton => 'Restaurar compra';
  @override
  String get paywallErrorGeneric =>
      'Não foi possível concluir a compra. Tente novamente.';
  @override
  String get paywallUnavailable =>
      'As compras não estão disponíveis nesta plataforma.';
  @override
  String get paywallAlreadyPro => 'Você já tem o Pro. Obrigado!';
  @override
  String get paywallClose => 'Fechar';

  @override
  String get paywallPrivacyPolicy => 'Política de Privacidade';

  @override
  String get paywallTermsOfService => 'Termos de Serviço';

  @override
  String get settingsLegal => 'Informações legais';

  @override
  String get legalPrivacyDocument => '''Última atualização: 11 de agosto de 2026

1. Escopo
 Esta Política de Privacidade explica como o 3dCalc trata as informações que você fornece ao usar o aplicativo. O responsável é Juan Marcelo Albis Ortiz, com sede na Bolívia. Uma conta não é necessária para os recursos principais.

2. Informações armazenadas
 As informações inseridas, como configurações, catálogos e cálculos, são armazenadas no dispositivo. Os backups ficam no local escolhido.

3. Compras
As compras são processadas pelo Google Play. O 3dCalc não recebe nem armazena os dados completos do cartão. A RevenueCat gerencia compras, restaurações e status de acesso.

 4. Compartilhamento
Não vendemos seus dados nem compartilhamos o conteúdo dos cálculos.

5. Exclusão e controle
 Você pode excluir os dados no aplicativo ou desinstalá-lo. Backups exportados devem ser excluídos manualmente.

6. Alterações e contato
 Podemos atualizar esta política quando o aplicativo ou seus requisitos legais mudarem. Para dúvidas, contate Juan Marcelo Albis Ortiz em marcheloalbis@gmail.com.

 Este documento é informativo e deve ser revisado com assessoria jurídica antes da publicação.''';

  @override
  String get legalTermsDocument => '''Última atualização: 11 de agosto de 2026

1. Aceitação
 Ao instalar ou usar o 3dCalc, você concorda com estes Termos de Serviço. O provedor é Juan Marcelo Albis Ortiz, Bolívia. Se não concordar, não use o aplicativo.

2. Uso permitido
 Você pode usar o 3dCalc para cálculos e informações de trabalho pessoais ou comerciais, conforme a lei aplicável.

3. Resultados e responsabilidade
 Os resultados são estimativas. Verifique entradas, custos, unidades e resultados antes de tomar decisões.

4. Compras e restauração
 A compra Pro é única, se assim configurada no Google Play, e não é uma assinatura automática.

5. Propriedade intelectual
O aplicativo, seu design e seus recursos pertencem aos respectivos proprietários.

6. Disponibilidade e alterações
Podemos atualizar, suspender ou remover recursos. Para dúvidas, contate marcheloalbis@gmail.com.

''';

  // === i18n consistency (hardcoded → l10n) ===
  @override
  String get commonError => 'Erro';
  @override
  String get commonNoResults => 'Nenhum resultado';
  @override
  String get commonDefault => 'Padrão';
  @override
  String get commonUndo => 'Desfazer';
  @override
  String get commonSaveImage => 'Salvar imagem';
  @override
  String get commonExportPdf => 'Exportar PDF';
  @override
  String get commonSharePdf => 'Compartilhar PDF';
  @override
  String get commonPrint => 'Imprimir';
  @override
  String get commonImageDownloaded => 'Imagem baixada';
  @override
  String get commonImageSavedGallery => 'Imagem salva na galeria';
  @override
  String get commonPdfExportError => 'Erro ao exportar PDF';
  @override
  String get commonPrintError => 'Erro ao imprimir';
  @override
  String get commonDefaultSuffix => ' (padrão)';
  @override
  String get historyExportCsv => 'Exportar CSV';
  @override
  String get historyEmptyCta => 'Crie um orçamento e toque em Salvar.';
  @override
  String get calcSectionOthers => 'Outros';
  @override
  String get settingsProfitBaseRange => 'Faixa: 0-1000';
  @override
  String get settingsKwhRateRange => 'Faixa: 0.10-5.00';
  @override
  String get shareErrorNotRendered =>
      'O resumo ainda não foi renderizado. Tente novamente em instantes.';
  @override
  String get shareErrorNoRegion =>
      'A região capturável do resumo não foi encontrada.';
  @override
  String get shareErrorEncode => 'Não foi possível codificar a imagem PNG.';
  @override
  String get shareErrorSaveGallery =>
      'Não foi possível salvar a imagem na galeria.';
  @override
  String shareErrorSaveWithMessage(String msg) =>
      'Não foi possível salvar a imagem: $msg';

  @override
  String get homeHeroTagline =>
      'Orçamentos 3D · Rápido · Preciso · Sempre com você';

  @override
  String get calcFormIncompleteWarning =>
      'Preencha o formulário antes de salvar.';
  @override
  String get calcSaveFailed => 'Não foi possível salvar.';
  @override
  String calcSavedWithId(int id) => 'Orçamento nº $id salvo.';
  @override
  String get calcSavedViewAction => 'Ver';
  @override
  String get calcAddMaterial => 'Adicionar material';
  @override
  String get calcPrinterPrefix => 'Impressora: ';
  @override
  String get calcChangePrinter => 'Alterar impressora';
  @override
  String get calcSearchPrinter => 'Pesquisar impressora...';
  @override
  String get calcSelectFilament => 'Selecionar filamento';
  @override
  String get calcSearchFilament => 'Pesquisar filamento...';

  @override
  String get detailBreakdown => 'Detalhamento';
  @override
  String detailDiscountPct(int pct) => 'Desconto ($pct%)';
  @override
  String get detailPreview => 'Visualização';

  @override
  String get quoteNoDiscount => 'Sem desconto';
  @override
  String quoteDiscountPct(int pct) => 'Desconto de $pct%';
  @override
  String get quoteDetail => 'Detalhes';
  @override
  String get quoteGeneratedWith => 'Gerado com 3dCalc';

  @override
  String get pdfFileName => 'quote_3dcalc.pdf';
  @override
  String get pdfShareSubject => 'Orçamento do 3dCalc';
  @override
  String get pdfDatePrefix => 'Data: ';
  @override
  String get pdfQuoteNumber => 'N\u00ba ';
  @override
  String get pdfValidUntilPrefix => 'V\u00e1lido at\u00e9: ';
  @override
  String get pdfClientPrefix => 'Cliente: ';
  @override
  String get pdfNotesTitle => 'Notas';
  @override
  String get pdfConditionsTitle => 'Condi\u00e7\u00f5es';
  @override
  String get pdfMaterialCosts => 'Custo dos materiais';
  @override
  String get pdfElectricity => 'Eletricidade';
  @override
  String get pdfTotalUpper => 'TOTAL';
  @override
  String get pdfHoursPrefix => 'Horas: ';
  @override
  String pdfDiscountPct(int pct) => 'Desconto: $pct%';

  @override
  String get dashboardEmptySubtitle => 'Crie seu primeiro orçamento do zero.';
  @override
  String get dashboardMonthlyTrend => 'Tendência mensal';
  @override
  String get dashboardTopMaterials => 'Materiais mais usados';

  @override
  String get historySearchHint => 'Pesquisar por nome ou cliente...';
  @override
  String get historyFilterAll => 'Todas';
  @override
  String get historyFilterSold => 'Vendidos';
  @override
  String get historyFilterPending => 'Pendentes';
  @override
  String get historyNoQuotesToExport => 'Nenhum orçamento para exportar';

  @override
  String get chartNoMonthlyData => 'Nenhum dado mensal';
  @override
  List<String> get chartShortMonths => const [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  String get filamentSearchHint => 'Pesquisar filamentos...';
  @override
  String filamentDeleted(String name) => '"$name" excluído';
  @override
  String get printerSearchHint => 'Pesquisar impressoras...';
  @override
  String printerDeleted(String name) => '"$name" excluído';
  @override
  String get printerErrorSave => 'Erro ao salvar';

  @override
  String get settingsErrorLoad => 'Erro ao carregar as configurações';
  @override
  String get settingsCurrencySearchHint =>
      'Pesquisar moeda por código ou nome...';
  @override
  String settingsCurrencyNoResults(String query) =>
      'Nenhum resultado para "$query"';
  @override
  String get settingsCurrencySymbolPrefix => 'Símbolo: ';

  @override
  String get routeNotFound => 'Página não encontrada';
  @override
  String get routeBackHome => 'Voltar para Início';

  @override
  String get themeModeSystem => 'Sistema';
  @override
  String get themeModeLight => 'Claro';
  @override
  String get themeModeDark => 'Escuro';

  @override
  String get splashLogo => 'Logo do 3dCalc';
  @override
  String onboardingPageCounter(int page, int total) => 'Página $page de $total';
  @override
  String commonNoResultsFor(String query) => 'Nenhum resultado para "$query"';
  @override
  String get historyEmptySearchHint => 'Tente outro termo.';

  @override
  String get filamentErrorLoad => 'Erro ao carregar os filamentos';
  @override
  String filamentNoResults(String query) =>
      'Nenhum filamento corresponde a "$query"';
  @override
  String get filamentEmptyList =>
      'Nenhum filamento. Toque em + para criar o primeiro.';
  @override
  String filamentDeleteConfirm(String name) => 'Excluir "$name"?';

  @override
  String get printerErrorLoad => 'Erro ao carregar as impressoras';
  @override
  String printerNoResults(String query) =>
      'Nenhuma impressora corresponde a "$query"';
  @override
  String get printerEmptyList =>
      'Nenhuma impressora. Toque em + para cadastrar a primeira.';
  @override
  String printerDeleteConfirm(String name) => 'Excluir "$name"?';
}
