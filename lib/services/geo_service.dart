import 'dart:math';

import '../models/lot.dart';
import '../models/recycler.dart';

/// Nagpur reference coordinate for demo collector (Sitabuldi/Dharampeth area).
const double kCollectorLat = 21.1350;
const double kCollectorLng = 79.0750;

/// Assumed transport cost in rupees per km if pickup is not available.
const int kTransportCostPerKm = 15;

/// Calculated match metrics for a single recycler relative to a lot.
class RecyclerMatch {
  final Recycler recycler;
  final double distanceKm;
  final int grossValue;
  final int transportCost;
  final int netInPocket;
  final double score;

  const RecyclerMatch({
    required this.recycler,
    required this.distanceKm,
    required this.grossValue,
    required this.transportCost,
    required this.netInPocket,
    required this.score,
  });
}

/// Pure Dart haversine distance calculation in kilometers.
/// No geolocator or map SDK required — operates fully offline.
double haversineDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * (pi / 180.0);
  final dLon = (lon2 - lon1) * (pi / 180.0);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180.0)) *
          cos(lat2 * (pi / 180.0)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Computes the net financial payout and distance for a [lot] and [recycler].
RecyclerMatch computeMatch({
  required Recycler recycler,
  required Lot lot,
  double collectorLat = kCollectorLat,
  double collectorLng = kCollectorLng,
}) {
  final distanceKm = haversineDistanceKm(
    collectorLat,
    collectorLng,
    recycler.lat,
    recycler.lng,
  );

  int gross = 0;
  for (final item in lot.items) {
    final rate = recycler.offeredRate(item.categoryId, item.ratePerKg);
    gross += (item.weightKg * rate).round();
  }

  // Free pickup = ₹0 transport deduction; self-transport = ₹15/km deduction
  final transportCost =
      recycler.pickupAvailable ? 0 : (distanceKm * kTransportCostPerKm).round();
  final netInPocket = max(0, gross - transportCost);

  // Ranking score prioritizes net payout, proximity, and CPCB authorisation
  final score = netInPocket +
      (recycler.authorised ? 50.0 : 0.0) -
      (distanceKm * 5.0);

  return RecyclerMatch(
    recycler: recycler,
    distanceKm: distanceKm,
    grossValue: gross,
    transportCost: transportCost,
    netInPocket: netInPocket,
    score: score,
  );
}

/// Returns all [recyclers] ranked descending by net in pocket and score.
List<RecyclerMatch> rankRecyclers({
  required List<Recycler> recyclers,
  required Lot lot,
  double collectorLat = kCollectorLat,
  double collectorLng = kCollectorLng,
}) {
  final matches = recyclers
      .map((r) => computeMatch(
            recycler: r,
            lot: lot,
            collectorLat: collectorLat,
            collectorLng: collectorLng,
          ))
      .toList();

  matches.sort((a, b) {
    final netCompare = b.netInPocket.compareTo(a.netInPocket);
    if (netCompare != 0) return netCompare;
    return b.score.compareTo(a.score);
  });

  return matches;
}
