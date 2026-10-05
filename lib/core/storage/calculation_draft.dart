// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

/// Estado serializable del formulario de cotizacion.
///
/// Guarda todos los campos del calculator para restaurar al reabrir la app.
class CalculationDraft {
  const CalculationDraft({
    this.weight = '',
    this.printHours = '',
    this.printMinutes = '',
    this.discountPct = '',
    this.filamentPrice = '',
    this.filamentGrams = '',
    this.label = '',
    this.filamentLabel = '',
    this.clientName = '',
    this.isAdvanced = false,
    this.materials = const [],
    // MED-07 fix (auditoría 2026-10-04): el draft de sesion no guardaba la
    // cantidad del lote; al reabrir la app un lote de 12 u volvía a 1 u.
    this.quantity = 1,
    this.extraLaborRate = '',
    this.extraPostProcessRate = '',
    this.extraFailureRate = '',
    this.extraMarkupOnMaterials = '',
    this.modelingMode = 'fixed',
    this.modelingValue = 0,
    this.postprocMode = 'fixed',
    this.postprocValue = 0,
    this.extraCostMode = 'fixed',
    this.extraCostValue = 0,
    this.extraCostLabel = '',
  });

  factory CalculationDraft.fromJson(Map<String, dynamic> json) {
    return CalculationDraft(
      weight: json['weight'] as String? ?? '',
      printHours: json['printHours'] as String? ?? '',
      printMinutes: json['printMinutes'] as String? ?? '',
      discountPct: json['discountPct'] as String? ?? '',
      filamentPrice: json['filamentPrice'] as String? ?? '',
      filamentGrams: json['filamentGrams'] as String? ?? '',
      label: json['label'] as String? ?? '',
      filamentLabel: json['filamentLabel'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      isAdvanced: json['isAdvanced'] as bool? ?? false,
      // MED-07: tolerante — drafts escritos por versiones previas no traen
      // la clave; caen al default 1 sin tumbar la restauracion.
      quantity: _toIntPositive(json['quantity']),
      materials:
          (json['materials'] as List?)
              ?.map((e) => MaterialDraft.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      extraLaborRate: json['extraLaborRate'] as String? ?? '',
      extraPostProcessRate: json['extraPostProcessRate'] as String? ?? '',
      extraFailureRate: json['extraFailureRate'] as String? ?? '',
      extraMarkupOnMaterials: json['extraMarkupOnMaterials'] as String? ?? '',
      modelingMode: json['modelingMode'] as String? ?? 'fixed',
      modelingValue: _toDouble(json['modelingValue']),
      postprocMode: json['postprocMode'] as String? ?? 'fixed',
      postprocValue: _toDouble(json['postprocValue']),
      extraCostMode: json['extraCostMode'] as String? ?? 'fixed',
      extraCostValue: _toDouble(json['extraCostValue']),
      extraCostLabel: json['extraCostLabel'] as String? ?? '',
    );
  }

  /// Acepta el valor numerico venga como `double` (draft nuevo) o como `String`
  /// (draft escrito por una version previa / por el editor de texto). Un draft
  /// corrupto no debe tumbar la restauracion: cae en 0.
  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Cantidad del lote desde JSON tolerante: Missing/invalido/<1 -> 1.
  static int _toIntPositive(Object? v) {
    if (v is num) return v.toInt() < 1 ? 1 : v.toInt();
    if (v is String) {
      final n = int.tryParse(v);
      return (n == null || n < 1) ? 1 : n;
    }
    return 1;
  }

  final String weight;
  final String printHours;
  final String printMinutes;
  final String discountPct;
  final String filamentPrice;
  final String filamentGrams;
  final String label;
  final String filamentLabel;
  final String clientName;
  final bool isAdvanced;
  final List<MaterialDraft> materials;

  /// Cantidad del lote (>= 1). MED-07 fix.
  final int quantity;

  // === F1: OTROS ===
  final String extraLaborRate;
  final String extraPostProcessRate;
  final String extraFailureRate;
  final String extraMarkupOnMaterials;

  // === v17: Costos de la pieza (modelado / postprocesado / extras) ===
  //
  // Modos: solo `pct` (porcentaje sobre coreBase) o `fixed` (monto fijo).
  // Los valores van como `double` porque terminan en columnas REAL de Drift.
  final String modelingMode;
  final double modelingValue;
  final String postprocMode;
  final double postprocValue;
  final String extraCostMode;
  final double extraCostValue;

  /// Texto libre de los extras ("2 argollas M3"). No afecta el calculo.
  final String extraCostLabel;

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'printHours': printHours,
    'printMinutes': printMinutes,
    'discountPct': discountPct,
    'filamentPrice': filamentPrice,
    'filamentGrams': filamentGrams,
    'label': label,
    'filamentLabel': filamentLabel,
    'clientName': clientName,
    'isAdvanced': isAdvanced,
    'quantity': quantity,
    'materials': materials.map((m) => m.toJson()).toList(),
    'extraLaborRate': extraLaborRate,
    'extraPostProcessRate': extraPostProcessRate,
    'extraFailureRate': extraFailureRate,
    'extraMarkupOnMaterials': extraMarkupOnMaterials,
    'modelingMode': modelingMode,
    'modelingValue': modelingValue,
    'postprocMode': postprocMode,
    'postprocValue': postprocValue,
    'extraCostMode': extraCostMode,
    'extraCostValue': extraCostValue,
    'extraCostLabel': extraCostLabel,
  };

  String encode() => jsonEncode(toJson());

  static CalculationDraft? tryDecode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CalculationDraft.fromJson(json);
    } catch (e) {
      // BUG-018 fix: loggear la causa para no perder silenciosamente el
      // draft del usuario (el form abre vacio sin explicacion).
      debugPrint('CalculationDraft.tryDecode fallo: $e');
      return null;
    }
  }
}

class MaterialDraft {
  const MaterialDraft({
    this.label = '',
    this.weight = '',
    this.pricePerBobbin = '',
    this.gramsPerBobbin = '',
    this.useOwnTime = false,
    this.materialHours = '',
    this.materialMinutes = '',
  });

  factory MaterialDraft.fromJson(Map<String, dynamic> json) {
    return MaterialDraft(
      label: json['label'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      pricePerBobbin: json['pricePerBobbin'] as String? ?? '',
      gramsPerBobbin: json['gramsPerBobbin'] as String? ?? '',
      useOwnTime: json['useOwnTime'] as bool? ?? false,
      materialHours: json['materialHours'] as String? ?? '',
      materialMinutes: json['materialMinutes'] as String? ?? '',
    );
  }

  final String label;
  final String weight;
  final String pricePerBobbin;
  final String gramsPerBobbin;

  /// Tiempo propio del material (exclusion mutua con el tiempo global).
  final bool useOwnTime;
  final String materialHours;
  final String materialMinutes;

  Map<String, dynamic> toJson() => {
    'label': label,
    'weight': weight,
    'pricePerBobbin': pricePerBobbin,
    'gramsPerBobbin': gramsPerBobbin,
    'useOwnTime': useOwnTime,
    'materialHours': materialHours,
    'materialMinutes': materialMinutes,
  };
}
