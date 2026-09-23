import 'package:flutter_test/flutter_test.dart';
import 'package:kabadi_setu/app_state.dart';
import 'package:kabadi_setu/models/category.dart';
import 'package:kabadi_setu/models/lot.dart';

void main() {
  group('Milestone 6 — Ledger & Safety Interstitial Tests', () {
    test('Safety card triggers for items with hazardLevel >= 2', () {
      const batteryLiIon = Category(
        id: 'battery_liion',
        nameEn: 'Li-ion Battery',
        nameHi: 'ली-आयन बैटरी',
        nameMr: 'लि-आयन बॅटरी',
        ratePerKg: 120,
        hazardLevel: 2,
        icon: 'battery',
      );

      const crtGlass = Category(
        id: 'crt_glass',
        nameEn: 'CRT Glass',
        nameHi: 'CRT कांच',
        nameMr: 'CRT काच',
        ratePerKg: 8,
        hazardLevel: 3,
        icon: 'crt',
      );

      const cable = Category(
        id: 'cable',
        nameEn: 'Cable',
        nameHi: 'केबल',
        nameMr: 'केबल',
        ratePerKg: 45,
        hazardLevel: 0,
        icon: 'cable',
      );

      expect(batteryLiIon.hazardLevel >= 2, isTrue);
      expect(crtGlass.hazardLevel >= 2, isTrue);
      expect(cable.hazardLevel >= 2, isFalse);
    });

    test('Weekly total sums confirmed and paid lots in current week', () async {
      final appState = AppState();

      final lot1 = Lot(
        id: 'lot_1',
        referenceCode: 'WK-01',
        status: LotStatus.confirmed,
        createdAt: DateTime.now(),
        agreedPrice: 1500,
        items: const [
          LotItem(
            categoryId: 'pcb_populated',
            categoryNameEn: 'Populated PCB',
            weightKg: 5.0,
            ratePerKg: 180,
          ),
        ],
      );

      final lot2 = Lot(
        id: 'lot_2',
        referenceCode: 'WK-02',
        status: LotStatus.paid,
        createdAt: DateTime.now(),
        agreedPrice: 2200,
        items: const [
          LotItem(
            categoryId: 'cable',
            categoryNameEn: 'Copper Wire',
            weightKg: 10.0,
            ratePerKg: 220,
          ),
        ],
      );

      // Draft lot should not be counted in weekly total
      final draftLot = Lot(
        id: 'lot_draft',
        referenceCode: 'WK-03',
        status: LotStatus.draft,
        createdAt: DateTime.now(),
        agreedPrice: 500,
        items: const [],
      );

      appState.ledger = [lot1, lot2, draftLot];

      expect(appState.weeklyTotal, equals(3700));
    });
  });
}
