// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/calculation_draft.dart';
import '../../../../core/storage/draft_storage_providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/filament_selector_dialog.dart';
import '../widgets/printer_selector_dialog.dart';
import '../widgets/result_sheet.dart';

/// Pantalla principal del calculator con UX mejorada.
///
/// **Secciones en Cards** (Express y Advanced):
/// 1. Materiales (tile "Material 1" en Express, lista en Advanced)
/// 2. Impresora activa
/// 3. OTROS (mano obra, post-procesado, falla, minimo, markup) — collapsable
/// 4. Tiempo de impresion (horas + minutos)
/// 5. Descuento
/// 6. Output (resumen con animacion "calculando...")
class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key, this.prefillCalc});

  /// Cotizacion guardada para precargar ("Reusar"). Si es null, la pagina
  /// restaura el draft de la sesion anterior (comportamiento normal).
  final Calculation? prefillCalc;

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _gramsCtrl;
  late final TextEditingController _labelCtrl; // material label (Express) / piece label (Advanced listener)
  late final TextEditingController _pieceLabelCtrl; // piece name (Express only)

  // OTROS controllers (F1: mano de obra, post-procesado, falla, minimo, markup).
  late final TextEditingController _extraLaborRateCtrl;
  late final TextEditingController _extraPostProcessRateCtrl;
  late final TextEditingController _extraFailureRateCtrl;
  late final TextEditingController _extraMarkupOnMaterialsCtrl;

  // Advanced controllers.
  final List<_MaterialCtrls> _materialCtrls = [];
  final _advancedListKey = GlobalKey<AnimatedListState>();

  /// Toggle local para la seccion OTROS (puramente visual, no persiste).
  bool _showOtros = false;

  /// Si `true`, los campos requeridos muestran error visual (border rojo).
  /// Se activa al tocar la barra inferior con form invalido.
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(calculatorNotifierProvider);
    _weightCtrl = TextEditingController(text: initial.weight);
    _hoursCtrl = TextEditingController(text: initial.printHours);
    _minutesCtrl = TextEditingController(text: initial.printMinutes);
    _discountCtrl = TextEditingController(text: initial.discountPct);
    _priceCtrl = TextEditingController(text: initial.filamentPrice);
    _gramsCtrl = TextEditingController(text: initial.filamentGrams);
    _labelCtrl = TextEditingController(text: initial.filamentLabel);
    _pieceLabelCtrl = TextEditingController(text: initial.label);
    _extraLaborRateCtrl =
        TextEditingController(text: initial.extraLaborRate);
    _extraPostProcessRateCtrl =
        TextEditingController(text: initial.extraPostProcessRate);
    _extraFailureRateCtrl =
        TextEditingController(text: initial.extraFailureRate);
    _extraMarkupOnMaterialsCtrl =
        TextEditingController(text: initial.extraMarkupOnMaterials);

    for (final c in [
      _weightCtrl,
      _hoursCtrl,
      _minutesCtrl,
      _discountCtrl,
      _priceCtrl,
      _gramsCtrl,
      _extraLaborRateCtrl,
      _extraPostProcessRateCtrl,
      _extraFailureRateCtrl,
      _extraMarkupOnMaterialsCtrl,
    ]) {
      c.addListener(_onAnyFieldChange);
    }
    _labelCtrl.addListener(() {
      ref.read(calculatorNotifierProvider.notifier)
          .setFilamentLabel(_labelCtrl.text);
    });
    _pieceLabelCtrl.addListener(() {
      ref.read(calculatorNotifierProvider.notifier)
          .setLabel(_pieceLabelCtrl.text);
    });

    if (initial.mode == CalculatorMode.advanced) {
      for (final m in initial.materials) {
        _materialCtrls.add(_MaterialCtrls.fromRow(m));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Prefill ("Reusar"): cargar la cotizacion guardada y sincronizar los
      // controllers. NO tocar reset/draft/defaults — el state precargado es
      // la fuente de verdad. Un solo post-frame (esta pagina) evita la race
      // que antes pisaba el prefill con reset()/draft.
      if (widget.prefillCalc != null) {
        final notifier = ref.read(calculatorNotifierProvider.notifier);
        await notifier.loadFromCalculation(widget.prefillCalc!);
        if (!mounted) return;
        _syncControllersFromState(ref.read(calculatorNotifierProvider));
        _rebuildAdvancedRows();
        return;
      }
      // Cargar el draft ANTES de resetear para no dejar la UI a medio
      // restaurar durante el gap async (evita el desync state <-> controllers
      // que hacia perder el auto-calc al tipear en el tile de filamento).
      final storage = ref.read(draftStorageProvider);
      final draft = await storage.load();
      if (!mounted) return;
      final notifier = ref.read(calculatorNotifierProvider.notifier);
      // Resetear state al entrar (no arrastrar datos de sesion anterior).
      notifier.reset();
      // Restaurar la impresora que el usuario eligio en una sesion anterior
      // (persistida en prefs). Si el id ya no existe, el fallback del
      // provider resuelve a la default o a la primera registrada.
      final savedPrinterId = ref
          .read(sharedPreferencesProvider)
          .getInt(kActivePrinterIdPrefsKey);
      if (savedPrinterId != null && mounted) {
        ref.read(activePrinterIdProvider.notifier).state = savedPrinterId;
      }
      if (draft != null) {
        // Restaurar el draft en notifier. El STATE es la fuente unica de
        // verdad; desde ahi se sincronizan los controllers (sync infalible).
        notifier.restoreFromDraft(draft);
        if (!mounted) return;
        _syncControllersFromState(ref.read(calculatorNotifierProvider));
        _rebuildAdvancedRows();
        return;
      }
      // Sin draft: resetear todos los controllers a vacio.
      _weightCtrl.text = '';
      _hoursCtrl.text = '';
      _minutesCtrl.text = '';
      _discountCtrl.text = '0';
      _priceCtrl.text = '';
      _gramsCtrl.text = '';
      _labelCtrl.text = '';
      _pieceLabelCtrl.text = '';
      _extraLaborRateCtrl.text = '';
      _extraPostProcessRateCtrl.text = '';
      _extraFailureRateCtrl.text = '';
      _extraMarkupOnMaterialsCtrl.text = '';
      // Cargar defaults del filamento por defecto para precio/gramos.
      final defaultFilament = ref.read(defaultFilamentProvider);
      if (defaultFilament != null) {
        ref
            .read(calculatorNotifierProvider.notifier)
            .loadFilamentDefaults(
              pricePerBobbin: defaultFilament.pricePerBobbin.toStringAsFixed(2),
              gramsPerBobbin: defaultFilament.gramsPerBobbin.toStringAsFixed(0),
            );
        if (!mounted) return;
        final updated = ref.read(calculatorNotifierProvider);
        _priceCtrl.text = updated.filamentPrice;
        _gramsCtrl.text = updated.filamentGrams;
      }
    });
  }

  Timer? _saveTimer;

  /// Sincroniza los 11 controllers desde el state restaurado.
  /// Fuente unica de verdad: el CalculatorState del notifier (evita
  /// desync si el draft y el state divergen tras el restore).
  void _syncControllersFromState(CalculatorState s) {
    _weightCtrl.text = s.weight;
    _hoursCtrl.text = s.printHours;
    _minutesCtrl.text = s.printMinutes;
    _discountCtrl.text = s.discountPct;
    _priceCtrl.text = s.filamentPrice;
    _gramsCtrl.text = s.filamentGrams;
    _labelCtrl.text = s.filamentLabel;
    _pieceLabelCtrl.text = s.label;
    _extraLaborRateCtrl.text = s.extraLaborRate;
    _extraPostProcessRateCtrl.text = s.extraPostProcessRate;
    _extraFailureRateCtrl.text = s.extraFailureRate;
    _extraMarkupOnMaterialsCtrl.text = s.extraMarkupOnMaterials;
  }

  /// Reconstruye los rows advanced del AnimatedList desde el state
  /// restaurado (el listado vive en [_materialCtrls], no en state.materials).
  /// Se llena ANTES del primer build del listado, asi initialItemCount
  /// toma el largo correcto y no hace falta insertItem (evita duplicados).
  void _rebuildAdvancedRows() {
    final materials = ref.read(calculatorNotifierProvider).materials;
    if (materials.isEmpty) return;
    for (final c in _materialCtrls) {
      c.dispose();
    }
    _materialCtrls.clear();
    for (final m in materials) {
      _materialCtrls.add(_MaterialCtrls.fromRow(m));
    }
  }

  void _onAnyFieldChange() {
    // Resetear errores visuales cuando el usuario empieza a escribir.
    if (_showValidationErrors) {
      _showValidationErrors = false;
      if (mounted) setState(() {});
    }
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    final draft = CalculationDraft(
      weight: _weightCtrl.text,
      printHours: _hoursCtrl.text,
      printMinutes: _minutesCtrl.text,
      discountPct: _discountCtrl.text,
      filamentPrice: _priceCtrl.text,
      filamentGrams: _gramsCtrl.text,
      label: _pieceLabelCtrl.text,
      filamentLabel: _labelCtrl.text,
      extraLaborRate: _extraLaborRateCtrl.text,
      extraPostProcessRate: _extraPostProcessRateCtrl.text,
      extraFailureRate: _extraFailureRateCtrl.text,
      extraMarkupOnMaterials: _extraMarkupOnMaterialsCtrl.text,
    );
    await ref.read(draftStorageProvider).save(draft);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _weightCtrl.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    _discountCtrl.dispose();
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    _labelCtrl.dispose();
    _pieceLabelCtrl.dispose();
    _extraLaborRateCtrl.dispose();
    _extraPostProcessRateCtrl.dispose();
    _extraFailureRateCtrl.dispose();
    _extraMarkupOnMaterialsCtrl.dispose();
    for (final c in _materialCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchMode(CalculatorMode mode) {
    if (mode == CalculatorMode.advanced) {
      // El gate lee el estado real del entitlement (no `isProProvider` solo):
      // durante el boot async (SP+DB) el notifier esta loading y isPro=false,
      // lo que daria un falso "locked" a un Pro real en cold start. Si sigue
      // loading, swallow (no gatear ni cambiar de modo); solo gateamos cuando
      // el estado esta resuelto.
      final ent = ref.read(entitlementNotifierProvider);
      if (ent.isLoading) return;
      if (!ref.read(isProProvider)) {
        // T14: free user intento cambiar a modo advanced. SnackBar dedicado
        // con CTA "Go Pro" (mismo destino /paywall que el history cap).
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            AppSnackBar.warning(
              EsBO.calculatorAdvancedLockedBody,
              actionLabel: EsBO.calculatorGoProAction,
              onAction: () {
                GoRouter.of(context).push('/paywall');
              },
            ),
          );
        return;
      }
    }
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    if (mode == CalculatorMode.advanced && _materialCtrls.isEmpty) {
      notifier.addMaterial();
      _materialCtrls.add(_MaterialCtrls.empty());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _advancedListKey.currentState?.insertItem(0);
      });
    }
    notifier.setMode(mode);
  }

  void _addMaterial() {
    ref.read(calculatorNotifierProvider.notifier).addMaterial();
    _materialCtrls.add(_MaterialCtrls.empty());
    final newIndex = _materialCtrls.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _advancedListKey.currentState?.insertItem(newIndex);
    });
  }

  void _removeMaterial(int index) {
    ref.read(calculatorNotifierProvider.notifier).removeMaterial(index);
    if (index < 0 || index >= _materialCtrls.length) return;
    final removed = _materialCtrls.removeAt(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _advancedListKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _MaterialRowTile(
            index: index,
            labelCtrl: removed.label,
            weightCtrl: removed.weight,
            priceCtrl: removed.price,
            gramsCtrl: removed.grams,
            deletable: true,
            onChanged: (_) {},
            onRemove: () {},
            pending: true,
          ),
        ),
        duration: const Duration(milliseconds: 200),
      );
    });
    removed.dispose();
  }

  void _resetAll() {
    ref.read(calculatorNotifierProvider.notifier).reset();
    final i = CalculatorState.initial();
    _weightCtrl.text = i.weight;
    _hoursCtrl.text = i.printHours;
    _minutesCtrl.text = i.printMinutes;
    _discountCtrl.text = i.discountPct;
    _priceCtrl.text = i.filamentPrice;
    _gramsCtrl.text = i.filamentGrams;
    _labelCtrl.text = i.filamentLabel;
    _pieceLabelCtrl.text = i.label;
    _extraLaborRateCtrl.text = '';
    _extraPostProcessRateCtrl.text = '';
    _extraFailureRateCtrl.text = '';
    _extraMarkupOnMaterialsCtrl.text = '';
    for (final c in _materialCtrls) {
      c.dispose();
    }
    _materialCtrls.clear();
  }

  Future<void> _showSaveDialog() async {
    final state = ref.read(calculatorNotifierProvider);
    if (!state.isValid || state.output == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.warning(EsBO.calcFormIncompleteWarning),
      );
      return;
    }
    final result = await showDialog<_SaveResult>(
      context: context,
      builder: (_) => const _SaveDialog(),
    );
    if (result == null || !mounted) return;
    try {
      final id = await ref
          .read(calculatorNotifierProvider.notifier)
          .save(clientName: result.clientName);
      if (!mounted) return;
      if (id != null) {
        await ref.read(draftStorageProvider).clear();
        if (!mounted) return;
      }
      if (id == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.calcSaveFailed));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(EsBO.calcSavedWithId(id)),
      );
    } on HistoryCapReachedException catch (_) {
      // T15: free user intento guardar la #11. SnackBar dedicado con CTA
      // "Go Pro" (reusamos calculatorGoProAction — mismo destino /paywall
      // que T14). No se persiste nada; los 10 items existentes intactos.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar.warning(
            EsBO.historyCapReachedBody,
            actionLabel: EsBO.calculatorGoProAction,
            onAction: () {
              GoRouter.of(context).push('/paywall');
            },
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('${EsBO.commonError}: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(ref.watch(localeStringsProvider).calcSheetTitle),
        ),
        actions: [
          Semantics(
            button: true,
            label: EsBO.calcActionReset,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: EsBO.calcActionReset,
              onPressed: _resetAll,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: state.mode == CalculatorMode.express
            ? _buildExpressForm(state, notifier, theme, currency)
            : _buildAdvancedForm(state, notifier, theme, currency),
      ),
      // Sticky bottom bar: SIEMPRE visible (Fix #3). Cumplio doble proposito:
      // - invalid → empty hint dinamico (lista campos faltantes).
      // - valid → total formateado + tap abre modal con resumen + acciones.
      bottomNavigationBar: ResultBottomBar(
        totalText: state.output != null
            ? formatCurrency(state.output!.totalPrice, currency)
            : '—',
        hasDiscount:
            state.output != null && state.output!.discountAmount > Decimal.zero,
        emptyHint: state.isValid
            ? null
            : _buildEmptyHint(state.missingRequiredFields),
        onTap: () {
          if (state.isValid && state.output != null) {
            showResultSheet(
              context: context,
              state: state,
              onSave: _showSaveDialog,
              onReset: _resetAll,
              onToggleDetail: () =>
                  ref.read(calculatorNotifierProvider.notifier).toggleDetail(),
              onDiscountChanged: (value) {
                ref
                    .read(calculatorNotifierProvider.notifier)
                    .setDiscountPct(value);
                // Sync el controller oculto del form para que el draft
                // persista el descuento (el listener agenda el save).
                if (_discountCtrl.text != value) {
                  _discountCtrl.text = value;
                }
              },
            );
          } else {
            setState(() => _showValidationErrors = true);
          }
        },
      ),
    );
  }

  /// Construye el hint dinamico para el empty state del bar.
  /// "Completa X para ver la cotizacion." (1)
  /// "Completa X y Y para ver la cotizacion." (2)
  /// "Completa X, Y y Z para ver la cotizacion." (3+)
  String _buildEmptyHint(List<String> missingKeys) {
    if (missingKeys.isEmpty) return EsBO.calcEmptyHint;
    String resolveFieldKey(String key) {
      switch (key) {
        case 'weight':
          return EsBO.calcFieldWeightShort;
        case 'price':
          return EsBO.calcFieldPriceShort;
        case 'time':
          return EsBO.calcFieldTimeShort;
        case 'material':
          return EsBO.calcFieldMaterialShort;
        default:
          return key;
      }
    }

    final parts = missingKeys.map(resolveFieldKey).toList();
    final joined = parts.length == 1
        ? parts.first
        : parts.length == 2
            ? '${parts[0]} y ${parts[1]}'
            : '${parts.sublist(0, parts.length - 1).join(', ')} '
                'y ${parts.last}';
    return '${EsBO.calcEmptyHintPrefix} $joined '
        '${EsBO.calcEmptyHintSuffix}.';
  }

  // ============================================================
  // EXPRESS FORM
  // ============================================================

  Widget _buildExpressForm(
    CalculatorState state,
    CalculatorNotifier notifier,
    ThemeData theme,
    WorldCurrency currency,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: MaxWidthScrollView(
        maxWidth: 720,
        child: _paperSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloque de titulo: el cotizador es una hoja de plano.
              _buildMembrete(context),
              const SizedBox(height: AppSpacing.xl),

              // Mode selector
              _ModeSelector(mode: state.mode, onChanged: _switchMode),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica hero: Peso de la pieza. Es el dato que mas pesa en
              // el total; por eso va primero, grande, con la etiqueta
              // opcional de la pieza integrada abajo.
              _RubricSection(
                icon: Icons.scale_rounded,
                title: EsBO.calcSectionWeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NumericInputField(
                      label: EsBO.calcFieldWeight,
                      controller: _weightCtrl,
                      onChanged: notifier.setWeight,
                      suffix: 'g',
                      helperText: EsBO.calcLabelWeightHelper,
                      keyHint: EsBO.calcKeyWeightHint,
                      isKey: true,
                      fontSize: 22,
                      showValidation: _showValidationErrors,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _pieceLabelCtrl,
                      decoration: InputDecoration(
                        labelText: EsBO.calcLabelOptional,
                        helperText: EsBO.calcLabelOptionalHelper,
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica hero: Tiempo de impresion. Con peso + tiempo ya se
              // arma el total; tambien grande para el caso 95%.
              _RubricSection(
                icon: Icons.timer_rounded,
                title: EsBO.calcSectionTime,
                child: Row(
                  children: [
                    Expanded(
                      child: NumericInputField(
                        label: EsBO.calcLabelHours,
                        controller: _hoursCtrl,
                        onChanged: notifier.setPrintHours,
                        suffix: 'h',
                        keyHint: EsBO.calcKeyHoursHint,
                        isKey: true,
                        fontSize: 22,
                        showValidation: _showValidationErrors,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: NumericInputField(
                        label: EsBO.calcLabelMinutes,
                        controller: _minutesCtrl,
                        onChanged: notifier.setPrintMinutes,
                        suffix: 'min',
                        keyHint: EsBO.calcKeyMinutesHint,
                        isKey: true,
                        fontSize: 22,
                        showValidation: _showValidationErrors,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica: Filamento (un solo material en Express). El peso
              // ya vive en la rubrica hero de arriba; aqui se elige el
              // filamento del catalogo y su precio/gramos.
              _RubricSection(
                icon: Icons.inventory_2_rounded,
                title: EsBO.calcSectionFilament,
                child: _MaterialRowTile(
                  index: 0,
                  labelCtrl: _labelCtrl,
                  weightCtrl: _weightCtrl,
                  priceCtrl: _priceCtrl,
                  gramsCtrl: _gramsCtrl,
                  deletable: false,
                  showLabel: true,
                  showWeight: false,
                  showValidation: _showValidationErrors,
                  onRemove: () {},
                  onChanged: (m) {
                    // El peso vive en la rubrica hero (setWeight del hero).
                    // NO tocar weight desde el tile: si los controllers van
                    // desincronizados pisaria el peso y limpiaria el total.
                    notifier.setFilamentLabel(m.label);
                    notifier.setFilamentPrice(m.pricePerBobbin);
                    notifier.setFilamentGrams(m.gramsPerBobbin);
                  },
                  pending: false,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica: Impresora
              _RubricSection(
                icon: Icons.print_rounded,
                title: EsBO.calcSectionPrinter,
                child: _PrinterIndicator(),
              ),
              const SizedBox(height: AppSpacing.xxl),



              // Rubrica colapsable: OTROS (mano de obra, post-procesado,
              // falla, markup) — al final para no interponerse al 95%.
              _buildOtrosSection(notifier, currency),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADVANCED FORM
  // ============================================================

  Widget _buildAdvancedForm(
    CalculatorState state,
    CalculatorNotifier notifier,
    ThemeData theme,
    WorldCurrency currency,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: MaxWidthScrollView(
        maxWidth: 720,
        child: _paperSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloque de titulo: el cotizador es una hoja de plano.
              _buildMembrete(context),
              const SizedBox(height: AppSpacing.xl),

              // Mode selector
              _ModeSelector(mode: state.mode, onChanged: _switchMode),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica: Pieza (nombre opcional de la pieza)
              _RubricSection(
                icon: Icons.category_rounded,
                title: EsBO.calcSectionPiece,
                child: TextField(
                  controller: _pieceLabelCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.calcLabelOptional,
                    helperText: EsBO.calcLabelOptionalHelper,
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica: Materiales (multi-material, agregable)
              _RubricSection(
                icon: Icons.inventory_2_rounded,
                title: EsBO.calcSectionMaterials,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedList(
                      key: _advancedListKey,
                      initialItemCount: _materialCtrls.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index, animation) {
                        if (index >= _materialCtrls.length) {
                          return const SizedBox.shrink();
                        }
                        return SizeTransition(
                          sizeFactor: animation,
                          child: _MaterialRowTile(
                            index: index,
                            labelCtrl: _materialCtrls[index].label,
                            weightCtrl: _materialCtrls[index].weight,
                            priceCtrl: _materialCtrls[index].price,
                            gramsCtrl: _materialCtrls[index].grams,
                            deletable: true,
                            showValidation: _showValidationErrors,
                            isKeyWeight: true,
                            onChanged: (m) => notifier.updateMaterial(
                              index,
                              label: m.label,
                              weight: m.weight,
                              pricePerBobbin: m.pricePerBobbin,
                              gramsPerBobbin: m.gramsPerBobbin,
                            ),
                            onRemove: () => _removeMaterial(index),
                            pending: false,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _addMaterial,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(EsBO.calcAddMaterial),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica: Tiempo de impresion (dato hero, va tras los
              // materiales que aportan el peso en multi-material).
              _RubricSection(
                icon: Icons.timer_rounded,
                title: EsBO.calcSectionTime,
                child: Row(
                  children: [
                    Expanded(
                      child: NumericInputField(
                        label: EsBO.calcLabelHours,
                        controller: _hoursCtrl,
                        onChanged: notifier.setPrintHours,
                        suffix: 'h',
                        keyHint: EsBO.calcKeyHoursHint,
                        isKey: true,
                        fontSize: 22,
                        showValidation: _showValidationErrors,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: NumericInputField(
                        label: EsBO.calcLabelMinutes,
                        controller: _minutesCtrl,
                        onChanged: notifier.setPrintMinutes,
                        suffix: 'min',
                        keyHint: EsBO.calcKeyMinutesHint,
                        isKey: true,
                        fontSize: 22,
                        showValidation: _showValidationErrors,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rubrica: Impresora
              _RubricSection(
                icon: Icons.print_rounded,
                title: EsBO.calcSectionPrinter,
                child: _PrinterIndicator(),
              ),
              const SizedBox(height: AppSpacing.xxl),



              // Rubrica colapsable: OTROS (mano de obra, post-procesado,
              // falla, markup) — al final para no interponerse al flujo.
              _buildOtrosSection(notifier, currency),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OTROS SECTION — collapsable card
  // ============================================================

  /// Seccion colapsable "Otros" con 4 campos F1 en grid 2x2.
  /// Toggle via [_showOtros]. Reutilizada en ambas formas (Express y Advanced).
  Widget _buildOtrosSection(
    CalculatorNotifier notifier,
    WorldCurrency currency,
  ) {
    final theme = Theme.of(context);
    final isPro = ref.watch(isProProvider);
    final entitlementState = ref.watch(entitlementNotifierProvider);
    final isLoading = entitlementState.isLoading;
    final showProBadge = !isPro && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.more_horiz_rounded,
          title: EsBO.calcSectionOthers,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProBadge) ...[
                const ProBadge(),
                const SizedBox(width: AppSpacing.xs),
              ],
              AnimatedRotation(
                turns: _showOtros ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onTap: () {
            if (!isPro) {
              context.push('/paywall');
            } else {
              setState(() => _showOtros = !_showOtros);
            }
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showOtros
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    children: [
                      // Row 1: Mano de obra + Post-procesado
                      Row(
                        children: [
                          Expanded(
                            child: NumericInputField(
                              label: EsBO.calcFieldLabor,
                              controller: _extraLaborRateCtrl,
                              onChanged: notifier.setExtraLaborRate,
                              suffix: '${currency.symbol}/h',
                              helperText: EsBO.calcFieldLaborHelper,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: NumericInputField(
                              label: EsBO.calcFieldPostProcess,
                              controller: _extraPostProcessRateCtrl,
                              onChanged: notifier.setExtraPostProcessRate,
                              suffix: '%',
                              helperText: EsBO.calcFieldPostProcessHelper,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Row 2: Tasa de falla + Desperdicio
                      Row(
                        children: [
                          Expanded(
                            child: NumericInputField(
                              label: EsBO.calcFieldFailure,
                              controller: _extraFailureRateCtrl,
                              onChanged: notifier.setExtraFailureRate,
                              suffix: '%',
                              helperText: EsBO.calcFieldFailureHelper,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: NumericInputField(
                              label: EsBO.calcFieldWaste,
                              controller: _extraMarkupOnMaterialsCtrl,
                              onChanged: notifier.setExtraMarkupOnMaterials,
                              suffix: '%',
                              helperText: EsBO.calcFieldWasteHelper,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Hoja de plano: superficie que sostiene las rubric.
  Widget _paperSheet({required Widget child}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Membrete de la hoja: titulo en caps, numero de recibo y fecha.
  Widget _buildMembrete(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dateStr = '$dd/$mm/${now.year}';

    // Bloque de titulo de plano: caja con reticulado, titulo + fecha.
    // El documento se identifica como plano de cotizacion.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            EsBO.calcSheetTitle.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 1,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dateStr,
            style: AppTheme.num(
              theme.textTheme.bodySmall ?? const TextStyle(),
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================

/// Small action chip for filament catalog actions.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// === Printer indicator ===

class _PrinterIndicator extends ConsumerWidget {
  const _PrinterIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activePrinter = ref.watch(activePrinterProvider);
    final printersAsync = ref.watch(printersListProvider);
    final printers = printersAsync.value ?? <PrinterProfile>[];

    return Semantics(
      button: true,
      label: activePrinter != null
          ? '${EsBO.calcPrinterPrefix}${activePrinter.name}'
          : '${EsBO.calcNoPrinter}. ${EsBO.calcPrinterEmptyCta}',
      child: InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: printers.isEmpty
          ? () => context.push('/settings/printers/new')
          : () => showPrinterSelectorDialog(context, ref, printers: printers),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.print_rounded,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: activePrinter != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activePrinter.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          activePrinter.brand != null &&
                                  activePrinter.brand!.isNotEmpty
                              ? '${activePrinter.brand} · ${activePrinter.averageWatts} W'
                              : '${activePrinter.averageWatts} W',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          EsBO.calcNoPrinter,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          EsBO.calcPrinterEmptyHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          EsBO.calcPrinterEmptyCta,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        ),
      ),
    );
  }

}

// === MaterialCtrls y MaterialRowTile ===

class _MaterialCtrls {
  _MaterialCtrls({
    required this.label,
    required this.weight,
    required this.price,
    required this.grams,
  });

  factory _MaterialCtrls.empty() => _MaterialCtrls(
    label: TextEditingController(),
    weight: TextEditingController(),
    price: TextEditingController(),
    grams: TextEditingController(),
  );

  factory _MaterialCtrls.fromRow(MaterialRow r) => _MaterialCtrls(
    label: TextEditingController(text: r.label),
    weight: TextEditingController(text: r.weight),
    price: TextEditingController(text: r.pricePerBobbin),
    grams: TextEditingController(text: r.gramsPerBobbin),
  );

  final TextEditingController label;
  final TextEditingController weight;
  final TextEditingController price;
  final TextEditingController grams;

  void dispose() {
    label.dispose();
    weight.dispose();
    price.dispose();
    grams.dispose();
  }
}

class _MaterialUpdate {
  const _MaterialUpdate({
    required this.label,
    required this.weight,
    required this.pricePerBobbin,
    required this.gramsPerBobbin,
  });
  final String label;
  final String weight;
  final String pricePerBobbin;
  final String gramsPerBobbin;
}

class _MaterialRowTile extends ConsumerWidget {
  const _MaterialRowTile({
    required this.index,
    required this.labelCtrl,
    required this.weightCtrl,
    required this.priceCtrl,
    required this.gramsCtrl,
    required this.onChanged,
    required this.deletable,
    this.showLabel = true,
    this.showWeight = true,
    required this.onRemove,
    required this.pending,
    this.showValidation = false,
    this.isKeyWeight = false,
  });

  final int index;
  final TextEditingController labelCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController gramsCtrl;
  final ValueChanged<_MaterialUpdate> onChanged;
  final bool deletable;
  final bool showLabel;

  /// Si `false`, oculta el campo peso (Express: el peso ya vive en la
  /// rubrica hero). Default `true`.
  final bool showWeight;

  final VoidCallback onRemove;
  final bool pending;
  final bool showValidation;

  /// Si `true`, marca el campo peso como clave (resaltado visual).
  final bool isKeyWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pending) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.value ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return Semantics(
      container: true,
      label: EsBO.calcMaterialTitle(index + 1),
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      // Fila de tabla impresa: solo reglas superior e inferior, sin caja.
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: badge + titulo + Spacer + catalog chips + (opcional) delete
          Row(
            children: [
              Semantics(
                label: EsBO.calcMaterialTitle(index + 1),
                excludeSemantics: true,
                child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.num(
                      theme.textTheme.labelMedium ?? const TextStyle(),
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
              Text(EsBO.calcMaterialTitle(index + 1), style: theme.textTheme.titleSmall),
              const Spacer(),
              if (filaments.isNotEmpty) ...[
                if (defaultFilament != null)
                  _ActionChip(
                    icon: Icons.star_rounded,
                    label: EsBO.calcMaterialUse(defaultFilament.name),
                    onTap: () => _loadFromFilament(ref, defaultFilament),
                  ),
                if (defaultFilament != null)
                  const SizedBox(width: AppSpacing.xs),
                _ActionChip(
                  icon: Icons.inventory_2_rounded,
                  label: EsBO.calcMaterialCatalog,
                  onTap: () async {
                    final filament = await showFilamentSelectorDialog(
                      context,
                      ref,
                      filaments: filaments,
                    );
                    if (filament != null) _loadFromFilament(ref, filament);
                  },
                ),
                if (deletable) const SizedBox(width: AppSpacing.xs),
              ],
              if (deletable)
                Semantics(
                  button: true,
                  label: EsBO.calcMaterialRemove(index + 1),
                  child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: EsBO.calcMaterialRemove(index + 1),
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: EsBO.calcFieldLabel,
                helperText: EsBO.calcFieldLabelHelper,
                isDense: true,
                prefixIcon: const Icon(Icons.label_outline, size: 18),
              ),
              onChanged: (v) => _emit(),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (showWeight) ...[
                Expanded(
                  child: NumericInputField(
                    label: EsBO.calcFieldWeight,
                    controller: weightCtrl,
                    onChanged: (v) => _emit(),
                    suffix: 'g',
                    isKey: isKeyWeight,
                    keyHint: EsBO.calcKeyWeightHint,
                    showValidation: showValidation,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: NumericInputField(
                  label: EsBO.calcFieldSpoolPrice,
                  controller: priceCtrl,
                  onChanged: (v) => _emit(),
                  suffix: currency.symbol,
                  showValidation: showValidation,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NumericInputField(
                  label: EsBO.calcFieldSpoolGrams,
                  controller: gramsCtrl,
                  onChanged: (v) => _emit(),
                  suffix: 'g',
                  showValidation: showValidation,
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  void _emit() {
    onChanged(
      _MaterialUpdate(
        label: labelCtrl.text,
        weight: weightCtrl.text,
        pricePerBobbin: priceCtrl.text,
        gramsPerBobbin: gramsCtrl.text,
      ),
    );
  }

  void _loadFromFilament(WidgetRef ref, Filament f) {
    labelCtrl.text = f.name;
    priceCtrl.text = f.pricePerBobbin.toStringAsFixed(2);
    gramsCtrl.text = f.gramsPerBobbin.toStringAsFixed(0);
    _emit();
  }

}

// === Mode Selector ===

/// Selector de modo Express / Advanced.
///
/// **Gate visual (UX)**: cuando el user es free (estado de entitlement
/// resuelto y `isPro=false`), el segmento "Advanced" se atenua
/// ([kLockedOpacity]) y muestra un [ProBadge] para senalar NOTORIAMENTE
/// que es Pro. Durante el boot async (loading) NO se muestra el badge
/// (evita falso "locked" en cold start, mismo patron que `_switchMode`).
/// El tap mantiene el gate actual (SnackBar + Go Pro) via `onChanged`.
class _ModeSelector extends ConsumerWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final CalculatorMode mode;
  final ValueChanged<CalculatorMode> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Patron de estado obligatorio: no marcar "locked" mientras el
    // entitlement sigue cargando (cold start).
    final ent = ref.watch(entitlementNotifierProvider);
    final locked = !ent.isLoading && !ref.watch(isProProvider);

    return Semantics(
      label: EsBO.calcSemanticMode(
        mode == CalculatorMode.express
            ? EsBO.calcModeExpress
            : EsBO.calcModeAdvanced,
      ),
      child: SegmentedButton<CalculatorMode>(
        segments: [
          ButtonSegment(
            value: CalculatorMode.express,
            label: Text(EsBO.calcModeExpress),
            icon: const Icon(Icons.flash_on_rounded),
          ),
          ButtonSegment(
            value: CalculatorMode.advanced,
            label: locked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // El badge se muestra a opacidad completa (leer +
                      // distintivo); solo texto/icono se atenuan.
                      Opacity(
                        opacity: kLockedOpacity,
                        child: Text(EsBO.calcModeAdvanced),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const ProBadge(),
                    ],
                  )
                : Text(EsBO.calcModeAdvanced),
            icon: locked
                ? Opacity(
                    opacity: kLockedOpacity,
                    child: const Icon(Icons.layers_rounded),
                  )
                : const Icon(Icons.layers_rounded),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}

// === Save dialog ===

class _SaveResult {
  const _SaveResult({this.clientName});
  final String? clientName;
}

class _SaveDialog extends StatefulWidget {
  const _SaveDialog();

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  final _clientCtrl = TextEditingController();

  @override
  void dispose() {
    _clientCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_SaveResult(clientName: _clientCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(EsBO.calcBtnSave),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _clientCtrl,
            decoration: InputDecoration(
              labelText: EsBO.calcDialogClient,
              helperText: EsBO.calcDialogClientHelper,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(EsBO.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(EsBO.commonSave)),
      ],
    );
  }
}

/// Rubrica impresa: header de seccion + contenido, sin caja de card.
///
/// Dentro de la hoja de plano, cada rubrica es un titulo
/// con su regla de cota ([SectionHeader]) seguido del contenido. Sin card
/// anidada: la hoja ya ES el documento.
class _RubricSection extends StatelessWidget {
  const _RubricSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(icon: icon, title: title),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
