import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kabadi_setu/app_state.dart';
import 'package:kabadi_setu/models/lot.dart';
import 'package:kabadi_setu/models/price_record.dart';
import 'package:kabadi_setu/models/sync_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SIH PS 26229 — Traceability & Lot Model Extensions', () {
    test('generateLotRef generates expected format LOT-YYYY-XXXXXX', () {
      final ref = generateLotRef();
      expect(ref.startsWith('LOT-${DateTime.now().year}-'), isTrue);
      expect(ref.length, equals(15));
    });

    test('Lot with traceability fields serializes to and from JSON', () {
      final lot = Lot(
        id: 'lot_trace_1',
        referenceCode: 'KS-1234',
        lotRef: 'LOT-2026-ABCDEF',
        collectorId: 'KS-COL-001',
        status: LotStatus.paid,
        createdAt: DateTime(2026, 3, 1, 10, 0),
        agreedPrice: 2500,
        paymentMethod: PaymentMethod.upi,
        upiRef: 'UPI-987654321',
        collectionLat: 21.1458,
        collectionLng: 79.0882,
        handoverLat: 21.1500,
        handoverLng: 79.0900,
        locationSource: 'manual_nagpur',
        items: const [
          LotItem(
            categoryId: 'pcb_populated',
            categoryNameEn: 'Populated PCB',
            weightKg: 10.0,
            ratePerKg: 250,
          ),
        ],
      );

      final json = lot.toJson();
      expect(json['lotRef'], equals('LOT-2026-ABCDEF'));
      expect(json['collectorId'], equals('KS-COL-001'));
      expect(json['paymentMethod'], equals('upi'));
      expect(json['upiRef'], equals('UPI-987654321'));
      expect(json['collectionLat'], equals(21.1458));
      expect(json['collectionLng'], equals(79.0882));

      final restored = Lot.fromJson(json);
      expect(restored.lotRef, equals('LOT-2026-ABCDEF'));
      expect(restored.collectorId, equals('KS-COL-001'));
      expect(restored.paymentMethod, equals(PaymentMethod.upi));
      expect(restored.upiRef, equals('UPI-987654321'));
      expect(restored.collectionLat, equals(21.1458));
      expect(restored.collectionLng, equals(79.0882));
    });

    test('QR payload includes compact traceability fields and parses correctly', () {
      final lot = Lot(
        id: 'lot_qr_trace',
        referenceCode: 'KS-9999',
        lotRef: 'LOT-2026-999999',
        collectorId: 'KS-COL-999',
        status: LotStatus.matched,
        createdAt: DateTime(2026, 3, 1, 12, 0),
        agreedPrice: 1800,
        collectionLat: 21.1458,
        collectionLng: 79.0882,
        items: const [
          LotItem(
            categoryId: 'cable',
            categoryNameEn: 'Copper Cable',
            weightKg: 4.0,
            ratePerKg: 450,
          ),
        ],
      );

      final qr = lot.toQrPayload();
      expect(qr, contains('lotRef'));
      expect(qr, contains('cid'));
      expect(qr, contains('lat'));

      final parsed = Lot.fromQrPayload(
        qr,
        categoryNameResolver: (id) => 'Copper Cable',
      );
      expect(parsed, isNotNull);
      expect(parsed!.lotRef, equals('LOT-2026-999999'));
      expect(parsed.collectorId, equals('KS-COL-999'));
      expect(parsed.collectionLat, closeTo(21.1458, 0.0001));
      expect(parsed.collectionLng, closeTo(79.0882, 0.0001));
    });
  });

  group('SIH PS 26229 — Price Records & Anomaly Detection', () {
    test('PriceRecord detects anomaly when recycler rate is below 70% of market min', () {
      final normal = PriceRecord(
        priceId: 'pr_1',
        materialCategory: 'pcb_populated',
        location: 'Nagpur',
        marketPrice: 200,
        recyclerPrice: 190,
        marketMin: 180,
        marketMax: 220,
        date: DateTime(2026, 1, 1),
      );
      expect(normal.isPriceAnomaly, isFalse);

      final anomaly = PriceRecord(
        priceId: 'pr_2',
        materialCategory: 'pcb_populated',
        location: 'Nagpur',
        marketPrice: 200,
        recyclerPrice: 110, // 110 < 180 * 0.70 (126) -> Anomaly!
        marketMin: 180,
        marketMax: 220,
        date: DateTime(2026, 1, 1),
      );
      expect(anomaly.isPriceAnomaly, isTrue);
    });

    test('PriceRecord serializes and deserializes accurately', () {
      final pr = PriceRecord(
        priceId: 'pr_json_test',
        materialCategory: 'battery_liion',
        location: 'Nagpur',
        date: DateTime(2026, 2, 15),
        marketPrice: 120,
        recyclerPrice: 125,
        source: 'demo',
      );

      final json = pr.toJson();
      final restored = PriceRecord.fromJson(json);
      expect(restored.priceId, equals('pr_json_test'));
      expect(restored.materialCategory, equals('battery_liion'));
      expect(restored.marketPrice, equals(120));
      expect(restored.recyclerPrice, equals(125));
      expect(restored.source, equals('demo'));
      expect(restored.location, equals('Nagpur'));
    });
  });

  group('SIH PS 26229 — Sync Records & Queue State', () {
    test('SyncRecord serializes and deserializes accurately', () {
      final rec = SyncRecord(
        syncId: 'sync_1',
        entityType: 'lot',
        entityId: 'lot_001',
        operation: 'create',
        createdAt: DateTime(2026, 3, 1),
        syncStatus: 'pending',
      );

      expect(rec.syncStatus, equals('pending'));

      final json = rec.toJson();
      final restored = SyncRecord.fromJson(json);
      expect(restored.syncId, equals('sync_1'));
      expect(restored.entityType, equals('lot'));
      expect(restored.operation, equals('create'));
      expect(restored.syncStatus, equals('pending'));
    });
  });

  group('SIH PS 26229 — AppState Extended Lifecycle', () {
    test('AppState generates unique collector ID and sets manual location', () async {
      final appState = AppState();
      await appState.init();

      expect(appState.collectorId, isNotEmpty);
      expect(appState.collectorId.startsWith('KS-'), isTrue);

      expect(appState.collectorLat, closeTo(21.1350, 0.001));
      expect(appState.collectorLng, closeTo(79.0750, 0.001));

      await appState.setCollectorLocation(19.0760, 72.8777, source: 'Mumbai');
      expect(appState.collectorLat, closeTo(19.0760, 0.001));
      expect(appState.collectorLng, closeTo(72.8777, 0.001));
      expect(appState.locationSource, equals('Mumbai'));
    });

    test('AppState seeds price history and checks price anomalies', () async {
      final appState = AppState();
      await appState.init();

      expect(appState.priceHistory, isNotEmpty);

      // PCB rate in categories is 180. Offered 100 is below 70% (126) -> anomaly!
      final anomalyResult = appState.isPriceAnomalous('pcb_populated', 100);
      expect(anomalyResult, isTrue);

      // Offered 185 is fair -> not an anomaly
      final fairResult = appState.isPriceAnomalous('pcb_populated', 185);
      expect(fairResult, isFalse);
    });

    test('AppState records UPI payment on lot and tracks in sync queue', () async {
      final appState = AppState();
      await appState.init();

      appState.loadDemoLot();
      final draft = appState.draftLot;
      expect(draft, isNotNull);
      final lotId = draft!.id;

      // Save draft into ledger by confirming it
      await appState.confirmHandover();

      final initialPendingSync = appState.pendingSyncCount;

      await appState.markLotPaid(
        lotId,
        method: PaymentMethod.upi,
        upiRef: 'UPI-TXN-12345678',
      );

      final paidLot = appState.ledger.firstWhere((l) => l.id == lotId);
      expect(paidLot.status, equals(LotStatus.paid));
      expect(paidLot.paymentMethod, equals(PaymentMethod.upi));
      expect(paidLot.upiRef, equals('UPI-TXN-12345678'));

      // Pending sync count should reflect the operations
      expect(appState.pendingSyncCount, greaterThanOrEqualTo(initialPendingSync));

      // Simulate sync
      await appState.simulateSync();
      expect(appState.pendingSyncCount, equals(0));
    });

    test('AppState loads demo dataset for stage presentation', () async {
      final appState = AppState();
      await appState.init();

      await appState.loadDemoDataset();

      expect(appState.ledger.length, greaterThanOrEqualTo(5));
      expect(appState.priceHistory.length, greaterThanOrEqualTo(5));
      expect(appState.totalEarnings, greaterThan(0));
      expect(appState.completedTransactionCount, greaterThanOrEqualTo(3));
      expect(appState.pendingEarnings, greaterThan(0));
    });
  });
}
