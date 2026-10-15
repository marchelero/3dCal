// ignore_for_file: public_member_api_docs
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/money/currency_settings_provider.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../features/settings/domain/settings.dart';
import '../../../../../features/settings/presentation/notifiers/settings_notifier.dart';
import '../../../../../l10n/app_locale.dart';
import '../../../../../l10n/es_bo.dart';
import '../../../../../shared/widgets/numeric_input_field.dart';

/// Paso 4 del flujo de setup: tu ganancia.
///
/// - Slider grande 0–500 % (divisions 50) + [NumericInputField] dentro de
///   una card opaca `surfaceContainerLow` PLEGABLE, al MISMO patrón que
///   la sección kWh: icono + título (`settingsProfitBase`) + valor vivo
///   `'N %'` en el header SOLO al colapsar + helper dentro de la card.
///   Ambas cards EXPANDIDAS por defecto (usuario 2026-10-11).
/// - Valores de EJEMPLO al primer arranque (profit 200 %, tarifa 1.00):
///   se persisten como punto de partida y el header muestra un icono "i"
///   con Tooltip tap (`setupExampleValuesHint`) mientras no se editen.
/// - Sección kWh **plegada** por defecto (muestra la tarifa actual o
///   `kDefaultKwhRate`); expandible con slider 0–5 + input.
/// - Persisten al cambiar vía `updateProfitBase` / `updateKwhRate`
///   (Decimal siempre; `double` solo en el volado del slider, comment
///   BUG-006-style abajo). Sin botón "Guardar" (AC-07).
/// - Reanudación AC-13: al montar (y al resolver el AsyncValue de settings)
///   los sliders/inputs se inicializan LEYENDO `settingsNotifierProvider`,
///   no defaults ciegos.
class ProfitStep extends ConsumerStatefulWidget {
  const ProfitStep({super.key});

  @override
  ConsumerState<ProfitStep> createState() => _ProfitStepState();
}

class _ProfitStepState extends ConsumerState<ProfitStep> {
  late final TextEditingController _profitCtrl;
  late final TextEditingController _kwhCtrl;

  // BUG-006: valores UI locales efímeros (el estado de negocio vive en
  // settingsNotifierProvider). El slider exige `double`; el Decimal
  // persistido es la source of truth y el double es solo su volado visual.
  double _profitValue = 0;
  double _kwhValue = 0;

  // Flags UI: si el usuario ya tocó un control, el seed no lo pisa.
  bool _profitTouched = false;
  bool _kwhTouched = false;

  // BUG-006: expansión de las cards = estado UI local efímero (no es
  // estado de negocio); el valor vivo del header se muestra solo al colapsar.
  // Ambas expandidas por defecto (usuario 2026-10-11).
  bool _profitExpanded = true;
  bool _kwhExpanded = true;

  // Flags UI: si el valor visible viene del ejemplo de primer arranque
  // (200 % / 1.00) y el usuario aún no lo tocó, cada card muestra el hint
  // `setupExampleValuesHint`. Al tocar el control el hint desaparece.
  bool _profitExample = false;
  bool _kwhExample = false;

