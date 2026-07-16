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

/// Pantalla principal del calculator con UX mejorada.
///
/// **Secciones en Cards**:
/// 1. Etiqueta + Peso de pieza
/// 2. Filamento (precio bobina + gramos + selector catalogo)
/// 3. Impresora activa
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
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode selector
          _ModeSelector(mode: state.mode, onChanged: _switchMode),
          const SizedBox(height: 16),

          // Card: Pieza
          _SectionCard(
            icon: Icons.category_rounded,
            title: 'Pieza',
            child: Column(
              children: [
                _buildLabelField(theme),
                const SizedBox(height: 12),
                DecimalInputField(
                  label: 'Peso de la pieza',
                  controller: _weightCtrl,
                  onChanged: notifier.setWeight,
                  suffix: 'g',
                  helperText: 'Gramos del modelo',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card: Filamento
          _SectionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Filamento',
            child: _FilamentSection(
              weightCtrl: _weightCtrl,
              priceCtrl: _priceCtrl,
              gramsCtrl: _gramsCtrl,
              onWeightChanged: notifier.setWeight,
              onPriceChanged: notifier.setFilamentPrice,
              onGramsChanged: notifier.setFilamentGrams,
            ),
          ),
          const SizedBox(height: 12),

          // Card: Impresora
          _SectionCard(
            icon: Icons.print_rounded,
            title: 'Impresora',
            child: _PrinterIndicator(),
          ),
          const SizedBox(height: 12),

          // Card: Tiempo
          _SectionCard(
            icon: Icons.timer_rounded,
            title: 'Tiempo de impresion',
            child: Row(
              children: [
                Expanded(
                  child: DecimalInputField(
                    label: 'Horas',
                    controller: _hoursCtrl,
                    onChanged: notifier.setPrintHours,
                    suffix: 'h',
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
          ),
          const SizedBox(height: 12),

          // Card: Descuento
          _SectionCard(
            icon: Icons.local_offer_rounded,
            title: 'Descuento',
            child: DecimalInputField(
              label: 'Descuento',
              controller: _discountCtrl,
              onChanged: notifier.setDiscountPct,
              suffix: '%',
              helperText: 'Porcentaje sobre el total final',
            ),
          ),
          const SizedBox(height: 20),

          // Output section
          const _OutputSection(),
          const SizedBox(height: 20),

          // Save button
          FilledButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar cotizacion'),
            onPressed: _showSaveDialog,
          ),
          const SizedBox(height: 12),

          // Reset link (text button, less prominent)
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Restablecer valores'),
              onPressed: _resetAll,
            ),
          ),
          const SizedBox(height: 24),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSelector(mode: state.mode, onChanged: _switchMode),
          const SizedBox(height: 16),

          // Card: Pieza
          _SectionCard(
            icon: Icons.category_rounded,
            title: 'Pieza',
            child: _buildLabelField(theme),
          ),
          const SizedBox(height: 12),

          // Card: Materiales
          _SectionCard(
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
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar material'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card: Impresora
          _SectionCard(
            icon: Icons.print_rounded,
            title: 'Impresora',
            child: _PrinterIndicator(),
          ),
          const SizedBox(height: 12),

          // Card: Tiempo
          _SectionCard(
            icon: Icons.timer_rounded,
            title: 'Tiempo de impresion',
            child: Row(
              children: [
                Expanded(
                  child: DecimalInputField(
                    label: 'Horas',
                    controller: _hoursCtrl,
                    onChanged: notifier.setPrintHours,
                    suffix: 'h',
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
          ),
          const SizedBox(height: 12),

          // Card: Descuento
          _SectionCard(
            icon: Icons.local_offer_rounded,
            title: 'Descuento',
            child: DecimalInputField(
              label: 'Descuento',
              controller: _discountCtrl,
              onChanged: notifier.setDiscountPct,
              suffix: '%',
              helperText: 'Porcentaje sobre el total final',
            ),
          ),
          const SizedBox(height: 20),

          // Output section
          const _OutputSection(),
          const SizedBox(height: 20),

          // Save button
          FilledButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar cotizacion'),
            onPressed: _showSaveDialog,
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Restablecer valores'),
              onPressed: _resetAll,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLabelField(ThemeData theme) {
    return TextField(
      controller: _labelCtrl,
      decoration: const InputDecoration(
        labelText: 'Etiqueta (opcional)',
        helperText: 'Ej: Soporte pared, Engranaje PETG',
        prefixIcon: Icon(Icons.label_outline),
      ),
    );
  }
}

// ============================================================
// SECTION CARD — wrapper reutilizable con icono + titulo
// ============================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FILAMENT SECTION
// ============================================================

class _FilamentSection extends ConsumerWidget {
  const _FilamentSection({
    required this.weightCtrl,
    required this.priceCtrl,
    required this.gramsCtrl,
    required this.onWeightChanged,
    required this.onPriceChanged,
    required this.onGramsChanged,
  });

  final TextEditingController weightCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController gramsCtrl;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onGramsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filamentsAsync = ref.watch(filamentsNotifierProvider);
    final filaments = filamentsAsync.valueOrNull ?? <Filament>[];
    final defaultFilament = ref.watch(defaultFilamentProvider);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecimalInputField(
                label: 'Precio bobina',
                controller: priceCtrl,
                onChanged: onPriceChanged,
                suffix: 'BOB',
                helperText: 'Costo del rollo',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DecimalInputField(
                label: 'Gramos bobina',
                controller: gramsCtrl,
                onChanged: onGramsChanged,
                suffix: 'g',
                helperText: 'Tipico 1000g',
              ),
            ),
          ],
        ),
        if (filaments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (defaultFilament != null)
                _ActionChip(
                  icon: Icons.star_rounded,
                  label: 'Usar ${defaultFilament.name}',
                  onTap: () => _loadFilament(ref, defaultFilament, priceCtrl, gramsCtrl),
                ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.inventory_2_rounded,
                label: 'Catalogo',
                onTap: () =>
                    _showFilamentDialog(context, ref, filaments, priceCtrl, gramsCtrl),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _loadFilament(WidgetRef ref, Filament f,
      TextEditingController priceCtrl, TextEditingController gramsCtrl) {
    ref.read(calculatorNotifierProvider.notifier).loadFilamentDefaults(
          pricePerBobbin: f.pricePerBobbin.toStringAsFixed(2),
          gramsPerBobbin: f.gramsPerBobbin.toStringAsFixed(0),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updated = ref.read(calculatorNotifierProvider);
      priceCtrl.text = updated.filamentPrice;
      gramsCtrl.text = updated.filamentGrams;
    });
  }

  void _showFilamentDialog(
    BuildContext context,
    WidgetRef ref,
    List<Filament> filaments,
    TextEditingController priceCtrl,
    TextEditingController gramsCtrl,
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
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    f.isDefault ? Icons.star_rounded : Icons.label_rounded,
                    color: f.isDefault ? Colors.amber : Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(f.name),
                subtitle: Text(
                  '${f.pricePerBobbin.toStringAsFixed(0)} BOB · '
                  '${f.gramsPerBobbin.toStringAsFixed(0)} g'
                  '${f.isDefault ? ' (default)' : ''}',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _loadFilament(ref, f, priceCtrl, gramsCtrl);
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
      borderRadius: BorderRadius.circular(12),
      onTap: printers.isEmpty
          ? null
          : () => _showPrinterDialog(context, ref, printers),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.print_rounded,
                  size: 20, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: activePrinter != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(activePrinter.name,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          activePrinter.brand != null &&
                                  activePrinter.brand!.isNotEmpty
                              ? '${activePrinter.brand} · ${activePrinter.averageWatts} W'
                              : '${activePrinter.averageWatts} W',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  : Text('Sin impresora registrada',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            if (printers.isNotEmpty)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
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
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.print_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
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

// === MaterialRow y controllers ===

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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
              Text('Material ${index + 1}',
                  style: theme.textTheme.titleSmall),
              const Spacer(),
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
          const SizedBox(height: 8),
          TextField(
            controller: ctrls.label,
            decoration: const InputDecoration(
              labelText: 'Etiqueta',
              helperText: 'Opcional (ej: PLA base)',
              isDense: true,
              prefixIcon: Icon(Icons.label_outline, size: 18),
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DecimalInputField(
                  label: 'Precio bobina',
                  controller: ctrls.price,
                  onChanged: (v) => _emit(),
                  suffix: 'BOB',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DecimalInputField(
                  label: 'Gramos / bobina',
                  controller: ctrls.grams,
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
    onChanged(_MaterialUpdate(
      label: ctrls.label.text,
      weight: ctrls.weight.text,
      pricePerBobbin: ctrls.price.text,
      gramsPerBobbin: ctrls.grams.text,
    ));
  }
}

// === Output section ===

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
    _calcTimer = Timer(const Duration(milliseconds: 1200), () {
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
    final theme = Theme.of(context);
    final output = state.output;

    return Column(
      children: [
        if (_calculating)
          _CalculatingAnimation()
        else if (output == null)
          _EmptyOutput(theme: theme)
        else
          _SummaryCard(
            output: output,
            label: state.label,
            discountPct: state.detailDiscountPct?.toStringAsFixed(0) ??
                state.discountPct,
            showDetail: state.showDetail,
            onToggleDetail: () =>
                ref.read(calculatorNotifierProvider.notifier).toggleDetail(),
            detailElectricCost: state.detailElectricCost,
            detailBaseCost: state.detailBaseCost,
            detailProfitAmount: state.detailProfitAmount,
            detailTotalFinal: state.detailTotalFinal,
          ),
      ],
    );
  }
}

class _CalculatingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Calculando...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOutput extends StatelessWidget {
  const _EmptyOutput({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, size: 32, color: color.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Completa peso, precio y tiempo de impresion\npara ver la cotizacion.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta resumen de la cotizacion — version mejorada.
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
    final color = theme.colorScheme;
    final hasLabel = label.trim().isNotEmpty;
    final hasDiscount = output.discountAmount > Decimal.zero;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primaryContainer,
            color.primaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label
          if (hasLabel) ...[
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.onPrimaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('dd MMM yyyy HH:mm').format(now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onPrimaryContainer.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Big price
          Text(
            formatBob(output.totalPrice),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.onPrimaryContainer,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle
          Text(
            'Total ${hasDiscount ? 'con descuento' : 'final'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          // Discount badge
          if (hasDiscount) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.errorContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Descuento $discountPct%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '-${formatBob(output.discountAmount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Toggle detail
          const SizedBox(height: 16),
          Align(
            child: TextButton.icon(
              icon: Icon(
                showDetail ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 18,
                color: color.onPrimaryContainer,
              ),
              label: Text(
                showDetail ? 'Ocultar detalle' : 'Ver detalle',
                style: TextStyle(color: color.onPrimaryContainer),
              ),
              onPressed: onToggleDetail,
            ),
          ),

          // Detail breakdown
          if (showDetail) ...[
            const Divider(height: 8, color: Colors.white24),
            const SizedBox(height: 8),
            _DetailSection(
              materialCost: output.materialCost,
              electricCost: detailElectricCost ?? Decimal.zero,
              baseCost: detailBaseCost ?? Decimal.zero,
              profitAmount: detailProfitAmount ?? Decimal.zero,
              totalFinal: detailTotalFinal ?? Decimal.zero,
              textColor: color.onPrimaryContainer,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.materialCost,
    required this.electricCost,
    required this.baseCost,
    required this.profitAmount,
    required this.totalFinal,
    this.textColor,
  });

  final Decimal materialCost;
  final Decimal electricCost;
  final Decimal baseCost;
  final Decimal profitAmount;
  final Decimal totalFinal;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = textColor ?? theme.colorScheme.onSurface;
    final s = theme.textTheme.bodySmall?.copyWith(
      color: tc.withValues(alpha: 0.8),
    );
    return Column(
      children: [
        _dr('Costo material', formatBob(materialCost), s, tc: tc),
        _dr('Costo energia', formatBob(electricCost), s, tc: tc),
        _dr('Costo base', formatBob(baseCost), s, tc: tc),
        _dr('Ganancia', formatBob(profitAmount), s,
            tc: theme.colorScheme.primary, isProfit: true),
        const Divider(height: 12, color: Colors.white24),
        _dr('Costo total final', formatBob(totalFinal), s, tc: tc, isTotal: true),
      ],
    );
  }

  Widget _dr(String label, String value, TextStyle? style,
      {Color? tc, bool isProfit = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: style?.copyWith(
                fontWeight: isTotal ? FontWeight.w600 : null,
                color: tc?.withValues(alpha: isTotal ? 1.0 : 0.8),
              )),
          Text(value,
              style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: isTotal
                    ? FontWeight.bold
                    : isProfit
                        ? FontWeight.w600
                        : FontWeight.w500,
                color: isProfit
                    ? tc
                    : isTotal
                        ? tc
                        : tc?.withValues(alpha: 0.8),
              )),
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
