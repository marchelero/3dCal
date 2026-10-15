// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/providers.dart';
import '../../../../../core/storage/draft_storage_providers.dart';
import '../../../../../core/storage/setup_draft_storage.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/filament_color_field.dart';
import '../../../../../shared/widgets/k3d_brands.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';
import '../../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../widgets/setup_chip.dart';
import '../../widgets/summary_row.dart';

/// Paso 3 del flujo de setup: tu filamento (obligatorio).
///
/// - Chips de marca ([SetupChip] sobre `kKnownFilamentBrands` + "Otro..."
///   para ingreso manual) y dentro de la card opaca (`surfaceContainerLow`)
///   los DOS campos siempre visibles — marca (solo-lectura con chip,
///   editable en "Otro...") y alias (opcional en chip, obligatorio en
///   manual; nunca se mezclan, bug 2026-10-11) — [FilamentColorField] y
///   precio ([NumericInputField], Decimal). El label/helper del campo de
///   color usan `onSurface`/`onSurfaceVariant` y sobre el gradiente
///   quedaban ilegibles (bug de validación 2026-10-11).
/// - Borrador local (cambio 2026-10-11: se eliminó el auto-guard con
///   debounce — escribir "155" guardaba "1" y colapsaba el form a mitad de
///   escritura). Marca/precio/gramos/color marcan el flag local
///   `_draftDirty` y el form se persiste vía [FilamentStepState.commitDraft]
///   (botón "Guardar" o commit-on-navigate como red de seguridad). Si el
///   borrador es válido ⇒ `filamentsNotifierProvider.create(asDefault:
///   true)` con nombre escrito por el usuario (opcional — vacío ⇒
///   auto-generado `'${brand} ${grams}g'`; el chip de marca lo precarga)
///   y gramos editables (default 1000); ediciones posteriores ⇒
///   `updateFilament` con su id. Incompleto ⇒ no-op (el gate bloquea el
///   avance).
/// - Si ya existe un filamento default (AC-13, reanudación): estado saved
///   con nombre + botón "editar" que vuelve al form pre-cargado.
/// - **Obligatoria (cambio de alcance 2026-10-11)**: el enlace "Lo agrego
///   después" fue eliminado; el container (`SetupFlowPage`) bloquea el
///   avance sin filamento default. **Sin auto-avance (cambio 2026-10-11)**:
///   el registro exitoso muestra SnackBar + colapso a la tarjeta saved y el
///   usuario navega a su ritmo (botones "Atrás"/"Siguiente" del container,
///   swipe o pills).
/// - **Botón "Guardar" (usuario 2026-10-11)**: el form muestra un
///   FilledButton "Guardar" cuando el borrador es válido (marca + precio +
///   gramos); al tocarlo persiste vía [commitDraft] y el gate abre
///   "Siguiente". El commit-on-navigate sigue como red de seguridad. La
///   tarjeta saved resume TODO el filamento (marca, precio, color, gramos)
///   con botón "editar".
class FilamentStep extends ConsumerStatefulWidget {
  const FilamentStep({super.key});

  @override
  ConsumerState<FilamentStep> createState() => FilamentStepState();
}

class FilamentStepState extends ConsumerState<FilamentStep> {
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  /// Nombre del filamento: opcional (usuario 2026-10-11 — "falta el dato
  /// Nombre... que sí podía ir opcional o por defecto la marca"). Vacío ⇒
  /// se auto-genera `'${brand} ${grams}g'` en [commitDraft]. Al tocar un
  /// chip de marca se precarga con ella si el campo está vacío.
  final _nameCtrl = TextEditingController();

  /// Gramos por bobina: editable con default 1000 (usuario 2026-10-11 —
  /// antes era fijo y oculto).
  final _gramsCtrl = TextEditingController(text: '1000');

  /// Foco del campo manual de marca ("Otro..."): al tocar el chip se
  /// solicita para abrir el teclado y hacer evidente que el campo apareció
  /// (bug 2026-10-11: "no hacía nada el botón Otros").
  final _manualBrandFocus = FocusNode();

  // BUG-006: flags UI locales efímeros (el estado de negocio — el filamento
  // default — vive en filamentsNotifierProvider).
  bool _showManualBrand = false;
  bool _editing = false;
  bool _saving = false;

