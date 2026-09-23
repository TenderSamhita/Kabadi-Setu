import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadi_setu/models/lot.dart';

void main() {
  group('Milestone 5 — Handover QR & Lifecycle Tests', () {
    test('Lot serializes to and deserializes from QR payload accurately', () {
      final originalLot = Lot(
        id: 'lot_alpha_1',
        referenceCode: 'KS-8942',
        status: LotStatus.matched,
        createdAt: DateTime(2024, 10, 24, 16, 15),
        agreedPrice: 1890,
        matchedRecyclerId: 'r1',
        matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
        items: const [
          LotItem(
            categoryId: 'cable',
            categoryNameEn: 'Copper Wire',
            weightKg: 4.5,
            ratePerKg: 420,
          ),
          LotItem(
            categoryId: 'pcb_populated',
            categoryNameEn: 'Populated PCB',
            weightKg: 2.0,
            ratePerKg: 195,
          ),
        ],
      );

      // 1. Serialize to QR payload
      final qrString = originalLot.toQrPayload();
      expect(qrString, isNotEmpty);

      final jsonMap = jsonDecode(qrString) as Map<String, dynamic>;
      expect(jsonMap['ref'], equals('KS-8942'));
      expect(jsonMap['total'], equals(1890));
      expect((jsonMap['items'] as List).length, equals(2));

      // 2. Recycler parses the QR payload
      final parsedLot = Lot.fromQrPayload(
        qrString,
        categoryNameResolver: (catId) =>
            catId == 'cable' ? 'Copper Wire' : 'Populated PCB',
        matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
      );

      expect(parsedLot, isNotNull);
      expect(parsedLot!.referenceCode, equals(originalLot.referenceCode));
      expect(parsedLot.agreedPrice, equals(originalLot.agreedPrice));
      expect(parsedLot.totalWeightKg, equals(6.5));
      expect(parsedLot.items.length, equals(2));
      expect(parsedLot.items[0].categoryId, equals('cable'));
      expect(parsedLot.items[0].weightKg, equals(4.5));
      expect(parsedLot.items[0].ratePerKg, equals(420));
      expect(parsedLot.status, equals(LotStatus.matched));
    });

    test('Full scan-and-confirm lifecycle transitions status to confirmed then paid', () {
      final lot = Lot(
        id: 'lot-test',
        referenceCode: 'CD56EF',
        status: LotStatus.matched,
        createdAt: DateTime.now(),
        agreedPrice: 950,
        items: const [
          LotItem(
            categoryId: 'motor',
            categoryNameEn: 'Electric Motor',
            weightKg: 5.0,
            ratePerKg: 190,
          ),
        ],
      );

      // Confirmed step (cash pending)
      final confirmedLot = lot.copyWith(status: LotStatus.confirmed);
      expect(confirmedLot.status, equals(LotStatus.confirmed));
      expect(confirmedLot.referenceCode, equals('CD56EF'));

      // Paid step (cash marked)
      final paidLot = confirmedLot.copyWith(status: LotStatus.paid);
      expect(paidLot.status, equals(LotStatus.paid));
      expect(paidLot.referenceCode, equals('CD56EF'));
    });
  });
}
