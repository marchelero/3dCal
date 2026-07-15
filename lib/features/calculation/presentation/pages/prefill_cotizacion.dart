// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../state/calculator_notifier.dart';
import 'calculator_page.dart';

/// Wrapper de [CalculatorPage] que pre-rellena el form desde una cotizacion
/// guardada (accion "Reusar" en el detalle).
///
/// **Comportamiento**:
/// - En `initState`, programa un post-frame callback que llama a
///   [CalculatorNotifier.loadFromCalculation] con [calc].
/// - El state se reemplaza ANTES del primer build visible del calculator
///   (el `addPostFrameCallback` corre antes del siguiente paint).
/// - Al volver a Home, la calculator queda con el state prefill (esto es
///   intencional: si el user quiere empezar de cero, presiona Reset).
class PrefilledCalculatorPage extends ConsumerStatefulWidget {
  const PrefilledCalculatorPage({super.key, required this.calc});

  final Calculation calc;

  @override
  ConsumerState<PrefilledCalculatorPage> createState() =>
      _PrefilledCalculatorPageState();
}

class _PrefilledCalculatorPageState
    extends ConsumerState<PrefilledCalculatorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(calculatorNotifierProvider.notifier)
          .loadFromCalculation(widget.calc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const CalculatorPage();
  }
}
