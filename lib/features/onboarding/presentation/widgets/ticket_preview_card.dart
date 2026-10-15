// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme_mode_provider.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/perforation.dart';

/// Ficha tipo ticket con la configuración en vivo del setup.
///
/// **Modo compacto (colapsado por defecto)**: una sola fila tipo ticket
/// (~50 px) con los valores ya configurados en formato inline
/// ("BRL · Dark · A1") + un contador sutil de pendientes ("+2 Pendiente").
/// El tap expande/colapsa ([AnimatedSize] 250 ms) a la vista completa con
/// todas las filas (Currency/Theme/Printers/Filaments/Base profit/
/// Electricity rate).
///
/// Se renderiza en los pasos 1–4 (el container la oculta en el paso 0 y en
/// el cierre). Solo `ref.watch` → la actualización es reactiva en la misma
/// interacción (AC-08). El estado de expandir/collapse es UI-local efímero
/// (BUG-006); el container la re-monta con key por página, así cambiar de
/// página la vuelve a colapsar.
class TicketPreviewCard extends ConsumerStatefulWidget {
  const TicketPreviewCard({super.key});

  @override
  ConsumerState<TicketPreviewCard> createState() => _TicketPreviewCardState();
}

class _TicketPreviewCardState extends ConsumerState<TicketPreviewCard> {
  // BUG-006: estado UI local efímero (no es estado de negocio).
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);
    final themeMode = ref.watch(themeModeProvider).label;
    final defaultPrinter = ref.watch(defaultPrinterProvider);
    final defaultFilament = ref.watch(defaultFilamentProvider);
    final settings = ref.watch(settingsNotifierProvider).value;
    final pending = EsBO.setupTicketPending;
    final profit = settings?.profitBase ?? Decimal.zero;
    final kwh = settings?.kwhRate ?? Decimal.zero;

    // Filas del ticket: (label, valor); valor == pendiente => sin configurar.
    final rows = <(String, String)>[
      (EsBO.configCurrency, '${currency.code} (${currency.symbol})'),
      (EsBO.settingsTheme, themeMode),
      (EsBO.printerTitle, defaultPrinter?.name ?? pending),
      (EsBO.filamentTitle, defaultFilament?.name ?? pending),
      (EsBO.settingsProfitBase, profit > Decimal.zero ? '$profit%' : pending),
      (
        EsBO.settingsKwhRate(currency.symbol),
        // LOW-4 (auditoría 2026-10-14): la tarifa se muestra SIN símbolo de
        // moneda (antes solo el número crudo, ej "1.00"). Formato compacto
        // acorde al ticket: símbolo pegado al valor ("$1").
        kwh > Decimal.zero ? '${currency.symbol}$kwh' : pending,
      ),
    ];
    final configured = rows.where((r) => r.$2 != pending).toList();
    final pendingCount = rows.length - configured.length;

    return Container(
      key: const ValueKey('setup-ticket-card'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Perforation(
            color: color.outlineVariant,
            margin: const EdgeInsets.only(top: AppSpacing.sm),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('setup-ticket-toggle'),
              borderRadius: BorderRadius.circular(AppRadii.xxl),
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Barra compacta: siempre visible (resumen + toggle).
                      _CompactBar(
                        summary: configured
                            .map((r) => r.$2.split(' (').first)
                            .join(' · '),
                        pendingCount: pendingCount,
                        expanded: _expanded,
                      ),
                      if (_expanded) ...[
                        const SizedBox(height: AppSpacing.sm),
                        for (final (label, value) in rows)
                          _TicketRow(label: label, value: value),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra del modo colapsado: valores configurados en línea + contador de
/// pendientes + icono de expandir/colapsar.
class _CompactBar extends StatelessWidget {
  const _CompactBar({
    required this.summary,
    required this.pendingCount,
    required this.expanded,
  });

  final String summary;
  final int pendingCount;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.confirmation_number_outlined,
          size: 16,
          color: color.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            [
              if (summary.isNotEmpty) summary,
              if (pendingCount > 0) '+$pendingCount ${EsBO.setupTicketPending}',
            ].join('   '),
            key: const ValueKey('setup-ticket-summary'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
