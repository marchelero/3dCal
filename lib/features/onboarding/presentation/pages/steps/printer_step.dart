// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/providers.dart';
import '../../../../../core/storage/draft_storage_providers.dart';
import '../../../../../core/storage/setup_draft_storage.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../../../../catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../../../catalog/printers/presentation/widgets/printer_catalog_selector.dart';
import '../../domain/featured_printer_presets.dart';
import '../../widgets/printer_preset_card.dart';
import '../../widgets/summary_row.dart';

/// Paso 2 del flujo de setup: tu impresora (obligatoria).
///
/// - Si ya existe una impresora por defecto (AC-13, reanudación): estado
///   saved con nombre + botón "editar" que vuelve al grid (patrón
///   `_DeviceSetupCard` del stepper viejo). Tocar OTRO preset del grid con
///   una default existente la ACTUALIZA (`updatePrinter` con su id,
///   `asDefault: true`) + SnackBar `setupPrinterUpdated` + vuelta a la
///   tarjeta saved (una sola printer en DB).
/// - Grid de [PrinterPresetCard] dentro del colapsable "Impresoras
///   populares" ([PrinterStepState._popularCtrl]). Tap a un preset (o a
///   "Personalizada") LLENA el form de detalle de abajo (marca, modelo,
///   watts, vida útil) — usuario 2026-10-11: el preset ya no es un
///   borrador aparte, siempre se edita vía el form. El form incluye un
///   sub-colapsable "Otros datos (opcional)": vida útil (default 7500),
///   horas de uso (default 0) y costo de compra — no bloquean el guardado.
///   Persistencia vía [PrinterStepState.commitDraft] (botón "Guardar" o
///   commit-on-navigate): create (una vez) / update + SnackBar + colapso a
///   la tarjeta saved. La tarjeta saved resume TODO el equipo (marca,
///   consumo, vida útil) con botón "editar".
/// - **Obligatoria (cambio de alcance 2026-10-11)**: el enlace "Lo agrego
///   después" fue eliminado; el container (`SetupFlowPage`) bloquea el
///   avance sin impresora default. **Sin auto-avance (cambio 2026-10-11)**:
///   el registro exitoso muestra SnackBar + colapso a la tarjeta saved y el
///   usuario navega a su ritmo (botones "Atrás"/"Siguiente" del container,
///   swipe o pills).
/// - **Botón "Guardar" (usuario 2026-10-11)**: el grid/form muestra un
///   FilledButton "Guardar" cuando el borrador es válido (preset elegido o
///   Personalizada completa); al tocarlo persiste vía [commitDraft] y el
///   gate abre "Siguiente" (se pinta al instante). El commit-on-navigate
///   sigue como red de seguridad. La tarjeta saved resume TODO el equipo
///   (marca, consumo, vida útil) con botón "editar".
class PrinterStep extends ConsumerStatefulWidget {
  const PrinterStep({super.key});

  @override
  ConsumerState<PrinterStep> createState() => PrinterStepState();
}

class PrinterStepState extends ConsumerState<PrinterStep> {
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _wattsCtrl = TextEditingController();

  /// Campos opcionales (usuario 2026-10-11): vida útil con default 7500,
  /// horas de uso con default 0 y costo de compra vacío (opcional). Se
  /// agrupan en un sub-colapsable "Otros datos" del form "Personalizada".
  final _lifeCtrl = TextEditingController(text: '7500');
  final _hoursCtrl = TextEditingController(text: '0');
  final _costCtrl = TextEditingController();

  /// Controller del colapsable "Impresoras populares": al elegir un preset
  /// se colapsa para que el foco quede en el form "Personalizada" lleno
  /// con los datos del preset (pedido del usuario 2026-10-11).
  final _popularCtrl = ExpansibleController();

  // BUG-006: flags UI locales efímeros (el estado de negocio — la impresora
  // default — vive en printersNotifierProvider).
  bool _showCustom = false;
  bool _editing = false;
  bool _saving = false;

  /// Borrador sucio: true al tocar un preset o al escribir en el form
  /// "Personalizada". Se limpia al persistir en [commitDraft] (sin
  /// auto-guard con debounce: escribir "155" guardaba "1" y colapsaba el
  /// form a mitad de escritura).
  bool _draftDirty = false;

