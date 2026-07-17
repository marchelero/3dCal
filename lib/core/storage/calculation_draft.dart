// ignore_for_file: public_member_api_docs
import 'dart:convert';

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
    this.extraLaborRate = '',
    this.extraPostProcessRate = '',
    this.extraFailureRate = '',
    this.extraMarkupOnMaterials = '',
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
      materials: (json['materials'] as List?)
              ?.map((e) =>
                  MaterialDraft.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      extraLaborRate: json['extraLaborRate'] as String? ?? '',
      extraPostProcessRate: json['extraPostProcessRate'] as String? ?? '',
      extraFailureRate: json['extraFailureRate'] as String? ?? '',
      extraMarkupOnMaterials: json['extraMarkupOnMaterials'] as String? ?? '',
    );
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

  // === F1: OTROS ===
  final String extraLaborRate;
  final String extraPostProcessRate;
  final String extraFailureRate;
  final String extraMarkupOnMaterials;

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
        'materials': materials.map((m) => m.toJson()).toList(),
        'extraLaborRate': extraLaborRate,
        'extraPostProcessRate': extraPostProcessRate,
        'extraFailureRate': extraFailureRate,
        'extraMarkupOnMaterials': extraMarkupOnMaterials,
      };

  String encode() => jsonEncode(toJson());

  static CalculationDraft? tryDecode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CalculationDraft.fromJson(json);
    } catch (_) {
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
  });

  factory MaterialDraft.fromJson(Map<String, dynamic> json) {
    return MaterialDraft(
      label: json['label'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      pricePerBobbin: json['pricePerBobbin'] as String? ?? '',
      gramsPerBobbin: json['gramsPerBobbin'] as String? ?? '',
    );
  }

  final String label;
  final String weight;
  final String pricePerBobbin;
  final String gramsPerBobbin;

  Map<String, dynamic> toJson() => {
        'label': label,
        'weight': weight,
        'pricePerBobbin': pricePerBobbin,
        'gramsPerBobbin': gramsPerBobbin,
      };
}
