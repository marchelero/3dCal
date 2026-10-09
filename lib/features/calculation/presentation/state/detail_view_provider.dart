// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/export/quote_report_variant.dart';

/// Estado de vista (efimero) del detalle de una cotizacion: variante de
/// reporte elegida + cantidad mostrada/editada.
///
/// Antes vivia en `setState` local de `_DetailState`; se migro a Riverpod
/// (T1-2) porque ambos valores afectan el reporte y el MONTO exportado (son
/// estado de negocio, no UI efimera). El provider es `autoDispose`: se libera
/// al salir de la pantalla.
///
/// El estado arranca en `null` (= "sin editar"). Mientras sea `null`, la
/// pantalla resuelve los valores guardados con [initialDetailViewState]; en la
/// primera edicion el notifier materializa ese valor por defecto y aplica el
/// cambio. Asi no hace falta "sembrar" el provider durante `initState`, que
/// Riverpod 3 prohibe (modificar un provider dentro del ciclo de vida del
/// widget).
class DetailViewState {
  const DetailViewState({required this.variant, required this.quantity});

  /// Variante del reporte (pantalla, PDF, PNG e impresion).
  final QuoteReportVariant variant;

  /// Cantidad mostrada/editada (lotes), siempre en `[1, kMaxQuantity]`.
  final int quantity;

  DetailViewState copyWith({QuoteReportVariant? variant, int? quantity}) =>
      DetailViewState(
        variant: variant ?? this.variant,
        quantity: quantity ?? this.quantity,
      );

  @override
  bool operator ==(Object other) =>
      other is DetailViewState &&
      variant == other.variant &&
      quantity == other.quantity;

  @override
  int get hashCode => Object.hash(variant, quantity);
}

/// Clampea una cantidad al rango valido `[1, kMaxQuantity]`.
int clampDetailQuantity(int quantity) {
  if (quantity < 1) return 1;
  if (quantity > kMaxQuantity) return kMaxQuantity;
  return quantity;
}

/// Estado por defecto derivado de la cotizacion guardada: variante segun el
/// modo (advanced/simple) y la cantidad guardada (>= 1).
DetailViewState initialDetailViewState(Calculation calc) => DetailViewState(
  variant: calc.isAdvanced
      ? QuoteReportVariant.clientAdvanced
      : QuoteReportVariant.clientSimple,
  quantity: clampDetailQuantity(calc.quantity),
);

/// Estado de vista del detalle activo. `null` = sin editar todavia; la pantalla
/// usa [initialDetailViewState] como fallback.
class DetailViewNotifier extends Notifier<DetailViewState?> {
  @override
  DetailViewState? build() => null;

  DetailViewState _resolve(Calculation calc) =>
      state ?? initialDetailViewState(calc);

  void setVariant(Calculation calc, QuoteReportVariant variant) {
    final current = _resolve(calc);
    if (current.variant == variant) return;
    state = current.copyWith(variant: variant);
  }

  void setQuantity(Calculation calc, int quantity) {
    final current = _resolve(calc);
    final clamped = clampDetailQuantity(quantity);
    if (current.quantity == clamped) return;
    state = current.copyWith(quantity: clamped);
  }

  void decrement(Calculation calc) =>
      setQuantity(calc, _resolve(calc).quantity - 1);

  void increment(Calculation calc) =>
      setQuantity(calc, _resolve(calc).quantity + 1);
}

/// Estado de vista del detalle activo. `autoDispose`: se libera al salir.
final detailViewProvider =
    NotifierProvider.autoDispose<DetailViewNotifier, DetailViewState?>(
      DetailViewNotifier.new,
    );
