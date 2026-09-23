class Recycler {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final bool authorised;
  final bool pickupAvailable;
  /// Offered rate per kg keyed by category id.
  /// Missing keys mean the recycler does not accept that category.
  final Map<String, int> ratesByCategory;

  const Recycler({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.authorised,
    required this.pickupAvailable,
    required this.ratesByCategory,
  });

  factory Recycler.fromJson(Map<String, dynamic> json) {
    final rawRates =
        (json['ratesByCategory'] as Map<String, dynamic>?) ?? {};
    final rates = rawRates.map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    return Recycler(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      authorised: json['authorised'] as bool,
      pickupAvailable: json['pickupAvailable'] as bool,
      ratesByCategory: rates,
    );
  }

  /// Returns offered rate for [categoryId], or the seed rate if not listed.
  int offeredRate(String categoryId, int seedRate) {
    return ratesByCategory[categoryId] ?? seedRate;
  }
}
