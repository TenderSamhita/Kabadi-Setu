import 'dart:convert';
import 'dart:math';

/// One line item within a lot (one category + weight).
class LotItem {
  final String categoryId;
  final String categoryNameEn;
  final double weightKg;
  /// Rate used at time of capture (seed rate, not recycler-specific).
  final int ratePerKg;
  /// Optional path to the captured photo for this item.
  final String? photoPath;

  const LotItem({
    required this.categoryId,
    required this.categoryNameEn,
    required this.weightKg,
    required this.ratePerKg,
    this.photoPath,
  });

  /// Indicative value at seed rate.
  int get indicativeValue => (weightKg * ratePerKg).round();

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryNameEn': categoryNameEn,
        'weightKg': weightKg,
        'ratePerKg': ratePerKg,
        if (photoPath != null) 'photoPath': photoPath,
      };

  factory LotItem.fromJson(Map<String, dynamic> json) => LotItem(
        categoryId: json['categoryId'] as String,
        categoryNameEn: json['categoryNameEn'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        ratePerKg: json['ratePerKg'] as int,
        photoPath: json['photoPath'] as String?,
      );
}

enum LotStatus {
  /// Items are still being added.
  draft,
  /// A recycler has been chosen, QR is ready to scan.
  matched,
  /// Recycler scanned and confirmed the QR.
  confirmed,
  /// Cash payment marked by collector.
  paid,
}

enum PaymentMethod {
  cash,
  upi,
}

/// Generates a LOT-YYYY-XXXXXX style traceability reference.
String generateLotRef() {
  final year = DateTime.now().year;
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random.secure();
  final suffix = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  return 'LOT-$year-$suffix';
}

/// A collection of items being sold in one transaction.
class Lot {
  final String id;
  final List<LotItem> items;
  final LotStatus status;
  final String? matchedRecyclerId;
  final String? matchedRecyclerName;
  /// Agreed total price at time of match.
  final int? agreedPrice;
  final DateTime createdAt;
  /// 6-character uppercase reference code shown on QR screen.
  final String referenceCode;
  /// LOT-YYYY-XXXXXX format traceability ID (generated when lot is first created).
  final String? lotRef;
  /// Collector identifier (generated UUID-style, no personal data).
  final String? collectorId;
  /// Payment method recorded at receipt.
  final PaymentMethod? paymentMethod;
  /// UPI transaction reference (only when paymentMethod == upi).
  final String? upiRef;
  /// GPS/manual coordinates where material was collected.
  final double? collectionLat;
  final double? collectionLng;
  /// GPS/manual coordinates where handover occurred.
  final double? handoverLat;
  final double? handoverLng;
  /// Source of location: 'gps', 'manual', or null.
  final String? locationSource;

  const Lot({
    required this.id,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.referenceCode,
    this.matchedRecyclerId,
    this.matchedRecyclerName,
    this.agreedPrice,
    this.lotRef,
    this.collectorId,
    this.paymentMethod,
    this.upiRef,
    this.collectionLat,
    this.collectionLng,
    this.handoverLat,
    this.handoverLng,
    this.locationSource,
  });

  double get totalWeightKg =>
      items.fold(0.0, (sum, item) => sum + item.weightKg);

  int get indicativeValue =>
      items.fold(0, (sum, item) => sum + item.indicativeValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'referenceCode': referenceCode,
        if (matchedRecyclerId != null) 'matchedRecyclerId': matchedRecyclerId,
        if (matchedRecyclerName != null)
          'matchedRecyclerName': matchedRecyclerName,
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        if (lotRef != null) 'lotRef': lotRef,
        if (collectorId != null) 'collectorId': collectorId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod!.name,
        if (upiRef != null) 'upiRef': upiRef,
        if (collectionLat != null) 'collectionLat': collectionLat,
        if (collectionLng != null) 'collectionLng': collectionLng,
        if (handoverLat != null) 'handoverLat': handoverLat,
        if (handoverLng != null) 'handoverLng': handoverLng,
        if (locationSource != null) 'locationSource': locationSource,
      };

