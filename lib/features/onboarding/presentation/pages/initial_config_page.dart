// ignore_for_file: public_member_api_docs

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/catalog/filaments/presentation/notifiers/filaments_notifier.dart';
import '../../../../features/catalog/printers/presentation/notifiers/printers_notifier.dart';
import '../../../../features/settings/domain/settings.dart';
import '../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/brand_selector_field.dart';
import '../../../../shared/widgets/k3d_brands.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../../../../shared/widgets/numeric_input_field.dart';

/// Primera pantalla al abrir la app por primera vez.
///
/// Stepper de 3 pasos:
/// 1. Idioma + moneda (requeridos, se persisten al cambiar).
/// 2. Impresora (requerida) + filamento (opcional con "lo agrego después").
/// 3. Ganancia base + costo de energía (precargados con defaults) + Resumen.
/// Al finalizar persiste [SettingsKeys.onboardingDone] y navega al home `/`.
class InitialConfigPage extends ConsumerStatefulWidget {
  const InitialConfigPage({super.key});

  @override
  ConsumerState<InitialConfigPage> createState() => _InitialConfigPageState();
}

class _InitialConfigPageState extends ConsumerState<InitialConfigPage> {
  static const int _totalSteps = 3;

  int _step = 0;

  // ── Paso 2: impresora ──
  final _printerFormKey = GlobalKey<FormState>();
  final _printerNameCtrl = TextEditingController();
  final _printerBrandCtrl = TextEditingController();
  final _printerWattsCtrl = TextEditingController();
  bool _printerSaving = false;
  bool _printerSaved = false;
  String? _printerSavedName;

  // ── Paso 2: filamento (opcional) ──
  final _filamentFormKey = GlobalKey<FormState>();
  final _filamentNameCtrl = TextEditingController();
  final _filamentBrandCtrl = TextEditingController();
  final _filamentPriceCtrl = TextEditingController();
  final _filamentGramsCtrl = TextEditingController(text: '1000');
  bool _filamentSaving = false;
  bool _filamentSkipped = false;
  bool _filamentSaved = false;
  String? _filamentSavedName;

  // ── Paso 3: ganancia + energía ──
  late final TextEditingController _profitCtrl;
  late final TextEditingController _kwhCtrl;

  @override
  void initState() {
    super.initState();
    final settings =
        ref.read(settingsNotifierProvider).value ?? Settings.defaults;
    _profitCtrl = TextEditingController(text: settings.profitBase.toString());
    _kwhCtrl = TextEditingController(text: settings.kwhRate.toString());
  }

  @override
  void dispose() {
    _printerNameCtrl.dispose();
    _printerBrandCtrl.dispose();
    _printerWattsCtrl.dispose();
    _filamentNameCtrl.dispose();
    _filamentBrandCtrl.dispose();
    _filamentPriceCtrl.dispose();
    _filamentGramsCtrl.dispose();
    _profitCtrl.dispose();
    _kwhCtrl.dispose();
    super.dispose();
  }

  // ── Validators (mismos patrones que los forms de catálogo) ──

  String? _requiredText(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    if (v.trim().length > 100) return EsBO.filamentMax100;
    return null;
  }

