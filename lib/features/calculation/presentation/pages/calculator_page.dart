// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/calculation_draft.dart';
import '../../../../core/storage/draft_storage_providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/avatar_icon.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
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
  const CalculatorPage({super.key});

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
      c.addListener(_scheduleDraftSave);
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
      // Resetear state al entrar (no arrastrar datos de sesion anterior).
      ref.read(calculatorNotifierProvider.notifier).reset();
      final storage = ref.read(draftStorageProvider);
      final draft = await storage.load();
      if (!mounted) return;
      if (draft != null) {
        // Restaurar el draft en notifier y sincronizar controllers.
        ref.read(calculatorNotifierProvider.notifier).restoreFromDraft(draft);
        if (!mounted) return;
        _weightCtrl.text = draft.weight;
        _hoursCtrl.text = draft.printHours;
        _minutesCtrl.text = draft.printMinutes;
        _discountCtrl.text = draft.discountPct;
        _priceCtrl.text = draft.filamentPrice;
        _gramsCtrl.text = draft.filamentGrams;
        _labelCtrl.text = draft.filamentLabel;
        _pieceLabelCtrl.text = draft.label;
        _extraLaborRateCtrl.text = draft.extraLaborRate;
        _extraPostProcessRateCtrl.text = draft.extraPostProcessRate;
        _extraFailureRateCtrl.text = draft.extraFailureRate;
        _extraMarkupOnMaterialsCtrl.text = draft.extraMarkupOnMaterials;
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
        AppSnackBar.warning('Completa el form antes de guardar.'),
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
        ).showSnackBar(AppSnackBar.error('No se pudo guardar.'));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success('Cotizacion #$id guardada.'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error('Error: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizacion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restablecer',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: SafeArea(
        child: state.mode == CalculatorMode.express
            ? _buildExpressForm(state, notifier, theme)
            : _buildAdvancedForm(state, notifier, theme),
      ),
      // Sticky bottom bar: SIEMPRE visible (Fix #3). Cumplio doble proposito:
      // - invalid → empty hint dinamico (lista campos faltantes).
      // - valid → total formateado + tap abre modal con resumen + acciones.
      bottomNavigationBar: ResultBottomBar(
        totalText: state.output != null
            ? formatBob(state.output!.totalPrice)
            : '—',
        hasDiscount:
            state.output != null && state.output!.discountAmount > Decimal.zero,
        emptyHint: state.isValid
            ? null
            : _buildEmptyHint(state.missingRequiredFields),
        onTap: state.isValid && state.output != null
            ? () => showResultSheet(
                context: context,
                state: state,
                onSave: _showSaveDialog,
                onReset: _resetAll,
                onToggleDetail: () =>
                    ref.read(calculatorNotifierProvider.notifier).toggleDetail(),
              )
            : null,
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
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: MaxWidthScrollView(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode selector
            _ModeSelector(mode: state.mode, onChanged: _switchMode),
            const SizedBox(height: AppSpacing.lg),

            // Card: Pieza (nombre opcional de la pieza)
            SectionCard(
              icon: Icons.category_rounded,
              title: EsBO.calcSectionPiece,
              child: TextField(
                controller: _pieceLabelCtrl,
                decoration: const InputDecoration(
                  labelText: EsBO.calcLabelOptional,
                  helperText: 'Nombre de la pieza (ej: Jarron 3D, Posavasos)',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Card: Materiales (Express: un solo material como en Advanced)
            SectionCard(
              icon: Icons.inventory_2_rounded,
              title: 'Materiales',
              child: _MaterialRowTile(
                index: 0,
                labelCtrl: _labelCtrl,
                weightCtrl: _weightCtrl,
                priceCtrl: _priceCtrl,
                gramsCtrl: _gramsCtrl,
                deletable: false,
                showLabel: true,
                onRemove: () {},
                onChanged: (m) {
                  // label actualiza filamentLabel (nombre del material)
                  notifier.setFilamentLabel(m.label);
                  notifier.setWeight(m.weight);
                  notifier.setFilamentPrice(m.pricePerBobbin);
                  notifier.setFilamentGrams(m.gramsPerBobbin);
                },
                pending: false,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

          // Card: Impresora
          SectionCard(
            icon: Icons.print_rounded,
            title: 'Impresora',
            child: _PrinterIndicator(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Card: OTROS (mano de obra, post-procesado, falla, minimo, markup)
          // Collapsable. Primero porque sus valores afectan tiempo y descuento.
          _buildOtrosSection(notifier),
          const SizedBox(height: AppSpacing.md),

          // Card: Tiempo
          SectionCard(
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
                    helperText: EsBO.calcLabelHoursHelper,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NumericInputField(
                    label: EsBO.calcLabelMinutes,
                    controller: _minutesCtrl,
                    onChanged: notifier.setPrintMinutes,
                    suffix: 'min',
                    helperText: EsBO.calcLabelMinutesHelper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Card: Descuento
          SectionCard(
            icon: Icons.local_offer_rounded,
            title: EsBO.calcSectionDiscount,
            child: NumericInputField(
              label: 'Descuento',
              controller: _discountCtrl,
              onChanged: notifier.setDiscountPct,
              suffix: '%',
              helperText: EsBO.calcLabelDiscountHelper,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // El output + botones Save/Reset ahora viven en el ResultBottomBar
          // sticky + modal sheet (Fix #3). El form queda limpio: solo inputs.
        ],
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
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: MaxWidthScrollView(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSelector(mode: state.mode, onChanged: _switchMode),
            const SizedBox(height: AppSpacing.lg),

            // Card: Etiqueta de la pieza (nombre global de la pieza)
            SectionCard(
              icon: Icons.category_rounded,
              title: EsBO.calcSectionPiece,
              child: TextField(
                controller: _pieceLabelCtrl,
                decoration: const InputDecoration(
                  labelText: EsBO.calcLabelOptional,
                  helperText: EsBO.calcLabelOptionalHelper,
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

          // Card: Materiales (multi-material, agregable)
          SectionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Materiales',
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
                  label: const Text('Agregar material'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Card: Impresora
          SectionCard(
            icon: Icons.print_rounded,
            title: 'Impresora',
            child: _PrinterIndicator(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Card: OTROS (mano de obra, post-procesado, falla, minimo, markup)
          // Collapsable. Primero porque sus valores afectan tiempo y descuento.
          _buildOtrosSection(notifier),
          const SizedBox(height: AppSpacing.md),

          // Card: Tiempo
          SectionCard(
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
                    helperText: EsBO.calcLabelHoursHelper,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NumericInputField(
                    label: EsBO.calcLabelMinutes,
                    controller: _minutesCtrl,
                    onChanged: notifier.setPrintMinutes,
                    suffix: 'min',
                    helperText: EsBO.calcLabelMinutesHelper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Card: Descuento
          SectionCard(
            icon: Icons.local_offer_rounded,
            title: EsBO.calcSectionDiscount,
            child: NumericInputField(
              label: 'Descuento',
              controller: _discountCtrl,
              onChanged: notifier.setDiscountPct,
              suffix: '%',
              helperText: EsBO.calcLabelDiscountHelper,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Output + Save/Reset viven en el ResultBottomBar + modal sheet
          // (Fix #3). Ver seccion EXPRESS para la nota completa.
        ],
        ),
      ),
    );
  }

  // ============================================================
  // OTROS SECTION — collapsable card
  // ============================================================

  /// Seccion colapsable "Otros" con 4 campos F1 en grid 2x2.
  /// Toggle via [_showOtros]. Reutilizada en ambas formas (Express y Advanced).
  Widget _buildOtrosSection(CalculatorNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              onTap: () => setState(() => _showOtros = !_showOtros),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.more_horiz_rounded, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Otros',
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _showOtros ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                  ],
                ),
              ),
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
                                  label: 'Mano de obra',
                                  controller: _extraLaborRateCtrl,
                                  onChanged: notifier.setExtraLaborRate,
                                  suffix: 'Bs/h',
                                  helperText: 'Tarifa por hora',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: NumericInputField(
                                  label: 'Post-procesado',
                                  controller: _extraPostProcessRateCtrl,
                                  onChanged: notifier.setExtraPostProcessRate,
                                  suffix: '%',
                                  helperText: '% del costo mat.',
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
                                  label: 'Tasa de falla',
                                  controller: _extraFailureRateCtrl,
                                  onChanged: notifier.setExtraFailureRate,
                                  suffix: '%',
                                  helperText: '% del costo base',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: NumericInputField(
                                  label: 'Desperdicio',
                                  controller: _extraMarkupOnMaterialsCtrl,
                                  onChanged: notifier.setExtraMarkupOnMaterials,
                                  suffix: '%',
                                  helperText: '% markup desperdicio',
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
        ),
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
      label: Text(label, style: const TextStyle(fontSize: 12)),
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
    final printers = printersAsync.valueOrNull ?? <PrinterProfile>[];

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: printers.isEmpty
          ? null
          : () => _showPrinterDialog(context, ref, printers),
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
                  : Text(
                      'Sin impresora registrada',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            if (printers.isNotEmpty)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  void _showPrinterDialog(
    BuildContext context,
    WidgetRef ref,
    List<PrinterProfile> printers,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar impresora'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: printers.length,
            itemBuilder: (_, i) {
              final p = printers[i];
              return ListTile(
                leading: AvatarIcon(icon: Icons.print_rounded),
                title: Text(p.name),
                subtitle: Text(
                  '${p.brand != null && p.brand!.isNotEmpty ? '${p.brand} · ' : ''}${p.averageWatts} W'
                  '${p.isDefault ? ' (default)' : ''}',
                ),
                onTap: () {
                  ref.read(activePrinterIdProvider.notifier).state = p.id;
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
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
    required this.onRemove,
    required this.pending,
  });

  final int index;
  final TextEditingController labelCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController gramsCtrl;
  final ValueChanged<_MaterialUpdate> onChanged;
  final bool deletable;
  final bool showLabel;
  final VoidCallback onRemove;
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pending) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.valueOrNull ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: badge + titulo + Spacer + catalog chips + (opcional) delete
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Material ${index + 1}', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (filaments.isNotEmpty) ...[
                if (defaultFilament != null)
                  _ActionChip(
                    icon: Icons.star_rounded,
                    label: 'Usar ${defaultFilament.name}',
                    onTap: () => _loadFromFilament(ref, defaultFilament),
                  ),
                if (defaultFilament != null)
                  const SizedBox(width: AppSpacing.xs),
                _ActionChip(
                  icon: Icons.inventory_2_rounded,
                  label: 'Catalogo',
                  onTap: () => _showCatalogDialog(context, ref, filaments),
                ),
                if (deletable) const SizedBox(width: AppSpacing.xs),
              ],
              if (deletable)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Quitar',
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Etiqueta',
                helperText: 'Opcional (ej: PLA base)',
                isDense: true,
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
              onChanged: (v) => _emit(),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: NumericInputField(
                  label: 'Peso',
                  controller: weightCtrl,
                  onChanged: (v) => _emit(),
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NumericInputField(
                  label: 'Precio bobina',
                  controller: priceCtrl,
                  onChanged: (v) => _emit(),
                  suffix: 'BOB',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NumericInputField(
                  label: 'Gramos / bobina',
                  controller: gramsCtrl,
                  onChanged: (v) => _emit(),
                  suffix: 'g',
                ),
              ),
            ],
          ),
        ],
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

  void _showCatalogDialog(
    BuildContext context,
    WidgetRef ref,
    List<Filament> filaments,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar filamento'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filaments.length,
            itemBuilder: (_, i) {
              final f = filaments[i];
              return ListTile(
                leading: AvatarIcon(
                  icon: f.isDefault ? Icons.star_rounded : Icons.label_rounded,
                  foreground: f.isDefault
                      ? Theme.of(context).colorScheme.tertiary
                      : null,
                ),
                title: Text(f.name),
                subtitle: Text(
                  '${f.pricePerBobbin.toStringAsFixed(0)} BOB · '
                  '${f.gramsPerBobbin.toStringAsFixed(0)} g'
                  '${f.isDefault ? ' (default)' : ''}',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _loadFromFilament(ref, f);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

// === Mode Selector ===

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final CalculatorMode mode;
  final ValueChanged<CalculatorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalculatorMode>(
      segments: const [
        ButtonSegment(
          value: CalculatorMode.express,
          label: Text('Express'),
          icon: Icon(Icons.flash_on_rounded),
        ),
        ButtonSegment(
          value: CalculatorMode.advanced,
          label: Text('Advanced'),
          icon: Icon(Icons.layers_rounded),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
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
      title: const Text('Guardar cotizacion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _clientCtrl,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              helperText: 'Opcional',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
