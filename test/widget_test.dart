import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadi_setu/app_state.dart';
import 'package:kabadi_setu/main.dart';
import 'package:kabadi_setu/models/category.dart';
import 'package:kabadi_setu/models/lot.dart';
import 'package:kabadi_setu/screens/category_guess_screen.dart';
import 'package:kabadi_setu/screens/role_screen.dart';
import 'package:kabadi_setu/screens/weigh_screen.dart';
import 'package:kabadi_setu/services/eco_impact_service.dart';
import 'package:kabadi_setu/services/scrap_analyzer_service.dart';
import 'package:kabadi_setu/strings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final appState = AppState();
    // Skip seed loading in tests — no asset bundle available here.
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const KabadiSetuApp(),
      ),
    );
    // Just verify it doesn't throw on first frame.
    expect(find.byType(KabadiSetuApp), findsOneWidget);
  });

  test('English dictionary and category naming works properly', () {
    expect(str('app_name', 'en'), 'Kabadi Setu');
    expect(str('rate_board_title', 'en'), 'Rate Board');
    expect(str('find_recycler', 'en'), 'Find Recycler');
    expect(str('weekly_earnings', 'en'), "This Week's Earnings");

    const cat = Category(
      id: 'pcb_populated',
      nameEn: 'Populated PCB',
      nameHi: 'भरा हुआ PCB',
      nameMr: 'भरलेला PCB',
      ratePerKg: 180,
      hazardLevel: 0,
      icon: 'pcb',
    );
    expect(cat.nameFor('en'), 'Populated PCB');
    expect(cat.nameFor('mr'), 'भरलेला PCB');
    expect(cat.nameFor('hi'), 'भरा हुआ PCB');
  });

  test('ScrapAnalyzerService classifies optical colors correctly', () {
    // 1. Green buffer -> Populated PCB
    final greenBytes = Uint8List(100 * 100 * 4);
    for (int i = 0; i < greenBytes.length; i += 4) {
      greenBytes[i] = 30; // R
      greenBytes[i + 1] = 160; // G
      greenBytes[i + 2] = 40; // B
      greenBytes[i + 3] = 255;
    }
    final greenResult = ScrapAnalyzerService.analyzeRgba(
      rgbaBytes: greenBytes,
      width: 100,
      height: 100,
    );
    expect(greenResult.topCategoryId, 'pcb_populated');
    expect(greenResult.reasonKey, 'detected_green_pcb');

    // 2. Copper/Red buffer -> Cable
    final copperBytes = Uint8List(100 * 100 * 4);
    for (int i = 0; i < copperBytes.length; i += 4) {
      copperBytes[i] = 190; // R
      copperBytes[i + 1] = 60; // G
      copperBytes[i + 2] = 25; // B
      copperBytes[i + 3] = 255;
    }
    final copperResult = ScrapAnalyzerService.analyzeRgba(
      rgbaBytes: copperBytes,
      width: 100,
      height: 100,
    );
    expect(copperResult.topCategoryId, 'cable');
    expect(copperResult.reasonKey, 'detected_copper_cable');

    // 3. Dark/Black buffer -> Battery
    final darkBytes = Uint8List(100 * 100 * 4);
    for (int i = 0; i < darkBytes.length; i += 4) {
      darkBytes[i] = 30; // R
      darkBytes[i + 1] = 30; // G
      darkBytes[i + 2] = 35; // B
      darkBytes[i + 3] = 255;
    }
    final darkResult = ScrapAnalyzerService.analyzeRgba(
      rgbaBytes: darkBytes,
      width: 100,
      height: 100,
    );
    expect(darkResult.topCategoryId, 'battery_liion');
    expect(darkResult.reasonKey, 'detected_dark_battery');

    // 4. White/Light buffer -> Mixed Plastic
    final lightBytes = Uint8List(100 * 100 * 4);
    for (int i = 0; i < lightBytes.length; i += 4) {
      lightBytes[i] = 220; // R
      lightBytes[i + 1] = 225; // G
      lightBytes[i + 2] = 230; // B
      lightBytes[i + 3] = 255;
    }
    final lightResult = ScrapAnalyzerService.analyzeRgba(
      rgbaBytes: lightBytes,
      width: 100,
      height: 100,
    );
    expect(lightResult.topCategoryId, 'mixed_plastic');
    expect(lightResult.reasonKey, 'detected_light_plastic');
  });

  testWidgets('English language tile can be selected on LaunchScreen',
      (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const KabadiSetuApp(),
      ),
    );

    // Verify English tile is displayed
    final enTileFinder = find.byKey(const ValueKey('lang_en'));
    expect(enTileFinder, findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Tap English tile
    await tester.tap(enTileFinder);
    await tester.pumpAndSettle();

    // Verify language changed to English in AppState
    expect(appState.language, 'en');

    // Verify navigated to RoleScreen with English title
    expect(find.byType(RoleScreen), findsOneWidget);
    expect(find.text('Select Role'), findsOneWidget);
  });

  testWidgets('WeighScreen allows direct typing and quick-add chips',
      (WidgetTester tester) async {
    final appState = AppState();
    appState.categories = const [
      Category(
        id: 'cable',
        nameEn: 'Copper Cable',
        nameHi: 'तांबे का तार',
        nameMr: 'तांब्याची वायर',
        ratePerKg: 380,
        hazardLevel: 0,
        icon: 'cable',
      ),
    ];
    appState.setLanguage('en');
    appState.startNewLot();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: WeighScreen(categoryId: 'cable'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial weight display is 1 kg
    final inputFinder = find.byKey(const ValueKey('weight_input_field'));
    expect(inputFinder, findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Tap quick add chip '+10 kg'
    final quickAdd10 = find.text('+10 kg');
    expect(quickAdd10, findsOneWidget);
    await tester.tap(quickAdd10);
    await tester.pumpAndSettle();

    // Weight should now be 11 kg (1 + 10)
    expect(find.text('11'), findsOneWidget);
    expect(find.text('≈ ₹4180'), findsOneWidget); // 11 * 380 = 4180

    // Test direct typing: enter '45.5'
    await tester.enterText(inputFinder, '45.5');
    await tester.pumpAndSettle();

    expect(find.text('45.5'), findsOneWidget);
    expect(find.text('≈ ₹17290'), findsOneWidget); // 45.5 * 380 = 17290

    // Tap primary action button to confirm
    final confirmBtn = find.text('View Rates →');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify item was added to draft lot with weight 45.5 kg
    expect(appState.draftLot?.items.length, 1);
    expect(appState.draftLot?.items.first.weightKg, 45.5);
    expect(appState.draftLot?.items.first.indicativeValue, 17290);
  });

  testWidgets(
      'CategoryGuessScreen supports viewing and selecting all categories',
      (WidgetTester tester) async {
    final appState = AppState();
    appState.categories = const [
      Category(
        id: 'pcb_populated',
        nameEn: 'Populated PCB',
        nameHi: 'भरा हुआ PCB',
        nameMr: 'भरलेला PCB',
        ratePerKg: 180,
        hazardLevel: 0,
        icon: 'pcb',
      ),
      Category(
        id: 'cable',
        nameEn: 'Cable',
        nameHi: 'केबल',
        nameMr: 'केबल',
        ratePerKg: 45,
        hazardLevel: 0,
        icon: 'cable',
      ),
      Category(
        id: 'mixed_plastic',
        nameEn: 'Mixed Plastic',
        nameHi: 'मिश्रित प्लास्टिक',
        nameMr: 'मिश्र प्लास्टिक',
        ratePerKg: 12,
        hazardLevel: 1,
        icon: 'plastic',
      ),
      Category(
        id: 'battery_liion',
        nameEn: 'Li-ion Battery',
        nameHi: 'ली-आयन बैटरी',
        nameMr: 'लि-आयन बॅटरी',
        ratePerKg: 120,
        hazardLevel: 2,
        icon: 'battery',
      ),
    ];
    appState.setLanguage('en');

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: CategoryGuessScreen(),
        ),
      ),
    );

    // Fast-forward past simulated 1200ms analysis delay
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Top AI suggestions should now be visible
    expect(find.text('Top AI Suggestions'), findsOneWidget);
    expect(find.text('Populated PCB'), findsOneWidget);
    expect(find.text('Cable'), findsOneWidget);

    // "Something else? View all 10 categories" button should be visible
    final viewAllBtn = find.byKey(const ValueKey('view_all_categories_btn'));
    expect(viewAllBtn, findsOneWidget);

    // Tap to open bottom sheet
    await tester.tap(viewAllBtn);
    await tester.pumpAndSettle();

    // Verify sheet opened with title and battery_liion option
    expect(find.text('All E-Waste Categories (10)'), findsOneWidget);
    final batteryOption =
        find.byKey(const ValueKey('sheet_cat_battery_liion'));
    expect(batteryOption, findsOneWidget);

    // Select Li-ion Battery
    await tester.tap(batteryOption);
    await tester.pumpAndSettle();

    // Sheet should close and selected battery tile should now be visible
    expect(find.byKey(const ValueKey('custom_selected_tile')), findsOneWidget);
    expect(find.text('Li-ion Battery'), findsWidgets);
    expect(find.text('⚠️ Hazardous'), findsOneWidget);

    // Tap confirm category to advance to WeighScreen
    final confirmBtn = find.text('Confirm Category');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(find.byType(WeighScreen), findsOneWidget);
    expect(find.text('Record Weight'), findsOneWidget);
  });

  test('EcoImpactService calculates CO2 and metal recovery according to circular norms', () {
    final lot = Lot(
      id: 'test_lot',
      status: LotStatus.draft,
      createdAt: DateTime.now(),
      referenceCode: 'ECO123',
      items: const [
        LotItem(
          categoryId: 'pcb_populated',
          categoryNameEn: 'Populated PCB',
          weightKg: 10.0,
          ratePerKg: 180,
        ),
        LotItem(
          categoryId: 'cable',
          categoryNameEn: 'Cable',
          weightKg: 20.0,
          ratePerKg: 45,
        ),
      ],
    );

    final impact = EcoImpactService.compute(lot);
    // 10kg PCB (1.8 kg CO2/kg) + 20kg Cable (2.5 kg CO2/kg) = 18 + 50 = 68.0 kg CO2
    expect(impact.co2SavedKg, 68.0);
    // 10kg * 140g + 20kg * 450g = 1400g + 9000g = 10400g = 10.4 kg Copper
    expect(impact.copperGrams, 10400.0);
    // 10kg * 25mg = 250mg Gold/Ag
    expect(impact.preciousMetalsMg, 250.0);
    expect(impact.co2String, '68.0 kg CO₂');
    expect(impact.copperString, '10.4 kg Copper');
    expect(impact.preciousMetalsString, '250 mg Gold/Ag');
  });

  test('AppState loadDemoLot initializes matched lot with valid payload and items', () {
    final state = AppState();
    final demoLot = state.loadDemoLot();

    expect(state.draftLot, isNotNull);
    expect(demoLot.items.length, 2);
    expect(demoLot.items[0].categoryId, 'pcb_populated');
    expect(demoLot.items[0].weightKg, 25.0);
    expect(demoLot.items[1].categoryId, 'cable');
    expect(demoLot.items[1].weightKg, 40.0);
    expect(demoLot.status, LotStatus.matched);
    expect(demoLot.matchedRecyclerName, 'Vidarbha E-Waste Recyclers');
    expect(demoLot.agreedPrice, 9300);
  });

  test('AppState markLotPaid updates status and ledger reactively', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    final demoLot = state.loadDemoLot();
    await state.recordConfirmedLot(demoLot);

    expect(state.ledger.first.status, LotStatus.confirmed);
    await state.markLotPaid(demoLot.referenceCode);
    expect(state.ledger.first.status, LotStatus.paid);
  });
}


