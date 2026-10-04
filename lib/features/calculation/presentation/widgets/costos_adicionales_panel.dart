// ignore_for_file: public_member_api_docs
//
// Seccion unificada "Costos de la pieza" — v17.
//
// Reemplaza las dos secciones que existian antes (la de costos de la pieza con
// tasa de falla / desperdicio, y la de costos adicionales con modelado /
// postprocesado / extras). Ahora hay UNA sola seccion, Pro-gated, con 5 campos
// en este orden:
//
//   1. Modelado y diseño  → switch [% ON | Fijo OFF] + valor
//   2. Postprocesado      → switch [% ON | Fijo OFF] + valor
//   3. Extras             → switch [% ON | Fijo OFF] + valor + descripcion
//   4. Tasa de falla      → solo %
//   5. Desperdicio        → solo %
//
// **Layout compacto** (mobile-first): los 5 campos van en una grilla de 2
// columnas para recuperar la densidad que se perdio al fusionar las secciones:
//
//   ┌ Modelado ──────┬ Postprocesado ─┐
//   │ [switch] valor │ [switch] valor │
//   ├ Extras (ancho completo) ────────┤
//   │ [switch] valor                 │
//   │ [descripcion]                  │
//   ├ Falla ─────────┬ Desperdicio ───┤
//   │ valor %        │ valor %        │
//   └────────────────┴────────────────┘
//
// Extras ocupa el ancho completo porque ademas del valor lleva la descripcion
// libre. El orden de lectura sigue siendo 1-2-3-4-5.
//
// **Switch**: es el mismo `Switch` de Material que el de "Tiempo independiente
// por material" del modo Avanzado. Apagado (OFF / izquierda) = `Fijo`, un monto
// en moneda local. Encendido (ON / derecha) = `%`, sobre `coreBase` (material +
// electricidad + amortizacion). No hay modo "Auto": el usuario decide siempre.
// Al moverlo el valor escrito se conserva y solo cambia su interpretacion; el
// sufijo del input (% o simbolo de moneda) acompania al modo.
//
// **Default**: los 3 primeros arrancan en `Fijo` con valor 0, asi que una
// cotizacion nueva no suma nada hasta que se configuren.
//
// **Persistencia**: cada setter dispara recomputo del `CalculatorNotifier`; el
// modo y el valor se guardan en Drift (v17) y en el draft de sesion.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/numeric_input_field.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../state/calculator_notifier.dart';
import 'calculator_bottom_bar.dart' show OtrosPeekPreview;

/// Switch binario `%` / `Fijo` — mismo widget `Switch` que el de "Tiempo
/// independiente por material" del modo Avanzado.
///
/// Posicion OFF (izquierda) = `Fijo` (monto local).
/// Posicion ON  (derecha) = `%` (sobre `coreBase`).
///
/// El `Switch` NUNCA se bloquea: el usuario siempre decide el modo. Lo que se
/// cambia al moverlo es la interpretacion del valor ya escrito (el numero se
/// conserva), y el sufijo del input acompania al modo.
class _PercentOrFixedSwitch extends StatelessWidget {
  const _PercentOrFixedSwitch({
    required this.mode,
    required this.onModeChanged,
  });

  /// Modo actual del state: `pct` o `fixed`.
  final String mode;

  /// Setter de modo del notifier (`setModelingMode`, etc).
  final void Function(String) onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPct = mode == 'pct';

    Widget side(String label, {required bool active}) {
      return Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: active ? cs.primary : cs.onSurfaceVariant,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // OFF = Fijo.
        side(EsBO.modeFixed, active: !isPct),
        const SizedBox(width: AppSpacing.xs),
        Switch(
          value: isPct,
          // Compacto: sin el padding extra de 48dp de area tactil, para que
          // entre junto a las etiquetas en una celda de 2 columnas.
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (v) => onModeChanged(v ? 'pct' : 'fixed'),
        ),
        const SizedBox(width: AppSpacing.xs),
        // ON = %.
        side(EsBO.modePercent, active: isPct),
      ],
    );
  }
}

/// Fila de la seccion: label + (opcional icono info) + (switch o solo input).
///
/// Si [mode] / [onModeChanged] vienen en null, la fila es de tipo "solo %"
/// (tasa de falla y desperdicio) y no dibuja switch.
class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.onValueChanged,
    this.mode,
    this.onModeChanged,
    this.helperText,
    this.infoTooltip,
    this.extraDescriptionController,
    this.extraDescriptionHint,
    this.onExtraDescriptionChanged,
  });

  final String label;
  final TextEditingController controller;

  /// Sufijo del NumericInputField: `%` o el simbolo de la moneda.
  final String suffix;

  /// Setter del valor numerico (se invoca en cada keystroke).
  final void Function(String) onValueChanged;

  /// `pct` | `fixed`. Null = fila de solo porcentaje (sin switch).
  final String? mode;
  final void Function(String)? onModeChanged;

  final String? helperText;

  /// Icono (i) con tooltip junto al label. Usado en Extras.
  final String? infoTooltip;

  /// Campo de descripcion libre, solo para Extras.
  final TextEditingController? extraDescriptionController;
  final String? extraDescriptionHint;
  final void Function(String)? onExtraDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Locales: un campo publico nullable no se puede promover con `!= null`,
    // asi que el switch y el tooltip se arman aca.
    final m = mode;
    final setMode = onModeChanged;
    final tooltip = infoTooltip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + (opcional icono info). En celda de 2 columnas el label se
        // puede truncar: siempre 1 linea + ellipsis.
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (tooltip != null)
              Tooltip(
                message: tooltip,
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),

        // Switch % / Fijo (solo filas con modo).
        if (m != null && setMode != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          _PercentOrFixedSwitch(mode: m, onModeChanged: setMode),
        ],

        const SizedBox(height: AppSpacing.xs),
        NumericInputField(
          label: '',
          controller: controller,
          suffix: suffix,
          helperText: helperText,
          onChanged: onValueChanged,
        ),

        // Descripcion libre (solo Extras).
        if (extraDescriptionController != null) ...[
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: extraDescriptionController,
            decoration: InputDecoration(
              isDense: true,
              hintText: extraDescriptionHint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            style: theme.textTheme.bodyMedium,
            onChanged: onExtraDescriptionChanged,
          ),
        ],
      ],
    );
  }
}

