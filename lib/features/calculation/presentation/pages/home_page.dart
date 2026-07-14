// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'calculator_page.dart';

/// Home page: navega al calculator (Sprint 3).
///
/// **Sprint 0** mostraba un placeholder con smoke test del formatter.
/// **Sprint 3** ya tenemos el calculator real, asi que el home es solo
/// un launcher.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3dcal'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calculate_outlined, size: 96),
                const SizedBox(height: 24),
                Text(
                  'Cotizador 3D',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Calculo reactivo. Local-first. BOB.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Nueva cotizacion'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CalculatorPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
