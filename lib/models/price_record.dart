/// A single price data point for a material category.
/// Used to build the Price Board / History screen for SIH dataset demonstration.
class PriceRecord {
  final String priceId;
  final String materialCategory;
  final String? materialSubCategory;
  final String location;
  final DateTime date;
  /// Local market / middleman buying price (₹/kg).
  final int marketPrice;
  /// Authorised recycler offered price (₹/kg).
  final int recyclerPrice;
  final String unit;
  final String? recyclerId;
  final int? marketMin;
  final int? marketMax;
  /// 'seed' | 'manual' | 'demo'
  final String source;

  const PriceRecord({
    required this.priceId,
    required this.materialCategory,
    this.materialSubCategory,
    required this.location,
    required this.date,
    required this.marketPrice,
    required this.recyclerPrice,
    this.unit = 'kg',
    this.recyclerId,
    this.marketMin,
    this.marketMax,
    this.source = 'seed',
  });

  Map<String, dynamic> toJson() => {
        'priceId': priceId,
        'materialCategory': materialCategory,
        if (materialSubCategory != null) 'materialSubCategory': materialSubCategory,
        'location': location,
        'date': date.toIso8601String(),
        'marketPrice': marketPrice,
        'recyclerPrice': recyclerPrice,
        'unit': unit,
        if (recyclerId != null) 'recyclerId': recyclerId,
        if (marketMin != null) 'marketMin': marketMin,
        if (marketMax != null) 'marketMax': marketMax,
        'source': source,
      };

  factory PriceRecord.fromJson(Map<String, dynamic> json) => PriceRecord(
        priceId: json['priceId'] as String,
        materialCategory: json['materialCategory'] as String,
        materialSubCategory: json['materialSubCategory'] as String?,
        location: json['location'] as String,
        date: DateTime.parse(json['date'] as String),
        marketPrice: json['marketPrice'] as int,
        recyclerPrice: json['recyclerPrice'] as int,
        unit: (json['unit'] as String?) ?? 'kg',
        recyclerId: json['recyclerId'] as String?,
        marketMin: json['marketMin'] as int?,
        marketMax: json['marketMax'] as int?,
        source: (json['source'] as String?) ?? 'seed',
      );

  /// Potential gain for a collector choosing the recycler over the local market.
  int get potentialGainPerKg => recyclerPrice - marketPrice;

  /// Returns true if the recycler price is significantly below market min (anomaly).
  bool get isPriceAnomaly {
    if (marketMin == null) return false;
    return recyclerPrice < (marketMin! * 0.70).round();
  }
}
