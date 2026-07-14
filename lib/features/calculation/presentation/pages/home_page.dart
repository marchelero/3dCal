import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/currency_formatter.dart';

/// Placeholder de HomePage.
///
/// Sprint 0: solo muestra que la app arranca, tema M3 funciona, y un ejemplo
/// del formateador de moneda BOB. Sprint 4 lo reemplaza por la pantalla real
/// con CalculationFormNotifier + Express/Avanzado.
class HomePage extends StatelessWidget {
  /// Crea la pantalla principal placeholder de Sprint 0.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('3dcal'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sprint 0 listo',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bootstrap + estructura + tema M3. Falta motor, '
                        'drift, formularios, history y dashboard.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Smoke test formatter:',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(formatBob(Decimal.fromInt(1234))),
                      Text(formatBob(Decimal.parse('46.05'))),
                      Text(formatBob(Decimal.zero)),
                      Text(formatHours(Decimal.parse('2.5'))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
