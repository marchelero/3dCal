// ignore_for_file: public_member_api_docs
/// Guia paso a paso de la cotizacion (modal estilo onboarding).
library;

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// Abre el modal "Como funciona la cotizacion": 6 pasos deslizables que
/// recorren el flujo completo (modo → material → impresora → tiempo →
/// extras → resultado).
///
/// Reutiliza el patron visual del onboarding (PageView + dots + boton
/// Siguiente) pero con los colores del colorScheme del theme (look neutro
/// de modal, coherente con el design system Material 3 de la app).
Future<void> showQuoteGuideDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const QuoteGuideDialog(),
  );
}

/// Dialog interno de la guia. Stateful: el PageView necesita animar la
/// pagina actual y el boton cambia en el ultimo paso.
class QuoteGuideDialog extends StatefulWidget {
  const QuoteGuideDialog({super.key});

  @override
  State<QuoteGuideDialog> createState() => _QuoteGuideDialogState();
}

class _QuoteGuideDialogState extends State<QuoteGuideDialog> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const int _totalPages = 6;

  List<_GuideStep> get _steps => [
    _GuideStep(
      icon: Icons.bolt_rounded,
      title: EsBO.quoteGuideStep1Title,
      body: EsBO.quoteGuideStep1Body,
    ),
    _GuideStep(
      icon: Icons.inventory_2_rounded,
      title: EsBO.quoteGuideStep2Title,
      body: EsBO.quoteGuideStep2Body,
    ),
    _GuideStep(
      icon: MdiIcons.printer3d,
      title: EsBO.quoteGuideStep3Title,
      body: EsBO.quoteGuideStep3Body,
    ),
    _GuideStep(
      icon: Icons.schedule_rounded,
      title: EsBO.quoteGuideStep4Title,
      body: EsBO.quoteGuideStep4Body,
    ),
    _GuideStep(
      icon: Icons.tune_rounded,
      title: EsBO.quoteGuideStep5Title,
      body: EsBO.quoteGuideStep5Body,
    ),
    _GuideStep(
      icon: Icons.receipt_long_rounded,
      title: EsBO.quoteGuideStep6Title,
      body: EsBO.quoteGuideStep6Body,
    ),
  ];

  bool get _isLast => _currentPage == _totalPages - 1;

  void _next() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final steps = _steps;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: icono + titulo.
              Semantics(
                header: true,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        EsBO.quoteGuideTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // PageView de pasos.
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final step = steps[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono decorativo circular.
                          Semantics(
                            excludeSemantics: true,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(
                                  alpha: 0.35,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 40,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Semantics(
                            header: true,
                            child: Text(
                              step.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Semantics(
                            label: step.body,
                            child: Text(
                              step.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Dots.
              Semantics(
                label: EsBO.quoteGuidePageCounter(
                  _currentPage + 1,
                  steps.length,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    steps.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: _currentPage == i
                            ? cs.primary
                            : cs.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Boton Siguiente / Cerrar.
              Semantics(
                button: true,
                label: _isLast ? EsBO.quoteGuideClose : EsBO.quoteGuideNext,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLast
                        ? () => Navigator.of(context).pop()
                        : _next,
                    icon: _isLast
                        ? const Icon(Icons.check_rounded)
                        : const Icon(Icons.arrow_forward_rounded),
                    iconAlignment: _isLast
                        ? IconAlignment.start
                        : IconAlignment.end,
                    label: Text(
                      _isLast ? EsBO.quoteGuideClose : EsBO.quoteGuideNext,
                    ),
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

class _GuideStep {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
