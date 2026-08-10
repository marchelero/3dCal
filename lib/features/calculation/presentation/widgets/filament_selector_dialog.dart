/// Selector de filamentos del cotizador.
///
/// Dialog con identidad visual propia de filamentos: AvatarIcon de etiqueta
/// (tile secondary, consistente con Ajustes → Catálogos → Filamentos),
/// subtitulo "precio sym · X g" y estrella dorada si es el default.
///
/// Retorna el filamento elegido para cargarlo en el formulario, o `null` si
/// el usuario cancela.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/avatar_icon.dart';
import '../../../../shared/widgets/default_badge.dart';
import 'selector_dialog_shell.dart';

/// Abre el selector de filamentos.
Future<Filament?> showFilamentSelectorDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<Filament> filaments,
}) {
  final sym = ref.read(selectedCurrencyProvider).symbol;

  return showSelectorDialog<Filament>(
    context: context,
    title: EsBO.calcSelectFilament,
    searchHint: EsBO.calcSearchFilament,
    items: filaments,
    matches: (f, query) =>
        f.name.toLowerCase().contains(query) ||
        (f.brand?.toLowerCase().contains(query) ?? false),
    itemBuilder: (context, f, select) {
      final theme = Theme.of(context);
      return ListTile(
        leading: AvatarIcon(
          icon: f.isDefault ? Icons.star_rounded : Icons.label_rounded,
          background: theme.colorScheme.secondaryContainer,
          foreground: f.isDefault
              ? theme.colorScheme.tertiary
              : theme.colorScheme.onSecondaryContainer,
        ),
        title: Text(f.name),
        subtitle: Text(
          '${f.pricePerBobbin.toStringAsFixed(0)} $sym · '
          '${f.gramsPerBobbin.toStringAsFixed(0)} g',
        ),
        trailing: f.isDefault ? const DefaultBadge(size: 20) : null,
        onTap: select,
      );
    },
  );
}
