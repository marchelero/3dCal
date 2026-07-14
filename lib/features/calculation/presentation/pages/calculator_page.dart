// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money/currency_formatter.dart';
import '../state/calculator_notifier.dart';
import '../state/calculator_state.dart';
import '../widgets/decimal_input_field.dart';

/// Pantalla principal del calculator (modo express, single material).
///
/// **Comportamiento**:
/// - Form con 8 inputs (peso, tiempo, watts, kwh, profit%, descuento%,
///   precio bobina, gramos por bobina).
/// - El output aparece abajo **solo cuando el form es valido** y muestra:
///   materialCost, electricCost, baseCost, effProfit%, profitAmount, totalPrice.
/// - Advertencia visual si `effProfit < 0` (descuento agresivo vs profit base).
/// - Boton "Reset" restaura los defaults MVP.
class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _wattsCtrl;
  late final TextEditingController _kwhCtrl;
  late final TextEditingController _profitCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _gramsCtrl;

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
    super.dispose();
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
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              notifier.reset();
              // Sincronizar controllers con el state reseteado.
              final i = CalculatorState.initial();
              _weightCtrl.text = i.weight;
              _hoursCtrl.text = i.printHours;
              _wattsCtrl.text = i.printerWatts;
              _kwhCtrl.text = i.kwhRate;
              _profitCtrl.text = i.profitPct;
              _discountCtrl.text = i.discountPct;
              _priceCtrl.text = i.filamentPrice;
              _gramsCtrl.text = i.filamentGrams;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Parametros de la pieza',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DecimalInputField(
                    label: 'Peso',
                    controller: _weightCtrl,
                    onChanged: notifier.setWeight,
                    suffix: 'g',
                    helperText: 'Gramos de la pieza',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecimalInputField(
                    label: 'Tiempo',
                    controller: _hoursCtrl,
                    onChanged: notifier.setPrintHours,
                    suffix: 'h',
                    helperText: 'Horas de impresion',
                  ),
                ),
              ],
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
            Text('Equipo y operacion', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DecimalInputField(
                    label: 'Watts',
                    controller: _wattsCtrl,
                    onChanged: notifier.setPrinterWatts,
                    suffix: 'W',
                    helperText: 'Consumo impresora',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecimalInputField(
                    label: 'Tarifa kWh',
                    controller: _kwhCtrl,
                    onChanged: notifier.setKwhRate,
                    suffix: 'BOB',
                    helperText: '0.60-0.80 BOB/kWh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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
            const SizedBox(height: 24),
            _OutputCard(state: state),
          ],
        ),
      ),
    );
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
            _Row(label: 'Costo material', value: formatBob(output.materialCost)),
            _Row(
                label: 'Costo electrico',
                value: formatBob(output.electricCost)),
            _Row(label: 'Costo base', value: formatBob(output.baseCost)),
            _Row(
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

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
