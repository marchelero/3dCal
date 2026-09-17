// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/es_bo.dart';

/// Resultado del bottom sheet de guardado: datos del cliente, notas,
/// condiciones y flag de "guardar como plantilla".
class SaveResult {
  const SaveResult({
    this.clientName,
    this.notes,
    this.conditions,
    this.saveAsTemplate = false,
  });
  final String? clientName;
  final String? notes;
  final String? conditions;

  /// True cuando el usuario marcó "guardar también como plantilla":
  /// se guarda en el historial Y se crea una plantilla reutilizable.
  final bool saveAsTemplate;
}

/// Bottom sheet para guardar una cotización: nombre del cliente, clientes
/// recientes (quick-pick), notas, condiciones y toggle de plantilla.
class SaveSheet extends StatefulWidget {
  const SaveSheet({super.key, this.recentClients = const []});

  /// Clientes más recientes para el quick-pick (chips).
  final List<String> recentClients;

  @override
  State<SaveSheet> createState() => SaveSheetState();
}

class SaveSheetState extends State<SaveSheet> {
  final _clientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  bool _saveAsTemplate = false;

  @override
  void dispose() {
    _clientCtrl.dispose();
    _notesCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      SaveResult(
        clientName: _clientCtrl.text,
        notes: _notesCtrl.text,
        conditions: _conditionsCtrl.text,
        saveAsTemplate: _saveAsTemplate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.primary.withValues(alpha: 0.15),
                          color.primaryContainer.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.save_rounded, color: color.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          EsBO.calcBtnSave,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          EsBO.calcDialogSaveSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Datos del cliente ──
              _fieldLabel(
                theme,
                Icons.person_outline_rounded,
                EsBO.calcDialogClient,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _clientCtrl,
                decoration: InputDecoration(
                  hintText: EsBO.calcDialogClientHelper,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                textInputAction: TextInputAction.next,
              ),
              if (widget.recentClients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _fieldLabel(
                  theme,
                  Icons.history_rounded,
                  EsBO.calcDialogRecentClients,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final client in widget.recentClients)
                      FilterChip(
                        avatar: _clientCtrl.text == client
                            ? const Icon(Icons.check_rounded, size: 18)
                            : null,
                        label: Text(client, overflow: TextOverflow.ellipsis),
                        selected: _clientCtrl.text == client,
                        onSelected: (_) =>
                            setState(() => _clientCtrl.text = client),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // ── Detalles ──
              _fieldLabel(
                theme,
                Icons.article_outlined,
                EsBO.calcDialogDetails,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.calcDialogNotes,
                  hintText: EsBO.calcDialogNotesHelper,
                  prefixIcon: const Icon(Icons.notes_rounded),
                  filled: true,
                  fillColor: color.surfaceContainerLow,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _conditionsCtrl,
                decoration: InputDecoration(
                  labelText: EsBO.calcDialogConditions,
                  hintText: EsBO.calcDialogConditionsHelper,
                  prefixIcon: const Icon(Icons.rule_rounded),
                  filled: true,
                  fillColor: color.surfaceContainerLow,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Plantilla ──
              Material(
                color: _saveAsTemplate
                    ? color.primaryContainer.withValues(alpha: 0.4)
                    : color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      setState(() => _saveAsTemplate = !_saveAsTemplate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _saveAsTemplate
                              ? Icons.playlist_add_check_circle_rounded
                              : Icons.playlist_add_circle_outlined,
                          size: 28,
                          color: _saveAsTemplate
                              ? color.primary
                              : color.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                EsBO.calcDialogSaveAsTemplate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _saveAsTemplate ? color.primary : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                EsBO.calcTemplateSaveAsAction,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _saveAsTemplate,
                          onChanged: (v) => setState(() => _saveAsTemplate = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Footer ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(EsBO.commonCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(EsBO.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(ThemeData theme, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
