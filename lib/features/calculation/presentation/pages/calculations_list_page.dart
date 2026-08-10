// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/currency_settings_provider.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';

import '../../../../shared/widgets/skeleton_widget.dart';
import '../../../entitlement/presentation/providers/entitlement_providers.dart';
import '../notifiers/calculations_notifier.dart';

/// Historial de cotizaciones guardadas con search + filtros.
class CalculationsListPage extends ConsumerStatefulWidget {
  const CalculationsListPage({super.key});

  @override
  ConsumerState<CalculationsListPage> createState() =>
      _CalculationsListPageState();
}

class _CalculationsListPageState
    extends ConsumerState<CalculationsListPage> {
  late final TextEditingController _searchCtrl;
  bool? _soldFilter;

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

    // Patron de estado del gate visual (UX): "locked" solo cuando el
    // entitlement esta resuelto y el user es free. Durante el boot async
    // (loading) el boton se ve normal (evita falso "locked" en cold start).
    final ent = ref.watch(entitlementNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final csvLocked = !ent.isLoading && !isPro;
    final usedCount = async.value?.length ?? 0;

    // Contador "x/$kFreeHistoryCap": solo para free, y solo cuando la
    // lista muestra el set completo (sin busqueda ni filtro de venta —
    // con filtros el count del state no representa el historial total).
    // `async.hasValue` evita mostrar "0/10" durante loading/error.
    final showHistoryCounter = csvLocked &&
        async.hasValue &&
        _searchCtrl.text.isEmpty &&
        _soldFilter == null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(EsBO.historyTitle),
        actions: [
          IconButton(
            icon: Opacity(
              opacity: csvLocked ? kLockedOpacity : 1.0,
              child: Icon(
                csvLocked
                    ? Icons.lock_rounded
                    : Icons.file_download_outlined,
                size: 20,
              ),
            ),
            tooltip: csvLocked
                ? EsBO.csvExportTooltipLocked
                : EsBO.historyExportCsv,
            onPressed: () => _exportCsv(notifier),
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
                hintText: EsBO.historySearchHint,
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (v) {
                notifier.search(v);
                setState(() {});
              },
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                _filterChip(EsBO.historyFilterAll, null),
                _filterChip(EsBO.historyFilterSold, true),
                _filterChip(EsBO.historyFilterPending, false),
              ],
            ),
          ),
          // History usage counter (free only)
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
                        horizontal: 16, vertical: 8),
                    itemCount: calcs.length,
                    itemBuilder: (_, i) => _StaggeredItem(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CalculationCard(
                            calc: calcs[i], notifier: notifier),
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
    final selected = _soldFilter == filter;
    return FilterChip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _soldFilter = _soldFilter == filter ? null : filter);
        ref
            .read(calculationsNotifierProvider.notifier)
            .setSoldFilter(_soldFilter);
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Future<void> _exportCsv(CalculationsNotifier notifier) async {
    // T16 (plan de monetizacion): CSV export es Pro. En Free, gate con
    // SnackBar que ofrece "Go Pro" y navega a /paywall. En Pro, se
    // procede con el export normal.
    //
    // Mismo patron que `_switchMode` (calculator_page.dart): el gate
    // lee el estado real del entitlement (no `isProProvider` solo).
    // Durante el boot async el notifier esta loading e isPro=false, lo
    // que daria un falso "locked" a un Pro real en cold start. Si sigue
    // loading, swallow (no gatear); solo gateamos resuelto.
    final ent = ref.read(entitlementNotifierProvider);
    if (ent.isLoading) return;
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.warning(
          EsBO.csvExportLockedBody,
          actionLabel: EsBO.csvGoProAction,
          onAction: () {
            if (!mounted) return;
            context.push('/paywall');
          },
        ),
      );
      return;
    }

    final async = ref.read(calculationsNotifierProvider);
    final calcs = async.value;
    if (calcs == null || calcs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(context, EsBO.historyNoQuotesToExport),
      );
      return;
    }

    final buf = StringBuffer();
    // Header
    buf.writeln(
        'Fecha,Pieza,Cliente,Total,Vendido,Materiales,Horas,Descuento,'
        'CostoMat,Elect,Profit');
    // Rows
    for (final c in calcs) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(c.createdAt.toLocal());
      final piece = _escapeCsv(c.pieceName ?? '');
      final client = _escapeCsv(c.clientName ?? '');
      final total = formatRaw(c.totalPriceSnapshot);
      final sold = c.isSold ? 'Si' : 'No';
      final hours = c.totalHours.toStringAsFixed(2);
      final discount = c.discountPercentage.toStringAsFixed(1);
      final matCost = formatRaw(c.materialCostSnapshot);
      final elect = formatRaw(c.electricCostSnapshot);
      final profit = formatRaw(c.profitAmountSnapshot);
      buf.writeln('$date,$piece,$client,$total,$sold,$hours,$discount,'
          '$matCost,$elect,$profit');
    }

    final bytes = Uint8List.fromList(utf8.encode(buf.toString()));
    final xfile = XFile.fromData(bytes,
        name: 'cotizaciones_3dcalc.csv', mimeType: 'text/csv');
    await Share.shareXFiles([xfile], text: EsBO.pdfShareSubject);
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

class _CalculationCard extends ConsumerWidget {
  const _CalculationCard({required this.calc, required this.notifier});

  final Calculation calc;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final client = calc.clientName;
    final currency = ref.watch(selectedCurrencyProvider);

    return Semantics(
      container: true,
      label: '${_title()}, ${formatCurrency(Decimal.parse(calc.totalPriceSnapshot.toString()), currency)}'
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
                // Leading icon (decorative — sale status already in label)
                ExcludeSemantics(
                  child: Hero(
                    tag: 'calc-hero-${calc.id}',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: calc.isSold
                            ? color.tertiaryContainer
                            : color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Icon(
                        calc.isSold
                            ? Icons.check_circle_rounded
                            : Icons.receipt_long_rounded,
                        color: calc.isSold
                            ? color.tertiary
                            : color.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
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
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: color.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              client,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        Text(
                          DateFormat('dd MMM HH:mm')
                              .format(calc.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
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
                    formatCurrency(Decimal.parse(
                        calc.totalPriceSnapshot.toString()), currency),
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

class _PopupMenu extends StatelessWidget {
  const _PopupMenu({required this.calc, required this.notifier});

  final Calculation calc;
  final CalculationsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TileAction>(
      onSelected: (a) => _handle(context, a),
      padding: EdgeInsets.zero,
      iconSize: 18,
      itemBuilder: (_) => [
        PopupMenuItem<_TileAction>(
          value: _TileAction.toggleSold,
          child: ListTile(
            leading: Icon(
              calc.isSold ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
              size: 20,
            ),
            title: Text(
                calc.isSold ? EsBO.calcDetailMarkPending : EsBO.calcDetailMarkSold,
                style: Theme.of(context).textTheme.labelLarge),
            dense: true,
          ),
        ),
        PopupMenuItem<_TileAction>(
          value: _TileAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, size: 20),
            title: Text(EsBO.commonDelete,
                style: Theme.of(context).textTheme.labelLarge),
            dense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handle(BuildContext context, _TileAction a) async {
    switch (a) {
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

enum _TileAction { toggleSold, delete }

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
