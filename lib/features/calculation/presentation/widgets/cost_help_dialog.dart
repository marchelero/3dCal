import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// Abre el dialogo "Como calibrar tus costos": explica en lenguaje simple
/// cada parametro de costo que alimenta [CalculationEngine] (
/// lib/features/calculation/domain/calculation_engine.dart).
///
/// Los textos viven en l10n (costHelp*) y las formulas documentadas reflejan
/// 1:1 la implementacion del motor para que el usuario pueda calibrar
/// electricidad, mano de obra, fallas, desperdicio, cargo minimo y margen.
Future<void> showCostHelpDialog(BuildContext context) {
  final theme = Theme.of(context);

  final items = <({IconData icon, String title, String body})>[
    (
      icon: Icons.bolt_rounded,
      title: EsBO.costHelpEnergyTitle,
      body: EsBO.costHelpEnergyBody,
    ),
    (
      icon: Icons.schedule_rounded,
      title: EsBO.costHelpLaborTitle,
      body: EsBO.costHelpLaborBody,
    ),
    (
      icon: Icons.handyman_rounded,
      title: EsBO.costHelpPostTitle,
      body: EsBO.costHelpPostBody,
    ),
    (
      icon: Icons.error_outline_rounded,
      title: EsBO.costHelpFailureTitle,
      body: EsBO.costHelpFailureBody,
    ),
    (
      icon: Icons.recycling_rounded,
      title: EsBO.costHelpWasteTitle,
      body: EsBO.costHelpWasteBody,
    ),
    (
      icon: Icons.vertical_align_bottom_rounded,
      title: EsBO.costHelpMinimumChargeTitle,
      body: EsBO.costHelpMinimumChargeBody,
    ),
    (
      icon: Icons.trending_up_rounded,
      title: EsBO.costHelpMarginTitle,
      body: EsBO.costHelpMarginBody,
    ),
  ];

  return showDialog<void>(
    context: context,
    builder: (context) {
      final dialogTheme = Theme.of(context);
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.insights_rounded,
              color: dialogTheme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                EsBO.costHelpTitle,
                style: dialogTheme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: dialogTheme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              style: dialogTheme.textTheme.bodySmall?.copyWith(
                                color: dialogTheme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(EsBO.commonCancel),
          ),
        ],
      );
    },
  );
}
