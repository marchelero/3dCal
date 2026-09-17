// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_widget.dart';
import '../../../../shared/widgets/smart_app_bar_actions.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart'
    show isProProvider;
import '../../data/calculation_repository.dart';
import '../notifiers/calculations_notifier.dart';
import '../notifiers/history_sort.dart';

/// Historial de cotizaciones guardadas con search + filtros.
class CalculationsListPage extends ConsumerStatefulWidget {
  const CalculationsListPage({super.key});

  @override
  ConsumerState<CalculationsListPage> createState() =>
      _CalculationsListPageState();
}

class _CalculationsListPageState extends ConsumerState<CalculationsListPage> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final async = ref.watch(calculationsNotifierProvider);
    final notifier = ref.read(calculationsNotifierProvider.notifier);

    // Estado de filtros activos (PRD 2026-09-11): el notifier es la unica
    // fuente de verdad; esto es lectura pura para pintar chips/resumen.
    final soldFilter = notifier.soldFilter;
    final dateRange = notifier.dateRange;
    final clientFilter = notifier.clientFilter;

    // Patron de estado del gate visual (UX): ya no se bloquea CSV —
    // los datos son del usuario y exportar es un derecho basico.
    final isPro = ref.watch(isProProvider);
    final usedCount = async.value?.length ?? 0;

    // Barra de resumen: visible SOLO con >=1 filtro activo (search, venta,
    // fechas o cliente). El orden NO cuenta como filtro.
    final hasActiveFilter =
        notifier.searchQuery.isNotEmpty ||
        soldFilter != null ||
        dateRange != null ||
        clientFilter != null;

    // Contador "x/$kFreeHistoryCap": solo free, y solo cuando la lista
    // muestra el set completo (sin filtros activos — con filtros el count
    // del state no representa el historial total).
    final showHistoryCounter = !isPro && async.hasValue && !hasActiveFilter;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.historyTitle),
        actions: [
          SmartAppBarActions(
            // M3 (review): CSV directo en pantallas normales; solo el orden
            // colapsa al menu ⋮ en angosto.
            priority: [
              Tooltip(
                message: EsBO.historyExportCsv,
                child: IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    size: 20,
                  ),
                  onPressed: () => _exportCsv(notifier),
                ),
              ),
            ],
            menuActions: [
              (
                icon: Icon(
                  Icons.sort_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: EsBO.historySortTitle,
                onTap: _showSortSheet,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: EsBO.historySearchMaterialsHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          notifier.search('');
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ),
              onChanged: (v) {
                notifier.search(v);
                setState(() {});
              },
            ),
          ),
          // Filter chips (Venta + Fechas + Cliente activo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _filterChip(EsBO.historyFilterAll, null),
                _filterChip(EsBO.historyFilterSold, true),
                _filterChip(EsBO.historyFilterPending, false),
                ..._dateChips(dateRange, notifier),
                ..._clientChips(clientFilter, notifier),
              ],
            ),
          ),
          // Barra de resumen: "N cotizaciones · total efectivo" (PRD 2026-09-11)
          if (hasActiveFilter && async.hasValue)
            _SummaryBar(calcs: async.value!),
          // History usage counter (free only, sin filtros activos)
          if (showHistoryCounter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      EsBO.historyUsageCounter(usedCount, kFreeHistoryCap),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: async.when(
              loading: () => const ListPageSkeleton(),
              error: (e, _) => ErrorView(
                message: EsBO.historyErrorLoad,
                details: e.toString(),
                onRetry: () => ref.invalidate(calculationsNotifierProvider),
              ),
              data: (calcs) {
                if (calcs.isEmpty) {
                  return EmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: _searchCtrl.text.isNotEmpty
                        ? EsBO.commonNoResultsFor(_searchCtrl.text)
                        : EsBO.historyEmpty,
                    subtitle: _searchCtrl.text.isNotEmpty
                        ? EsBO.historyEmptySearchHint
                        : EsBO.historyEmptyCta,
                    ctaLabel: EsBO.homeActionNewCalc,
                    ctaIcon: Icons.add_rounded,
                    onCta: () => context.push('/calculator'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(calculationsNotifierProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: calcs.length,
                    itemBuilder: (_, i) => _StaggeredItem(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CalculationCard(
                          calc: calcs[i],
                          notifier: notifier,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool? filter) {
    final notifier = ref.read(calculationsNotifierProvider.notifier);
    final soldFilter = notifier.soldFilter;
    final selected = soldFilter == filter;
    return FilterChip(
      label: Text(label, style: Theme.of(context).textTheme.labelMedium),
      selected: selected,
      onSelected: (_) {
        // Toggle: repetir el valor activo lo limpia (null = todas).
        notifier.setSoldFilter(selected ? null : filter);
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// Chips del filtro de fechas (PRD 2026-09-11): sin rango abren el
  /// selector de presets; con rango muestran el label compacto + ×.
  List<Widget> _dateChips(DateTimeRange? range, CalculationsNotifier n) {
    if (range != null) {
      return [
        InputChip(
          label: Text(_dateChipLabel(range)),
          onDeleted: () => n.setDateRange(null),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ];
    }
    return [
      FilterChip(
        label: Text(
          EsBO.historyFilterDate,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        selected: false,
        onSelected: (_) => _showDateSheet(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ];
  }

  /// Chip del cliente activo (PRD 2026-09-11): avatar + label + × para
  /// limpiar. Fuera del filtro no se muestra chip.
  List<Widget> _clientChips(String? client, CalculationsNotifier n) {
    if (client == null) return const [];
    return [
      InputChip(
        avatar: Icon(
          Icons.person_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        label: Text(EsBO.historyClientFilterChip(client)),
        onDeleted: () => n.setClientFilter(null),
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ];
  }

  /// Label compacto del chip de fechas: '7 d' / '30 d' para los presets
  /// por dias, 'dd/MM – dd/MM' para el resto (incluye bornes, por eso +1).
  String _dateChipLabel(DateTimeRange range) {
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final days = end.difference(start).inDays + 1;
    if (days == 7) return '7 d';
    if (days == 30) return '30 d';
    return EsBO.historyDateRangeLabel(range);
  }

  /// Sheet de presets de fecha (PRD 2026-09-11): Hoy / 7d / 30d / Este mes /
  /// Este año / Todo / Personalizado.
  Future<void> _showDateSheet() async {
    final now = DateTime.now();
    final preset = await showModalBottomSheet<_DatePreset>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        // SingleChildScrollView: el sheet nada scrollable puede medir menos
        // que su contenido (7 presets + header) en superficies bajas.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  EsBO.historyFilterDate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final (preset, label) in _datePresetOptions)
                ListTile(
                  leading: const Icon(Icons.date_range_rounded, size: 20),
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(preset),
                ),
            ],
          ),
        ),
      ),
    );
    if (preset == null || !mounted) return;
    switch (preset) {
      case _DatePreset.today:
        _applyDateRange(
          DateTimeRange(start: _startOfDay(now), end: _endOfDay(now)),
        );
      case _DatePreset.sevenDays:
        _applyDateRange(
          DateTimeRange(
            start: _startOfDay(now.subtract(const Duration(days: 6))),
            end: _endOfDay(now),
          ),
        );
      case _DatePreset.thirtyDays:
        _applyDateRange(
          DateTimeRange(
            start: _startOfDay(now.subtract(const Duration(days: 29))),
            end: _endOfDay(now),
          ),
        );
      case _DatePreset.month:
        _applyDateRange(
          DateTimeRange(
            start: _startOfDay(DateTime(now.year, now.month, 1)),
            end: _endOfDay(DateTime(now.year, now.month + 1, 0)),
          ),
        );
      case _DatePreset.year:
        _applyDateRange(
          DateTimeRange(
            start: _startOfDay(DateTime(now.year, 1, 1)),
            end: _endOfDay(DateTime(now.year, 12, 31)),
          ),
        );
      case _DatePreset.all:
        // "Todo" elimina el filtro de fechas.
        ref.read(calculationsNotifierProvider.notifier).setDateRange(null);
      case _DatePreset.custom:
        await _pickCustomRange(now);
    }
  }

  /// Presets accesibles del sheet de fechas.
  List<(_DatePreset, String)> get _datePresetOptions => [
    (_DatePreset.today, EsBO.historyDatePresetToday),
    (_DatePreset.sevenDays, EsBO.historyDatePreset7d),
    (_DatePreset.thirtyDays, EsBO.historyDatePreset30d),
    (_DatePreset.month, EsBO.historyDatePresetMonth),
    (_DatePreset.year, EsBO.historyDatePresetYear),
    (_DatePreset.all, EsBO.historyDatePresetAll),
    (_DatePreset.custom, EsBO.historyDatePresetCustom),
  ];

  /// "Personalizado": date range picker; el end seleccionado se lleva a
  /// fin-de-dia para que el filtro del notifier sea inclusivo en el dia.
  Future<void> _pickCustomRange(DateTime now) async {
    final notifier = ref.read(calculationsNotifierProvider.notifier);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: _startOfDay(now),
      initialDateRange: notifier.dateRange,
    );
    if (picked == null || !mounted) return;
    notifier.setDateRange(
      DateTimeRange(
        start: _startOfDay(picked.start),
        end: _endOfDay(picked.end),
      ),
    );
  }

  void _applyDateRange(DateTimeRange range) {
    ref.read(calculationsNotifierProvider.notifier).setDateRange(range);
  }

  /// Sheet de orden (PRD 2026-09-11): 5 opciones con check en la activa.
  /// El orden NO es un filtro (no afecta contador free ni resumen).
  Future<void> _showSortSheet() async {
    final notifier = ref.read(calculationsNotifierProvider.notifier);
    final current = notifier.sort;
    final selected = await showModalBottomSheet<HistorySort>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        // SingleChildScrollView: mismo patron que el sheet de fechas.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  EsBO.historySortTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final (sort, label) in _sortOptions)
                ListTile(
                  leading: sort == current
                      ? const Icon(Icons.check_rounded, size: 20)
                      : null,
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(sort),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    notifier.setSort(selected);
  }

  /// Opciones del sheet de orden, ordenadas como aparecen en la UI.
  List<(HistorySort, String)> get _sortOptions => [
    (HistorySort.dateNewest, EsBO.historySortDateNewest),
    (HistorySort.dateOldest, EsBO.historySortDateOldest),
    (HistorySort.priceHigh, EsBO.historySortPriceHigh),
    (HistorySort.priceLow, EsBO.historySortPriceLow),
    (HistorySort.clientAz, EsBO.historySortClientAz),
  ];

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999, 999);

  Future<void> _exportCsv(CalculationsNotifier notifier) async {
    // CSV export es gratuito — los datos son del usuario.
    // Solo se verifica que no este loading (evita double-tap).

    // PRD criterio #10: el CSV exporta el historial COMPLETO (`notifier.all`),
    // no el set filtrado que se muestra en pantalla.
    final calcs = notifier.all;
    if (calcs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(AppSnackBar.info(context, EsBO.historyNoQuotesToExport));
      return;
    }

    final buf = StringBuffer();
    // Header (localized via csvExportHeader; column order MUST stay in sync
    // with the writer below).
    buf.writeln(EsBO.csvExportHeader.join(','));
    // Rows (valores efectivos = unitario x cantidad)
    for (final c in calcs) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(c.createdAt.toLocal());
      final piece = _escapeCsv(c.pieceName ?? '');
      final client = _escapeCsv(c.clientName ?? '');
      final total = formatRaw(c.totalPriceSnapshot * c.quantity);
      final sold = c.isSold ? EsBO.csvValueYes : EsBO.csvValueNo;
      final hours = (c.totalHours * c.quantity).toStringAsFixed(2);
      final discount = c.discountPercentage.toStringAsFixed(1);
      final batchPct = c.batchDiscountPercent != null
          ? double.tryParse(c.batchDiscountPercent!)?.toStringAsFixed(1) ?? ''
          : '';
      final batchAmt = c.batchDiscountAmount != null
          ? formatRaw(double.tryParse(c.batchDiscountAmount!) ?? 0)
          : '';
      final matCost = formatRaw(c.materialCostSnapshot * c.quantity);
      final elect = formatRaw(c.electricCostSnapshot * c.quantity);
      final profit = formatRaw(c.profitAmountSnapshot * c.quantity);
      buf.writeln(
        '$date,$piece,$client,${c.quantity},$total,$sold,$hours,$discount,'
        '$batchPct,$batchAmt,$matCost,$elect,$profit',
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(buf.toString()));
    final xfile = XFile.fromData(
      bytes,
      name: EsBO.csvFileName,
      mimeType: 'text/csv',
    );
    await SharePlus.instance.share(
      ShareParams(files: [xfile], text: EsBO.pdfShareSubject),
    );
  }

  /// Formatea double sin separadores de miles (raw para CSV).
  static String formatRaw(double v) =>
      v.toStringAsFixed(2).replaceAll('.', ',');

  /// Escapa string para CSV (envuelve en quotes si contiene coma o quote).
  static String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

/// Barra de resumen del historial (PRD 2026-09-11).
///
/// Muestra "N cotizaciones · $total" con el TOTAL EFECTIVO del set filtrado
/// (unitario x cantidad). Visible SOLO con >=1 filtro activo.
class _SummaryBar extends ConsumerWidget {
  const _SummaryBar({required this.calcs});

  final List<CalculationListItem> calcs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(selectedCurrencyProvider);
    final total = calcs.fold<Decimal>(
      Decimal.zero,
      (acc, c) => acc + c.effectiveTotal,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              EsBO.historyFilterSummary(
                calcs.length,
                formatCurrency(total, currency),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Presets del sheet de fechas del historial.
enum _DatePreset { today, sevenDays, thirtyDays, month, year, all, custom }

class _CalculationCard extends ConsumerWidget {
  const _CalculationCard({required this.calc, required this.notifier});

  final CalculationListItem calc;
  final CalculationsNotifier notifier;

  String _title() {
    final piece = calc.pieceName;
    if (piece != null && piece.isNotEmpty) return piece;
    final client = calc.clientName;
    if (client != null && client.isNotEmpty) {
      return '${EsBO.calcSheetTitle} · $client';
    }
    return EsBO.calcDetailNoName;
  }

  /// PRD 2026-09-11: togglea el filtro de cliente desde el tap en el nombre
  /// del card (una columna con filtros a nivel historial).
  void _toggleClientFilter(String name) {
    // N1 (review): el filtro del notifier es case-insensitive; normalizar
    // ambos lados para que toggle y highlight no diverjan.
    notifier.setClientFilter(
      notifier.clientFilter?.toLowerCase() == name.toLowerCase() ? null : name,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final client = calc.clientName;
    final currency = ref.watch(selectedCurrencyProvider);
    // PRD 2026-09-11: resaltar el cliente cuando el historial lo filtra.
    // N1: comparacion case-insensitive (igual que el filtro del notifier).
    final isClientFiltered =
        client != null &&
        client.toLowerCase() == (notifier.clientFilter ?? '').toLowerCase();

    return Semantics(
      container: true,
      label:
          // BUG-017 fix: toStringAsFixed(2) evita notacion cientifica/NaN
          // en Decimal.parse para snapshots corruptos. Total efectivo =
          // unitario x cantidad (lotes).
          '${_title()}, ${formatCurrency(calc.effectiveTotal, currency)}'
          '${calc.isSold ? ", ${EsBO.calcDetailSold}" : ""}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            onTap: () => context.push('/history/${calc.id}', extra: calc),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Leading: thumbnail 44x44 cuando la cotizacion tiene
                  // foto persistida (F2/F3); si no, el icono decorativo de
                  // siempre (sale status ya esta en el label). El BLOB solo
                  // se materializa on-demand por card (familia autoDispose).
                  ExcludeSemantics(
                    child: calc.hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            child: _CardThumb(
                              calcId: calc.id,
                              isSold: calc.isSold,
                            ),
                          )
                        : _IconPlaceholder(isSold: calc.isSold),
                  ),
                  const SizedBox(width: 14),
                  // Body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            if (client != null && client.isNotEmpty) ...[
                              Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: color.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: InkWell(
                                  onTap: () => _toggleClientFilter(client),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xxs,
                                    ),
                                    child: Text(
                                      client,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isClientFiltered
                                                ? color.primary
                                                : color.onSurfaceVariant,
                                            fontWeight: isClientFiltered
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: color.onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Flexible(
                              child: Text(
                                DateFormat(
                                  'dd MMM HH:mm',
                                ).format(calc.createdAt.toLocal()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Price + menu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        // BUG-017 fix: idem, toStringAsFixed(2).
                        // Total efectivo = unitario x cantidad (lotes).
                        formatCurrency(calc.effectiveTotal, currency),
                        // M2: precio en list item usa JetBrains Mono + tabular
                        // para alineacion vertical de cifras en el listado.
                        style: GoogleFonts.jetBrainsMono(
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: color.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (calc.quantity > 1)
                        Text(
                          '${calc.quantity} u.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      _PopupMenu(calc: calc, notifier: notifier),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// BLOB de imagen de una cotizacion, materializado SOLO on-demand (F3).
///
/// La lista nunca carga BLOBs: cada card que va a mostrar thumbnail
/// consulta la fila completa via [CalculationRepository.getById] en una
/// familia autoDispose (se descarta al salir de la pagina).
final _cardBlobProvider = FutureProvider.autoDispose.family<Uint8List?, int>((
  ref,
  calcId,
) async {
  final repo = ref.watch(calculationRepositoryProvider);
  final calc = await repo.getById(calcId);
  return calc?.pieceImageBlob;
});

/// Cuadro decorativo 44x44 (icono por estado) usado como fallback del
/// thumbnail y como leading cuando la cotizacion no tiene foto.
class _IconPlaceholder extends StatelessWidget {
  const _IconPlaceholder({required this.isSold});

  final bool isSold;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSold ? color.tertiaryContainer : color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Icon(
        isSold ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
        color: isSold ? color.tertiary : color.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}

/// Thumbnail 44x44 del BLOB persistido, cargado on-demand (F3).
///
/// Muestra el placeholder de icono mientras el BLOB no llega (o si por
/// algun motivo la row ya no tiene foto).
class _CardThumb extends ConsumerWidget {
  const _CardThumb({required this.calcId, required this.isSold});

  final int calcId;
  final bool isSold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final blobAsync = ref.watch(_cardBlobProvider(calcId));
    final blob = blobAsync.value;
    if (blob == null) return _IconPlaceholder(isSold: isSold);
    return Image.memory(
      blob,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      // Decode acotado (RNF): 88px alcanza para 44px a hasta 2x, no
      // decodifica el JPEG full.
      cacheWidth: 88,
      cacheHeight: 88,
      errorBuilder: (_, _, _) => Container(
        width: 44,
        height: 44,
        color: color.surfaceContainerHighest,
        child: Icon(
          isSold ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
          color: isSold ? color.tertiary : color.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}

class _PopupMenu extends ConsumerWidget {
  const _PopupMenu({required this.calc, required this.notifier});

  final CalculationListItem calc;
  final CalculationsNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_TileAction>(
      onSelected: (a) => _handle(context, ref, a),
      padding: EdgeInsets.zero,
      iconSize: 18,
      itemBuilder: (_) => [
        PopupMenuItem<_TileAction>(
          value: _TileAction.repeat,
          child: ListTile(
            leading: const Icon(Icons.replay_rounded, size: 20),
            title: Text(
              EsBO.calcDetailReuse,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            dense: true,
          ),
        ),
        PopupMenuItem<_TileAction>(
          value: _TileAction.duplicate,
          child: ListTile(
            leading: const Icon(Icons.copy_all_rounded, size: 20),
            title: Text(
              EsBO.calcDuplicateAction,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            dense: true,
          ),
        ),
        PopupMenuItem<_TileAction>(
          value: _TileAction.toggleSold,
          child: ListTile(
            leading: Icon(
              calc.isSold
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              size: 20,
            ),
            title: Text(
              calc.isSold
                  ? EsBO.calcDetailMarkPending
                  : EsBO.calcDetailMarkSold,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            dense: true,
          ),
        ),
        PopupMenuItem<_TileAction>(
          value: _TileAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, size: 20),
            title: Text(
              EsBO.commonDelete,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            dense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handle(BuildContext context, WidgetRef ref, _TileAction a) async {
    switch (a) {
      case _TileAction.repeat:
        // "Cotizar igual": cargar la cotizacion completa y navegar al
        // calculator con prefill (misma UX que el FAB del detalle).
        final repo = ref.read(calculationRepositoryProvider);
        final full = await repo.getById(calc.id);
        if (full != null && context.mounted) {
          await context.push('/calculator/prefill', extra: full);
        }
      case _TileAction.duplicate:
        try {
          await notifier.duplicate(
            calc.id,
            pieceNameSuffix: EsBO.calcDuplicateSuffix,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(AppSnackBar.success(EsBO.calcDuplicateSuccess));
        } catch (e) {
          if (e is HistoryCapReachedException) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                AppSnackBar.info(
                  context,
                  EsBO.historyCapReachedBody,
                  actionLabel: EsBO.calculatorGoProAction,
                  onAction: () => context.push('/paywall'),
                ),
              );
            return;
          }
          debugPrint('Duplicate quote failed: $e');
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(AppSnackBar.error(EsBO.calcDuplicateError));
        }
      case _TileAction.toggleSold:
        await notifier.toggleSold(calc.id, !calc.isSold);
      case _TileAction.delete:
        final confirm = await showConfirmDialog(
          context,
          title: EsBO.calcDetailDeleteTitle,
          message: EsBO.calcDetailDeleteConfirm,
        );
        if (confirm) {
          await notifier.delete(calc.id);
        }
    }
  }
}

enum _TileAction { repeat, duplicate, toggleSold, delete }

/// Staggered entrance animation para items de lista.
///
/// Cada item hace slide-up + fade con delay progresivo segun [index].
/// El efecto es visible al entrar a la pagina (entran uno tras otro).
class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(_anim),
        child: widget.child,
      ),
    );
  }
}
