// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/calculation_draft.dart';
import '../../../../core/storage/draft_storage_providers.dart';
import '../../../catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/decimal_input_field.dart';
import '../../domain/entities/calculation_output.dart';

/// Pantalla principal del calculator.
///
/// **Modos** (toggle en body):
/// - `express`: 1 material con inputs top-level.
/// - `advanced`: lista de materiales con [AnimatedList].
///
/// Formula: totalPrice = materialCost - discountAmount.
/// Sin electricidad, sin profit, sin watts.
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
  late final TextEditingController _labelCtrl;

  // Advanced controllers.
  final List<_MaterialCtrls> _materialCtrls = [];
  final _advancedListKey = GlobalKey<AnimatedListState>();

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
    _labelCtrl = TextEditingController(text: initial.label);

    for (final c in [
      _weightCtrl, _hoursCtrl, _minutesCtrl, _discountCtrl,
      _priceCtrl, _gramsCtrl,
    ]) {
      c.addListener(_scheduleDraftSave);
    }
    _labelCtrl.addListener(() {
      ref.read(calculatorNotifierProvider.notifier).setLabel(_labelCtrl.text);
    });

    if (initial.mode == CalculatorMode.advanced) {
      for (final m in initial.materials) {
        _materialCtrls.add(_MaterialCtrls.fromRow(m));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Auto-poblar filamento default (si no hay draft).
      final storage = ref.read(draftStorageProvider);
      final draft = await storage.load();
      if (draft == null && mounted) {
        final defaultFilament = ref.read(defaultFilamentProvider);
        if (defaultFilament != null) {
          ref.read(calculatorNotifierProvider.notifier).loadFilamentDefaults(
                pricePerBobbin:
                    defaultFilament.pricePerBobbin.toStringAsFixed(2),
                gramsPerBobbin:
                    defaultFilament.gramsPerBobbin.toStringAsFixed(0),
              );
          final updated = ref.read(calculatorNotifierProvider);
          _priceCtrl.text = updated.filamentPrice;
          _gramsCtrl.text = updated.filamentGrams;
        }
      }
      await _restoreDraftIfAny();
    });
  }

  bool _draftRestored = false;
  Timer? _saveTimer;

  Future<void> _restoreDraftIfAny() async {
    if (_draftRestored) return;
    _draftRestored = true;
    // Limpiar draft al entrar — cada cotizacion arranca limpia.
    final storage = ref.read(draftStorageProvider);
    await storage.clear();
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
      label: _labelCtrl.text,
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
            ctrls: removed,
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
    _labelCtrl.text = i.label;
    for (final c in _materialCtrls) {
      c.dispose();
    }
    _materialCtrls.clear();
  }

  Future<void> _showSaveDialog() async {
    final state = ref.read(calculatorNotifierProvider);
    if (!state.isValid || state.output == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el form antes de guardar.')),
      );
      return;
    }
    final result = await showDialog<_SaveResult>(
      context: context,
      builder: (_) => const _SaveDialog(),
    );
    if (result == null || !mounted) return;
    try {
      final id = await ref.read(calculatorNotifierProvider.notifier).save(
            clientName: result.clientName,
          );
      if (!mounted) return;
      if (id != null) {
        await ref.read(draftStorageProvider).clear();
        if (!mounted) return;
      }
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cotizacion #$id guardada.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizacion')),
      body: SafeArea(
        child: state.mode == CalculatorMode.express
            ? _buildExpressForm(state, notifier, theme)
            : _buildAdvancedForm(state, notifier, theme),
      ),
    );
  }

  Widget _buildExpressForm(
    CalculatorState state,
    CalculatorNotifier notifier,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSelector(mode: state.mode, onChanged: _switchMode),
          const SizedBox(height: 12),
          _PrinterIndicator(),
          const SizedBox(height: 16),
          // 1. Label (top)
          Text('Etiqueta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Etiqueta',
              helperText: 'Opcional — ej: Soporte pared',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          // 2. Filament section (peso + precio, sin gramos)
          _FilamentSection(
            weightCtrl: _weightCtrl,
            priceCtrl: _priceCtrl,
            onWeightChanged: notifier.setWeight,
            onPriceChanged: notifier.setFilamentPrice,
          ),
          const SizedBox(height: 20),
          // 3. Time
          Text('Tiempo impresion', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DecimalInputField(
                  label: 'Horas',
                  controller: _hoursCtrl,
                  onChanged: notifier.setPrintHours,
                  suffix: 'h',
                  helperText: 'Tiempo impresion',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecimalInputField(
                  label: 'Minutos',
                  controller: _minutesCtrl,
                  onChanged: notifier.setPrintMinutes,
                  suffix: 'min',
                  helperText: '0-59',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4. Discount
          DecimalInputField(
            label: 'Descuento',
            controller: _discountCtrl,
            onChanged: notifier.setDiscountPct,
            suffix: '%',
            helperText: 'Porcentaje sobre total final',
          ),
          const SizedBox(height: 24),
          // 5. Output section with summary + calculando animation
          const _OutputSection(),
          const SizedBox(height: 24),
          // 6. Bottom buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar cotizacion'),
                  onPressed: _showSaveDialog,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Restablecer'),
                onPressed: _resetAll,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedForm(
    CalculatorState state,
    CalculatorNotifier notifier,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSelector(mode: state.mode, onChanged: _switchMode),
          const SizedBox(height: 12),
          _PrinterIndicator(),
          const SizedBox(height: 16),
          // 1. Label (top)
          Text('Etiqueta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Etiqueta',
              helperText: 'Opcional — ej: Soporte pared',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          // 2. Materials list
          Text('Materiales', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
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
                  ctrls: _materialCtrls[index],
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addMaterial,
            icon: const Icon(Icons.add),
            label: const Text('Agregar material'),
          ),
          const SizedBox(height: 20),
          // 3. Time
          Text('Tiempo impresion', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DecimalInputField(
                  label: 'Horas',
                  controller: _hoursCtrl,
                  onChanged: notifier.setPrintHours,
                  suffix: 'h',
                  helperText: 'Tiempo impresion',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecimalInputField(
                  label: 'Minutos',
                  controller: _minutesCtrl,
                  onChanged: notifier.setPrintMinutes,
                  suffix: 'min',
                  helperText: '0-59',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4. Discount
          DecimalInputField(
            label: 'Descuento',
            controller: _discountCtrl,
            onChanged: notifier.setDiscountPct,
            suffix: '%',
            helperText: 'Porcentaje sobre total final',
          ),
          const SizedBox(height: 24),
          // 5. Output section with summary + calculando animation
          const _OutputSection(),
          const SizedBox(height: 24),
          // 6. Bottom buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar cotizacion'),
                  onPressed: _showSaveDialog,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Restablecer'),
                onPressed: _resetAll,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seccion de filamento con selector opcional de catalogo.
class _FilamentSection extends ConsumerWidget {
  const _FilamentSection({
    required this.weightCtrl,
    required this.priceCtrl,
    required this.onWeightChanged,
    required this.onPriceChanged,
  });

  final TextEditingController weightCtrl;
  final TextEditingController priceCtrl;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onPriceChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.valueOrNull ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pieza y filamento', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DecimalInputField(
          label: 'Peso',
          controller: weightCtrl,
          onChanged: onWeightChanged,
          suffix: 'g',
          helperText: 'Gramos de la pieza',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DecimalInputField(
                label: 'Precio bobina',
                controller: priceCtrl,
                onChanged: onPriceChanged,
                suffix: 'BOB',
                helperText: 'Costo del rollo (default 1000g)',
              ),
            ),
            if (filaments.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.star),
                tooltip: 'Usar filamento default',
                onPressed: defaultFilament != null
                    ? () => _loadFilament(ref, defaultFilament, priceCtrl)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.inventory_2_outlined),
                tooltip: 'Seleccionar filamento del catalogo',
                onPressed: () =>
                    _showFilamentDialog(context, ref, filaments, priceCtrl),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _loadFilament(WidgetRef ref, Filament f,
      TextEditingController priceCtrl) {
    ref.read(calculatorNotifierProvider.notifier).loadFilamentDefaults(
          pricePerBobbin: f.pricePerBobbin.toStringAsFixed(2),
          gramsPerBobbin: f.gramsPerBobbin.toStringAsFixed(0),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updated = ref.read(calculatorNotifierProvider);
      priceCtrl.text = updated.filamentPrice;
    });
  }

  void _showFilamentDialog(
    BuildContext context,
    WidgetRef ref,
    List<Filament> filaments,
    TextEditingController priceCtrl,
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
                leading: const Icon(Icons.label_outline),
                title: Text(f.name),
                subtitle: Text(
                  '${f.pricePerBobbin.toStringAsFixed(0)} BOB · '
                  '${f.gramsPerBobbin.toStringAsFixed(0)} g'
                  '${f.isDefault ? ' (default)' : ''}',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _loadFilament(ref, f, priceCtrl);
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

// === Printer indicator ===

class _PrinterIndicator extends ConsumerWidget {
  const _PrinterIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activePrinter = ref.watch(activePrinterProvider);
    final printersAsync = ref.watch(printersListProvider);
    final printers = printersAsync.valueOrNull ?? <PrinterProfile>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Impresora', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: printers.isEmpty
              ? null
              : () => _showPrinterDialog(context, ref, printers),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.print_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: activePrinter != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(activePrinter.name,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500)),
                            Text(
                              activePrinter.brand != null &&
                                      activePrinter.brand!.isNotEmpty
                                  ? '${activePrinter.brand} · ${activePrinter.averageWatts} W'
                                  : '${activePrinter.averageWatts} W',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        )
                      : Text('Sin impresora registrada',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme
                                  .colorScheme.onSurfaceVariant)),
                ),
                if (printers.isNotEmpty)
                  const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ],
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
                leading: const Icon(Icons.print_outlined),
                title: Text(p.name),
                subtitle: Text(
                  '${p.brand != null && p.brand!.isNotEmpty ? '${p.brand} · ' : ''}${p.averageWatts} W'
                  '${p.isDefault ? ' (default)' : ''}',
                ),
                onTap: () {
                  ref.read(activePrinterIdProvider.notifier).state =
                      p.id;
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

// === MaterialRow y controllers (sin cambios funcionales) ===

/// Bundle de controllers para 1 fila de material en modo advanced.
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

class _MaterialRowTile extends StatelessWidget {
  const _MaterialRowTile({
    required this.index,
    required this.ctrls,
    required this.onChanged,
    required this.onRemove,
    required this.pending,
  });

  final int index;
  final _MaterialCtrls ctrls;
  final ValueChanged<_MaterialUpdate> onChanged;
  final VoidCallback onRemove;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    if (pending) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Material ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Quitar',
                  onPressed: onRemove,
                ),
              ],
            ),
            TextField(
              controller: ctrls.label,
              decoration: const InputDecoration(
                labelText: 'Etiqueta',
                helperText: 'Opcional (ej: PLA base)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _emit(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DecimalInputField(
                    label: 'Peso',
                    controller: ctrls.weight,
                    onChanged: (v) => _emit(),
                    suffix: 'g',
                    helperText: 'Gramos en la pieza',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DecimalInputField(
                    label: 'Precio bobina',
                    controller: ctrls.price,
                    onChanged: (v) => _emit(),
                    suffix: 'BOB',
                    helperText: 'Costo del rollo',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DecimalInputField(
                    label: 'Gramos / bobina',
                    controller: ctrls.grams,
                    onChanged: (v) => _emit(),
                    suffix: 'g',
                    helperText: 'Tipico 1000',
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
    onChanged(_MaterialUpdate(
      label: ctrls.label.text,
      weight: ctrls.weight.text,
      pricePerBobbin: ctrls.price.text,
      gramsPerBobbin: ctrls.grams.text,
    ));
  }
}

// === Output section (resumen + animacion "calculando...") ===

/// Seccion de output con animacion "Calculando..." y tarjeta resumen.
/// Reemplaza al antiguo _OutputCard con desglose plano.
class _OutputSection extends ConsumerStatefulWidget {
  const _OutputSection();

  @override
  ConsumerState<_OutputSection> createState() => _OutputSectionState();
}

class _OutputSectionState extends ConsumerState<_OutputSection> {
  bool _calculating = false;
  Timer? _calcTimer;

  @override
  void dispose() {
    _calcTimer?.cancel();
    super.dispose();
  }

  void _triggerCalculating() {
    _calcTimer?.cancel();
    if (!mounted) return;
    setState(() => _calculating = true);
    _calcTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _calculating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CalculatorState>(calculatorNotifierProvider, (prev, next) {
      final outputChanged = prev?.output != next.output;
      final versionChanged = prev?.computeVersion != next.computeVersion;
      if ((outputChanged || versionChanged) && next.output != null) {
        _triggerCalculating();
      }
    });

    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final theme = Theme.of(context);
    final output = state.output;

    return Column(
      children: [
        if (_calculating)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 12),
                Text('Calculando...'),
              ],
            ),
          )
        else if (output == null)
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completa peso, precio y tiempo de impresion '
                      'para ver la cotizacion.',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _SummaryCard(
            output: output,
            label: state.label,
            discountPct: state.detailDiscountPct?.toStringAsFixed(0) ??
                state.discountPct,
            showDetail: state.showDetail,
            onToggleDetail: notifier.toggleDetail,
            detailElectricCost: state.detailElectricCost,
            detailBaseCost: state.detailBaseCost,
            detailProfitAmount: state.detailProfitAmount,
            detailTotalFinal: state.detailTotalFinal,
          ),
      ],
    );
  }
}

/// Tarjeta resumen de la cotizacion.
/// Muestra: etiqueta (opcional), fecha/hora, precio grande,
/// detalle de descuento (si aplica), y ojito para desglose completo.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.output,
    required this.label,
    required this.discountPct,
    required this.showDetail,
    required this.onToggleDetail,
    required this.detailElectricCost,
    required this.detailBaseCost,
    required this.detailProfitAmount,
    required this.detailTotalFinal,
  });

  final CalculationOutput output;
  final String label;
  final String discountPct;
  final bool showDetail;
  final VoidCallback onToggleDetail;
  final Decimal? detailElectricCost;
  final Decimal? detailBaseCost;
  final Decimal? detailProfitAmount;
  final Decimal? detailTotalFinal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLabel = label.trim().isNotEmpty;
    final hasDiscount = output.discountAmount > Decimal.zero;
    final now = DateTime.now();

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Etiqueta (opcional)
            if (hasLabel) ...[
              Text(label,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
            ],
            // Fecha/hora
            Text(DateFormat('dd MMM yyyy HH:mm').format(now),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            // Precio grande — precio final tras descuento (sobre totalFinal con % x2)
            Text(formatBob(output.totalPrice),
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            // Descuento
            if (hasDiscount) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Descuento ${discountPct}%: -'
                      '${formatBob(output.discountAmount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer),
                    ),
                    const SizedBox(height: 4),
                    Text('Total final: ${formatBob(output.totalPrice)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer)),
                  ],
                ),
              ),
            ],
            // Ojito toggle
            const SizedBox(height: 16),
            Align(
              child: TextButton.icon(
                icon: Icon(
                  showDetail ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                ),
                label:
                    Text(showDetail ? 'Ocultar detalle' : 'Ver detalle'),
                onPressed: onToggleDetail,
              ),
            ),
            // Desglose completo (ojito visible)
            if (showDetail) ...[
              const Divider(height: 8),
              _DetailSection(
                materialCost: output.materialCost,
                electricCost: detailElectricCost ?? Decimal.zero,
                baseCost: detailBaseCost ?? Decimal.zero,
                profitAmount: detailProfitAmount ?? Decimal.zero,
                totalFinal: detailTotalFinal ?? Decimal.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Desglose detallado de costos (electricidad, ganancia, etc).
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.materialCost,
    required this.electricCost,
    required this.baseCost,
    required this.profitAmount,
    required this.totalFinal,
  });

  final Decimal materialCost;
  final Decimal electricCost;
  final Decimal baseCost;
  final Decimal profitAmount;
  final Decimal totalFinal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final profitColor = theme.colorScheme.primary;
    return Column(
      children: [
        _dr('Costo material', formatBob(materialCost), s),
        _dr('Costo energia', formatBob(electricCost), s),
        _dr('Costo base', formatBob(baseCost), s),
        _dr('Ganancia', formatBob(profitAmount), s, isProfit: true,
            profitColor: profitColor),
        const Divider(height: 12),
        _dr('Costo total final', formatBob(totalFinal), s, isTotal: true),
      ],
    );
  }

  Widget _dr(String label, String value, TextStyle? style,
      {bool isProfit = false, bool isTotal = false,
      Color? profitColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: style?.copyWith(
                  fontWeight: isTotal ? FontWeight.w600 : null)),
          Text(value,
              style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isProfit ? profitColor : null,
              )),
        ],
      ),
    );
  }
}

// === Selector de modo (sin cambios) ===

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
          icon: Icon(Icons.flash_on),
        ),
        ButtonSegment(
          value: CalculatorMode.advanced,
          label: Text('Advanced'),
          icon: Icon(Icons.layers),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

// === Save dialog (simplificado, sin pieceName — usa label) ===

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
              border: OutlineInputBorder(),
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