  /// settings AsyncValue puede resolver DESPUÉS del primer frame; el seed
  /// se aplica en initState (si ya hay valor) o al primer dato del listen.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _profitCtrl = TextEditingController();
    _kwhCtrl = TextEditingController();
    final settings = ref.read(settingsNotifierProvider).value;
    if (settings != null) {
      _seeded = true;
      _seedFromSettings(settings);
    }
  }

  @override
  void dispose() {
    _profitCtrl.dispose();
    _kwhCtrl.dispose();
    super.dispose();
  }

  /// Normaliza un Decimal a texto de input: sin cola de ceros ('125.0'→'125').
  static String _decimalText(Decimal d) {
    return d == d.truncate() ? d.truncate().toString() : d.toString();
  }

  /// Precarga sliders/inputs desde los settings persistidos (AC-13). Cuando
  /// el valor persistido es 0 ("sin configurar" del stepper viejo) se
  /// siembra un valor de EJEMPLO (ganancia 200 %, tarifa 1.00) que se
  /// persiste como punto de partida y se marca con el hint; el usuario lo
  /// cambia según su caso. Cada control se precarga solo si el usuario no
  /// lo tocó aún (los flags UI evitan pisar su elección).
  void _seedFromSettings(Settings settings) {
    if (!_profitTouched) {
      final profit = settings.profitBase;
      if (profit == Decimal.zero) {
        _profitValue = 200;
        _profitCtrl.text = '200';
        _profitExample = true;
        // Persiste el ejemplo: el cierre/resumen y el cálculo post-setup
        // ven un valor real, no 0. Post-frame para no notificar providers
        // durante build/listen.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _persistProfit(200);
        });
      } else {
        _profitValue = profit.toDouble().clamp(0.0, 500.0);
        _profitCtrl.text = _decimalText(profit);
      }
    }
    if (!_kwhTouched) {
      final kwh = settings.kwhRate;
      if (kwh == Decimal.zero) {
        _kwhValue = 1;
        _kwhCtrl.text = '1';
        _kwhExample = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _persistKwh(Decimal.one);
        });
      } else {
        _kwhValue = kwh.toDouble().clamp(0.0, 5.0);
        _kwhCtrl.text = _decimalText(kwh);
      }
    }
  }

  void _persistProfit(int value) {
    ref
        .read(settingsNotifierProvider.notifier)
        .updateProfitBase(Decimal.fromInt(value));
  }

  void _persistKwh(Decimal value) {
    ref.read(settingsNotifierProvider.notifier).updateKwhRate(value);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    // Seed perezoso: si settings resolvió tras el primer frame (o el
    // usuario re-entra con valores ya persistidos), precarga una sola vez.
    ref.listen(settingsNotifierProvider, (_, next) {
      final settings = next.value;
      if (_seeded || settings == null) return;
      _seeded = true;
      _seedFromSettings(settings);
    });

    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EsBO.setupProfitTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Card opaca plegable con el MISMO patrón que la sección kWh:
          // slider + NumericInputField dentro de surfaceContainerLow (los
          // colores de tema son ilegibles sobre el gradiente); el header
          // muestra el valor vivo SOLO cuando la card está colapsada.
          // Material (no DecoratedBox): el ExpansionTile pinta su
          // ListTile/ink sobre el Material más cercano con color de fondo.
          Material(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const ValueKey('setup-profit-section'),
              initiallyExpanded: true,
              // BUG-006: estado UI local efímero (expansión de la card).
              onExpansionChanged: (open) =>
                  setState(() => _profitExpanded = open),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              iconColor: color.onSurface,
              textColor: color.onSurface,
              title: Row(
                children: [
                  Icon(Icons.percent_rounded, size: 20, color: color.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EsBO.settingsProfitBase,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Icono "i" con el aviso de valor de ejemplo (mismo patrón
                  // Tooltip tap del menú de settings); visible solo mientras
                  // el valor sea el sembrado en el primer arranque.
                  if (_profitExample)
                    Tooltip(
                      message: EsBO.setupExampleValuesHint,
                      triggerMode: TooltipTriggerMode.tap,
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              // Valor vivo SOLO en el header colapsado (preview); al
              // expandir se oculta porque el slider/input de abajo ya lo
              // muestran y solo ocupa espacio.
              subtitle: _profitExpanded
                  ? null
                  : Text(
                      '${_profitCtrl.text.isEmpty ? '0' : _profitCtrl.text} %',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EsBO.configProfitHelper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _bigSlider(
                  color: color.primary,
                  trackColor: color.primaryContainer,
                  value: _profitValue,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  label: '${_profitValue.round()}%',
                  onChanged: (v) {
                    setState(() {
                      _profitValue = v;
                      _profitCtrl.text = v.round().toString();
                      _profitExample = false;
                    });
                    _profitTouched = true;
                  },
                  onChangeEnd: (v) => _persistProfit(v.round()),
                ),
                NumericInputField(
                  key: const ValueKey('setup-profit-input'),
                  label: EsBO.settingsProfitBase,
                  controller: _profitCtrl,
                  allowDecimals: false,
                  suffix: '%',
                  helperText: EsBO.settingsProfitBaseHelper,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return EsBO.commonRequired;
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null) return EsBO.commonInvalidNumber;
                    // LOW-3 (auditoría 2026-10-14): el rango del validator
                    // alineado al del slider (0–500); antes aceptaba hasta
                    // 1000 y el valor quedaba pinchado en el tope del
                    // slider.
                    if (n < 0 || n > 500) {
                      return EsBO.settingsProfitBaseRange500;
                    }
                    return null;
                  },
                  onBlur: (raw) {
                    final n = int.tryParse(raw.trim());
                    // LOW-3: mismo rango 0–500 que el slider y el validator.
                    if (n == null || n < 0 || n > 500) return;
                    _profitTouched = true;
                    _persistProfit(n);
                    setState(() {
                      _profitValue = n.clamp(0, 500).toDouble();
                      _profitExample = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // kWh expandido por defecto (usuario 2026-10-11): el header
          // muestra la tarifa actual (persistida o el ejemplo 1.00) con la
          // moneda activa solo al colapsar. Material (no DecoratedBox): el
          // ExpansionTile pinta su ListTile/ink sobre el Material más
          // cercano con color de fondo.
          Material(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const ValueKey('setup-kwh-section'),
              initiallyExpanded: true,
              // BUG-006: estado UI local efímero (expansión de la card).
              onExpansionChanged: (open) => setState(() => _kwhExpanded = open),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              iconColor: color.onSurface,
              textColor: color.onSurface,
              title: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 20, color: color.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EsBO.settingsKwhRate(currency.symbol),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Mismo icono "i" de valor de ejemplo que la card de
                  // ganancia (Tooltip tap, patrón del menú de settings).
                  if (_kwhExample)
                    Tooltip(
                      message: EsBO.setupExampleValuesHint,
                      triggerMode: TooltipTriggerMode.tap,
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              // Valor vivo SOLO en el header colapsado (preview); al
              // expandir se oculta porque el slider/input de abajo ya lo
              // muestran y solo ocupa espacio.
              subtitle: _kwhExpanded
                  ? null
                  : Text(
                      '${_kwhCtrl.text.isEmpty ? '0' : _kwhCtrl.text} '
                      '${currency.symbol}/kWh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EsBO.configKwhHelper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _bigSlider(
                  color: color.secondary,
                  trackColor: color.secondaryContainer,
                  value: _kwhValue,
                  min: 0,
                  max: 5,
                  divisions: 50,
                  label:
                      '${_kwhValue.toStringAsFixed(2)} '
                      '${currency.symbol}',
                  onChanged: (v) {
                    setState(() {
                      _kwhValue = v;
                      _kwhCtrl.text = v.toStringAsFixed(2);
                      _kwhExample = false;
                    });
                    _kwhTouched = true;
                  },
                  onChangeEnd: (v) =>
                      _persistKwh(Decimal.parse(v.toStringAsFixed(2))),
                ),
                NumericInputField(
                  key: const ValueKey('setup-kwh-input'),
                  label: EsBO.settingsKwhRate(currency.symbol),
                  controller: _kwhCtrl,
                  allowDecimals: true,
                  suffix: '${currency.symbol}/kWh',
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return EsBO.commonRequired;
                    }
                    final n = Decimal.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null) return EsBO.commonInvalidNumber;
                    if (n < Decimal.zero || n > Decimal.parse('5.00')) {
                      return EsBO.settingsKwhRateRange;
                    }
                    return null;
                  },
                  onBlur: (raw) {
                    final n = Decimal.tryParse(raw.trim().replaceAll(',', '.'));
                    if (n == null ||
                        n < Decimal.zero ||
                        n > Decimal.parse('5.00')) {
                      return;
                    }
                    _kwhTouched = true;
                    _persistKwh(n);
                    setState(() {
                      _kwhValue = n.toDouble().clamp(0.0, 5.0);
                      _kwhExample = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Slider grande compartido (ganancia y kWh): track grueso + thumb
  /// amplio para que se sienta el "grande" del rediseño.
  Widget _bigSlider({
    required Color color,
    required Color trackColor,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: color,
        inactiveTrackColor: trackColor,
        thumbColor: color,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayColor: color.withValues(alpha: 0.15),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
