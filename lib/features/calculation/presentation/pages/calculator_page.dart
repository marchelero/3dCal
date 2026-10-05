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
import '../../data/calculation_repository.dart'
    show CalculationRepository, DraftMaterialInput;
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/calculator_bottom_bar.dart';
import '../widgets/calculator_wizard.dart';
import '../widgets/cost_help_dialog.dart';
import '../widgets/costos_adicionales_panel.dart';
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
/// 3. Ajustes: cantidad (Pro) + descuento + "Costos de la pieza" (Pro, los 5 campos).
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
  const CalculatorPage({
    super.key,
    this.prefillCalc,
    this.newMode = false,
    this.editMode = false,
  });

  /// Cotizacion guardada para precargar ("Reusar"). Si es null, la pagina
  /// restaura el draft de la sesion anterior (comportamiento normal).
  final Calculation? prefillCalc;

  /// Cuando true, abre con formulario vacío y descarta el draft local.
  final bool newMode;

  /// Cuando true, [prefillCalc] se abre para EDITAR: al guardar se
  /// actualiza esa misma fila (mismo id/fecha/estado de venta) en vez de
  /// crear una cotizacion nueva.
  ///
  /// El modo vive en la pagina, no en el notifier global: asi cada apertura
  /// decide su propio modo y no queda un flag pegajoso de "estoy editando"
  /// si el usuario mas adelante abre una cotizacion nueva.
  final bool editMode;

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

  // Controllers de la seccion "Costos de la pieza". Las tasas de mano de obra
  // y post-proceso que vivian aqui se fueron en v17: quedaron absorbidas por
  // los campos "Modelado y diseño" y "Postprocesado" (switch % / fijo).
  late final TextEditingController _extraFailureRateCtrl;
  late final TextEditingController _extraMarkupOnMaterialsCtrl;

  // === v17: Costos de la pieza — controllers para los 3 campos de servicio
  // (Modelado, Postprocesado, Extras) + el description TextField de Extras.
  // Cada uno sobrevive a rebuilds via State del padre; el panel
  // `CostosAdicionalesPanel` los lee via `ref.read(...)`.
  late final TextEditingController _modelingCtrl;
  late final TextEditingController _postprocCtrl;
  late final TextEditingController _extraCostCtrl;
  late final TextEditingController _extraCostLabelCtrl;

  // Quantity controller.
  late final TextEditingController _quantityCtrl;

  // Advanced controllers.
  final List<MaterialCtrls> _materialCtrls = [];
  final _advancedListKey = GlobalKey<AnimatedListState>();

  /// Paso visible del wizard (0-based). Estado efimero de UI: setState es
  /// el mecanismo permitido (no se persiste ni se comparte).
  int _step = 0;

  /// Total de pasos del wizard.
  static const int _kStepCount = 3;

  /// Si `true`, los campos requeridos muestran error visual (border rojo).
  /// Se activa al tocar la barra inferior con form invalido.
  bool _showValidationErrors = false;

  /// Repo cacheado para persistir el parcial en [dispose] (donde `ref` ya no
  /// es usable). Se captura al montar.
  CalculationRepository? _cachedRepo;

  /// Ultimo state del form visto. Fuente para persistir el parcial en
  /// [dispose] sin `ref`. Se actualiza en cada build.
  CalculatorState? _cachedState;

  /// Ultimo id de parcial activo visto. Con el se hace upsert en [dispose].
  int? _cachedPartialId;

  /// True una vez que el usuario guardo la cotizacion como definitiva
  /// (boton Guardar). A partir de ahi el autoguardado rapido NO debe correr:
  /// recrearia un borrador huerfano que el historial mostraria como "Borrador"
  /// ademas de la cotizacion real.
  bool _savedDefinitive = false;

  /// True mientras la pagina restaura estado async (prefill de "Reusar"/
  /// "Editar", draft de sesion o defaults del catalogo). Evita que el form
  /// se muestre vacio por un instante antes de que aparezcan los valores.
  bool _isRestoring = true;

  /// True una vez que se persistio el parcial al salir (X/back/dispose).
  /// Evita que las multiples invocaciones de [_persistPartialSync] durante un
  /// mismo pop guarden dos veces (la segunda, sin `ref`, con datos viejos).
  bool _partialPersisted = false;

  /// Habilita el pop programaticamente (tras guardar) para que [PopScope] con
  /// `canPop: false` no vuelva a interceptarlo (evita el bucle pop).
  bool _allowPop = false;

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
    // Cachear el repo mientras `ref` es valido (dispose no puede leerlo).
    _cachedRepo = ref.read(calculationRepositoryProvider);
    final initial = ref.read(calculatorNotifierProvider);
    _weightCtrl = TextEditingController(text: initial.weight);
    _hoursCtrl = TextEditingController(text: initial.printHours);
    _minutesCtrl = TextEditingController(text: initial.printMinutes);
    _discountCtrl = TextEditingController(text: initial.discountPct);
    _priceCtrl = TextEditingController(text: initial.filamentPrice);
    _gramsCtrl = TextEditingController(text: initial.filamentGrams);
    _labelCtrl = TextEditingController(text: initial.filamentLabel);
    _pieceLabelCtrl = TextEditingController(text: initial.label);
    _extraFailureRateCtrl = TextEditingController(
      text: initial.extraFailureRate,
    );
    _extraMarkupOnMaterialsCtrl = TextEditingController(
      text: initial.extraMarkupOnMaterials,
    );
    _modelingCtrl = TextEditingController(text: initial.modelingValue);
    _postprocCtrl = TextEditingController(text: initial.postprocValue);
    _extraCostCtrl = TextEditingController(text: initial.extraCostValue);
    _extraCostLabelCtrl = TextEditingController(text: initial.extraCostLabel);
    _quantityCtrl = TextEditingController(text: '${initial.quantity}');

    for (final c in [
      _weightCtrl,
      _hoursCtrl,
      _minutesCtrl,
      _discountCtrl,
      _priceCtrl,
      _gramsCtrl,
      _extraFailureRateCtrl,
      _extraMarkupOnMaterialsCtrl,
      _modelingCtrl,
      _postprocCtrl,
      _extraCostCtrl,
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
    _extraCostLabelCtrl.addListener(() {
      // Description libre: NO triggerea recompute (solo etiqueta, no cambia
      // el calculo). Se persiste en el state, pero el listener no se mete en
      // _onAnyFieldChange para evitar saltos del recompute por cada keystroke
      // de descripcion.
      ref
          .read(calculatorNotifierProvider.notifier)
          .setExtraCostLabel(_extraCostLabelCtrl.text);
    });

    if (initial.mode == CalculatorMode.advanced) {
      for (final m in initial.materials) {
        _materialCtrls.add(MaterialCtrls.fromRow(m));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
      // Bug fix: "Nueva cotización" debe abrir vacío, no continuar draft.
      if (widget.newMode) {
        await ref.read(draftStorageProvider).clear();
        if (!mounted) return;
        // Refrescar el banner "Continuar" en Home: draftStatusProvider
        // (draft de sesion en SharedPreferences) no es reactivo y se
        // invalida a mano. latestPartialProvider ya es StreamProvider y se
        // actualiza solo con cada escritura a la tabla.
        ref.invalidate(draftStatusProvider);
        // Nueva cotizacion: soltar el puntero al parcial anterior. El
        // borrador viejo queda en el historial (retomable), pero esta sesion
        // arranca con identidad nueva.
        ref.read(currentPartialIdProvider.notifier).state = null;
        ref.read(calculatorNotifierProvider.notifier).reset();
        // Limpiar controllers — se inicializaron con valores del draft
        // antes de este callback (initState los crea con initial.*).
        _weightCtrl.text = '';
        _hoursCtrl.text = '';
        _minutesCtrl.text = '';
        _priceCtrl.text = '';
        _gramsCtrl.text = '';
        _discountCtrl.text = '0';
        _labelCtrl.text = '';
        _pieceLabelCtrl.text = '';
        _extraFailureRateCtrl.text = '';
        _extraMarkupOnMaterialsCtrl.text = '';
        _modelingCtrl.text = '';
        _postprocCtrl.text = '';
        _extraCostCtrl.text = '';
        _extraCostLabelCtrl.text = '';
        _quantityCtrl.text = '1';
        return;
      }
      // Prefill ("Reusar"): cargar la cotizacion guardada y sincronizar los
      // controllers. NO tocar reset/draft/defaults — el state precargado es
      // la fuente de verdad. Un solo post-frame (esta pagina) evita la race
      // que antes pisaba el prefill con reset()/draft.
      if (widget.prefillCalc != null) {
        final notifier = ref.read(calculatorNotifierProvider.notifier);
        await notifier.loadFromCalculation(widget.prefillCalc!);
        if (!mounted) return;
        // El prefill arranca una cotizacion NUEVA en el formulario: soltar el
        // puntero al parcial anterior. "Reusar" crea un id nuevo (el autosave
        // inserta un parcial nuevo); "Editar" guarda sobre prefillCalc.id.
        ref.read(currentPartialIdProvider.notifier).state = null;
        // Garantiza el total calculado ni bien se entra (Editar/Reusar), sin
        // esperar a que el usuario toque un campo.
        notifier.recompute();
        if (!mounted) return;
        _syncControllersFromState(ref.read(calculatorNotifierProvider));
        _rebuildAdvancedRows();
        _syncGlobalTimeFields(ref.read(calculatorNotifierProvider));
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
        _syncGlobalTimeFields(ref.read(calculatorNotifierProvider));
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
      _extraFailureRateCtrl.text = '';
      _extraMarkupOnMaterialsCtrl.text = '';
      _modelingCtrl.text = '';
      _postprocCtrl.text = '';
      _extraCostCtrl.text = '';
      _extraCostLabelCtrl.text = '';
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
      } finally {
        // Terminar el loader de restauracion pase lo que pase (cualquier
        // rama: prefill, draft, nueva o vacio).
        if (mounted && _isRestoring) {
          setState(() => _isRestoring = false);
        }
      }
    });
  }

  Timer? _saveTimer;
  Timer? _partialSaveTimer;

  /// Sincroniza los 11 controllers desde el state restaurado.
  /// Fuente unica de verdad: el CalculatorState del notifier (evita
  /// desync si el draft y el state divergen tras el restore).
  void _syncControllersFromState(CalculatorState s) {
    // Solo sobreescribir si el state tiene valor (no vacío). Evita que un
    // state temporal (post-reset, pre-restore) borre los controllers que
    // ya tienen datos del draft.
    if (s.weight.isNotEmpty) _weightCtrl.text = s.weight;
    if (s.printHours.isNotEmpty) _hoursCtrl.text = s.printHours;
    if (s.printMinutes.isNotEmpty) _minutesCtrl.text = s.printMinutes;
    _discountCtrl.text = s.discountPct;
    if (s.filamentPrice.isNotEmpty) _priceCtrl.text = s.filamentPrice;
    if (s.filamentGrams.isNotEmpty) _gramsCtrl.text = s.filamentGrams;
    if (s.filamentLabel.isNotEmpty) _labelCtrl.text = s.filamentLabel;
    if (s.label.isNotEmpty) _pieceLabelCtrl.text = s.label;
    if (s.extraFailureRate.isNotEmpty) {
      _extraFailureRateCtrl.text = s.extraFailureRate;
    }
    if (s.extraMarkupOnMaterials.isNotEmpty) {
      _extraMarkupOnMaterialsCtrl.text = s.extraMarkupOnMaterials;
    }
    // v17: sincronizar los 4 controllers del panel Costos adicionales.
    // Sin esta linea, recargar una cotizacion guardada dejaria los
    // TextFields mostrando el valor viejo.
    if (s.modelingValue.isNotEmpty) {
      _modelingCtrl.text = s.modelingValue;
    }
    if (s.postprocValue.isNotEmpty) {
      _postprocCtrl.text = s.postprocValue;
    }
    if (s.extraCostValue.isNotEmpty) {
      _extraCostCtrl.text = s.extraCostValue;
    }
    if (s.extraCostLabel.isNotEmpty) {
      _extraCostLabelCtrl.text = s.extraCostLabel;
    }
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
    // Hay cambios nuevos: habilitar de nuevo el guardado de salida (por si un
    // intento de pop previo no llego a cerrar la pagina).
    _partialPersisted = false;
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  /// Construye el draft de sesion desde los controllers + el state actual.
  ///
  /// Incluye `isAdvanced` y `materials` para que una cotizacion Advanced se
  /// restaure completa (filas de material + tiempo propio por material).
  /// Antes solo se guardaban los campos escalares, lo que hacia que un draft
  /// Advanced volviera como Express sin materiales.
  CalculationDraft _buildSessionDraft() {
    final s = ref.read(calculatorNotifierProvider);
    return CalculationDraft(
      isAdvanced: s.mode == CalculatorMode.advanced,
      materials: s.materials
          .map(
            (m) => MaterialDraft(
              label: m.label,
              weight: m.weight,
              pricePerBobbin: m.pricePerBobbin,
              gramsPerBobbin: m.gramsPerBobbin,
              useOwnTime: m.useOwnTime,
              materialHours: m.materialHours,
              materialMinutes: m.materialMinutes,
            ),
          )
          .toList(),
      weight: _weightCtrl.text,
      printHours: _hoursCtrl.text,
      printMinutes: _minutesCtrl.text,
      discountPct: _discountCtrl.text,
      filamentPrice: _priceCtrl.text,
      filamentGrams: _gramsCtrl.text,
      label: _pieceLabelCtrl.text,
      filamentLabel: _labelCtrl.text,
      extraLaborRate: s.extraLaborRate,
      extraPostProcessRate: s.extraPostProcessRate,
      extraFailureRate: _extraFailureRateCtrl.text,
      extraMarkupOnMaterials: _extraMarkupOnMaterialsCtrl.text,
      // v17: modo + valor de los 3 costos de servicio, para que el draft de
      // sesion los restaure tal cual (el switch incluido). El input acepta
      // coma decimal, asi que se normaliza antes de parsear.
      modelingMode: s.modelingMode,
      modelingValue: _draftDouble(_modelingCtrl.text),
      postprocMode: s.postprocMode,
      postprocValue: _draftDouble(_postprocCtrl.text),
      extraCostMode: s.extraCostMode,
      extraCostValue: _draftDouble(_extraCostCtrl.text),
      extraCostLabel: _extraCostLabelCtrl.text,
    );
  }

  /// Texto de un input numerico -> REAL para el draft. Acepta coma o punto
  /// decimal; texto vacio o invalido -> 0.
  static double _draftDouble(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  /// True si el form no tiene nada que preservar. En Advanced basta con que
  /// haya al menos un material (aunque no tenga horas globales).
  bool get _formIsEmpty {
    final s = ref.read(calculatorNotifierProvider);
    if (s.mode == CalculatorMode.advanced && s.materials.isNotEmpty) {
      return false;
    }
    return _weightCtrl.text.isEmpty &&
        _hoursCtrl.text.isEmpty &&
        _minutesCtrl.text.isEmpty &&
        _priceCtrl.text.isEmpty &&
        _gramsCtrl.text.isEmpty;
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    await ref.read(draftStorageProvider).save(_buildSessionDraft());
  }

  /// Guardado síncrono del draft para dispose(). Solo guarda si el form
  /// tiene contenido (evita que dispose re-guarde un draft que "Nueva
  /// cotización" acaba de borrar — el dispose del widget viejo se ejecuta
  /// DESPUÉS del clear del widget nuevo).
  void _saveDraftSync() {
    try {
      // No guardar si el form está vacío (nueva cotización o reset).
      if (_formIsEmpty) return;
      ref
          .read(sharedPreferencesProvider)
          .setString('form_draft', _buildSessionDraft().encode());
    } catch (_) {
      // Silenciar: si falla, el debounce async cubrirá el caso normal.
    }
  }

  /// True cuando se esta editando un BORRADOR existente (no una cotizacion
  /// definitiva).
  ///
  /// Diferencia clave del autoguardado:
  /// - Editar un borrador -> SI autoguarda en ese mismo id (el usuario sigue
  ///   armando la cotizacion; cada cambio debe persistirse en el parcial).
  /// - Editar una cotizacion definitiva -> NO autoguarda como parcial (la fila
  ///   ya es real; se actualiza con Guardar).
  bool get _editingDraft => widget.editMode && (widget.prefillCalc?.isPartial ?? false);

  void _schedulePartialSave() {
    // Editar una cotizacion DEFINITIVA no autoguarda como parcial (crearia un
    // borrador duplicado). Editar un BORRADOR si: hay que reflejar cada cambio.
    if (widget.editMode && !_editingDraft) return;
    // Si ya se guardo como definitiva, no re-crear un borrador.
    if (_savedDefinitive) return;
    _partialSaveTimer?.cancel();
    _partialSaveTimer = Timer(
      const Duration(milliseconds: 1500),
      _persistPartial,
    );
  }

  Future<void> _persistPartial() async {
    if (!mounted) return;
    if ((widget.editMode && !_editingDraft) || _savedDefinitive) return;
    if (_isRestoring) return;
    final state = ref.read(calculatorNotifierProvider);
    if (state.output == null) {
      debugPrint(
        '[PartialSave] skip: output=null (form inválido o recompute falló)',
      );
      return;
    }
    final materials = _partialMaterialInputs(state);
    try {
      final repo = ref.read(calculationRepositoryProvider);
      final companion = CalculatorNotifier.stateToPartialDto(state);
      // Upsert sobre el parcial activo (mismo id) para no crear uno nuevo
      // por cada guardado. Al editar un borrador, el id ES el del prefill
      // (el provider se reseteo al entrar en modo edicion).
      final existingId = _partialTargetId;
      // No sobrescribir un borrador existente con un estado sin materiales.
      if (materials.isEmpty && existingId != null) return;
      final id = await repo.savePartial(
        companion,
        materials: materials,
        existingId: existingId,
      );
      ref.read(currentPartialIdProvider.notifier).state = id;
      // NO se invalida el historial aca: el autoguardado corre cada pocos
      // segundos mientras el usuario tipea, y recargar la lista completa
      // (con `materialLabelsByCalcId`) en cada guardado volvia lenta la app en
      // web. El historial se refresca al volver (autoDispose de sus providers)
      // y en el guardado definitivo / salida.
      debugPrint('[PartialSave] guardado id=$id');
    } catch (e, st) {
      debugPrint('[PartialSave] ERROR: $e\n$st');
    }
  }

  /// Id al que debe apuntar el autoguardado del parcial.
  ///
  /// - Editando un borrador: el id del borrador ([prefillCalc]).
  /// - Caso normal: el parcial activo ([currentPartialIdProvider]).
  int? get _partialTargetId => _editingDraft
      ? widget.prefillCalc!.id
      : ref.read(currentPartialIdProvider);

  /// Persiste el parcial AHORA (fire-and-forget), pensado para ejecutarse
  /// antes de salir de la pagina.
  ///
  /// **Por que existe**: el guardado rapido tiene un debounce de 1.5s. Si el
  /// usuario escribe y sale antes de ese tiempo (patron normal: cotizar, ver
  /// el resultado, volver), [dispose] cancelaba el timer SIN guardar y el
  /// parcial nunca llegaba al historial. Esto lo fuerza en la salida.
  ///
  /// En [dispose] `ref` ya esta invalidado (Riverpod), asi que se usan las
  /// referencias cacheadas ([_cachedRepo] + el state leido en el ultimo
  /// cambio). En la salida via X/back el `ref` todavia vive y se lee fresco.
  /// Devuelve un [Future] que completa cuando el guardado termina, para que
  /// el X pueda **esperar** antes de hacer `pop` (si no, el guardado async se
  /// perdia al desmontarse el arbol).
  Future<void> _persistPartialSync() async {
    // No autoguardar si: se edita una DEFINITIVA (fila real, se persiste con
    // Guardar) o si ya se guardo definitiva (recrearia un borrador huerfano).
    // Editar un BORRADOR si autoguarda (refleja cada cambio).
    if ((widget.editMode && !_editingDraft) || _savedDefinitive) return;
    // No sobrescribir el borrador mientras la restauracion esta en curso: el
    // state todavia no refleja la fila y se guardaria un borrador incompleto
    // (perdiendo materiales/modo ya persistidos).
    if (_isRestoring) return;
    // Una sola vez por salida: X/back y dispose pueden llamar este metodo; la
    // segunda invocacion (dispose, sin `ref`) podia sobrescribir con un state
    // cacheado viejo o crear un borrador duplicado.
    if (_partialPersisted) return;
    _partialPersisted = true;
    CalculationRepository? repo;
    CalculatorState? state;
    int? existingId;
    try {
      state = ref.read(calculatorNotifierProvider);
      repo = ref.read(calculationRepositoryProvider);
      existingId = _partialTargetId;
    } catch (_) {
      // dispose: `ref` invalido. Usar lo cacheado.
      state = _cachedState;
      repo = _cachedRepo;
      existingId = _editingDraft ? widget.prefillCalc!.id : _cachedPartialId;
    }
    if (state == null || repo == null) return;
    await _persistToRepo(repo, state, existingId);
  }

  Future<void> _persistToRepo(
    CalculationRepository repo,
    CalculatorState state,
    int? existingId,
  ) async {
    debugPrint(
      '[PartialSave][toRepo] existingId=$existingId '
      'editingDraft=$_editingDraft output=${state.output != null}',
    );
    if (state.output == null) return;
    final materials = _partialMaterialInputs(state);
    // No sobrescribir un borrador con un estado que no tiene materiales: en
    // Advanced sin materiales validos no hay nada util que persistir y se
    // borrarian los materiales que ya estaban guardados. En Express sin peso
    // pasa lo mismo (la fila quedaria sin su material implicito).
    if (materials.isEmpty && existingId != null) return;
    final companion = CalculatorNotifier.stateToPartialDto(state);
    try {
      final id = await repo.savePartial(
        companion,
        materials: materials,
        existingId: existingId,
      );
      debugPrint('[PartialSave] onExit guardado id=$id');
    } catch (e, st) {
      debugPrint('[PartialSave] onExit ERROR: $e\n$st');
    }
  }

  /// Convierte los materiales del state a filas para la tabla de materiales.
  ///
  /// Sin esto, un parcial guardado en Advanced se reusaba SIN materiales:
  /// `savePartial` solo escribia la fila de `calculations`.
  ///
  /// **Express**: no hay filas de material, pero el formulario SI tiene un
  /// material (peso + precio + gramos). Se persiste ese material "implicito"
  /// para que "Reusar"/detalle recuperen el peso y el filamento: la lista de
  /// materiales es la unica fuente para reconstruir esos campos (las columnas
  /// de `calculations` no guardan el peso ni el precio por bobina).
  ///
  /// El desglose de tiempo por material se persiste desde schema v15
  /// (`useOwnTime` / `materialHours` / `materialMinutes`).
  List<DraftMaterialInput> _partialMaterialInputs(CalculatorState state) {
    debugPrint(
      '[PartialSave][mats] mode=${state.mode} '
      'stateMats=${state.materials.length} ctrlMats=${_materialCtrls.length} '
      'weight=${state.weight}',
    );
    if (state.mode != CalculatorMode.advanced) {
      final weight = CalculatorState.parseDecimal(state.weight);
      final price = CalculatorState.parseDecimal(state.filamentPrice);
      final grams = CalculatorState.parseDecimal(state.filamentGrams);
      if (weight == null || weight <= Decimal.zero) return const [];
      return [
        DraftMaterialInput(
          label: state.filamentLabel.isNotEmpty
              ? state.filamentLabel
              : 'Filamento',
          weightGrams: weight.toDouble(),
          pricePerBobbin: (price ?? Decimal.zero).toDouble(),
          gramsPerBobbin: (grams ?? Decimal.fromInt(1000)).toDouble(),
        ),
      ];
    }
    return state.materials
        .map(
          (m) => DraftMaterialInput(
            label: m.label,
            weightGrams:
                (CalculatorState.parseDecimal(m.weight) ?? Decimal.zero)
                    .toDouble(),
            pricePerBobbin:
                (CalculatorState.parseDecimal(m.pricePerBobbin) ?? Decimal.zero)
                    .toDouble(),
            gramsPerBobbin:
                (CalculatorState.parseDecimal(m.gramsPerBobbin) ?? Decimal.zero)
                    .toDouble(),
            useOwnTime: m.useOwnTime,
            materialHours: m.ownTimeHoursDecimal?.toDouble(),
            materialMinutes: m.ownTimeMinutesDecimal?.toDouble(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    // Guardar draft de forma síncrona ANTES de dispose. Si el usuario sale
    // rápido, el debounce de 500ms no tuvo tiempo de disparar y el banner
    // "Continuar" no aparecería. SharedPreferences.write es suficientemente
    // rápido para dispose (microseconds en web, <1ms en mobile).
    _saveDraftSync();
    // Forzar el guardado rapido pendiente ANTES de cancelar el timer: si el
    // usuario salio dentro de la ventana de debounce (1.5s), el parcial nunca
    // se persistia y no aparecia en el historial. El X/back ya lo guardan con
    // await; `_partialPersisted` evita el doble guardado.
    _persistPartialSync();
    _saveTimer?.cancel();
    _partialSaveTimer?.cancel();
    // NO invalidar el historial desde dispose: hacerlo puede dejar la lista en
    // `loading` perpetuo si el provider se reconstruye durante el desmontaje
    // (el skeleton anima sin fin -> CanvasKit reintenta shaders en bucle y la
    // app se pone lenta). El X y el back ya invalidan ANTES del pop.
    // NO limpiar `currentPartialIdProvider` aca: el parcial sigue en la DB y
    // ese provider es el vinculo entre el borrador y la proxima sesion. Si se
    // limpiaba al salir, al volver el guardado definitivo no sabia cual
    // parcial convertir, creaba una fila nueva y dejaba el borrador huerfano
    // (aparecia en el historial como "Borrador" junto a la cotizacion real).
    // Se limpia en los casos correctos: "Nueva cotizacion" (newMode) y
    // prefill ("Reusar"/"Editar"), y tras un guardado definitivo.
    _scrollCtrl.dispose();
    _weightCtrl.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    _discountCtrl.dispose();
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    _labelCtrl.dispose();
    _pieceLabelCtrl.dispose();
    _extraFailureRateCtrl.dispose();
    _extraMarkupOnMaterialsCtrl.dispose();
    _modelingCtrl.dispose();
    _postprocCtrl.dispose();
    _extraCostCtrl.dispose();
    _extraCostLabelCtrl.dispose();
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
      // Heredar el material Express (peso + filamento + precio/gramos) a la
      // primera fila Advanced: pasar a multi-material no debe perder lo que el
      // usuario ya habia cargado.
      final prev = ref.read(calculatorNotifierProvider);
      notifier.addMaterial();
      _materialCtrls.add(
        MaterialCtrls(
          label: TextEditingController(text: prev.filamentLabel),
          weight: TextEditingController(text: prev.weight),
          price: TextEditingController(text: prev.filamentPrice),
          grams: TextEditingController(text: prev.filamentGrams),
          materialHours: TextEditingController(),
          materialMinutes: TextEditingController(),
        ),
      );
      // Reflejar el material heredado en el state.
      notifier.updateMaterial(
        0,
        label: prev.filamentLabel,
        weight: prev.weight,
        pricePerBobbin: prev.filamentPrice,
        gramsPerBobbin: prev.filamentGrams,
      );
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
    // La lista de materiales vive fuera del draft solo si se persiste: sin
    // esto, "Continuar" vuelva con los materiales previos.
    _onAnyFieldChange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _advancedListKey.currentState?.insertItem(newIndex);
    });
  }

  void _removeMaterial(int index) {
    ref.read(calculatorNotifierProvider.notifier).removeMaterial(index);
    if (index < 0 || index >= _materialCtrls.length) return;
    final removed = _materialCtrls.removeAt(index);
    // Si se elimino el ultimo material con tiempo propio, el campo global
    // vuelve a mostrar el tiempo global guardado.
    _syncGlobalTimeFields(ref.read(calculatorNotifierProvider));
    _onAnyFieldChange();
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

  /// Escribe en los controllers de "Tiempo de impresión" lo que el usuario
  /// debe ver:
  /// - Si algun material tiene tiempo propio → la **suma** de esos tiempos
  ///   (los fields siguen siendo editables; editarlos apaga los switches).
  /// - Si ningun material tiene tiempo propio → el tiempo global del state.
  ///
  /// Es la contraparte visual de [CalculatorState.totalHoursDecimal], que
  /// aplica la misma precedencia. Mantiene el form y el state alineados.
  void _syncGlobalTimeFields(CalculatorState s) {
    String h;
    String m;
    // Minutos enteros (no `materialsOwnTimeDecimal * 60`): evita perder 1 min
    // por truncamiento decimal (3h04m + 3h06m = 370 min, no 369).
    final mins = s.totalMinutes;
    if (s.anyMaterialOwnTime && mins != null) {
      h = (mins ~/ 60).toString();
      final mm = mins % 60;
      m = mm == 0 ? '' : mm.toString();
    } else {
      h = s.printHours;
      m = s.printMinutes;
    }
    if (_hoursCtrl.text != h) _hoursCtrl.text = h;
    if (_minutesCtrl.text != m) _minutesCtrl.text = m;
  }

  /// Toggle del switch "Tiempo propio" de un material (Advanced).
  ///
  /// No se apaga el tiempo global al activar: ese campo pasa a mostrar la
  /// suma de los tiempos propios (ver [_syncGlobalTimeFields]). Al desactivar
  /// el ultimo switch, el campo vuelve a mostrar el tiempo global guardado.
  void _onMaterialTimeToggle(int index, bool value) {
    if (index < 0 || index >= _materialCtrls.length) return;
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final ctrls = _materialCtrls[index];

    if (value) {
      // Heredar el tiempo global visible la primera vez, para no obligar a
      // reescribir un numero que el usuario ya habia puesto.
      if (ctrls.materialHours.text.isEmpty &&
          ctrls.materialMinutes.text.isEmpty &&
          !ref.read(calculatorNotifierProvider).anyMaterialOwnTime) {
        ctrls.materialHours.text = _hoursCtrl.text;
        ctrls.materialMinutes.text = _minutesCtrl.text;
      }
    } else {
      ctrls.materialHours.text = '';
      ctrls.materialMinutes.text = '';
    }

    notifier.updateMaterial(
      index,
      useOwnTime: value,
      materialHours: ctrls.materialHours.text,
      materialMinutes: ctrls.materialMinutes.text,
    );
    _syncGlobalTimeFields(ref.read(calculatorNotifierProvider));
    _onAnyFieldChange();
    if (mounted) setState(() {});
  }

  /// Limpia el tiempo propio de todos los materiales. Se invoca cuando el
  /// usuario edita el tiempo global: la Exclusion es mutua, asi que escribir
  /// en el global apaga los switches individuales.
  void _clearMaterialOwnTimes() {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final materials = List<MaterialRow>.from(
      ref.read(calculatorNotifierProvider).materials,
    );
    var changed = false;
    for (var i = 0; i < materials.length; i++) {
      if (!materials[i].useOwnTime) continue;
      if (i < _materialCtrls.length) {
        _materialCtrls[i].materialHours.text = '';
        _materialCtrls[i].materialMinutes.text = '';
      }
      notifier.updateMaterial(
        i,
        useOwnTime: false,
        materialHours: '',
        materialMinutes: '',
      );
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  /// Wrapper de horas globales: desactiva los tiempos propios al escribir.
  void _onGlobalHoursChanged(String value) {
    if (value.trim().isNotEmpty) _clearMaterialOwnTimes();
    ref.read(calculatorNotifierProvider.notifier).setPrintHours(value);
  }

  /// Wrapper de minutos globales: desactiva los tiempos propios al escribir.
  void _onGlobalMinutesChanged(String value) {
    if (value.trim().isNotEmpty) _clearMaterialOwnTimes();
    ref.read(calculatorNotifierProvider.notifier).setPrintMinutes(value);
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
    _extraFailureRateCtrl.text = '';
    _extraMarkupOnMaterialsCtrl.text = '';
    _modelingCtrl.text = '';
    _postprocCtrl.text = '';
    _extraCostCtrl.text = '';
    _extraCostLabelCtrl.text = '';
    for (final c in _materialCtrls) {
      c.dispose();
    }
    _materialCtrls.clear();
    // Borrar parcial existente (T6).
    final partialId = ref.read(currentPartialIdProvider);
    if (partialId != null) {
      ref.read(calculationRepositoryProvider).deletePartial(partialId);
      ref.read(currentPartialIdProvider.notifier).state = null;
    }
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
      builder: (sheetCtx) => SaveSheet(
        recentClients: recentClients,
        // Editar una cotizacion existente: precargar cliente/notas/condiciones
        // para no dejar el form vacio ni perder el cliente al re-guardar.
        initialClientName: widget.prefillCalc?.clientName,
        initialNotes: widget.prefillCalc?.notes,
        initialConditions: widget.prefillCalc?.conditions,
      ),
    );
    if (result == null || !mounted) return;
    // Editar DEFINITIVA (fila real ya guardada) vs editar BORRADOR (aun no
    // es cotizacion). El segundo debe convertirse en definitiva al guardar.
    final isEditing = widget.editMode && widget.prefillCalc != null;
    final partialId = ref.read(currentPartialIdProvider);
    final targetId = isEditing ? widget.prefillCalc!.id : partialId;
    // Se guarda como definitiva siempre que NO se edite una cotizacion ya
    // definitiva: cubre el caso normal (parcial activo) y el de editar un
    // borrador. Editar una definitiva conserva su estado.
    final convertsToDefinitive = isEditing
        ? (widget.prefillCalc!.isPartial)
        : (partialId != null);
    try {
      final notifier = ref.read(calculatorNotifierProvider.notifier);

      // 1) Guardar en el historial. Con targetId actualiza esa fila; con
      //    markDefinitive la convierte en cotizacion definitiva.
      final id = await notifier.save(
        clientName: result.clientName,
        notes: result.notes,
        conditions: result.conditions,
        pieceImageBytes: pieceImageBytes,
        updateId: targetId,
        markDefinitive: convertsToDefinitive,
      );
      if (id == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.calcSaveFailed));
        return;
      }
      // Guardado definitivo: apagar el autoguardado rapido para que no
      // re-cree un borrador al salir.
      _savedDefinitive = true;
      _partialSaveTimer?.cancel();
      // La fila ya es definitiva: soltar el puntero al parcial.
      if (convertsToDefinitive) {
        ref.read(currentPartialIdProvider.notifier).state = null;
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
      //    draft vacío. Tambien cancelamos el timer del guardado rapido: si
      //    quedaba pendiente, podia re-crear un parcial (y confundir el
      //    historial) despues de que el guardado real ya limpio el form.
      await ref.read(draftStorageProvider).clear();
      _saveTimer?.cancel();
      _partialSaveTimer?.cancel();
      _resetAll();
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar.success(
            isEditing
                ? ref.read(localeStringsProvider).calcEditSavedWithId(id)
                : EsBO.calcSavedWithId(id),
            actionLabel: EsBO.calcSavedViewAction,
            onAction: () async {
              if (!mounted) return;
              final calc = await ref
                  .read(calculationRepositoryProvider)
                  .getById(id);
              if (!mounted || calc == null) return;
              unawaited(context.push('/history/$id', extra: calc));
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
        onVariantChanged: (variant) => ref
            .read(calculatorNotifierProvider.notifier)
            .setReportVariant(variant),
        onDiscountChanged: (value) {
          ref.read(calculatorNotifierProvider.notifier).setDiscountPct(value);
          if (_discountCtrl.text != value) {
            _discountCtrl.text = value;
          }
        },
        onImageAttached: () {
          if (ref.read(isValidProvider)) {
            _schedulePartialSave();
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
    final offset =
        box.localToGlobal(Offset.zero).dy -
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
    // Cachear el ultimo state para poder persistir el parcial en dispose.
    _cachedState = state;
    _cachedPartialId = _editingDraft
        ? widget.prefillCalc!.id
        : ref.watch(currentPartialIdProvider);
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
    // Autoguardado rapido: debe correr en CADA recalculo (cada nuevo total),
    // no solo cuando el form pasa de invalido a valido. `isValidProvider` es
    // un bool que ya no cambia tras el primer calculo, asi que cambiar el peso
    // o el material NO re-disparaba el guardado y el borrador quedaba viejo.
    // `computeVersion` incrementa en cada _recompute -> es la señal correcta.
    ref.listen<int>(
      calculatorNotifierProvider.select((s) => s.computeVersion),
      (prev, next) {
        if (prev == next) return;
        // Solo si hay un total valido que guardar.
        if (ref.read(isValidProvider)) {
          _schedulePartialSave();
        }
      },
    );
    final totalText = isValid ? formatCurrency(state.lotTotal, currency) : null;

    return PopScope(
      // Interceptamos el pop (back del sistema / gesto / navegador) para
      // poder ESPERAR el guardado del parcial antes de salir. Con el patron
      // anterior (didPop = true) el guardado era fire-and-forget y se perdia
      // al desmontarse el arbol en web. `_allowPop` deja pasar el pop
      // programatico que disparamos nosotros tras guardar.
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _allowPop) return;
        await _persistPartialSync();
        // Cancelar el debounce pendiente (ver nota en el boton X).
        _partialSaveTimer?.cancel();
        if (!mounted) return;
        // El historial se refresca solo via drift watchItems() (el write
        // del parcial dispara el stream). No hace falta invalidate manual.
        setState(() => _allowPop = true);
      },
      child: Scaffold(
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
            onPressed: () async {
              // Persistir el parcial pendiente ANTES de salir y ESPERARLO:
              // fire-and-forget se perdia al desmontarse el arbol (web).
              await _persistPartialSync();
              // Cancelar el debounce pendiente: si el usuario sale dentro de
              // la ventana de 1.5s, el timer quedaba vivo tras el pop (un
              // `Timer is still pending` en tests y un guardado tardio).
              _partialSaveTimer?.cancel();
              if (!context.mounted) return;
              // El historial se refresca solo via drift watchItems().
              setState(() => _allowPop = true);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
        title: Semantics(
          header: true,
          child: Text(
            widget.editMode
                // En edicion el titulo cambia: el usuario debe saber que
                // "Guardar" va a SOBRESCRIBIR la cotizacion existente y no
                // a crear una segunda en el historial.
                ? ref.watch(localeStringsProvider).calcEditTitle
                : ref.watch(localeStringsProvider).calcSheetTitle,
          ),
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
      body: _isRestoring
          // Loader mientras se restaura el prefill ("Reusar"/"Editar") o el
          // draft: evita mostrar el formulario vacio por un instante antes de
          // que aparezcan los valores.
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            )
          : SafeArea(
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
                              ? _buildStepPieceExpress(
                                  state,
                                  notifier,
                                  currency,
                                )
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
  /// El step bar ya muestra el nombre de la seccion. Esta wrapper provee
  /// el paper sheet con un borde animado que indica la seccion activa.
  Widget _buildScrollSection({
    Key? key,
    required int sectionIndex,
    required ThemeData theme,
    required ColorScheme cs,
    required Widget child,
  }) {
    final isActive = sectionIndex == _step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? cs.primary.withValues(alpha: 0.08)
                : cs.onSurface.withValues(alpha: 0.08),
            blurRadius: isActive ? 16 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _paperSheet(key: key, child: child),
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
    // Cuando algun material tiene tiempo propio, estos fields muestran la
    // SUMA de esos tiempos. Siguen editables: al escribir, se apagan los
    // switches individuales y el valor tipeado pasa a ser el tiempo global.
    final ownTimeActive = ref
        .read(calculatorNotifierProvider)
        .anyMaterialOwnTime;
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
                  onChanged: _onGlobalHoursChanged,
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
                  onChanged: _onGlobalMinutesChanged,
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
        if (ownTimeActive) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  EsBO.calcTimeSumOfMaterials,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  /// PASO 3 (comun): cantidad (Pro) + descuento + "Costos de la pieza" (Pro,
  /// los 5 campos). El descuento subio desde el result sheet al form: ahora es
  /// un campo de primer nivel del wizard.
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

        // v17: seccion unificada "Costos adicionales" con los 5 campos:
        // modelado, postprocesado, extras (switch % / fijo) + tasa de falla y
        // desperdicio (solo %). Reemplaza la seccion de Otros y la de costos
        // adicionales, que eran dos bloques separados.
        _buildPieceCostsSection(),
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
                      useOwnTime:
                          state.materials.length > index &&
                          state.materials[index].useOwnTime,
                      materialHoursCtrl: _materialCtrls[index].materialHours,
                      materialMinutesCtrl:
                          _materialCtrls[index].materialMinutes,
                      deletable: true,
                      showValidation: _showValidationErrors,
                      isKeyWeight: true,
                      onTimeToggle: (v) => _onMaterialTimeToggle(index, v),
                      onChanged: (m) {
                        notifier.updateMaterial(
                          index,
                          label: m.label,
                          weight: m.weight,
                          pricePerBobbin: m.pricePerBobbin,
                          gramsPerBobbin: m.gramsPerBobbin,
                          useOwnTime: m.useOwnTime,
                          materialHours: m.materialHours,
                          materialMinutes: m.materialMinutes,
                        );
                        // El campo global muestra la suma: actualizarla en
                        // vivo mientras el usuario tipea el tiempo del material.
                        _syncGlobalTimeFields(
                          ref.read(calculatorNotifierProvider),
                        );
                        // Sin esto, editar un material NO persistia nada:
                        // los controllers de materiales no tienen listener
                        // propio y el draft quedaba con la lista anterior.
                        _onAnyFieldChange();
                      },
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
  // COSTOS ADICIONALES — seccion collapsable Pro con los 5 campos
  // ============================================================

  /// Seccion colapsable "Costos adicionales" (Pro) con los 5 campos.
  ///
  /// El gate Pro, el peek preview y el toggle viven dentro del panel; la
  /// pagina solo le pasa los `TextEditingController` de cada campo (que son
  /// de la pagina para sobrevivir a rebuilds y-centralizar el `dispose()`).
  ///
  /// Orden de los campos:
  /// 1. Modelado y diseño (switch % / fijo)
  /// 2. Postprocesado (switch % / fijo)
  /// 3. Extras (switch % / fijo + descripcion)
  /// 4. Tasa de falla (solo %)
  /// 5. Desperdicio (solo %)
  Widget _buildPieceCostsSection() {
    return CostosAdicionalesPanel(
      modelingCtrl: _modelingCtrl,
      postprocCtrl: _postprocCtrl,
      extraCostCtrl: _extraCostCtrl,
      extraCostLabelCtrl: _extraCostLabelCtrl,
      failureCtrl: _extraFailureRateCtrl,
      wasteCtrl: _extraMarkupOnMaterialsCtrl,
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
                    color: hasTiers
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
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
  /// La decoracion (borde, sombra) se maneja en [_buildScrollSection] via
  /// AnimatedContainer para permitir la animacion de seccion activa.
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