  /// Borrador sucio: true al tocar chip/marca/precio/color. Se limpia al
  /// persistir en [commitDraft] (sin auto-guard con debounce: escribir
  /// "155" guardaba "1" y colapsaba el form a mitad de escritura).
  bool _draftDirty = false;

  /// Color seleccionado (`#RRGGBB` o null). Es parte del form (UI-local)
  /// hasta que [commitDraft] lo persiste vía el notifier.
  String? _color;

  /// Id del filamento creado/editado por este step; ediciones posteriores
  /// van a `updateFilament` en lugar de crear duplicado.
  int? _createdFilamentId;

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
    if (ref.read(defaultFilamentProvider) == null) _restoreDraft();
    _brandCtrl.addListener(_markDraftDirty);
    _priceCtrl.addListener(_markDraftDirty);
    _gramsCtrl.addListener(_markDraftDirty);
    _nameCtrl.addListener(_markDraftDirty);
  }

  @override
  void dispose() {
    _brandCtrl.removeListener(_markDraftDirty);
    _priceCtrl.removeListener(_markDraftDirty);
    _gramsCtrl.removeListener(_markDraftDirty);
    _nameCtrl.removeListener(_markDraftDirty);
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    _nameCtrl.dispose();
    _manualBrandFocus.dispose();
    super.dispose();
  }

  /// Cualquier cambio de los controllers deja el borrador "sucio" (la
  /// persistencia ocurre solo al navegar, vía [commitDraft]) y repinta para
  /// mostrar/ocultar el botón "Guardar" según [_canSave].
  void _markDraftDirty() {
    _draftDirty = true;
    _persistDraft();
    // BUG-006: repinta UI-local (visibilidad del botón Guardar); el estado
    // de negocio sigue en el notifier.
    if (mounted) setState(() {});
  }

  /// El cambio de color también marca el borrador como sucio.
  void _onColorChanged(String? value) {
    _draftDirty = true;
    setState(() => _color = value);
    // MED-2: persistir el color en el borrador.
    _persistDraft();
  }

  /// MED-2: precarga el form con lo tipeado en la sesión anterior (app
  /// matada antes de navegar). El borrador restaurado queda "sucio" para
  /// que el commit-on-navigate lo persista si el usuario navega sin tocar
  /// nada más.
  void _restoreDraft() {
    final draft = _drafts.loadFilament();
    if (draft == null) return;
    _brandCtrl.text = draft['brand'] as String? ?? '';
    _priceCtrl.text = draft['price'] as String? ?? '';
    _gramsCtrl.text = draft['grams'] as String? ?? '1000';
    _nameCtrl.text = draft['name'] as String? ?? '';
    _color = draft['color'] as String?;
    _createdFilamentId = draft['filamentId'] as int?;
    _showManualBrand = (draft['showManualBrand'] as bool?) ?? false;
    _draftDirty = true;
  }

  /// MED-2: persiste el form actual en prefs (fire-and-forget sin debounce
  /// — la racionalidad está documentada en [SetupDraftStorage]).
  void _persistDraft() {
    _drafts.saveFilament({
      'brand': _brandCtrl.text,
      'price': _priceCtrl.text,
      'grams': _gramsCtrl.text,
      'name': _nameCtrl.text,
      'color': _color,
      'filamentId': _createdFilamentId,
      'showManualBrand': _showManualBrand,
    });
  }

  /// Texto pre-cargado del precio: evita el '125.0' crudo del double
  /// almacenado en drift (REAL).
  static String _priceText(double price) {
    final d = Decimal.parse(price.toString());
    return d == d.truncate() ? d.truncate().toString() : d.toString();
  }

  /// Texto pre-cargado de los gramos (double de drift → sin cola de ceros).
  static String _gramsText(double grams) {
    final d = Decimal.parse(grams.toString());
    return d == d.truncate() ? d.truncate().toString() : d.toString();
  }

  /// Persiste el borrador del form (botón "Guardar" o al navegar, vía
  /// `SetupFlowPage`). No-op si no hay cambios pendientes ([_draftDirty]) o
  /// si el borrador sigue incompleto (marca vacía, alias en modo manual,
  /// precio o gramos no parseables/En rango). Create (una vez) / update
  /// según exista default.
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
    final future = _commitDraftBody();
    _commitInFlight = future;
    try {
      await future;
    } finally {
      _commitInFlight = null;
    }
  }

  Future<void> _commitDraftBody() async {
    final brand = _brandCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final price = Decimal.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final grams = int.tryParse(_gramsCtrl.text.trim());
    if (brand.isEmpty ||
        (_showManualBrand && name.isEmpty) ||
        price == null ||
        price <= Decimal.zero ||
        grams == null ||
        grams <= 0) {
      return;
    }

    final notifier = ref.read(filamentsNotifierProvider.notifier);
    final existing = ref.read(defaultFilamentProvider);
    final existingId = _createdFilamentId ?? existing?.id;
    // Alias: el escrito por el usuario o el auto-generado "${marca}
    // ${gramos}g" (solo en modo chip known; en modo manual el alias es
    // obligatorio y ya se validó arriba).
    final finalName = name.isEmpty ? '$brand ${grams}g' : name;

    setState(() => _saving = true);
    try {
      if (existingId == null) {
        await notifier.create(
          name: finalName,
          brand: brand,
          pricePerBobbin: price,
          gramsPerBobbin: Decimal.fromInt(grams),
          asDefault: true,
          color: _color,
        );
        // El step puede desmontarse si el commit corre con un swipe en
        // curso: no tocar ref/context sin mounted.
        if (!mounted) return;
        // Resolver el id recién creado para futuras ediciones.
        final fresh = ref.read(filamentsNotifierProvider).value ?? const [];
        _createdFilamentId = _matchId(fresh, finalName, brand);
        _draftDirty = false;
        // MED-2: commit OK ⇒ el borrador en prefs ya no aporta nada.
        _drafts.clearFilament();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.success(EsBO.configFilamentSaved));
      } else {
        final current = _byId(
          ref.read(filamentsNotifierProvider).value,
          existingId,
        );
        if (current == null) return;
        final changed =
            current.name != finalName ||
            (current.brand ?? '') != brand ||
            Decimal.parse(current.pricePerBobbin.toString()) != price ||
            Decimal.parse(current.gramsPerBobbin.toString()) !=
                Decimal.fromInt(grams) ||
            current.color != _color;
        _draftDirty = false;
        if (changed) {
          await notifier.updateFilament(
            id: existingId,
            name: finalName,
            brand: brand,
            pricePerBobbin: price,
            gramsPerBobbin: Decimal.fromInt(grams),
            asDefault: true,
            color: _color,
            updateColor: true,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(AppSnackBar.success(EsBO.setupFilamentUpdated));
          // Colapsa a la tarjeta saved para que el flip sea evidente. Sin
          // auto-avance: el usuario navega a su ritmo (2026-10-11).
          setState(() => _editing = false);
        }
        // MED-2: commit OK (con cambios o ya sincronizado) ⇒ sin borrador
        // pendiente en prefs.
        _drafts.clearFilament();
      }
    } catch (e) {
      debugPrint('Setup filament draft commit failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error(EsBO.filamentErrorSave));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "editar" en el estado saved: vuelve al form pre-cargado del filamento
  /// default (ediciones → updateFilament).
  void _editDefault(Filament filament) {
    _createdFilamentId = filament.id;
    _brandCtrl.text = filament.brand ?? '';
    _nameCtrl.text = filament.name;
    _priceCtrl.text = _priceText(filament.pricePerBobbin);
    _gramsCtrl.text = _gramsText(filament.gramsPerBobbin);
    _color = filament.color;
    // El pre-cargado dispara los listeners: el borrador queda limpio (los
    // valores ya coinciden con la default; no hay nada que guardar).
    _draftDirty = false;
    setState(() {
      _editing = true;
      _showManualBrand =
          (filament.brand ?? '').isNotEmpty &&
          !kKnownFilamentBrands.contains(filament.brand);
    });
    // MED-2: capturar _showManualBrand en el borrador (los setters de
    // arriba persistieron con el flag anterior).
    _persistDraft();
  }

  static Filament? _byId(List<Filament>? list, int id) {
    if (list == null) return null;
    for (final f in list) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// El borrador es guardable: marca no vacía + precio parseable > 0 +
  /// gramos enteros > 0. En modo manual ("Otro...", [ _showManualBrand ])
  /// además el alias (nombre) es obligatorio — marca y alias son dos campos
  /// distintos (ej: marca "Creality", alias "PLA Negro"; pedido del usuario
  /// 2026-10-11). Controla la habilitación del botón "Guardar".
  bool get _canSave {
    final brand = _brandCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final price = Decimal.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final grams = int.tryParse(_gramsCtrl.text.trim());
    return brand.isNotEmpty &&
        (!_showManualBrand || name.isNotEmpty) &&
        price != null &&
        price > Decimal.zero &&
        grams != null &&
        grams > 0;
  }

  static int? _matchId(List<Filament> list, String name, String brand) {
    for (final f in list) {
      if (f.name == name && (f.brand ?? '') == brand) return f.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild al cambiar idioma y al cambiar el filamento default.
    ref.watch(localeProvider);
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final theme = Theme.of(context);

    // Estado guardado (AC-13): default existente → tarjeta saved.
    if (defaultFilament != null && !_editing) {
      return _buildSaved(context, defaultFilament);
    }
    return _buildForm(context, theme);
  }

  Widget _buildSaved(BuildContext context, Filament filament) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            EsBO.setupFilamentTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            key: const ValueKey('setup-filament-saved-card'),
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
                    // Check animado al aparecer (mismo flip que PrinterStep).
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Container(
                        key: ValueKey(
                          'setup-filament-saved-check-${filament.id}',
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
                          Text(
                            filament.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            EsBO.configFilamentSaved,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('setup-filament-edit'),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: EsBO.commonEdit,
                      onPressed: () => _editDefault(filament),
                    ),
                  ],
                ),
                // Resumen del filamento guardado (usuario 2026-10-11):
                // detalle completo bajo el header para ver qué quedó
                // registrado.
                const SizedBox(height: AppSpacing.sm),
                Divider(
                  height: 1,
                  color: color.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.xs),
                SummaryRow(
                  icon: Icons.storefront_outlined,
                  label: EsBO.filamentBrand,
                  value: (filament.brand ?? '').isEmpty
                      ? EsBO.setupTicketPending
                      : filament.brand!,
                ),
                SummaryRow(
                  icon: Icons.attach_money_rounded,
                  label: EsBO.filamentPrice(currency.symbol),
                  value:
                      '${_priceText(filament.pricePerBobbin)} '
                      '${currency.symbol}',
                ),
                SummaryRow(
                  icon: Icons.scale_rounded,
                  label: EsBO.filamentGrams,
                  value: '${_gramsText(filament.gramsPerBobbin)} g',
                ),
                if ((filament.color ?? '').isNotEmpty)
                  SummaryRow(
                    icon: Icons.color_lens_outlined,
                    label: EsBO.filamentColorLabel,
                    value: filament.color!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme) {
    final currency = ref.watch(selectedCurrencyProvider);
    final color = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EsBO.setupFilamentTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            EsBO.setupFilamentSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BrandChips(
            selectedBrand: _brandCtrl.text.trim(),
            manualSelected: _showManualBrand,
            onSelected: (brand) {
              // BUG-006: el texto de los controllers es estado UI-local; el
              // setState refleja la selección del chip al instante. El
              // alias NO se precarga con la marca (bug 2026-10-11: los dos
              // campos parecían uno solo); si queda vacío, commitDraft
              // auto-genera "${marca} ${gramos}g".
              setState(() {
                _brandCtrl.text = brand;
                // Volver de "Otro..." a un chip known deja la marca en
                // modo solo-lectura (mismo comportamiento que el form
                // in-app).
                _showManualBrand = false;
              });
              // MED-2: los setters de arriba ya persistieron con el flag
              // viejo; se re-persiste para capturar _showManualBrand=false.
              _persistDraft();
            },
            onManual: () {
              // Bug 2026-10-11: "Otro..." "no hacía nada" — el campo manual
              // aparecía sin foco y con la marca del chip anterior adentro
              // (idéntico a lo que ya se veía). Se limpia la selección de
              // chip, se muestra el campo vacío y se abre el teclado. El
              // nombre precargado con la marca del chip se limpia junto con
              // ella (si el usuario lo editó a mano, se conserva).
              setState(() {
                final previousBrand = _brandCtrl.text.trim();
                if (_nameCtrl.text.trim() == previousBrand) {
                  _nameCtrl.clear();
                }
                _showManualBrand = true;
                _brandCtrl.clear();
              });
              // MED-2: persistir el modo manual en el borrador.
              _persistDraft();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _manualBrandFocus.requestFocus();
              });
            },
          ),
          // Card opaca para los campos de form: sus labels/helpers usan
          // onSurface/onSurfaceVariant (colores de superficie) y sobre el
          // gradiente quedaban ilegibles (bug de validación 2026-10-11).
          // Mismo patrón que la card "Personalizada" del paso impresora.
          const SizedBox(height: AppSpacing.lg),
          Container(
            key: const ValueKey('setup-filament-form-card'),
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
                // Los DOS campos siempre visibles (usuario 2026-10-11:
                // "solo veo 1... donde se está mezclando ambos"): marca y
                // alias nunca se mezclan. En modo chip la marca es
                // solo-lectura (la llena el chip); en modo "Otro..." es
                // editable y obligatoria.
                TextField(
                  key: const ValueKey('setup-filament-brand-field'),
                  controller: _brandCtrl,
                  readOnly: !_showManualBrand,
                  focusNode: _showManualBrand ? _manualBrandFocus : null,
                  decoration: InputDecoration(labelText: EsBO.filamentBrand),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Alias opcional (usuario 2026-10-11): vacío ⇒ se
                // auto-genera "${marca} ${gramos}g" al guardar (solo en
                // modo chip; en modo manual es obligatorio). NO se precarga
                // con la marca: antes el alias venía con la marca adentro y
                // los dos campos parecían uno solo (bug 2026-10-11).
                TextField(
                  key: const ValueKey('setup-filament-name'),
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.filamentName,
                    helperText: EsBO.filamentNameHelper,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilamentColorField(value: _color, onChanged: _onColorChanged),
                const SizedBox(height: AppSpacing.lg),
                NumericInputField(
                  key: const ValueKey('setup-filament-price'),
                  label: EsBO.filamentPrice(currency.symbol),
                  controller: _priceCtrl,
                  allowDecimals: true,
                  helperText: EsBO.setupFilamentPriceHint,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Gramos por bobina editable (default 1000) — pedido del
                // usuario 2026-10-11: antes era fijo y oculto.
                NumericInputField(
                  key: const ValueKey('setup-filament-grams'),
                  label: EsBO.filamentGrams,
                  controller: _gramsCtrl,
                  allowDecimals: false,
                  helperText: EsBO.filamentGramsHelper,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          // Botón "Guardar" (usuario 2026-10-11): persiste el borrador al
          // tocar y abre el gate — "Siguiente" se pinta al instante al
          // registrarse la default. Habilitado SOLO cuando marca + precio
          // son válidos (_canSave); el commit-on-navigate queda como red
          // de seguridad.
          if (_canSave) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('setup-filament-save'),
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

/// Chips de marca del filamento (`kKnownFilamentBrands`) + "Otro..." para
/// ingreso manual. Estilo [SetupChip] (fondo opaco + `onSurface`): contraste
/// AA sobre el gradiente del flujo (bug de validación 2026-10-11).
class _BrandChips extends StatelessWidget {
  const _BrandChips({
    required this.selectedBrand,
    required this.onSelected,
    required this.onManual,
    this.manualSelected = false,
  });

  final String selectedBrand;
  final ValueChanged<String> onSelected;
  final VoidCallback onManual;

  /// true cuando el modo manual ("Otro...") está activo: el chip se
  /// resalta con primaryContainer para que el estado sea visible (el campo
  /// manual puede quedar fuera del viewport en pantallas chicas).
  final bool manualSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final brand in kKnownFilamentBrands)
          SetupChip(
            key: ValueKey('setup-filament-brand-$brand'),
            label: brand,
            selected: selectedBrand == brand,
            onTap: () => onSelected(brand),
          ),
        SetupChip(
          key: const ValueKey('setup-filament-brand-other'),
          label: EsBO.brandSelectorOther,
          selected: manualSelected,
          showCheck: false,
          onTap: onManual,
        ),
      ],
    );
  }
}
