/// Selector de impresoras del cotizador.
///
/// Dialog con identidad visual propia de impresoras: AvatarIcon de impresora
/// (tile tertiary, consistente con Ajustes → Catálogos → Impresoras),
/// subtitulo "marca · X W", estrella dorada si es la default y check en la
/// impresora activa de la sesion.
///
/// Al elegir, actualiza la impresora activa y la persiste (best-effort) para
/// restaurarla en la proxima sesion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers.dart';
import '../../../../core/storage/draft_storage_providers.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/avatar_icon.dart';
import '../../../../shared/widgets/default_badge.dart';
import 'selector_dialog_shell.dart';

/// Abre el selector de impresoras. Retorna `true` si el usuario eligio una.
Future<bool> showPrinterSelectorDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<PrinterProfile> printers,
}) async {
  final activeId = ref.read(activePrinterIdProvider);

  final selected = await showSelectorDialog<PrinterProfile>(
    context: context,
    title: EsBO.calcChangePrinter,
    searchHint: EsBO.calcSearchPrinter,
    items: printers,
    matches: (p, query) =>
        p.name.toLowerCase().contains(query) ||
        (p.brand?.toLowerCase().contains(query) ?? false),
    itemBuilder: (context, p, select) {
      final theme = Theme.of(context);
      final isActive = p.id == activeId;
      return ListTile(
        leading: AvatarIcon(
          icon: Icons.print_rounded,
          background: theme.colorScheme.tertiaryContainer,
          foreground: theme.colorScheme.onTertiaryContainer,
        ),
        title: Text(p.name),
        subtitle: Text(
          '${p.brand != null && p.brand!.isNotEmpty ? '${p.brand} · ' : ''}'
          '${p.averageWatts} W',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.isDefault) const DefaultBadge(size: 20),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
        onTap: select,
      );
    },
  );

  if (selected == null) return false;
  ref.read(activePrinterIdProvider.notifier).state = selected.id;
  // Persistir la eleccion para restaurarla en la proxima sesion (best-effort).
  await _persistActivePrinterId(ref, selected.id);
  return true;
}

Future<void> _persistActivePrinterId(WidgetRef ref, int id) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(kActivePrinterIdPrefsKey, id);
  } catch (e) {
    // BUG-019 fix: loggear — la seleccion sigue valida en sesion, pero el
    // usuario pierde la persistencia entre sesiones sin saberlo.
    debugPrint('Fallo al persistir impresora activa ($id): $e');
  }
}