  factory Lot.fromJson(Map<String, dynamic> json) => Lot(
        id: json['id'] as String,
        items: (json['items'] as List)
            .map((e) => LotItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: LotStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        referenceCode: json['referenceCode'] as String,
        matchedRecyclerId: json['matchedRecyclerId'] as String?,
        matchedRecyclerName: json['matchedRecyclerName'] as String?,
        agreedPrice: json['agreedPrice'] as int?,
        lotRef: json['lotRef'] as String?,
        collectorId: json['collectorId'] as String?,
        paymentMethod: json['paymentMethod'] != null
            ? PaymentMethod.values.byName(json['paymentMethod'] as String)
            : null,
        upiRef: json['upiRef'] as String?,
        collectionLat: (json['collectionLat'] as num?)?.toDouble(),
        collectionLng: (json['collectionLng'] as num?)?.toDouble(),
        handoverLat: (json['handoverLat'] as num?)?.toDouble(),
        handoverLng: (json['handoverLng'] as num?)?.toDouble(),
        locationSource: json['locationSource'] as String?,
      );

  Lot copyWith({
    List<LotItem>? items,
    LotStatus? status,
    String? matchedRecyclerId,
    String? matchedRecyclerName,
    int? agreedPrice,
    String? lotRef,
    String? collectorId,
    PaymentMethod? paymentMethod,
    String? upiRef,
    double? collectionLat,
    double? collectionLng,
    double? handoverLat,
    double? handoverLng,
    String? locationSource,
  }) =>
      Lot(
        id: id,
        createdAt: createdAt,
        referenceCode: referenceCode,
        items: items ?? this.items,
        status: status ?? this.status,
        matchedRecyclerId: matchedRecyclerId ?? this.matchedRecyclerId,
        matchedRecyclerName: matchedRecyclerName ?? this.matchedRecyclerName,
        agreedPrice: agreedPrice ?? this.agreedPrice,
        lotRef: lotRef ?? this.lotRef,
        collectorId: collectorId ?? this.collectorId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        upiRef: upiRef ?? this.upiRef,
        collectionLat: collectionLat ?? this.collectionLat,
        collectionLng: collectionLng ?? this.collectionLng,
        handoverLat: handoverLat ?? this.handoverLat,
        handoverLng: handoverLng ?? this.handoverLng,
        locationSource: locationSource ?? this.locationSource,
      );

  /// Serialise to a compact JSON string for embedding in QR.
  /// Carries a plain JSON payload — intentionally NOT signed.
  /// See AGENTS.md: "the QR carries a plain JSON payload, and that's intentional"
  String toQrPayload() => jsonEncode({
        'ref': referenceCode,
        if (lotRef != null) 'lotRef': lotRef,
        if (collectorId != null) 'cid': collectorId,
        'items': items
            .map((i) => {
                  'cat': i.categoryId,
                  'kg': i.weightKg,
                  'rate': i.ratePerKg,
                })
            .toList(),
        'total': agreedPrice ?? indicativeValue,
        'ts': createdAt.millisecondsSinceEpoch,
        if (collectionLat != null) 'lat': collectionLat,
        if (collectionLng != null) 'lng': collectionLng,
      });

  /// Parse a compact QR JSON payload back into a Lot object.
  static Lot? fromQrPayload(
    String payload, {
    String Function(String catId)? categoryNameResolver,
    String? matchedRecyclerName,
  }) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final ref = map['ref'] as String;
      final rawItems = map['items'] as List<dynamic>;
      final total = (map['total'] as num).toInt();
      final ts = map['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['ts'] as int)
          : DateTime.now();
      final lotRef = map['lotRef'] as String?;
      final collectorId = map['cid'] as String?;
      final lat = (map['lat'] as num?)?.toDouble();
      final lng = (map['lng'] as num?)?.toDouble();

      final items = rawItems.map((e) {
        final m = e as Map<String, dynamic>;
        final catId = m['cat'] as String;
        final kg = (m['kg'] as num).toDouble();
        final rate = (m['rate'] as num).toInt();
        final name = categoryNameResolver != null
            ? categoryNameResolver(catId)
            : catId;
        return LotItem(
          categoryId: catId,
          categoryNameEn: name,
          weightKg: kg,
          ratePerKg: rate,
        );
      }).toList();

      return Lot(
        id: 'lot_${ref}_${ts.millisecondsSinceEpoch}',
        items: items,
        status: LotStatus.matched,
        createdAt: ts,
        referenceCode: ref,
        agreedPrice: total,
        matchedRecyclerName: matchedRecyclerName,
        lotRef: lotRef,
        collectorId: collectorId,
        collectionLat: lat,
        collectionLng: lng,
      );
    } catch (_) {
      return null;
    }
  }
}