/// Seccion colapsable "Costos adicionales" con los 5 campos.
///
/// Pro-gated (igual que la seccion de Otros que reemplaza): Free ve el
/// ProBadge y al tocar el header lo manda al paywall. Colapsado muestra el
/// peek preview con los nombres de los 5 campos.
///
/// Los `TextEditingController` los provee el padre (`calculator_page`): cada
/// field mantiene su controller en el State del padre, no aqui, para sobrevivir
/// a rebuilds y para que el `dispose()` siga siendo del padre.
class CostosAdicionalesPanel extends ConsumerStatefulWidget {
  const CostosAdicionalesPanel({
    super.key,
    required this.modelingCtrl,
    required this.postprocCtrl,
    required this.extraCostCtrl,
    required this.extraCostLabelCtrl,
    required this.failureCtrl,
    required this.wasteCtrl,
  });

  final TextEditingController modelingCtrl;
  final TextEditingController postprocCtrl;
  final TextEditingController extraCostCtrl;
  final TextEditingController extraCostLabelCtrl;
  final TextEditingController failureCtrl;
  final TextEditingController wasteCtrl;

  @override
  ConsumerState<CostosAdicionalesPanel> createState() =>
      _CostosAdicionalesPanelState();
}

class _CostosAdicionalesPanelState
    extends ConsumerState<CostosAdicionalesPanel> {
  /// Colapsado por defecto: el peek preview ya anuncia los 5 campos y el
  /// espacio en el wizard es limitado.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(calculatorNotifierProvider);
    final notifier = ref.read(calculatorNotifierProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);

    final isPro = ref.watch(isProProvider);
    final entitlementState = ref.watch(entitlementNotifierProvider);
    final isLoading = entitlementState.isLoading;
    final showProBadge = !isPro && !isLoading;

    String moneyOrPercent(String mode) =>
        mode == 'pct' ? EsBO.modePercent : currency.symbol;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.tune_rounded,
          title: EsBO.calcSectionPieceCosts,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProBadge) ...[
                const ProBadge(),
                const SizedBox(width: AppSpacing.xs),
              ],
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onTap: () {
            if (!isPro) {
              context.push('/paywall');
            } else {
              setState(() => _expanded = !_expanded);
            }
          },
        ),

        // Peek preview con los 5 nombres cuando esta colapsado.
        if (!_expanded)
          OtrosPeekPreview(
            locked: showProBadge,
            labels: [
              EsBO.calcExtraModeling,
              EsBO.calcExtraPostprocess,
              EsBO.calcExtraExtras,
              EsBO.calcFieldFailure,
              EsBO.calcFieldWaste,
            ],
          ),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila 1 — 2 columnas: Modelado | Postprocesado.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CostRow(
                              label: EsBO.calcExtraModeling,
                              mode: state.modelingMode,
                              onModeChanged: notifier.setModelingMode,
                              controller: widget.modelingCtrl,
                              suffix: moneyOrPercent(state.modelingMode),
                              onValueChanged: notifier.setModelingValue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _CostRow(
                              label: EsBO.calcExtraPostprocess,
                              mode: state.postprocMode,
                              onModeChanged: notifier.setPostprocMode,
                              controller: widget.postprocCtrl,
                              suffix: moneyOrPercent(state.postprocMode),
                              onValueChanged: notifier.setPostprocValue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Fila 2 — Extras a lo ancho (necesita la descripcion).
                      _CostRow(
                        label: EsBO.calcExtraExtras,
                        mode: state.extraCostMode,
                        onModeChanged: notifier.setExtraCostMode,
                        controller: widget.extraCostCtrl,
                        suffix: moneyOrPercent(state.extraCostMode),
                        onValueChanged: notifier.setExtraCostValue,
                        infoTooltip: EsBO.extraInfo,
                        extraDescriptionController: widget.extraCostLabelCtrl,
                        extraDescriptionHint: EsBO.extraDescriptionHint,
                        onExtraDescriptionChanged: notifier.setExtraCostLabel,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Fila 3 — 2 columnas: Tasa de falla | Desperdicio.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CostRow(
                              label: EsBO.calcFieldFailure,
                              controller: widget.failureCtrl,
                              suffix: EsBO.modePercent,
                              helperText: EsBO.calcFieldFailureHelper,
                              onValueChanged: notifier.setExtraFailureRate,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _CostRow(
                              label: EsBO.calcFieldWaste,
                              controller: widget.wasteCtrl,
                              suffix: EsBO.modePercent,
                              helperText: EsBO.calcFieldWasteHelper,
                              onValueChanged:
                                  notifier.setExtraMarkupOnMaterials,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