  /// Preset elegido en el grid (borrador local, sin persistencia
  /// inmediata); se persiste en [commitDraft] al navegar.
  FeaturedPrinterPreset? _selectedPreset;

  /// Id de la impresora creada/editada por el formulario "Personalizada";
  /// ediciones posteriores van a `updatePrinter` en lugar de crear duplicado.
  int? _createdPrinterId;

  /// MED-2: storage de borradores del setup (prefs). El form se persiste en
  /// cada cambio y se restaura al montar si la app se mató antes de navegar.
  SetupDraftStorage get _drafts => ref.read(setupDraftStorageProvider);

  /// MED-3: Future del commit en curso (null si no hay). El container lo
  /// awaits antes de evaluar el gate tras un swipe (el commit-on-navigate
  /// es fire-and-forget y sin este await el gate comparaba contra el
  /// provider aún vacío → snap-back + hint engañoso).
  Future<void>? _commitInFlight;

  /// MED-3: true mientras un commit corre en este step.
  bool get isCommitting => _commitInFlight != null;

  /// Future del commit en curso (null si no hay). Ver [isCommitting].
  Future<void>? get commitInFlight => _commitInFlight;

  @override
  void initState() {
    super.initState();
    // MED-2: restaura el borrador persistido ANTES de enganchar los
    // listeners (asignar texto así no dispara _markDraftDirty ni repinta
    // durante initState). AC-13: solo precarga el form si la tarjeta saved
    // no tiene prioridad (sin default persistido); con default, el build
    // muestra la tarjeta y el form queda oculto de todos modos.
    if (ref.read(defaultPrinterProvider) == null) _restoreDraft();
    _brandCtrl.addListener(_markDraftDirty);
    _modelCtrl.addListener(_markDraftDirty);
    _wattsCtrl.addListener(_markDraftDirty);
    _lifeCtrl.addListener(_markDraftDirty);
    _hoursCtrl.addListener(_markDraftDirty);
    _costCtrl.addListener(_markDraftDirty);
  }

