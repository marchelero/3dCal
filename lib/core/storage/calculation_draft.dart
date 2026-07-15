// ignore_for_file: public_member_api_docs
import 'dart:convert';

/// Estado serializable del formulario de cotizacion.
///
/// Guarda todos los campos del calculator para restaurar al reabrir la app
/// (PRD NFR-3: crash recovery).
class CalculationDraft {
  const CalculationDraft({
    this.weight = '',
    this.printHours = '',
    this.printerWatts = '',
    this.kwhRate = '',
    this.profitPct = '',
    this.discountPct = '',
    this.filamentPrice = '',
    this.filamentGrams = '',
    this.pieceName = '',
    this.clientName = '',
    this.isAdvanced = false,
    this.materials = const [],
  });

  factory CalculationDraft.fromJson(Map<String, dynamic> json) {
    return CalculationDraft(
      weight: json['weight'] as String? ?? '',
      printHours: json['printHours'] as String? ?? '',
      printerWatts: json['printerWatts'] as String? ?? '',
      kwhRate: json['kwhRate'] as String? ?? '',
      profitPct: json['profitPct'] as String? ?? '',
      discountPct: json['discountPct'] as String? ?? '',
      filamentPrice: json['filamentPrice'] as String? ?? '',
      filamentGrams: json['filamentGrams'] as String? ?? '',
      pieceName: json['pieceName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      isAdvanced: json['isAdvanced'] as bool? ?? false,
      materials: (json['materials'] as List?)
              ?.map((e) =>
                  MaterialDraft.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  final String weight;
  final String printHours;
  final String printerWatts;
  final String kwhRate;
  final String profitPct;
  final String discountPct;
  final String filamentPrice;
  final String filamentGrams;
  final String pieceName;
  final String clientName;
  final bool isAdvanced;
  final List<MaterialDraft> materials;

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'printHours': printHours,
        'printerWatts': printerWatts,
        'kwhRate': kwhRate,
        'profitPct': profitPct,
        'discountPct': discountPct,
        'filamentPrice': filamentPrice,
        'filamentGrams': filamentGrams,
        'pieceName': pieceName,
        'clientName': clientName,
        'isAdvanced': isAdvanced,
        'materials': materials.map((m) => m.toJson()).toList(),
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
