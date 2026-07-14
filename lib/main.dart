import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Bootstrap de tresdcal. ProviderScope envuelve toda la app para que los
  // Riverpod notifiers tengan acceso al grafo de providers.
  runApp(
    const ProviderScope(
      child: TresdcalApp(),
    ),
  );
}
