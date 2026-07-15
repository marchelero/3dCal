// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/providers.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/decimal_input_field.dart';

/// Pantalla principal del calculator.
///
/// **Modos** (toggle en AppBar):
/// - `express`: 1 material con 8 inputs top-level.
/// - `advanced`: lista de materiales con [AnimatedList], inputs comunes
///   (tiempo, watts, kwh, profit, descuento) abajo.
class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  // Common controllers (ambos modos).
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _wattsCtrl;
  late final TextEditingController _kwhCtrl;
  late final TextEditingController _profitCtrl;
  late final TextEditingController _discountCtrl;

  // Express controllers.
  late final TextEditingController _weightCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _gramsCtrl;

  // Advanced controllers: List<MaterialCtrls>, uno por material.
  final List<_MaterialCtrls> _materialCtrls = [];
  final _advancedListKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    final initial = ref.read(calculatorNotifierProvider);
    _weightCtrl = TextEditingController(text: initial.weight);
    _hoursCtrl = TextEditingController(text: initial.printHours);
    _wattsCtrl = TextEditingController(text: initial.printerWatts);
    _kwhCtrl = TextEditingController(text: initial.kwhRate);
    _profitCtrl = TextEditingController(text: initial.profitPct);
    _discountCtrl = TextEditingController(text: initial.discountPct);
    _priceCtrl = TextEditingController(text: initial.filamentPrice);
    _gramsCtrl = TextEditingController(text: initial.filamentGrams);

    // Si ya esta en advanced mode con materials, sincronizar controllers.
    if (initial.mode == CalculatorMode.advanced) {
      for (final m in initial.materials) {
        _materialCtrls.add(_MaterialCtrls.fromRow(m));
      }
    }

    // Auto-poblar filamento default + impresora activa DESPUES del build.
    // Riverpod no permite modificar providers durante initState (crashea en
    // web). addPostFrameCallback ejecuta despues del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
      final activePrinter = ref.read(activePrinterProvider);
      if (activePrinter != null) {
        ref
            .read(calculatorNotifierProvider.notifier)
            .setPrinterWatts(activePrinter.averageWatts.toString());
        _wattsCtrl.text = activePrinter.averageWatts.toString();
      }
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _hoursCtrl.dispose();
    _wattsCtrl.dispose();
    _kwhCtrl.dispose();
    _profitCtrl.dispose();
    _discountCtrl.dispose();
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    for (final c in _materialCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchMode(CalculatorMode mode) {
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    if (mode == CalculatorMode.advanced &&
        _materialCtrls.isEmpty) {
      // Inicializar 1 material vacio al entrar a advanced.
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
    _wattsCtrl.text = i.printerWatts;
    _kwhCtrl.text = i.kwhRate;
    _profitCtrl.text = i.profitPct;
    _discountCtrl.text = i.discountPct;
    _priceCtrl.text = i.filamentPrice;
    _gramsCtrl.text = i.filamentGrams;
    // Dispose advanced ctrls.
    for (final c in _materialCtrls) {
      c.dispose();
    }
    _materialCtrls.clear();
  }

  /// Muestra dialog para guardar la cotizacion actual.
  ///
  /// - Si el form no es valido, muestra snackbar y no abre dialog.
  /// - Si el user guarda, delega a [CalculatorNotifier.save] y muestra
  ///   snackbar de exito/error.
  Future<void> _showSaveDialog() async {
    final state = ref.read(calculatorNotifierProvider);
    if (!state.isValid || state.output == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el form antes de guardar.'),
        ),
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
            pieceName: result.pieceName,
            clientName: result.clientName,
          );
      if (!mounted) return;
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
        title: const Text('Cotizacion express'),
        actions: [
          IconButton(
            tooltip: 'Guardar cotizacion',
            icon: const Icon(Icons.save),
            onPressed: _showSaveDialog,
          ),
          _PrinterSelector(
            onSelected: (printer) {
              ref.read(activePrinterIdProvider.notifier).state = printer.id;
              notifier.setPrinterWatts(printer.averageWatts.toString());
              _wattsCtrl.text = printer.averageWatts.toString();
            },
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
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
          _ModeSelector(
            mode: state.mode,
            onChanged: _switchMode,
          ),
          const SizedBox(height: 16),
          Text('Parametros de la pieza', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          DecimalInputField(
            label: 'Peso',
            controller: _weightCtrl,
            onChanged: notifier.setWeight,
            suffix: 'g',
            helperText: 'Gramos de la pieza',
          ),
        const SizedBox(height: 24),
        Text('Filamento', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DecimalInputField(
                label: 'Precio bobina',
                controller: _priceCtrl,
                onChanged: notifier.setFilamentPrice,
                suffix: 'BOB',
                helperText: 'Costo del rollo',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DecimalInputField(
                label: 'Gramos / bobina',
                controller: _gramsCtrl,
                onChanged: notifier.setFilamentGrams,
                suffix: 'g',
                helperText: 'Tipico 1000',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _commonFields(notifier),
        const SizedBox(height: 24),
        _OutputCard(state: state),
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
          _ModeSelector(
            mode: state.mode,
            onChanged: _switchMode,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          _commonFields(notifier),
          const SizedBox(height: 24),
          _OutputCard(state: state),
        ],
      ),
    );
  }

  Widget _commonFields(CalculatorNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tiempo y equipo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DecimalInputField(
                label: 'Tiempo',
                controller: _hoursCtrl,
                onChanged: notifier.setPrintHours,
                suffix: 'h',
                helperText: 'Horas de impresion',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DecimalInputField(
                label: 'Watts',
                controller: _wattsCtrl,
                onChanged: notifier.setPrinterWatts,
                suffix: 'W',
                helperText: 'Consumo impresora',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DecimalInputField(
                label: 'Tarifa kWh',
                controller: _kwhCtrl,
                onChanged: notifier.setKwhRate,
                suffix: 'BOB',
                helperText: '0.60-0.80 BOB/kWh',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DecimalInputField(
                label: 'Profit',
                controller: _profitCtrl,
                onChanged: notifier.setProfitPct,
                suffix: '%',
                helperText: 'Markup sobre costo',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DecimalInputField(
                label: 'Descuento',
                controller: _discountCtrl,
                onChanged: notifier.setDiscountPct,
                suffix: '%',
                helperText: 'Penaliza profit x2',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.state});

  final CalculatorState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final output = state.output;
    if (output == null) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Completa peso, tiempo, precio y gramos del filamento '
                  'para ver la cotizacion.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isNegativeProfit =
        output.effectiveProfitPercentage < Decimal.zero;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precio final', style: theme.textTheme.titleMedium),
                Text(
                  formatBob(output.totalPrice),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _OutputRow(
                label: 'Costo material', value: formatBob(output.materialCost)),
            _OutputRow(
                label: 'Costo electrico',
                value: formatBob(output.electricCost)),
            _OutputRow(label: 'Costo base', value: formatBob(output.baseCost)),
            _OutputRow(
              label: 'Profit efectivo',
              value:
                  '${formatPercentage(output.effectiveProfitPercentage)}  '
                  '(${formatBob(output.profitAmount)})',
              valueColor: isNegativeProfit
                  ? theme.colorScheme.error
                  : theme.colorScheme.onPrimaryContainer,
            ),
            if (isNegativeProfit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Descuento agresivo: profit efectivo < 0. '
                        'Se cobra profit = 0 (no se vende a perdida).',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de impresora en el AppBar del calculator.
class _PrinterSelector extends ConsumerWidget {
  const _PrinterSelector({required this.onSelected});

  final ValueChanged<PrinterProfile> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activePrinterProvider);
    final async = ref.watch(printersListProvider);
    final printers = async.valueOrNull ?? const <PrinterProfile>[];
    final label = active?.name ?? 'Sin impresora';
    return PopupMenuButton<PrinterProfile>(
      tooltip: 'Impresora activa',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final p in printers)
          PopupMenuItem<PrinterProfile>(
            value: p,
            child: Row(
              children: [
                Icon(
                  p.isDefault ? Icons.star : Icons.print,
                  size: 18,
                  color: p.id == active?.id
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(p.name)),
                Text('${p.averageWatts} W',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.print, size: 20),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Selector de modo (Express / Advanced) mostrado al inicio del body.
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

/// Resultado del dialog de guardar.
class _SaveResult {
  const _SaveResult({this.pieceName, this.clientName});
  final String? pieceName;
  final String? clientName;
}

/// Dialog modal para capturar nombre de pieza / cliente antes de guardar.
///
/// Ambos campos son opcionales. Si el user los deja vacios, se guardan
/// como `null` (proforma rapida).
class _SaveDialog extends StatefulWidget {
  const _SaveDialog();

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  final _pieceCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();

  @override
  void dispose() {
    _pieceCtrl.dispose();
    _clientCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _SaveResult(
        pieceName: _pieceCtrl.text,
        clientName: _clientCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar cotizacion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pieceCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la pieza',
              helperText: 'Opcional',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          const SizedBox(height: 12),
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
