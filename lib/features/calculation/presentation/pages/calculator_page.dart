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
import '../widgets/cost_help_dialog.dart';
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
  late final TextEditingController
  _labelCtrl; // material label (Express) / piece label (Advanced listener)
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
    _extraLaborRateCtrl = TextEditingController(text: initial.extraLaborRate);
    _extraPostProcessRateCtrl = TextEditingController(
      text: initial.extraPostProcessRate,
    );
    _extraFailureRateCtrl = TextEditingController(
      text: initial.extraFailureRate,
    );
    _extraMarkupOnMaterialsCtrl = TextEditingController(
      text: initial.extraMarkupOnMaterials,
    );

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
      ref
          .read(calculatorNotifierProvider.notifier)
          .setFilamentLabel(_labelCtrl.text);
    });
    _pieceLabelCtrl.addListener(() {
      ref
          .read(calculatorNotifierProvider.notifier)
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
            AppSnackBar.info(
              context,
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
          child: const SizedBox.shrink(),
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

  /// Bottom sheet de plantillas de trabajo: tap = aplica al form
  /// (reusa [CalculatorNotifier.loadFromCalculation]); icono = elimina.
  Future<void> _showTemplatesSheet() async {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);
    final List<Calculation> templates;
    try {
      templates = await notifier.templates();
    } catch (e) {
      debugPrint('List templates failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.calcTemplateApplyError));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        if (templates.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_copy_outlined,
                    size: 48,
                    color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    EsBO.calcTemplateEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetCtx).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  EsBO.calcTemplatesTitle,
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (ctx, i) {
                    final t = templates[i];
                    final name = (t.pieceName?.trim().isNotEmpty ?? false)
                        ? t.pieceName!.trim()
                        : EsBO.calcTemplateUntitled;
                    return ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(name),
                      subtitle: Text(
                        formatCurrency(
                          Decimal.parse(
                            t.totalPriceSnapshot.toStringAsFixed(2),
                          ),
                          currency,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: EsBO.commonDelete,
                        onPressed: () async {
                          try {
                            final ok = await notifier.deleteTemplate(t.id);
                            if (!sheetCtx.mounted) return;
                            ScaffoldMessenger.of(
                              sheetCtx,
                            ).hideCurrentSnackBar();
                            if (!ok) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                AppSnackBar.error(EsBO.calcTemplateDeleteError),
                              );
                              return;
                            }
                            Navigator.of(sheetCtx).pop();
                            await _showTemplatesSheet();
                          } catch (e) {
                            debugPrint('Delete template failed: $e');
                            if (!sheetCtx.mounted) return;
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              AppSnackBar.error(EsBO.calcTemplateDeleteError),
                            );
                          }
                        },
                      ),
                      onTap: () async {
                        try {
                          await notifier.loadFromCalculation(t);
                          if (!sheetCtx.mounted) return;
                          Navigator.of(sheetCtx).pop();
                          if (!mounted) return;
                          // BUG-FIX: sincronizar controllers con el state
                          // cargado. Sin esto, el state tiene los datos pero
                          // los campos de texto quedan vacíos (solo se ve el
                          // total en el AppBar/bottom bar).
                          _syncControllersFromState(
                            ref.read(calculatorNotifierProvider),
                          );
                          _rebuildAdvancedRows();
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              AppSnackBar.success(
                                EsBO.calcTemplateApplySuccess,
                              ),
                            );
                        } catch (e) {
                          debugPrint('Apply template failed: $e');
                          if (!sheetCtx.mounted) return;
                          ScaffoldMessenger.of(sheetCtx).showSnackBar(
                            AppSnackBar.error(EsBO.calcTemplateApplyError),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSaveDialog() async {
    final state = ref.read(calculatorNotifierProvider);
    if (!state.isValid || state.output == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.warning(EsBO.calcFormIncompleteWarning));
      return;
    }
    final recentClients = await ref
        .read(calculationRepositoryProvider)
        .recentClientNames();
    if (!mounted) return;
    final result = await showModalBottomSheet<_SaveResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetCtx) => _SaveSheet(recentClients: recentClients),
    );
    if (result == null || !mounted) return;
    try {
      final notifier = ref.read(calculatorNotifierProvider.notifier);

      // 1) Siempre guardar en el historial (no modifica el state).
      final id = await notifier.save(
        clientName: result.clientName,
        notes: result.notes,
        conditions: result.conditions,
      );
      if (id == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.calcSaveFailed));
        return;
      }

      // 2) Opcionalmente, además, crear una plantilla reutilizable.
      //    IMPORTANTE: hacerlo ANTES de resetear el form. Si reseteamos
      //    primero, `state.isValid`/`state.output` dejan de ser válidos y
      //    `saveAsTemplate` no crea nada (bug: plantilla que desaparece).
      if (result.saveAsTemplate) {
        try {
          await notifier.saveAsTemplate(clientName: result.clientName);
        } catch (e) {
          debugPrint('Save template failed: $e');
        }
      }
      if (!mounted) return;

      // 3) Limpiar el formulario y el estado en memoria al guardar: sin esto
      //    los valores quedan "cacheados" en el notifier y solo desaparecen
      //    al salir y volver a entrar. El reset dispara listeners que
      //    re-agendarían el draft; lo cancelamos para no re-persistir un
      //    draft vacío.
      await ref.read(draftStorageProvider).clear();
      _saveTimer?.cancel();
      _resetAll();
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar.success(
            EsBO.calcSavedWithId(id),
            actionLabel: EsBO.calcSavedViewAction,
            onAction: () {
              if (!mounted) return;
              context.push('/history/$id');
            },
          ),
        );
    } on HistoryCapReachedException catch (_) {
      // T15: free user intento guardar la #11. SnackBar dedicado con CTA
      // "Go Pro" (reusamos calculatorGoProAction — mismo destino /paywall
      // que T14). No se persiste nada; los 10 items existentes intactos.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar.info(
            context,
            EsBO.historyCapReachedBody,
            actionLabel: EsBO.calculatorGoProAction,
            onAction: () {
              GoRouter.of(context).push('/paywall');
            },
          ),
        );
    } catch (e) {
      debugPrint('Quote save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.error(EsBO.commonErrorGeneric));
    }
  }

  /// Abre el modal sheet de resultado (resumen + acciones).
  void _openResultSheet() {
    final state = ref.read(calculatorNotifierProvider);
    if (state.isValid && state.output != null) {
      showResultSheet(
        context: context,
        state: state,
        onSave: _showSaveDialog,
        onReset: _resetAll,
        onToggleDetail: () =>
            ref.read(calculatorNotifierProvider.notifier).toggleDetail(),
        onDiscountChanged: (value) {
          ref.read(calculatorNotifierProvider.notifier).setDiscountPct(value);
          if (_discountCtrl.text != value) {
            _discountCtrl.text = value;
          }
        },
      );
    } else {
      setState(() => _showValidationErrors = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);
    final theme = Theme.of(context);
    final isValid = state.isValid && state.output != null;
    final totalText = isValid
        ? formatCurrency(
            state.output!.totalPrice * Decimal.fromInt(state.quantity),
            currency,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        // Salida explícita: con ruta push, el leading por defecto es una
        // flecha sutil. Un botón "cerrar" comunica mejor que vuelve al menú
        // (sobre todo en web, donde no hay back del sistema).
        leading: Semantics(
          button: true,
          label: EsBO.calcCloseAction,
          child: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: EsBO.calcCloseAction,
            onPressed: () => context.pop(),
          ),
        ),
        title: Semantics(
          header: true,
          child: Text(ref.watch(localeStringsProvider).calcSheetTitle),
        ),
        actions: [
          // Total chip: siempre visible en el AppBar (nunca se tapa con
          // el teclado). Tap abre el sheet de resultado.
          if (totalText != null)
            Semantics(
              button: true,
              label: '${EsBO.calcResultBarTapHint}: $totalText',
              child: _TotalChip(
                totalText: totalText,
                hasDiscount: state.output!.discountAmount > Decimal.zero,
                onTap: _openResultSheet,
              ),
            ),
          Semantics(
            button: true,
            label: EsBO.costHelpTitle,
            child: IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: EsBO.costHelpTitle,
              onPressed: () => showCostHelpDialog(context),
            ),
          ),
          Semantics(
            button: true,
            label: EsBO.calcTemplatesTitle,
            child: IconButton(
              icon: const Icon(Icons.folder_copy_rounded),
              tooltip: EsBO.calcTemplatesTitle,
              onPressed: _showTemplatesSheet,
            ),
          ),
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
      // Bottom bar: ahora muestra hint de validación (cuando inválido) y
      // también el total como recordatorio (tap abre el sheet). Ya NO es
      // la única fuente del total — el AppBar lo muestra siempre.
      bottomNavigationBar: ResultBottomBar(
        totalText: totalText ?? '—',
        hasDiscount:
            state.output != null && state.output!.discountAmount > Decimal.zero,
        emptyHint: state.isValid
            ? null
            : _buildEmptyHint(state.missingRequiredFields),
        onTap: _openResultSheet,
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
              const SizedBox(height: AppSpacing.md),

              // Mode selector compacto (alineado a la derecha)
              Align(
                alignment: Alignment.centerRight,
                child: _ModeSelector(mode: state.mode, onChanged: _switchMode),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── SECCIÓN UNIFICADA: Pieza + Material ──
              // En Express, peso + filamento van juntos para reducir scroll.
              // El usuario elige filamento del catálogo (trae precio/grams)
              // y pone el peso de la pieza — todo en una tarjeta.
              _RubricSection(
                icon: Icons.category_rounded,
                title: EsBO.calcSectionPiece,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre de la pieza (opcional, compacto)
                    TextField(
                      controller: _pieceLabelCtrl,
                      decoration: InputDecoration(
                        labelText: EsBO.calcLabelOptional,
                        helperText: EsBO.calcLabelOptionalHelper,
                        isDense: true,
                        prefixIcon: const Icon(Icons.label_outline, size: 18),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Peso — campo hero (grande, clave)
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
                    // Filamento: selector inline del catálogo
                    _ExpressFilamentRow(
                      labelCtrl: _labelCtrl,
                      priceCtrl: _priceCtrl,
                      gramsCtrl: _gramsCtrl,
                      showValidation: _showValidationErrors,
                      onChanged: (m) {
                        notifier.setFilamentLabel(m.label);
                        notifier.setFilamentPrice(m.pricePerBobbin);
                        notifier.setFilamentGrams(m.gramsPerBobbin);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Tiempo de impresión ──
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
              const SizedBox(height: AppSpacing.lg),

              // ── Impresora ──
              _RubricSection(
                icon: Icons.print_rounded,
                title: EsBO.calcSectionPrinter,
                child: const _PrinterIndicator(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── OTROS (con peek preview) ──
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
              const SizedBox(height: AppSpacing.md),

              // Mode selector compacto
              Align(
                alignment: Alignment.centerRight,
                child: _ModeSelector(mode: state.mode, onChanged: _switchMode),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Rubrica: Pieza (nombre opcional de la pieza)
              _RubricSection(
                icon: Icons.category_rounded,
                title: EsBO.calcSectionPiece,
                child: TextField(
                  controller: _pieceLabelCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.calcLabelOptional,
                    helperText: EsBO.calcLabelOptionalHelper,
                    isDense: true,
                    prefixIcon: const Icon(Icons.label_outline, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

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
              const SizedBox(height: AppSpacing.lg),

              // Rubrica: Tiempo de impresion
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
              const SizedBox(height: AppSpacing.lg),

              // Rubrica: Impresora
              _RubricSection(
                icon: Icons.print_rounded,
                title: EsBO.calcSectionPrinter,
                child: const _PrinterIndicator(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Rubrica colapsable: OTROS (con peek preview)
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
  ///
  /// **Peek preview**: cuando esta colapsado, muestra los nombres de los
  /// 4 campos en una fila sutil (labels atenuados) para que el usuario
  /// sepa que existe sin tener que tocar. Free ve un overlay de bloqueo;
  /// Pro puede expandir normalmente.
  Widget _buildOtrosSection(
    CalculatorNotifier notifier,
    WorldCurrency currency,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
                  color: cs.onSurfaceVariant,
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
        // Peek preview: labels de los 4 campos cuando esta colapsado
        if (!_showOtros) _OtrosPeekPreview(locked: showProBadge),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: cs.outlineVariant),
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

// === Total chip en AppBar ===

/// Chip animado que muestra el total calculado en el AppBar.
/// Siempre visible (no se tapa con el teclado). Tap abre el sheet
/// de resultado con el desglose completo y acciones.
class _TotalChip extends StatefulWidget {
  const _TotalChip({
    required this.totalText,
    required this.hasDiscount,
    required this.onTap,
  });

  final String totalText;
  final bool hasDiscount;
  final VoidCallback onTap;

  @override
  State<_TotalChip> createState() => _TotalChipState();
}

class _TotalChipState extends State<_TotalChip>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;

  @override
  void initState() {
    super.initState();
    // Pulse sutil una sola vez cuando aparece el total por primera vez.
    _pulseCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
          )
          ..forward().then((_) {
            _pulseCtrl?.dispose();
            _pulseCtrl = null;
          });
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chip = Semantics(
      button: true,
      label: '${EsBO.calcResultBarTapHint}: ${widget.totalText}',
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: cs.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.totalText,
                style: AppTheme.num(
                  theme.textTheme.labelLarge ?? const TextStyle(),
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.hasDiscount) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onError,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );

    // Pulse sutil al primer render.
    if (_pulseCtrl != null) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeOutBack),
        ),
        child: chip,
      );
    }
    return chip;
  }
}

// ============================================================

/// Small action chip for filament catalog actions.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.maxWidth,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
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

class _MaterialRowTile extends ConsumerStatefulWidget {
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
  final bool showWeight;
  final VoidCallback onRemove;
  final bool showValidation;
  final bool isKeyWeight;

  @override
  ConsumerState<_MaterialRowTile> createState() => _MaterialRowTileState();
}

class _MaterialRowTileState extends ConsumerState<_MaterialRowTile> {
  /// Nombre del filamento seleccionado del catálogo (solo display).
  /// NO sobreescribe la Etiqueta del usuario.
  String _selectedFilamentName = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.value ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final hasCatalog = filaments.isNotEmpty;

    return Semantics(
      container: true,
      label: EsBO.calcMaterialTitle(widget.index + 1),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: cs.outlineVariant),
            bottom: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: badge + título + delete ──
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: AppTheme.num(
                        theme.textTheme.labelMedium ?? const TextStyle(),
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  EsBO.calcMaterialTitle(widget.index + 1),
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                if (widget.deletable)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: EsBO.calcMaterialRemove(widget.index + 1),
                    onPressed: widget.onRemove,
                    style: IconButton.styleFrom(foregroundColor: cs.error),
                  ),
              ],
            ),

            // ── Row compacta: Etiqueta + Filamento ──
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // Etiqueta (campo del usuario)
                if (widget.showLabel)
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: widget.labelCtrl,
                      decoration: InputDecoration(
                        labelText: EsBO.calcFieldLabel,
                        hintText: EsBO.calcFieldLabelHelper,
                        isDense: true,
                        prefixIcon: const Icon(Icons.label_outline, size: 18),
                      ),
                      onChanged: (v) => _emit(),
                    ),
                  ),
                if (widget.showLabel && hasCatalog)
                  const SizedBox(width: AppSpacing.sm),
                // Selector de filamento
                if (hasCatalog)
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      onTap: () async {
                        final filament = await showFilamentSelectorDialog(
                          context,
                          ref,
                          filaments: filaments,
                        );
                        if (filament != null) _loadFromFilament(filament);
                      },
                      child: InputDecorator(
                        isEmpty: _selectedFilamentName.isEmpty,
                        decoration: InputDecoration(
                          labelText: EsBO.calcFieldFilament,
                          hintText: EsBO.calcSelectFilament,
                          prefixIcon: const Icon(
                            Icons.inventory_2_rounded,
                            size: 18,
                          ),
                          suffixIcon: const Icon(Icons.expand_more_rounded),
                          isDense: true,
                        ),
                        child: Text(
                          _selectedFilamentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── "Usar default" debajo del selector si aplica ──
            if (hasCatalog &&
                defaultFilament != null &&
                _selectedFilamentName != defaultFilament.name) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: _ActionChip(
                  icon: Icons.star_rounded,
                  label: EsBO.calcMaterialUse(defaultFilament.name),
                  maxWidth: 180,
                  onTap: () => _loadFromFilament(defaultFilament),
                ),
              ),
            ],

            // ── Peso + (chips o campos de precio/grams) ──
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (widget.showWeight) ...[
                  Expanded(
                    child: NumericInputField(
                      label: EsBO.calcFieldWeight,
                      controller: widget.weightCtrl,
                      onChanged: (v) => _emit(),
                      suffix: 'g',
                      isKey: widget.isKeyWeight,
                      keyHint: EsBO.calcKeyWeightHint,
                      showValidation: widget.showValidation,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // Si filamento del catálogo: chip compacto
                if (_selectedFilamentName.isNotEmpty &&
                    widget.priceCtrl.text.isNotEmpty)
                  _MaterialCostChip(
                    price: widget.priceCtrl.text,
                    grams: widget.gramsCtrl.text,
                    currency: currency,
                  )
                else ...[
                  // Sin filamento: campos manuales
                  Expanded(
                    child: NumericInputField(
                      label: EsBO.calcFieldSpoolPrice,
                      controller: widget.priceCtrl,
                      onChanged: (v) => _emit(),
                      suffix: currency.symbol,
                      showValidation: widget.showValidation,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: NumericInputField(
                      label: EsBO.calcFieldSpoolGrams,
                      controller: widget.gramsCtrl,
                      onChanged: (v) => _emit(),
                      suffix: 'g',
                      showValidation: widget.showValidation,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _emit() {
    widget.onChanged(
      _MaterialUpdate(
        label: widget.labelCtrl.text,
        weight: widget.weightCtrl.text,
        pricePerBobbin: widget.priceCtrl.text,
        gramsPerBobbin: widget.gramsCtrl.text,
      ),
    );
  }

  void _loadFromFilament(Filament f) {
    // Solo actualiza precio/grams — NO sobreescribe la Etiqueta
    setState(() => _selectedFilamentName = f.name);
    widget.priceCtrl.text = f.pricePerBobbin.toStringAsFixed(2);
    widget.gramsCtrl.text = f.gramsPerBobbin.toStringAsFixed(0);
    _emit();
  }
}

/// Chip compacto de costo de filamento: muestra precio y gramos inline.
/// Se usa en Advanced cuando el filamento viene del catálogo (estilo Express).
class _MaterialCostChip extends StatelessWidget {
  const _MaterialCostChip({
    required this.price,
    required this.grams,
    required this.currency,
  });

  final String price;
  final String grams;
  final WorldCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currency.symbol}$price',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' / ${grams}g',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// === Mode Selector ===

/// Selector de modo Express / Advanced — compacto pill toggle.
///
/// Ocupa poco espacio horizontal: dos pills con icono + texto, alineados
/// a la derecha del header. El modo activo tiene fondo filled; el inactivo
/// es transparente con borde sutil.
///
/// **Gate visual (UX)**: cuando el user es free y el entitlement esta
/// resuelto, el pill "Avanzado" se atenua y muestra [ProBadge]. El tap
/// dispara el gate actual (SnackBar + Go Pro) via `onChanged`.
class _ModeSelector extends ConsumerWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final CalculatorMode mode;
  final ValueChanged<CalculatorMode> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementNotifierProvider);
    final locked = !ent.isLoading && !ref.watch(isProProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      label: EsBO.calcSemanticMode(
        mode == CalculatorMode.express
            ? EsBO.calcModeExpress
            : EsBO.calcModeAdvanced,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModePill(
            icon: Icons.flash_on_rounded,
            label: EsBO.calcModeExpress,
            isActive: mode == CalculatorMode.express,
            onTap: () => onChanged(CalculatorMode.express),
            activeColor: cs.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ModePill(
            icon: Icons.layers_rounded,
            label: locked ? null : EsBO.calcModeAdvanced,
            isActive: mode == CalculatorMode.advanced,
            locked: locked,
            onTap: () => onChanged(CalculatorMode.advanced),
            activeColor: cs.tertiary,
          ),
        ],
      ),
    );
  }
}

/// Pill individual del mode selector.
class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    this.locked = false,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final effectiveColor = locked && !isActive
        ? cs.onSurfaceVariant.withValues(alpha: 0.5)
        : isActive
        ? activeColor
        : cs.onSurfaceVariant;

    return Material(
      color: isActive
          ? activeColor.withValues(alpha: 0.12)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: BorderSide(
          color: isActive
              ? activeColor.withValues(alpha: 0.4)
              : cs.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: effectiveColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
              if (locked) ...[const SizedBox(width: 4), const ProBadge()],
            ],
          ),
        ),
      ),
    );
  }
}

// === Save dialog ===

class _SaveResult {
  const _SaveResult({
    this.clientName,
    this.notes,
    this.conditions,
    this.saveAsTemplate = false,
  });
  final String? clientName;
  final String? notes;
  final String? conditions;

  /// True cuando el usuario marcó "guardar también como plantilla":
  /// se guarda en el historial Y se crea una plantilla reutilizable.
  final bool saveAsTemplate;
}

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({this.recentClients = const []});

  /// Clientes más recientes para el quick-pick (chips).
  final List<String> recentClients;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  final _clientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  bool _saveAsTemplate = false;

  @override
  void dispose() {
    _clientCtrl.dispose();
    _notesCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _SaveResult(
        clientName: _clientCtrl.text,
        notes: _notesCtrl.text,
        conditions: _conditionsCtrl.text,
        saveAsTemplate: _saveAsTemplate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.primary.withValues(alpha: 0.15),
                          color.primaryContainer.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.save_rounded, color: color.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          EsBO.calcBtnSave,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          EsBO.calcDialogSaveSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Datos del cliente ──
              _fieldLabel(
                theme,
                Icons.person_outline_rounded,
                EsBO.calcDialogClient,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _clientCtrl,
                decoration: InputDecoration(
                  hintText: EsBO.calcDialogClientHelper,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                textInputAction: TextInputAction.next,
              ),
              if (widget.recentClients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _fieldLabel(
                  theme,
                  Icons.history_rounded,
                  EsBO.calcDialogRecentClients,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final client in widget.recentClients)
                      FilterChip(
                        avatar: _clientCtrl.text == client
                            ? const Icon(Icons.check_rounded, size: 18)
                            : null,
                        label: Text(client, overflow: TextOverflow.ellipsis),
                        selected: _clientCtrl.text == client,
                        onSelected: (_) =>
                            setState(() => _clientCtrl.text = client),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // ── Detalles ──
              _fieldLabel(
                theme,
                Icons.article_outlined,
                EsBO.calcDialogDetails,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.calcDialogNotes,
                  hintText: EsBO.calcDialogNotesHelper,
                  prefixIcon: const Icon(Icons.notes_rounded),
                  filled: true,
                  fillColor: color.surfaceContainerLow,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _conditionsCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.calcDialogConditions,
                  hintText: EsBO.calcDialogConditionsHelper,
                  prefixIcon: const Icon(Icons.rule_rounded),
                  filled: true,
                  fillColor: color.surfaceContainerLow,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Plantilla ──
              Material(
                color: _saveAsTemplate
                    ? color.primaryContainer.withValues(alpha: 0.4)
                    : color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      setState(() => _saveAsTemplate = !_saveAsTemplate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _saveAsTemplate
                              ? Icons.playlist_add_check_circle_rounded
                              : Icons.playlist_add_circle_outlined,
                          size: 28,
                          color: _saveAsTemplate
                              ? color.primary
                              : color.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                EsBO.calcDialogSaveAsTemplate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _saveAsTemplate ? color.primary : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                EsBO.calcTemplateSaveAsAction,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _saveAsTemplate,
                          onChanged: (v) => setState(() => _saveAsTemplate = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Footer ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(EsBO.commonCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(EsBO.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(ThemeData theme, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// Filament row compacto para Express: selector de catálogo + precio/grams
/// inline en una sola fila. Reemplaza al [_MaterialRowTile] completo en
/// modo Express para reducir scroll.
///
/// Muestra: selector de filamento (tap para abrir catálogo) + chips con
/// precio y gramos de la bobina. Si no hay filamentos en el catálogo,
/// muestra los campos manuales (precio + gramos).
class _ExpressFilamentRow extends ConsumerWidget {
  const _ExpressFilamentRow({
    required this.labelCtrl,
    required this.priceCtrl,
    required this.gramsCtrl,
    required this.showValidation,
    required this.onChanged,
  });

  final TextEditingController labelCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController gramsCtrl;
  final bool showValidation;
  final ValueChanged<_MaterialUpdate> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.value ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final hasFilaments = filaments.isNotEmpty;
    final hasLabel = labelCtrl.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de filamento o campos manuales
          if (hasFilaments)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.xs),
              onTap: () async {
                final filament = await showFilamentSelectorDialog(
                  context,
                  ref,
                  filaments: filaments,
                );
                if (filament != null) {
                  labelCtrl.text = filament.name;
                  priceCtrl.text = filament.pricePerBobbin.toStringAsFixed(2);
                  gramsCtrl.text = filament.gramsPerBobbin.toStringAsFixed(0);
                  onChanged(
                    _MaterialUpdate(
                      label: filament.name,
                      weight: '',
                      pricePerBobbin: filament.pricePerBobbin.toStringAsFixed(
                        2,
                      ),
                      gramsPerBobbin: filament.gramsPerBobbin.toStringAsFixed(
                        0,
                      ),
                    ),
                  );
                }
              },
              child: InputDecorator(
                isEmpty: !hasLabel,
                decoration: InputDecoration(
                  labelText: EsBO.calcFieldFilament,
                  hintText: EsBO.calcSelectFilament,
                  prefixIcon: const Icon(Icons.inventory_2_rounded, size: 18),
                  suffixIcon: const Icon(Icons.expand_more_rounded),
                  isDense: true,
                ),
                child: Text(
                  labelCtrl.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            // Sin catálogo: campos manuales de precio/grams
            Row(
              children: [
                Expanded(
                  child: NumericInputField(
                    label: EsBO.calcFieldSpoolPrice,
                    controller: priceCtrl,
                    onChanged: (_) => onChanged(_emit()),
                    suffix: currency.symbol,
                    showValidation: showValidation,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: NumericInputField(
                    label: EsBO.calcFieldSpoolGrams,
                    controller: gramsCtrl,
                    onChanged: (_) => onChanged(_emit()),
                    suffix: 'g',
                    showValidation: showValidation,
                  ),
                ),
              ],
            ),

          // Chip "Usar default" + info de precio/grams del filamento elegido
          if (hasLabel || defaultFilament != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (hasLabel) ...[
                  // Chip con precio y gramos del filamento actual
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${currency.symbol}${priceCtrl.text}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' / ${gramsCtrl.text}g',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // "Usar default" si hay default y es diferente al actual
                if (defaultFilament != null &&
                    labelCtrl.text != defaultFilament.name)
                  _ActionChip(
                    icon: Icons.star_rounded,
                    label: EsBO.calcMaterialUse(defaultFilament.name),
                    maxWidth: 180,
                    onTap: () {
                      labelCtrl.text = defaultFilament.name;
                      priceCtrl.text = defaultFilament.pricePerBobbin
                          .toStringAsFixed(2);
                      gramsCtrl.text = defaultFilament.gramsPerBobbin
                          .toStringAsFixed(0);
                      onChanged(
                        _MaterialUpdate(
                          label: defaultFilament.name,
                          weight: '',
                          pricePerBobbin: defaultFilament.pricePerBobbin
                              .toStringAsFixed(2),
                          gramsPerBobbin: defaultFilament.gramsPerBobbin
                              .toStringAsFixed(0),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _MaterialUpdate _emit() => _MaterialUpdate(
    label: labelCtrl.text,
    weight: '',
    pricePerBobbin: priceCtrl.text,
    gramsPerBobbin: gramsCtrl.text,
  );
}

/// Peek preview de la seccion "Otros" cuando esta colapsado.
///
/// Muestra los labels de los 4 campos en una fila compacta y atenuada.
/// Si [locked] es true (usuario free), agrega un overlay sutil con icono
/// de candado y un borde punteado para sugerir que hay contenido bloqueado.
class _OtrosPeekPreview extends StatelessWidget {
  const _OtrosPeekPreview({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.45);

    final labels = [
      EsBO.calcFieldLabor,
      EsBO.calcFieldPostProcess,
      EsBO.calcFieldFailure,
      EsBO.calcFieldWaste,
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: locked
              ? Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        child: Row(
          children: [
            // Labels en fila envolvente
            Expanded(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: labels.map((label) {
                  return Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: dimColor,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }).toList(),
              ),
            ),
            if (locked) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: cs.primary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
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