  String? _requiredWatts(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    final n = int.tryParse(v.trim());
    if (n == null) return EsBO.commonInvalidNumber;
    if (n < 0) return EsBO.printerMustBeNonNegative;
    return null;
  }

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
    final parsed = Decimal.tryParse(v.trim().replaceAll(',', '.'));
    if (parsed == null) return EsBO.commonInvalidNumber;
    if (parsed <= Decimal.zero) return EsBO.filamentMustBePositive;
    return null;
  }

  // ── Guardado de impresora ──

  Future<void> _savePrinter() async {
    if (_printerSaving) return;
    if (!_printerFormKey.currentState!.validate()) return;
    setState(() => _printerSaving = true);
    final name = _printerNameCtrl.text.trim();
    final brand = _printerBrandCtrl.text.trim();
    final watts = int.parse(_printerWattsCtrl.text.trim());
    try {
      await ref
          .read(printersNotifierProvider.notifier)
          .create(
            name: name,
            brand: brand.isEmpty ? null : brand,
            averageWatts: watts,
            asDefault: true,
          );
      if (!mounted) return;
      setState(() {
        _printerSaved = true;
        _printerSavedName = name;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.success(EsBO.configPrinterSaved));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error('${EsBO.printerErrorSave}: $e'));
      }
    } finally {
      if (mounted) setState(() => _printerSaving = false);
    }
  }

  void _resetPrinter() {
    setState(() {
      _printerSaved = false;
      _printerSavedName = null;
    });
  }

  // ── Guardado de filamento ──

  Future<void> _saveFilament() async {
    if (_filamentSaving) return;
    if (!_filamentFormKey.currentState!.validate()) return;
    setState(() => _filamentSaving = true);
    final name = _filamentNameCtrl.text.trim();
    final brand = _filamentBrandCtrl.text.trim();
    final price = Decimal.parse(
      _filamentPriceCtrl.text.trim().replaceAll(',', '.'),
    );
    final grams = Decimal.parse(
      _filamentGramsCtrl.text.trim().replaceAll(',', '.'),
    );
    try {
      await ref
          .read(filamentsNotifierProvider.notifier)
          .create(
            name: name,
            brand: brand.isEmpty ? null : brand,
            pricePerBobbin: price,
            gramsPerBobbin: grams,
            asDefault: true,
          );
      if (!mounted) return;
      setState(() {
        _filamentSaved = true;
        _filamentSavedName = name;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.success(EsBO.configFilamentSaved));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppSnackBar.error('${EsBO.filamentErrorSave}: $e'));
      }
    } finally {
      if (mounted) setState(() => _filamentSaving = false);
    }
  }

  void _resetFilament() {
    setState(() {
      _filamentSaved = false;
      _filamentSavedName = null;
    });
  }

  // ── Navegación del stepper ──

  bool get _canContinue {
    if (_step == 1) return _printerSaved;
    return true;
  }

  Future<void> _finish() async {
    // Paso 3: persistir ganancia + energía (si cambiaron) antes de salir.
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final profit = Decimal.tryParse(
      _profitCtrl.text.trim().replaceAll(',', '.'),
    );
    if (profit != null) await notifier.updateProfitBase(profit);
    final kwh = Decimal.tryParse(_kwhCtrl.text.trim().replaceAll(',', '.'));
    if (kwh != null) await notifier.updateKwhRate(kwh);
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.onboardingDone, true);
    if (!mounted) return;
    // Tras la config inicial, mostrar las slides explicativas (OnboardingPage).
    GoRouter.of(context).go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: MaxWidthScrollView(
            maxWidth: 480,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // App icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/3dlogo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Title
                  Text(
                    EsBO.configTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Step counter + progress bar (M3 nativo)
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 16, color: color.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          EsBO.configStepCounter(_step + 1, _totalSteps),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 6,
                      semanticsLabel: EsBO.configStepCounter(
                        _step + 1,
                        _totalSteps,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Step subtitle (microcopy "por que" del paso)
                  Text(
                    _step == 0
                        ? EsBO.configStepSubtitle1
                        : _step == 1
                        ? EsBO.configStepSubtitle2
                        : EsBO.configStepSubtitle3,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Step content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(theme, color),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Nav buttons
                  Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _step = _step - 1),
                            child: Text(EsBO.configBack),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        flex: _step > 0 ? 2 : 1,
                        child: FilledButton(
                          onPressed: _canContinue ? _goNext : null,
                          child: Text(
                            _step == _totalSteps - 1
                                ? EsBO.configStartButton
                                : EsBO.configContinue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goNext() {
    if (_step < _totalSteps - 1) {
      setState(() => _step = _step + 1);
    } else {
      _finish();
    }
  }

  Widget _buildStep(ThemeData theme, ColorScheme color) {
    switch (_step) {
      case 0:
        return const _Step1Content();
      case 1:
        return _buildStep2(theme, color);
      default:
        return _buildStep3(theme, color);
    }
  }

  // ── Paso 2: impresora (requerida) + filamento (opcional) ──

  Widget _buildStep2(ThemeData theme, ColorScheme color) {
    final currency = ref.watch(selectedCurrencyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Impresora
        _StepSectionHeader(
          icon: Icons.print_rounded,
          title: EsBO.configPrinterRequired,
          color: color.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configPrinterSectionHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_printerSaved)
          _SavedCard(
            icon: Icons.print_rounded,
            title: _printerSavedName ?? '',
            subtitle: EsBO.configPrinterSaved,
            onEdit: _resetPrinter,
          )
        else
          Form(
            key: _printerFormKey,
            child: Column(
              children: [
                BrandSelectorField(
                  domain: BrandDomain.printer,
                  controller: _printerBrandCtrl,
                  label: EsBO.filamentBrand,
                  helperText: EsBO.printerBrandHelper,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _printerNameCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.printerModel,
                    helperText: EsBO.printerModelHelper,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _requiredText,
                ),
                const SizedBox(height: AppSpacing.md),
                NumericInputField(
                  label: EsBO.printerWatts,
                  controller: _printerWattsCtrl,
                  allowDecimals: false,
                  helperText: EsBO.printerWattsHelper,
                  textInputAction: TextInputAction.done,
                  validator: _requiredWatts,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  icon: _printerSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(EsBO.commonSave),
                  onPressed: _printerSaving ? null : _savePrinter,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
        // Filamento (opcional)
        _StepSectionHeader(
          icon: Icons.label_rounded,
          title: EsBO.configFilamentOptional,
          color: color.secondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configFilamentSectionHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_filamentSaved)
          _SavedCard(
            icon: Icons.label_rounded,
            title: _filamentSavedName ?? '',
            subtitle: EsBO.configFilamentSaved,
            onEdit: _resetFilament,
          )
        else if (_filamentSkipped)
          _FilamentSkipCard(
            onAdd: () => setState(() => _filamentSkipped = false),
          )
        else
          Form(
            key: _filamentFormKey,
            child: Column(
              children: [
                BrandSelectorField(
                  domain: BrandDomain.filament,
                  controller: _filamentBrandCtrl,
                  label: EsBO.filamentBrand,
                  helperText: EsBO.filamentBrandHelper,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _filamentNameCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.filamentName,
                    helperText: EsBO.filamentNameHelper,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _requiredText,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _filamentPriceCtrl,
                  decoration: InputDecoration(
                    labelText: EsBO.filamentPrice(currency.symbol),
                    helperText: EsBO.filamentPriceHelper,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _requiredNumber,
                ),
                const SizedBox(height: AppSpacing.md),
                NumericInputField(
                  label: EsBO.filamentGrams,
                  controller: _filamentGramsCtrl,
                  allowDecimals: false,
                  helperText: EsBO.filamentGramsHelper,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  icon: _filamentSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(EsBO.commonSave),
                  onPressed: _filamentSaving ? null : _saveFilament,
                ),
                TextButton(
                  onPressed: _filamentSaving
                      ? null
                      : () => setState(() => _filamentSkipped = true),
                  child: Text(EsBO.configFilamentLater),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Paso 3: ganancia + energía + resumen ──

  Widget _buildStep3(ThemeData theme, ColorScheme color) {
    final currency = ref.watch(selectedCurrencyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepSectionHeader(
          icon: Icons.percent_rounded,
          title: EsBO.settingsProfitBase,
          color: color.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configProfitHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NumericInputField(
                label: EsBO.settingsProfitBase,
                controller: _profitCtrl,
                allowDecimals: false,
                suffix: '%',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
                  final n = int.tryParse(v.trim());
                  if (n == null) return EsBO.commonInvalidNumber;
                  if (n < 0 || n > 1000) return EsBO.settingsProfitBaseRange;
                  return null;
                },
                onBlur: (raw) {
                  final n = int.tryParse(raw.trim());
                  if (n == null || n < 0 || n > 1000) return;
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateProfitBase(Decimal.fromInt(n));
                },
              ),
            ),
            _TypicalTag(
              controller: _profitCtrl,
              defaultValue: Settings.defaults.profitBase.toString(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _StepSectionHeader(
          icon: Icons.bolt_rounded,
          title: EsBO.settingsKwhRate(currency.symbol),
          color: color.secondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configKwhHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NumericInputField(
                label: EsBO.settingsKwhRate(currency.symbol),
                controller: _kwhCtrl,
                allowDecimals: true,
                suffix: '${currency.symbol}/kWh',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return EsBO.commonRequired;
                  final n = Decimal.tryParse(v.trim().replaceAll(',', '.'));
                  if (n == null) return EsBO.commonInvalidNumber;
                  if (n < Decimal.parse('0.10') || n > Decimal.parse('5.00')) {
                    return EsBO.settingsKwhRateRange;
                  }
                  return null;
                },
                onBlur: (raw) {
                  final n = Decimal.tryParse(raw.trim().replaceAll(',', '.'));
                  if (n == null ||
                      n < Decimal.parse('0.10') ||
                      n > Decimal.parse('5.00')) {
                    return;
                  }
                  ref.read(settingsNotifierProvider.notifier).updateKwhRate(n);
                },
              ),
            ),
            _TypicalTag(
              controller: _kwhCtrl,
              defaultValue: Settings.defaults.kwhRate.toString(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Resumen de lo configurado (reemplaza el onboarding marketing).
        _ConfigSummaryCard(
          currency: currency,
          printerName: _printerSavedName,
          filamentName: _filamentSavedName,
          filamentSkipped: _filamentSkipped,
          profitCtrl: _profitCtrl,
          kwhCtrl: _kwhCtrl,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Slide motivacional breve (reemplaza las 4 slides de OnboardingPage).
        Center(
          child: Column(
            children: [
              Icon(Icons.celebration_rounded, size: 48, color: color.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                EsBO.configSummaryImprint,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Step 1 content ──────────────────────────────────

class _Step1Content extends ConsumerWidget {
  const _Step1Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepSectionHeader(
          icon: Icons.language_rounded,
          title: EsBO.configLanguage,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configLanguageHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppLocale>(
              value: ref.watch(localeProvider),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: AppLocale.es,
                  child: Text(EsBO.localeEs),
                ),
                DropdownMenuItem(
                  value: AppLocale.en,
                  child: Text(EsBO.localeEn),
                ),
                DropdownMenuItem(
                  value: AppLocale.ptBr,
                  child: Text(EsBO.localePtBr),
                ),
                DropdownMenuItem(
                  value: AppLocale.de,
                  child: Text(EsBO.localeDe),
                ),
                DropdownMenuItem(
                  value: AppLocale.fr,
                  child: Text(EsBO.localeFr),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _StepSectionHeader(
          icon: Icons.attach_money_rounded,
          title: EsBO.configCurrency,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          EsBO.configCurrencyHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CurrencyDropdown(),
      ],
    );
  }
}

class _CurrencyDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsNotifierProvider).value ?? Settings.defaults;
    final current = WorldCurrency.fromCode(settings.currencyCode);
    return DropdownButtonFormField<WorldCurrency>(
      initialValue: current,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      items: WorldCurrency.all.map((wc) {
        return DropdownMenuItem(
          value: wc,
          child: Text('${wc.code} — ${wc.name} (${wc.symbol})'),
        );
      }).toList(),
      onChanged: (selected) {
        if (selected == null) return;
        ref
            .read(settingsNotifierProvider.notifier)
            .updateCurrency(selected.code);
      },
    );
  }
}

// ─── Shared step pieces ──────────────────────────────

/// Header de sección dentro de un paso: icono en chip + título.
class _StepSectionHeader extends StatelessWidget {
  const _StepSectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card con check de confirmación + botón para volver a editar.
class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.primaryContainer,
              child: Icon(icon, size: 20, color: color.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: EsBO.filamentEdit,
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card para el filamento cuando el usuario eligió "lo agrego después".
class _FilamentSkipCard extends StatelessWidget {
  const _FilamentSkipCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: color.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    EsBO.configFilamentSkipHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(EsBO.configFilamentAddAction),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge "Típico" junto a un campo numerico: aparece solo cuando el texto
/// del [controller] coincide con [defaultValue]. Desaparece al editar.
class _TypicalTag extends StatelessWidget {
  const _TypicalTag({required this.controller, required this.defaultValue});

  final TextEditingController controller;
  final String defaultValue;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDefault = controller.text.trim() == defaultValue.trim();
        if (!isDefault) return const SizedBox(width: 8);
        return Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: color.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              EsBO.settingsDefaultTypical,
              style: themeTextSmall(context).copyWith(
                color: color.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle themeTextSmall(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall ?? const TextStyle();
}

/// Resumen de lo configurado (paso 3): muestra los 6 valores en una card.
/// Reemplaza el onboarding marketing (OnboardingPage 4 slides).
class _ConfigSummaryCard extends ConsumerWidget {
  const _ConfigSummaryCard({
    required this.currency,
    required this.printerName,
    required this.filamentName,
    required this.filamentSkipped,
    required this.profitCtrl,
    required this.kwhCtrl,
  });

  final WorldCurrency currency;
  final String? printerName;
  final String? filamentName;
  final bool filamentSkipped;
  final TextEditingController profitCtrl;
  final TextEditingController kwhCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final locale = ref.watch(localeProvider);
    final strings = ref.watch(localeStringsProvider);
    final languageLabel = switch (locale) {
      AppLocale.es => strings.localeEs,
      AppLocale.en => strings.localeEn,
      AppLocale.ptBr => strings.localePtBr,
      AppLocale.de => strings.localeDe,
      AppLocale.fr => strings.localeFr,
    };

    final filamentLabel = filamentSkipped || filamentName == null
        ? EsBO.configFilamentSkipStatus
        : filamentName!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_rounded, size: 18, color: color.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              EsBO.configSummaryTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.tertiaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.tertiary.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.language_rounded,
                  label: EsBO.configLanguage,
                  value: languageLabel,
                ),
                _SummaryRow(
                  icon: Icons.attach_money_rounded,
                  label: EsBO.configCurrency,
                  value: '${currency.code} (${currency.symbol})',
                ),
                _SummaryRow(
                  icon: Icons.print_rounded,
                  label: EsBO.configPrinterRequired,
                  value: printerName ?? '—',
                ),
                _SummaryRow(
                  icon: Icons.label_rounded,
                  label: EsBO.configFilamentOptional,
                  value: filamentLabel,
                ),
                _SummaryRow(
                  icon: Icons.percent_rounded,
                  label: EsBO.settingsProfitBase,
                  value: '${profitCtrl.text.trim()} %',
                ),
                _SummaryRow(
                  icon: Icons.bolt_rounded,
                  label: EsBO.settingsKwhRate(currency.symbol),
                  value: '${kwhCtrl.text.trim()} ${currency.symbol}/kWh',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
