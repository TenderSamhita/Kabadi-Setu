import 'package:flutter_test/flutter_test.dart';
import 'package:kabadi_setu/models/lot.dart';
import 'package:kabadi_setu/models/recycler.dart';
import 'package:kabadi_setu/services/geo_service.dart';

void main() {
  group('GeoService & Recycler Ranking', () {
    test('Haversine distance calculates reasonable Nagpur distances', () {
      // Distance between Sitabuldi (21.1458, 79.0882) and Nagpur West (21.1602, 79.0632)
      final distance = haversineDistanceKm(21.1458, 79.0882, 21.1602, 79.0632);
      expect(distance, greaterThan(2.0));
      expect(distance, lessThan(4.0));
    });

    test('Transport cost deducted when pickup is not available', () {
      final recyclerWithPickup = Recycler(
        id: 'r1',
        name: 'Vidarbha',
        lat: 21.1458,
        lng: 79.0882,
        authorised: true,
        pickupAvailable: true,
        ratesByCategory: {'pcb_populated': 200},
      );

      final recyclerNoPickup = Recycler(
        id: 'r2',
        name: 'Green Nagpur',
        lat: 21.1458,
        lng: 79.0882,
        authorised: true,
        pickupAvailable: false,
        ratesByCategory: {'pcb_populated': 200},
      );

      final lot = Lot(
        id: 'lot-1',
        status: LotStatus.draft,
        createdAt: DateTime.now(),
        referenceCode: 'AB12CD',
        items: const [
          LotItem(
            categoryId: 'pcb_populated',
            categoryNameEn: 'Populated PCB',
            weightKg: 10.0,
            ratePerKg: 180,
          ),
        ],
      );

      final matchWithPickup = computeMatch(
        recycler: recyclerWithPickup,
        lot: lot,
        collectorLat: 21.1350,
        collectorLng: 79.0750,
      );

      final matchNoPickup = computeMatch(
        recycler: recyclerNoPickup,
        lot: lot,
        collectorLat: 21.1350,
        collectorLng: 79.0750,
      );

      expect(matchWithPickup.transportCost, equals(0));
      expect(matchNoPickup.transportCost, greaterThan(0));
      expect(matchWithPickup.netInPocket, greaterThan(matchNoPickup.netInPocket));
    });

    test('Changing recycler rate or coordinates visibly changes ranking order', () {
      final r1 = Recycler(
        id: 'r1',
        name: 'Recycler Alpha',
        lat: 21.1458,
        lng: 79.0882,
        authorised: true,
        pickupAvailable: true,
        ratesByCategory: {'pcb_populated': 190},
      );

      final r2 = Recycler(
        id: 'r2',
        name: 'Recycler Beta',
        lat: 21.1458,
        lng: 79.0882,
        authorised: true,
        pickupAvailable: true,
        ratesByCategory: {'pcb_populated': 180},
      );

      final lot = Lot(
        id: 'lot-1',
        status: LotStatus.draft,
        createdAt: DateTime.now(),
        referenceCode: 'AB12CD',
        items: const [
          LotItem(
            categoryId: 'pcb_populated',
            categoryNameEn: 'Populated PCB',
            weightKg: 10.0,
            ratePerKg: 180,
          ),
        ],
      );

      // Initially Alpha (₹190) beats Beta (₹180)
      var ranked = rankRecyclers(recyclers: [r1, r2], lot: lot);
      expect(ranked.first.recycler.id, equals('r1'));

      // If Beta increases rate to ₹210, Beta takes 1st place!
      final r2UpdatedRate = Recycler(
        id: 'r2',
        name: 'Recycler Beta',
        lat: 21.1458,
        lng: 79.0882,
        authorised: true,
        pickupAvailable: true,
        ratesByCategory: {'pcb_populated': 210},
      );

      ranked = rankRecyclers(recyclers: [r1, r2UpdatedRate], lot: lot);
      expect(ranked.first.recycler.id, equals('r2'));

      // If Beta moves 50km away with no pickup, transport cost degrades net payout
      final r2FarAway = Recycler(
        id: 'r2',
        name: 'Recycler Beta',
        lat: 21.6000,
        lng: 79.5000,
        authorised: true,
        pickupAvailable: false,
        ratesByCategory: {'pcb_populated': 210},
      );

      ranked = rankRecyclers(recyclers: [r1, r2FarAway], lot: lot);
      expect(ranked.first.recycler.id, equals('r1'));
    });
  });
}
