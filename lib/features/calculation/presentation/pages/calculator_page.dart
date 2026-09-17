// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
import '../../../../shared/widgets/perforation.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/smart_app_bar_actions.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../../../settings/domain/discount_tier.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/calculator_bottom_bar.dart';
import '../widgets/calculator_wizard.dart';
import '../widgets/cost_help_dialog.dart';
import '../widgets/filament_row.dart';
import '../widgets/material_management.dart';
import '../widgets/mode_selector.dart';
import '../widgets/result_sheet.dart';
import '../widgets/save_sheet.dart';

/// Pantalla principal del calculator â€” WIZARD de 3 pasos (rediseño 2026-09).
///
/// Pasos (modo Express | modo Advanced comparten los pasos 2-3):
/// 1. Pieza: nombre + peso + filamento (Express) | nombre + materiales
///    (Advanced). Incluye membrete y selector de modo.
/// 2. Impresion: horas/minutos + impresora activa.
/// 3. Otros: cantidad (Pro) + descuento + OTROS/costos de la pieza (Pro).
///
/// El resultado NO es un paso: la barra de total fija abajo (con lineas de
/// lote y hint de validacion) se conserva en todos los pasos y su tap abre
/// el desglose completo â€” solo que ahora debajo vive el mini-footer de
/// navegacion del wizard: dos flechas espejo (atras/adelante, la de avance
/// disabled en el ultimo paso) con el contador "Paso X de 3" en el medio.
///
/// El indice del paso es estado efimero de UI (setState permitido, ver
/// Non-Negotiables). El negocio vive en [CalculatorNotifier]; el chip de
/// total del AppBar conserva el feedback live en cualquier paso.
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

  // Quantity controller.
  late final TextEditingController _quantityCtrl;

  // Advanced controllers.
  final List<MaterialCtrls> _materialCtrls = [];
  final _advancedListKey = GlobalKey<AnimatedListState>();

  /// Toggle local para la seccion OTROS (puramente visual, no persiste).
  bool _showOtros = false;

  /// Paso visible del wizard (0-based). Estado efimero de UI: setState es
  /// el mecanismo permitido (no se persiste ni se comparte).
  int _step = 0;

  /// Total de pasos del wizard.
  static const int _kStepCount = 3;

  /// Si `true`, los campos requeridos muestran error visual (border rojo).
  /// Se activa al tocar la barra inferior con form invalido.
  bool _showValidationErrors = false;

  /// Scroll controller para el scroll continuo del wizard.
  late final ScrollController _scrollCtrl;

  /// Keys de cada seccion para detectar posicion via scroll.
  final GlobalKey _section1Key = GlobalKey();
  final GlobalKey _section2Key = GlobalKey();
  final GlobalKey _section3Key = GlobalKey();

  /// Timestamp del ultimo cambio de step para evitar loops de scroll.
  DateTime _lastStepChange = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
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
    _quantityCtrl = TextEditingController(text: '${initial.quantity}');

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
        _materialCtrls.add(MaterialCtrls.fromRow(m));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Prefill ("Reusar"): cargar la cotizacion guardada y sincronizar los
      // controllers. NO tocar reset/draft/defaults â€” el state precargado es
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
      _materialCtrls.add(MaterialCtrls.fromRow(m));
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
    _scrollCtrl.dispose();
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
    _quantityCtrl.dispose();
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
      _materialCtrls.add(MaterialCtrls.empty());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _advancedListKey.currentState?.insertItem(0);
      });
    }
    notifier.setMode(mode);
  }

  void _addMaterial() {
    ref.read(calculatorNotifierProvider.notifier).addMaterial();
    _materialCtrls.add(MaterialCtrls.empty());
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
    // Tras un reset el usuario vuelve al inicio del wizard (el paso
    // resultado ya no tiene contenido util sin form valido).
    if (mounted) setState(() => _step = 0);
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

  Future<void> _showSaveDialog(Uint8List? pieceImageBytes) async {
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
    final result = await showModalBottomSheet<SaveResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetCtx) => SaveSheet(recentClients: recentClients),
    );
    if (result == null || !mounted) return;
    try {
      final notifier = ref.read(calculatorNotifierProvider.notifier);

      // 1) Siempre guardar en el historial (no modifica el state). La foto
      // de la pieza viaja desde el result sheet (F2).
      final id = await notifier.save(
        clientName: result.clientName,
        notes: result.notes,
        conditions: result.conditions,
        pieceImageBytes: pieceImageBytes,
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
    } on FormIncompleteException catch (_) {
      // Defensivo: el boton Guardar solo es accesible cuando el form es
      // valido, pero si llega un save invalido no crasheamos ni confundimos
      // con el mensaje generico: se muestra el hint de campos faltantes.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar.error(EsBO.calcSaveFailed));
    } on HistoryCapReachedException catch (_) {
      // T15: free user intento guardar la #11. SnackBar dedicado con CTA
      // "Go Pro" (reusamos calculatorGoProAction â€” mismo destino /paywall
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

  /// Navegacion del wizard: scroll suave a la seccion del paso indicado.
  /// Cuando el usuario toca un paso en el step bar, hace scroll automatico.
  void _goStep(int index) {
    final clamped = index.clamp(0, _kStepCount - 1);
    if (clamped == _step) return;
    FocusScope.of(context).unfocus();
    _lastStepChange = DateTime.now();
    setState(() => _step = clamped);
    _scrollToSection(clamped);
  }

  /// Scroll suave a la seccion indicada (0=pieza, 1=impresion, 2=ajustes).
  void _scrollToSection(int sectionIndex) {
    final keys = [_section1Key, _section2Key, _section3Key];
    final key = keys[sectionIndex];
    final context = key.currentContext;
    if (context == null) return;

    // Calcular la posicion offsetando el step bar (~60px) y un padding.
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero).dy -
        box.size.height * 0.05; // 5% padding arriba

    _scrollCtrl.animateTo(
      _scrollCtrl.offset + offset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Callback del ScrollNotification: detecta cual seccion esta visible
  /// y actualiza _step automaticamente.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    if (_scrollCtrl.position.maxScrollExtent == 0) return false;

    // Evitar loops: si acabamos de cambiar de step por tap, ignorar.
    final now = DateTime.now();
    if (now.difference(_lastStepChange).inMilliseconds < 500) return false;

    final viewportHeight = MediaQuery.of(context).size.height;

    // Determinar qué sección está más visible.
    final keys = [_section1Key, _section2Key, _section3Key];
    var mostVisible = 0;
    var bestVisibility = double.infinity;

    for (var i = 0; i < keys.length; i++) {
      final ctx = keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero).dy;
      final center = position + box.size.height / 2;
      final distFromCenter = (center - viewportHeight / 2).abs();
      if (distFromCenter < bestVisibility) {
        bestVisibility = distFromCenter;
        mostVisible = i;
      }
    }

    if (mostVisible != _step) {
      setState(() => _step = mostVisible);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);
    final isValid = state.isValid && state.output != null;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // feature A (Hito 1): escalones de descuento. El stream se escucha AC

    // (no en el notifier) para no sostener una suscripción drift en unit
    // tests; al emitir se actualiza el lote (lotTotal, líneas, hint).
    ref.listen(discountTiersProvider, (_, next) {
      notifier.updateTiers(next.value ?? const <DiscountTier>[]);
    });
    final totalText = isValid ? formatCurrency(state.lotTotal, currency) : null;

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
          // AppBar adaptativo: el chip de total es prioridad (SIEMPRE
          // directo); el resto colapsa a un menu â‹® en pantallas angostas.
          SmartAppBarActions(
            priority: [
              // Total chip: siempre visible en el AppBar (nunca se tapa con
              // el teclado). Tap abre el sheet de resultado.
              if (totalText != null)
                Semantics(
                  button: true,
                  label: '${EsBO.calcResultBarTapHint}: $totalText',
                  child: TotalChip(
                    totalText: totalText,
                    hasDiscount:
                        state.output!.discountAmount > Decimal.zero ||
                        state.showsBatchLine,
                    onTap: _openResultSheet,
                  ),
                ),
            ],
            menuActions: [
              (
                icon: const Icon(Icons.help_outline_rounded),
                label: EsBO.costHelpTitle,
                onTap: () => showCostHelpDialog(context),
              ),
              (
                icon: const Icon(Icons.folder_copy_rounded),
                label: EsBO.calcTemplatesTitle,
                onTap: _showTemplatesSheet,
              ),
              (
                icon: const Icon(Icons.refresh_rounded),
                label: EsBO.calcActionReset,
                onTap: _resetAll,
              ),
              (
                icon: const Icon(Icons.settings_outlined),
                label: EsBO.settingsTitle,
                onTap: () => context.push('/settings/standalone'),
              ),
            ],
            overflowTooltip: EsBO.commonMoreActions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          // stretch: el step bar (Row con Expanded) y la perforacion
          // (CustomPaint de ancho infinito) necesitan ancho acotado.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de pasos: actualiza automaticamente al hacer scroll.
            CalcWizardStepBar(
              labels: [
                EsBO.calcSectionPiece,
                EsBO.calcWizardStepPrint,
                EsBO.calcWizardStepAdjust,
              ],
              current: _step,
              onTapStep: _goStep,
            ),
            const Perforation(),
            // Scroll continuo: las 3 secciones en una sola vista.
            // El ScrollController detecta cual seccion esta visible y
            // actualiza el step bar automaticamente.
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: MaxWidthScrollView(
                    maxWidth: 720,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Membrete fuera de cualquier card: siempre arriba.
                        _buildMembrete(context),
                        const SizedBox(height: AppSpacing.lg),

                        // Seccion 1: Pieza
                        _buildScrollSection(
                          key: _section1Key,
                          sectionIndex: 0,
                          theme: theme,
                          cs: cs,
                          child: state.mode == CalculatorMode.express
                              ? _buildStepPieceExpress(state, notifier, currency)
                              : _buildStepAdvancedMaterials(state, notifier),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Seccion 2: Impresion
                        _buildScrollSection(
                          key: _section2Key,
                          sectionIndex: 1,
                          theme: theme,
                          cs: cs,
                          child: _buildStepPrint(notifier),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Seccion 3: Ajustes
                        _buildScrollSection(
                          key: _section3Key,
                          sectionIndex: 2,
                          theme: theme,
                          cs: cs,
                          child: _buildStepAdjust(notifier, currency),
                        ),
                        // Padding inferior para que el ultimo paso no quede
                        // tapado por la bottom bar.
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Barra INFERIOR simplificada: solo el total / hint de validacion.
      // El footer de navegacion (atras/adelante) se elimina porque la
      // navegacion ahora es por scroll continuo.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.showsBatchLine && totalText != null) ...[
              BatchLines(state: state, currency: currency),
              const Perforation(),
            ],
            ResultBottomBar(
              totalText: totalText ?? 'â€”',
              hasDiscount:
                  state.output != null &&
                  (state.output!.discountAmount > Decimal.zero ||
                      state.showsBatchLine),
              emptyHint: state.isValid
                  ? null
                  : _buildEmptyHint(state.missingRequiredFields),
              onTap: _openResultSheet,
            ),
          ],
        ),
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
    final connector = EsBO.calcEmptyHintConnector;
    final joined = parts.length == 1
        ? parts.first
        : parts.length == 2
        ? '${parts[0]} $connector ${parts[1]}'
        : '${parts.sublist(0, parts.length - 1).join(', ')} '
              '$connector ${parts.last}';
    return '${EsBO.calcEmptyHintPrefix} $joined '
        '${EsBO.calcEmptyHintSuffix}.';
  }

  // ============================================================
  // WIZARD STEPS (scroll continuo 2026-09)
  // ============================================================

  /// Seccion del scroll continuo: hoja de plano sin header duplicado.
  /// El step bar ya muestra el nombre de la seccion. Esta wrapper solo
  /// provee el paper sheet.
  Widget _buildScrollSection({
    Key? key,
    required int sectionIndex,
    required ThemeData theme,
    required ColorScheme cs,
    required Widget child,
  }) {
    return _paperSheet(
      key: key,
      child: child,
    );
  }

  /// PASO 1 (Express): Pieza â€” nombre opcional + peso (hero) + filamento.
  /// Mantiene la regla del 95%: los 3 inputs clave van en esta primera
  /// pantalla, sin scrollear.
  Widget _buildStepPieceExpress(
    CalculatorState state,
    CalculatorNotifier notifier,
    WorldCurrency currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode selector compacto (alineado a la derecha)
        Align(
          alignment: Alignment.centerRight,
          child: ModeSelector(mode: state.mode, onChanged: _switchMode),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Pieza: nombre + peso + filamento
        RubricSection(
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
              // Peso â€” campo hero (grande, clave)
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
              ExpressFilamentRow(
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
      ],
    );
  }

  /// PASO 2 (comun): Impresion â€” tiempo (horas+minutos) + impresora activa.
  Widget _buildStepPrint(CalculatorNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // â”€â”€ Tiempo de impresión â”€â”€
        RubricSection(
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
        const SizedBox(height: AppSpacing.xl),

        // â”€â”€ Impresora â”€â”€
        RubricSection(
          icon: MdiIcons.printer3d,
          title: EsBO.calcSectionPrinter,
                    child: const PrinterIndicator(),
        ),
      ],
    );
  }

  /// PASO 3 (comun): Otros â€” cantidad (Pro) + descuento + OTROS/costos de
  /// la pieza (Pro). El descuento subio desde el result sheet al form:
  /// ahora es un campo de primer nivel del wizard.
  Widget _buildStepAdjust(CalculatorNotifier notifier, WorldCurrency currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // â”€â”€ Cantidad (Pro) â”€â”€
        _buildQuantitySection(notifier),
        const SizedBox(height: AppSpacing.xl),

        // â”€â”€ Descuento â”€â”€
        RubricSection(
          icon: Icons.percent_rounded,
          title: EsBO.calcSectionDiscount,
          child: NumericInputField(
            label: EsBO.calcLabelDiscount,
            controller: _discountCtrl,
            onChanged: notifier.setDiscountPct,
            suffix: '%',
            helperText: EsBO.calcLabelDiscountHelper,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // â”€â”€ OTROS (con peek preview) â”€â”€
        _buildOtrosSection(notifier, currency),
      ],
    );
  }

  // ============================================================
  // ADVANCED MATERIALS STEP (paso 1 del modo multi-material)
  // ============================================================

  Widget _buildStepAdvancedMaterials(
    CalculatorState state,
    CalculatorNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode selector compacto
        Align(
          alignment: Alignment.centerRight,
          child: ModeSelector(mode: state.mode, onChanged: _switchMode),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Pieza: nombre opcional
        RubricSection(
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
        const SizedBox(height: AppSpacing.xl),

        // Materiales (multi-material, agregable)
        RubricSection(
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
                    child: MaterialRowTile(
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
      ],
    );
  }

  // ============================================================
  // OTROS SECTION â€” collapsable card
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
          title: EsBO.calcSectionPieceCosts,
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
        if (!_showOtros) OtrosPeekPreview(locked: showProBadge),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showOtros
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    children: [
                      // Fila 1: Mano de obra + Post-procesado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: AppSpacing.sm),
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
                      // Fila 2: Falla + Desperdicio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: AppSpacing.sm),
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

  // ============================================================
  // QUANTITY SECTION â€” Pro-gated
  // ============================================================

  /// Seccion de cantidad de unidades (Pro). Muestra +/- y campo de texto.
  /// Free ve el ProBadge; al tocar se redirige al paywall.
  /// Al lado del titulo muestra un icono de info con los escalones configurados.
  Widget _buildQuantitySection(CalculatorNotifier notifier) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPro = ref.watch(isProProvider);
    final entitlementState = ref.watch(entitlementNotifierProvider);
    final isLoading = entitlementState.isLoading;
    final showProBadge = !isPro && !isLoading;
    final quantity = ref.watch(calculatorNotifierProvider).quantity;

    // Escalón aplicado (feature A): hint "X % desde N u." bajo el campo.
    final batchPct = ref.watch(
      calculatorNotifierProvider.select((s) => s.batchAppliedPercent),
    );
    final batchMinQty = ref.watch(
      calculatorNotifierProvider.select((s) => s.batchAppliedMinQty),
    );
    final showBatchHint = quantity > 1 && batchPct != null;
    final hintPct = pctInt(batchPct);
    final hintMinQty = batchMinQty ?? 0;

    // Escalones configurados en Settings (para el tooltip informativo).
    final tiersAsync = ref.watch(discountTiersProvider);
    final tiers = tiersAsync.value ?? const <DiscountTier>[];
    final hasTiers = tiers.isNotEmpty;

    // Sincronizar el controller cuando cambia quantity desde +/-
    if (_quantityCtrl.text != '$quantity') {
      _quantityCtrl.text = '$quantity';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.layers_rounded,
          title: EsBO.resultQuantityLabel,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProBadge) const ProBadge(),
              const SizedBox(width: AppSpacing.xs),
              // Icono de info: muestra los escalones al tocar (siempre visible).
              Tooltip(
                message: _buildTiersTooltip(tiers),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasTiers
                        ? cs.primaryContainer.withValues(alpha: 0.5)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: hasTiers ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.remove_rounded),
              onPressed: quantity > 1
                  ? () {
                      if (!isPro) {
                        context.push('/paywall');
                      } else {
                        notifier.setQuantity(quantity - 1);
                      }
                    }
                  : null,
            ),
            SizedBox(
              width: 64,
              child: TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTheme.num(
                  theme.textTheme.titleMedium ?? const TextStyle(),
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (!isPro) {
                    context.push('/paywall');
                    return;
                  }
                  final parsed = int.tryParse(val) ?? 1;
                  final clamped = parsed.clamp(1, kMaxQuantity);
                  notifier.setQuantity(clamped);
                },
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                if (!isPro) {
                  context.push('/paywall');
                } else {
                  notifier.setQuantity(quantity + 1);
                }
              },
            ),
          ],
        ),
        // Hint del escalón aplicado (feature A â€” Hito 1): informa el umbral
        // activo del descuento mayorista, p.ej. "10 % desde 10 u.".
        if (showBatchHint) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.percent_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                EsBO.calcQuantityBatchHint(hintPct, hintMinQty),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Construye el texto del tooltip de escalones de descuento.
  /// Lista los escalones configurados en Settings: "10% desde 5 u.\n15% desde 10 u."
  String _buildTiersTooltip(List<DiscountTier> tiers) {
    if (tiers.isEmpty) return EsBO.calcQuantityNoTiers;
    final buffer = StringBuffer(EsBO.calcQuantityTiersTitle);
    for (final tier in tiers) {
      buffer.writeln(
        '${pctInt(tier.percent)}% ${EsBO.calcQuantityFrom} ${tier.minQty} ${EsBO.calcQuantityUnits}',
      );
    }
    return buffer.toString().trimRight();
  }

  /// Hoja de plano: superficie que sostiene las rubric.
  Widget _paperSheet({Key? key, required Widget child}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      key: key,
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