  @override
  void dispose() {
    _brandCtrl.removeListener(_markDraftDirty);
    _modelCtrl.removeListener(_markDraftDirty);
    _wattsCtrl.removeListener(_markDraftDirty);
    _lifeCtrl.removeListener(_markDraftDirty);
    _hoursCtrl.removeListener(_markDraftDirty);
    _costCtrl.removeListener(_markDraftDirty);
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _wattsCtrl.dispose();
    _lifeCtrl.dispose();
    _hoursCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  /// Cualquier cambio de los controllers deja el borrador "sucio" (los
  /// dropdowns del selector escriben brand/model/watts en secuencia; la
  /// persistencia ocurre solo al navegar, vía [commitDraft], lo que
  /// también evita guardar estados intermedios) y repinta para
  /// mostrar/ocultar el botón "Guardar" según [_canSave].
  void _markDraftDirty() {
    _draftDirty = true;
    _persistDraft();
    // BUG-006: repinta UI-local (visibilidad del botón Guardar); el estado
    // de negocio sigue en el notifier.
    if (mounted) setState(() {});
  }

  /// MED-2: precarga el form con lo tipeado en la sesión anterior (app
  /// matada antes de navegar). El borrador restaurado queda "sucio" para
  /// que el commit-on-navigate lo persista si el usuario navega sin tocar
  /// nada más.
  void _restoreDraft() {
    final draft = _drafts.loadPrinter();
    if (draft == null) return;
    _brandCtrl.text = draft['brand'] as String? ?? '';
    _modelCtrl.text = draft['model'] as String? ?? '';
    _wattsCtrl.text = draft['watts'] as String? ?? '';
    _lifeCtrl.text = draft['life'] as String? ?? '7500';
    _hoursCtrl.text = draft['hours'] as String? ?? '0';
    _costCtrl.text = draft['cost'] as String? ?? '';
    _createdPrinterId = draft['printerId'] as int?;
    _showCustom = (draft['showCustom'] as bool?) ?? false;
    _draftDirty = true;
  }

  /// MED-2: persiste el form actual en prefs (fire-and-forget sin debounce
  /// — la racionalidad está documentada en [SetupDraftStorage]).
  void _persistDraft() {
    _drafts.savePrinter({
      'brand': _brandCtrl.text,
      'model': _modelCtrl.text,
      'watts': _wattsCtrl.text,
      'life': _lifeCtrl.text,
      'hours': _hoursCtrl.text,
      'cost': _costCtrl.text,
      'printerId': _createdPrinterId,
      'showCustom': _showCustom,
    });
  }

  static PrinterProfile? _byId(List<PrinterProfile> list, int id) {
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }

  static int? _matchId(List<PrinterProfile> list, String brand, String name) {
    for (final p in list) {
      if (p.name == name && (p.brand ?? '') == brand) return p.id;
    }
    return null;
  }

  /// Selección de un preset del grid (usuario 2026-10-11): LLENA el form
  /// "Personalizada" con sus datos (marca, modelo, watts, vida útil —
  /// default 7500 si el preset no trae), abre el form y COLAPSA la sección
  /// "Impresoras populares" para que el foco quede en el detalle. La
  /// persistencia ocurre al tocar "Guardar" o al navegar ([commitDraft]);
  /// si YA existe una default, el commit la ACTUALIZA (una sola printer).
  void _selectPreset(FeaturedPrinterPreset preset) {
    // El pre-cargado dispara los listeners (_markDraftDirty → setState).
    _brandCtrl.text = preset.brand;
    _modelCtrl.text = preset.model;
    _wattsCtrl.text = preset.watts.toString();
    _lifeCtrl.text = (preset.usefulLifeHours ?? 7500).toString();
    _selectedPreset = preset;
    _draftDirty = true;
    setState(() => _showCustom = true);
    // MED-2: los setters de arriba ya persistieron con el flag viejo; se
    // re-persiste para capturar _showCustom=true.
    _persistDraft();
    // Colapsa el colapsable de populares (no-op si ya está colapsado).
    if (_popularCtrl.isExpanded) _popularCtrl.collapse();
  }

  /// Persiste el borrador (botón "Guardar" o commit-on-navigate). Prioridad:
  /// el form "Personalizada" (que el preset ahora siempre llena). No-op si
  /// no hay cambios pendientes ([_draftDirty]) o si el form sigue
  /// incompleto (el gate del container bloquea el avance sin default).
  Future<void> commitDraft() async {
    final inFlight = _commitInFlight;
    if (inFlight != null) {
      // MED-3: ya hay un commit en curso (swipe fire-and-forget + tap de
      // "Siguiente" rápido): esperarlo para que el gate del container
      // evalúe contra el provider ya actualizado.
      await inFlight;
      return;
    }
    if (!_draftDirty) return;
    final future = _commitCustomForm();
    _commitInFlight = future;
    try {
      await future;
    } finally {
      _commitInFlight = null;
    }
  }

  /// Create (una vez) / update del formulario "Personalizada" (que también
  /// se llena al elegir un preset). Se invoca desde [commitDraft] (botón
  /// "Guardar" o al navegar). Los campos opcionales (vida útil, horas,
  /// costo) se persisten si son válidos; vacíos/inválidos ⇒ null (el
  /// repo los trata como absent en update).
  Future<void> _commitCustomForm() async {
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final watts = int.tryParse(_wattsCtrl.text.trim());
    if (brand.isEmpty || model.isEmpty || watts == null || watts < 0) return;

    // LOW-2: clamp de la vida útil al rango razonable (>= 1, mismo mínimo
    // que valida el form in-app — printer_form_page._validateLife; el tope
    // es defensivo contra tipeos absurdos).
    final life = (int.tryParse(_lifeCtrl.text.trim()) ?? 7500).clamp(1, 100000);
    final hours = int.tryParse(_hoursCtrl.text.trim()) ?? 0;
    final costText = _costCtrl.text.trim().replaceAll(',', '.');
    final cost = Decimal.tryParse(costText);

    final notifier = ref.read(printersNotifierProvider.notifier);
    final printers = ref.read(printersNotifierProvider).value ?? const [];
    final existingId = _createdPrinterId ?? _matchId(printers, brand, model);

    setState(() => _saving = true);
    try {
      if (existingId == null) {
        await notifier.create(
          name: model,
          brand: brand,
          averageWatts: watts,
          usefulLifeHours: life,
          currentHours: hours,
          purchaseCost: cost,
          asDefault: true,
        );
        if (!mounted) return;
        // Resolver el id recién creado para futuras ediciones.
        final fresh = ref.read(printersNotifierProvider).value ?? const [];
        _createdPrinterId = _matchId(fresh, brand, model);
        _draftDirty = false;
        // MED-2: commit OK ⇒ el borrador en prefs ya no aporta nada.
        _drafts.clearPrinter();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.success(EsBO.configPrinterSaved));
      } else {
        final current = _byId(printers, existingId);
        if (current == null) return;
        _draftDirty = false;
        // HIGH-1 (auditoría 2026-10-14): el costo de compra también cuenta
        // como "changed" — antes editar SOLO el costo se descartaba porque
        // la comparación lo omitía. Null de ambos lados: drift expone
        // double?, el form trae Decimal?.
        final currentCost = current.purchaseCost == null
            ? null
            : Decimal.parse(current.purchaseCost.toString());
        if (current.name != model ||
            (current.brand ?? '') != brand ||
            current.averageWatts != watts ||
            current.usefulLifeHours != life ||
            current.currentHours != hours ||
            currentCost != cost) {
          await notifier.updatePrinter(
            id: existingId,
            name: model,
            brand: brand,
            averageWatts: watts,
            usefulLifeHours: life,
            currentHours: hours,
            purchaseCost: cost,
            // El repo trata `purchaseCost: null` como absent
            // (printer_repository.dart:88-92): para poder VACIAR un costo
            // que existía hay que pedirlo con clearAmortization (que además
            // limpia la vida útil, su par de amortización). Solo se pide
            // cuando el usuario vació un costo PREVIO: así una edición sin
            // costo (caso común) no pisa la vida útil guardada.
            clearAmortization: cost == null && current.purchaseCost != null,
          );
          if (!mounted) return;
          // Edición completada y persistida → feedback claro: SnackBar de
          // actualización + colapso a la tarjeta saved con el nombre nuevo
          // (el flip con check animado confirma que se modificó). Sin
          // auto-avance: el usuario navega a su ritmo (2026-10-11).
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(AppSnackBar.success(EsBO.setupPrinterUpdated));
          setState(() {
            _editing = false;
            _showCustom = false;
          });
        }
        // MED-2: commit OK (con cambios o ya sincronizado) ⇒ sin borrador
        // pendiente en prefs.
        _drafts.clearPrinter();
      }
    } catch (e) {
      debugPrint('Setup printer draft commit failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.printerErrorSave));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "editar" en el estado saved: vuelve al grid con el formulario
  /// pre-cargado de la impresora default (ediciones → updatePrinter).
  void _editDefault(PrinterProfile printer) {
    _createdPrinterId = printer.id;
    _brandCtrl.text = printer.brand ?? '';
    _modelCtrl.text = printer.name;
    _wattsCtrl.text = printer.averageWatts.toString();
    // Campos opcionales pre-cargados (default 7500/0 si la default no
    // tiene valores — BDs viejas).
    _lifeCtrl.text = (printer.usefulLifeHours ?? 7500).toString();
    _hoursCtrl.text = (printer.currentHours ?? 0).toString();
    _costCtrl.text = printer.purchaseCost == null
        ? ''
        : _costText(printer.purchaseCost!);
    // El pre-cargado dispara los listeners: el borrador queda limpio (los
    // valores ya coinciden con la default; no hay nada que guardar).
    _selectedPreset = null;
    _draftDirty = false;
    setState(() {
      _editing = true;
      _showCustom = true;
    });
    // MED-2: capturar _showCustom=true en el borrador (los setters de
    // arriba persistieron con el flag anterior).
    _persistDraft();
  }

  /// Texto pre-cargado del costo (double de drift → sin cola de ceros).
  static String _costText(double cost) {
    final d = Decimal.parse(cost.toString());
    return d == d.truncate() ? d.truncate().toString() : d.toString();
  }

  /// El borrador es guardable: el form "Personalizada" completo (marca +
  /// modelo + watts válidos) — el preset ahora llena ese mismo form, así que
  /// una sola validación cubre ambos caminos. Controla la habilitación del
  /// botón "Guardar".
  bool get _canSave {
    if (!_showCustom) return false;
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final watts = int.tryParse(_wattsCtrl.text.trim());
    return brand.isNotEmpty && model.isNotEmpty && watts != null && watts >= 0;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild al cambiar idioma y al cambiar la impresora default.
    ref.watch(localeProvider);
    final defaultPrinter = ref.watch(defaultPrinterProvider);
    final theme = Theme.of(context);

    // Estado guardado (AC-13): default existente → tarjeta saved.
    if (defaultPrinter != null && !_editing) {
      return _buildSaved(context, defaultPrinter);
    }
    return _buildGrid(context, theme, defaultPrinter);
  }

  Widget _buildSaved(BuildContext context, PrinterProfile printer) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            EsBO.setupPrinterTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            key: const ValueKey('setup-printer-saved-card'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Check animado al aparecer: el flip grid→saved debe verse
                    // como una confirmación evidente (bug F2 feedback).
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Container(
                        key: ValueKey(
                          'setup-printer-saved-check-${printer.id}',
                        ),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 24,
                          color: color.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre prominente (el flip debe ser innegable).
                          Text(
                            printer.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            EsBO.configPrinterSaved,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('setup-printer-edit'),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: EsBO.commonEdit,
                      onPressed: () => _editDefault(printer),
                    ),
                  ],
                ),
                // Resumen del equipo guardado (usuario 2026-10-11): detalle
                // completo bajo el header para ver qué quedó registrado.
                const SizedBox(height: AppSpacing.sm),
                Divider(
                  height: 1,
                  color: color.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.xs),
                SummaryRow(
                  icon: Icons.storefront_outlined,
                  label: EsBO.filamentBrand,
                  value: (printer.brand ?? '').isEmpty
                      ? EsBO.setupTicketPending
                      : printer.brand!,
                ),
                SummaryRow(
                  icon: Icons.bolt_rounded,
                  label: EsBO.printerWatts,
                  value: '${printer.averageWatts} W',
                ),
                if (printer.usefulLifeHours != null)
                  SummaryRow(
                    icon: Icons.schedule_rounded,
                    label: EsBO.printerUsefulLifeHours,
                    value: '${printer.usefulLifeHours}',
                  ),
                if (printer.currentHours != null && printer.currentHours! > 0)
                  SummaryRow(
                    icon: Icons.hourglass_bottom_rounded,
                    label: EsBO.printerCurrentHours,
                    value: '${printer.currentHours}',
                  ),
                if (printer.purchaseCost != null)
                  SummaryRow(
                    icon: Icons.payments_outlined,
                    label: EsBO.printerPurchaseCost,
                    value: _costText(printer.purchaseCost!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ThemeData theme,
    PrinterProfile? defaultPrinter,
  ) {
    final color = theme.colorScheme;
    final presets = featuredPresets();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EsBO.setupPrinterTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsBO.setupPrinterSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Colapsable "Impresoras populares" (usuario 2026-10-11): al
          // elegir un preset se colapsa y el form "Personalizada" de
          // abajo queda lleno con sus datos (foco en el detalle).
          // Material (no DecoratedBox): el ExpansionTile pinta su
          // ListTile/ink sobre el Material más cercano con color de fondo.
          Material(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const ValueKey('setup-printer-popular'),
              controller: _popularCtrl,
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              iconColor: color.onSurface,
              textColor: color.onSurface,
              title: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 20,
                    color: color.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EsBO.setupPrinterPopular,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2 columnas incluso en ventanas delgadas: el ancho de las
                // tarjetas se adapta al espacio disponible. 1 sola columna
                // (ancho completo) solo en el caso extremo (< 280px).
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = AppSpacing.md;
                    final available = constraints.maxWidth;
                    final twoColumns = available >= 280;
                    final cardWidth = twoColumns
                        ? (available - gap) / 2
                        : available;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final preset in presets)
                          PrinterPresetCard(
                            key: ValueKey(
                              'setup-printer-preset-'
                              '${preset.brand}-${preset.model}',
                            ),
                            width: cardWidth,
                            brand: preset.brand,
                            model: preset.model,
                            watts: preset.watts,
                            // Selección = último preset elegido (borrador
                            // que llena el form) o la default registrada.
                            selected:
                                (_selectedPreset != null &&
                                    _selectedPreset!.brand == preset.brand &&
                                    _selectedPreset!.model == preset.model) ||
                                (defaultPrinter != null &&
                                    defaultPrinter.name == preset.model &&
                                    (defaultPrinter.brand ?? '') ==
                                        preset.brand),
                            onTap: () => _selectPreset(preset),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!_showCustom)
            _CustomPrinterCard(
              onTap: () {
                setState(() {
                  // Abrir "Personalizada" reemplaza la elección de preset
                  // (si no, el commit priorizaría el preset y el form
                  // quedaría descartado en silencio).
                  _showCustom = true;
                  _selectedPreset = null;
                });
                // MED-2: persistir el flag en el borrador.
                _persistDraft();
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EsBO.setupPrinterCustom,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrinterCatalogSelector(
                    compact: true,
                    brandController: _brandCtrl,
                    modelController: _modelCtrl,
                    wattsController: _wattsCtrl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NumericInputField(
                    key: const ValueKey('setup-printer-custom-watts'),
                    label: EsBO.printerWatts,
                    controller: _wattsCtrl,
                    allowDecimals: false,
                    helperText: EsBO.printerWattsHelper,
                    textInputAction: TextInputAction.done,
                  ),
                  // Otros datos (opcional, usuario 2026-10-11): plegados
                  // por defecto — con marca+modelo+watts ya se puede guardar;
                  // vida útil (default 7500), horas de uso (default 0) y
                  // costo de compra se completan cuando el usuario quiera.
                  // Material transparente propio: el ExpansionTile pinta su
                  // ListTile/ink sobre el Material más cercano; sin este
                  // wrapper el color del Container padre tapa los efectos
                  // (assert de framework "ListTile background color or ink
                  // splashes may be invisible").
                  Material(
                    type: MaterialType.transparency,
                    child: ExpansionTile(
                      key: const ValueKey('setup-printer-extra'),
                      initiallyExpanded: false,
                      tilePadding: EdgeInsets.zero,
                      iconColor: color.onSurface,
                      textColor: color.onSurface,
                      title: Row(
                        children: [
                          Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: color.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              EsBO.setupPrinterExtra,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NumericInputField(
                          key: const ValueKey('setup-printer-custom-life'),
                          label: EsBO.printerUsefulLifeHours,
                          controller: _lifeCtrl,
                          allowDecimals: false,
                          helperText: EsBO.printerUsefulLifeHoursHelper,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        NumericInputField(
                          key: const ValueKey('setup-printer-custom-hours'),
                          label: EsBO.printerCurrentHours,
                          controller: _hoursCtrl,
                          allowDecimals: false,
                          helperText: EsBO.printerCurrentHoursHelper,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        NumericInputField(
                          key: const ValueKey('setup-printer-custom-cost'),
                          label: EsBO.printerPurchaseCost,
                          controller: _costCtrl,
                          allowDecimals: true,
                          helperText: EsBO.printerPurchaseCostHelper,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Botón "Guardar" (usuario 2026-10-11): persiste el borrador al
          // tocar (preset elegido o Personalizada completa) y abre el gate
          // — "Siguiente" se pinta al instante al registrarse la default.
          // Habilitado SOLO cuando el borrador es válido (_canSave); el
          // commit-on-navigate queda como red de seguridad.
          if (_canSave) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('setup-printer-save'),
                onPressed: _saving ? null : commitDraft,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(EsBO.commonSave),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta "Personalizada": toggle que abre el selector del catálogo; el
/// borrador se persiste al navegar (sin botón Guardar, vía [PrinterStepState
/// .commitDraft]).
class _CustomPrinterCard extends StatelessWidget {
  const _CustomPrinterCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          key: const ValueKey('setup-printer-custom'),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  EsBO.setupPrinterCustom,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
