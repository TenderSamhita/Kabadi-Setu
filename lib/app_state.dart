import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/category.dart' as cat_model;
import 'models/lot.dart';
import 'models/price_record.dart';
import 'models/recycler.dart';
import 'models/sync_record.dart';

const _kLedgerKey = 'kabadi_ledger_v1';
const _kRecyclerRatesKey = 'kabadi_recycler_rates_v1';
const _kCategoryRatesKey = 'kabadi_category_rates_v1';
const _kCollectorIdKey = 'kabadi_collector_id_v1';
const _kPriceHistoryKey = 'kabadi_price_history_v1';
const _kSyncQueueKey = 'kabadi_sync_queue_v1';
const _kCollectorLatKey = 'kabadi_collector_lat_v1';
const _kCollectorLngKey = 'kabadi_collector_lng_v1';
const _kLocationSourceKey = 'kabadi_location_source_v1';
const _kLanguageKey = 'kabadi_language_v1';

/// Single source of truth for runtime app state.
/// One ChangeNotifier is enough — do not introduce Riverpod, Bloc, or any
/// DI framework. See AGENTS.md.
class AppState extends ChangeNotifier {
  // ── Identity ────────────────────────────────────────────────────────────

  /// 'collector' or 'recycler'. Toggled on the role screen.
  String role = 'collector';

  /// 'mr' (Marathi) | 'hi' (Hindi) | 'en' (English fallback).
  String language = 'mr';

  /// Generated collector ID — no personal data, stored locally.
  String collectorId = '';

  // ── Seed data (read-only, loaded once at startup) ────────────────────────

  List<cat_model.Category> categories = [];
  List<Recycler> recyclers = [];

  bool seedLoaded = false;

  /// Recycler-specific rate overrides loaded from / saved to shared_preferences.
  /// Shape: { recyclerId -> { categoryId -> ratePerKg } }
  Map<String, Map<String, int>> recyclerRateOverrides = {};

  /// Floor-rate overrides broadcast via Rate Card QR.
  /// Shape: { categoryId -> ratePerKg }
  Map<String, int> categoryRateOverrides = {};

  // ── Collector location (manual or GPS-sourced) ───────────────────────────

  /// Current collector coordinates. Defaults to Nagpur reference if not set.
  double collectorLat = 21.1350;
  double collectorLng = 79.0750;

  /// 'gps' | 'manual' | 'default'
  String locationSource = 'default';

  // ── In-progress lot ─────────────────────────────────────────────────────

  Lot? draftLot;

  // ── Ledger (persisted) ───────────────────────────────────────────────────

  List<Lot> ledger = [];

  // ── Price history (persisted) ─────────────────────────────────────────────

  List<PriceRecord> priceHistory = [];

  // ── Sync queue (persisted) ───────────────────────────────────────────────

  List<SyncRecord> syncQueue = [];

  // ── Connectivity simulation ──────────────────────────────────────────────

  /// True = simulate online. Toggled from UI for demo. No real network calls.
  bool isOnline = false;

  DateTime? lastSyncTime;

  // ── Initialisation ───────────────────────────────────────────────────────

  /// Call once from main() before runApp(), or lazily on first screen load.
  Future<void> init() async {
    await Future.wait([
      _loadSeedData(),
      _loadLedger(),
      _loadRateOverrides(),
      _loadCollectorId(),
      _loadPriceHistory(),
      _loadSyncQueue(),
      _loadLocation(),
      _loadLanguage(),
    ]);
    // Seed price history from categories if empty
    if (priceHistory.isEmpty) {
      _seedPriceHistory();
    }
    seedLoaded = true;
    notifyListeners();
  }

  Future<void> _loadSeedData() async {
    final catJson = await rootBundle.loadString('assets/seed/categories.json');
    final recJson = await rootBundle.loadString('assets/seed/recyclers.json');

    final catList = jsonDecode(catJson) as List<dynamic>;
    final recList = jsonDecode(recJson) as List<dynamic>;

    categories = catList
        .map((e) => cat_model.Category.fromJson(e as Map<String, dynamic>))
        .toList();
    recyclers = recList
        .map((e) => Recycler.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadLedger() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLedgerKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      ledger = list
          .map((e) => Lot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      ledger = [];
    }
  }

  Future<void> _saveLedger() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLedgerKey,
      jsonEncode(ledger.map((l) => l.toJson()).toList()),
    );
  }

  // ── Price history persistence ─────────────────────────────────────────────

  Future<void> _loadPriceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPriceHistoryKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      priceHistory = list
          .map((e) => PriceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      priceHistory = [];
    }
  }

  Future<void> _savePriceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPriceHistoryKey,
      jsonEncode(priceHistory.map((p) => p.toJson()).toList()),
    );
  }

  /// Seeds the price history with current seed data — run only when empty.
  void _seedPriceHistory() {
    final now = DateTime.now();
    // Generate 5 historical snapshots over the past 5 months
    for (int monthOffset = 4; monthOffset >= 0; monthOffset--) {
      final date = DateTime(now.year, now.month - monthOffset, 15);
      for (final cat in categories) {
        // Market price ~ 55–65% of seed rate
        final marketPct = 0.55 + (monthOffset * 0.02); // slight variation
        final marketPrice = (cat.ratePerKg * marketPct).round();
        // Recycler price = seed rate with small monthly variation
        final recyclerPrice = cat.ratePerKg + (monthOffset * 2);
        priceHistory.add(PriceRecord(
          priceId: 'seed_${cat.id}_${date.millisecondsSinceEpoch}',
          materialCategory: cat.id,
          location: 'Nagpur',
          date: date,
          marketPrice: marketPrice,
          recyclerPrice: recyclerPrice,
          marketMin: (recyclerPrice * 0.80).round(),
          marketMax: (recyclerPrice * 1.15).round(),
          source: 'seed',
        ));
      }
    }
    // Save asynchronously
    _savePriceHistory();
  }

  // ── Sync queue persistence ────────────────────────────────────────────────

  Future<void> _loadSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSyncQueueKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      syncQueue = list
          .map((e) => SyncRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      syncQueue = [];
    }
  }

  Future<void> _saveSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSyncQueueKey,
      jsonEncode(syncQueue.map((s) => s.toJson()).toList()),
    );
  }

  void _enqueueSyncRecord(String entityType, String entityId, String operation) {
    final record = SyncRecord(
      syncId: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      createdAt: DateTime.now(),
    );
    syncQueue.insert(0, record);
    _saveSyncQueue(); // fire and forget
  }

  // ── Collector ID persistence ──────────────────────────────────────────────

  Future<void> _loadCollectorId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kCollectorIdKey);
    if (id != null && id.isNotEmpty) {
      collectorId = id;
    } else {
      collectorId = _generateCollectorId();
      await prefs.setString(_kCollectorIdKey, collectorId);
    }
  }

  String _generateCollectorId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final suffix = List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'KS-$suffix';
  }

  // ── Location persistence ──────────────────────────────────────────────────

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kCollectorLatKey);
    final lng = prefs.getDouble(_kCollectorLngKey);
    final src = prefs.getString(_kLocationSourceKey);
    if (lat != null && lng != null) {
      collectorLat = lat;
      collectorLng = lng;
      locationSource = src ?? 'manual';
    }
  }

  Future<void> setCollectorLocation(
    double lat,
    double lng, {
    String source = 'manual',
  }) async {
    collectorLat = lat;
    collectorLng = lng;
    locationSource = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kCollectorLatKey, lat);
    await prefs.setDouble(_kCollectorLngKey, lng);
    await prefs.setString(_kLocationSourceKey, source);
    notifyListeners();
  }

  // ── Language persistence ──────────────────────────────────────────────────

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_kLanguageKey);
    if (lang != null && (lang == 'mr' || lang == 'hi' || lang == 'en')) {
      language = lang;
    }
  }

  // ── Rate override persistence ─────────────────────────────────────────────

  Future<void> _loadRateOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_kRecyclerRatesKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        recyclerRateOverrides = decoded.map(
          (rid, ratesRaw) => MapEntry(
            rid,
            (ratesRaw as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v as int)),
          ),
        );
      }
    } catch (_) {
      recyclerRateOverrides = {};
    }
    try {
      final raw = prefs.getString(_kCategoryRatesKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        categoryRateOverrides = decoded.map((k, v) => MapEntry(k, v as int));
      }
    } catch (_) {
      categoryRateOverrides = {};
    }
  }

  Future<void> _saveRecyclerRateOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRecyclerRatesKey, jsonEncode(recyclerRateOverrides));
  }

  Future<void> _saveCategoryRateOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCategoryRatesKey, jsonEncode(categoryRateOverrides));
  }

  // ── Role & language setters ──────────────────────────────────────────────

  void setRole(String newRole) {
    assert(newRole == 'collector' || newRole == 'recycler');
    role = newRole;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    assert(lang == 'mr' || lang == 'hi' || lang == 'en');
    language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, lang);
    notifyListeners();
  }

  // ── Connectivity simulation ───────────────────────────────────────────────

  /// Simulates going online and "syncing" all pending items.
  /// In the hackathon prototype there is no real server — this demonstrates
  /// the sync queue architecture and marks items as synced locally.
  Future<void> simulateSync() async {
    isOnline = true;
    notifyListeners();
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));
    // Mark all pending items as synced
    for (final record in syncQueue) {
      if (record.syncStatus == 'pending') {
        record.syncStatus = 'synced';
      }
    }
    lastSyncTime = DateTime.now();
    await _saveSyncQueue();
    notifyListeners();
  }

  void setOffline() {
    isOnline = false;
    notifyListeners();
  }

  int get pendingSyncCount =>
      syncQueue.where((s) => s.syncStatus == 'pending').length;

  // ── Effective rate helpers ────────────────────────────────────────────────

  /// Returns the effective floor rate for a category:
  /// categoryRateOverrides (from QR scan) > seed ratePerKg.
  int effectiveRateForCategory(String categoryId) {
    if (categoryRateOverrides.containsKey(categoryId)) {
      return categoryRateOverrides[categoryId]!;
    }
    try {
      return categories.firstWhere((c) => c.id == categoryId).ratePerKg;
    } catch (_) {
      return 0;
    }
  }

  /// Returns the effective rate this recycler pays for a category:
  /// recyclerRateOverrides > seed ratesByCategory > seed ratePerKg.
  int effectiveRecyclerRate(String recyclerId, String categoryId) {
    final override = recyclerRateOverrides[recyclerId]?[categoryId];
    if (override != null) return override;
    try {
      final recycler = recyclers.firstWhere((r) => r.id == recyclerId);
      final seeded = recycler.ratesByCategory[categoryId];
      if (seeded != null) return seeded;
    } catch (_) {}
    return effectiveRateForCategory(categoryId);
  }

  // ── Rate update actions ───────────────────────────────────────────────────

  Future<void> updateRecyclerRates(
      String recyclerId, Map<String, int> rates) async {
    recyclerRateOverrides[recyclerId] = Map<String, int>.from(rates);
    await _saveRecyclerRateOverrides();
    notifyListeners();
  }

  Future<void> applyRateUpdateFromQr(Map<String, dynamic> payload) async {
    assert(payload['type'] == 'rate_update');
    final ratesRaw = payload['rates'] as Map<String, dynamic>;
    final newRates = ratesRaw.map((k, v) => MapEntry(k, v as int));
    categoryRateOverrides.addAll(newRates);
    await _saveCategoryRateOverrides();
    final rid = payload['recyclerId'] as String?;
    if (rid != null) {
      recyclerRateOverrides[rid] = newRates;
      await _saveRecyclerRateOverrides();
    }
    notifyListeners();
  }

  // ── Draft lot management ─────────────────────────────────────────────────

  void startNewLot() {
    draftLot = Lot(
      id: _newId(),
      items: const [],
      status: LotStatus.draft,
      createdAt: DateTime.now(),
      referenceCode: _newRef(),
      lotRef: generateLotRef(),
      collectorId: collectorId,
      collectionLat: collectorLat,
      collectionLng: collectorLng,
      locationSource: locationSource,
    );
    notifyListeners();
  }

  void addItemToDraft(LotItem item) {
    assert(draftLot != null, 'Call startNewLot() first.');
    draftLot = draftLot!.copyWith(items: [...draftLot!.items, item]);
    notifyListeners();
  }

  void matchDraftToRecycler({
    required String recyclerId,
    required String recyclerName,
    required int agreedPrice,
  }) {
    assert(draftLot != null);
    draftLot = draftLot!.copyWith(
      status: LotStatus.matched,
      matchedRecyclerId: recyclerId,
      matchedRecyclerName: recyclerName,
      agreedPrice: agreedPrice,
    );
    notifyListeners();
  }

  /// Populates a realistic demo lot for Smart India Hackathon jury presentations.
  Lot loadDemoLot() {
    startNewLot();
    draftLot = draftLot!.copyWith(
      items: const [
        LotItem(
          categoryId: 'pcb_populated',
          categoryNameEn: 'Populated PCB',
          weightKg: 25.0,
          ratePerKg: 180,
        ),
        LotItem(
          categoryId: 'cable',
          categoryNameEn: 'Cable',
          weightKg: 40.0,
          ratePerKg: 120,
        ),
      ],
      status: LotStatus.matched,
      matchedRecyclerId: 'r1',
      matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
      agreedPrice: 9300,
    );
    notifyListeners();
    return draftLot!;
  }

  /// Seeds 5 demo lots, 5 price records, 3 traceability-ready transactions
  /// for SIH jury demonstration. Labels all data as DEMO.
  Future<void> loadDemoDataset() async {
    final now = DateTime.now();
    final demoLots = <Lot>[
      Lot(
        id: 'demo_lot_1',
        referenceCode: 'DM0001',
        lotRef: 'LOT-${now.year}-DM0001',
        collectorId: collectorId,
        status: LotStatus.paid,
        createdAt: now.subtract(const Duration(days: 6)),
        agreedPrice: 9300,
        matchedRecyclerId: 'r1',
        matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
        paymentMethod: PaymentMethod.cash,
        collectionLat: 21.1350,
        collectionLng: 79.0750,
        locationSource: 'manual',
        items: const [
          LotItem(categoryId: 'pcb_populated', categoryNameEn: 'Populated PCB', weightKg: 25.0, ratePerKg: 195),
          LotItem(categoryId: 'cable', categoryNameEn: 'Cable', weightKg: 40.0, ratePerKg: 48),
        ],
      ),
      Lot(
        id: 'demo_lot_2',
        referenceCode: 'DM0002',
        lotRef: 'LOT-${now.year}-DM0002',
        collectorId: collectorId,
        status: LotStatus.paid,
        createdAt: now.subtract(const Duration(days: 4)),
        agreedPrice: 2600,
        matchedRecyclerId: 'r2',
        matchedRecyclerName: 'Nagpur Green Recyclers',
        paymentMethod: PaymentMethod.upi,
        upiRef: 'UPI-20260929-8842',
        collectionLat: 21.1402,
        collectionLng: 79.0812,
        locationSource: 'manual',
        items: const [
          LotItem(categoryId: 'battery_liion', categoryNameEn: 'Li-ion Battery', weightKg: 12.0, ratePerKg: 125),
          LotItem(categoryId: 'lcd_panel', categoryNameEn: 'LCD Panel', weightKg: 8.0, ratePerKg: 98),
        ],
      ),
      Lot(
        id: 'demo_lot_3',
        referenceCode: 'DM0003',
        lotRef: 'LOT-${now.year}-DM0003',
        collectorId: collectorId,
        status: LotStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 2)),
        agreedPrice: 1540,
        matchedRecyclerId: 'r3',
        matchedRecyclerName: 'Central India E-Cycle',
        collectionLat: 21.1280,
        collectionLng: 79.0920,
        locationSource: 'manual',
        items: const [
          LotItem(categoryId: 'motor', categoryNameEn: 'Motor', weightKg: 18.0, ratePerKg: 57),
          LotItem(categoryId: 'bare_board', categoryNameEn: 'Bare PCB', weightKg: 10.0, ratePerKg: 67),
        ],
      ),
      Lot(
        id: 'demo_lot_4',
        referenceCode: 'DM0004',
        lotRef: 'LOT-${now.year}-DM0004',
        collectorId: collectorId,
        status: LotStatus.paid,
        createdAt: now.subtract(const Duration(days: 10)),
        agreedPrice: 672,
        matchedRecyclerId: 'r5',
        matchedRecyclerName: 'Maharashtra E-Scrap Hub',
        paymentMethod: PaymentMethod.cash,
        collectionLat: 21.1390,
        collectionLng: 79.0710,
        locationSource: 'manual',
        items: const [
          LotItem(categoryId: 'mixed_plastic', categoryNameEn: 'Mixed Plastic', weightKg: 30.0, ratePerKg: 12),
          LotItem(categoryId: 'mixed_cable', categoryNameEn: 'Mixed Cable', weightKg: 8.0, ratePerKg: 38),
        ],
      ),
      Lot(
        id: 'demo_lot_5',
        referenceCode: 'DM0005',
        lotRef: 'LOT-${now.year}-DM0005',
        collectorId: collectorId,
        status: LotStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 1)),
        agreedPrice: 3040,
        matchedRecyclerId: 'r1',
        matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
        collectionLat: 21.1350,
        collectionLng: 79.0750,
        locationSource: 'manual',
        items: const [
          LotItem(categoryId: 'pcb_populated', categoryNameEn: 'Populated PCB', weightKg: 8.0, ratePerKg: 195),
          LotItem(categoryId: 'cable', categoryNameEn: 'Cable', weightKg: 20.0, ratePerKg: 48),
          LotItem(categoryId: 'battery_liion', categoryNameEn: 'Li-ion Battery', weightKg: 5.0, ratePerKg: 130),
        ],
      ),
    ];

    // Add demo lots (avoid duplicates by checking referenceCode)
    for (final lot in demoLots) {
      final existingIdx = ledger.indexWhere((l) => l.referenceCode == lot.referenceCode);
      if (existingIdx == -1) {
        ledger.insert(0, lot);
        _enqueueSyncRecord('lot', lot.id, 'create');
      }
    }

    // Add 5 demo price records
    final demoPrices = <PriceRecord>[
      PriceRecord(
        priceId: 'demo_p1',
        materialCategory: 'pcb_populated',
        location: 'Mumbai',
        date: now.subtract(const Duration(days: 1)),
        marketPrice: 30,
        recyclerPrice: 190,
        marketMin: 170,
        marketMax: 220,
        recyclerId: 'r1',
        source: 'demo',
      ),
      PriceRecord(
        priceId: 'demo_p2',
        materialCategory: 'cable',
        location: 'Mumbai',
        date: now.subtract(const Duration(days: 1)),
        marketPrice: 80,
        recyclerPrice: 105,
        marketMin: 90,
        marketMax: 120,
        recyclerId: 'r2',
        source: 'demo',
      ),
      PriceRecord(
        priceId: 'demo_p3',
        materialCategory: 'battery_liion',
        location: 'Nagpur',
        date: now,
        marketPrice: 70,
        recyclerPrice: 130,
        marketMin: 110,
        marketMax: 145,
        recyclerId: 'r1',
        source: 'demo',
      ),
      PriceRecord(
        priceId: 'demo_p4',
        materialCategory: 'lcd_panel',
        location: 'Nagpur',
        date: now,
        marketPrice: 60,
        recyclerPrice: 98,
        marketMin: 85,
        marketMax: 105,
        recyclerId: 'r2',
        source: 'demo',
      ),
      PriceRecord(
        priceId: 'demo_p5',
        materialCategory: 'crt_glass',
        location: 'Pune',
        date: now,
        marketPrice: 5,
        recyclerPrice: 8,
        marketMin: 6,
        marketMax: 10,
        source: 'demo',
      ),
    ];

    for (final pr in demoPrices) {
      final existingIdx = priceHistory.indexWhere((p) => p.priceId == pr.priceId);
      if (existingIdx == -1) {
        priceHistory.insert(0, pr);
        _enqueueSyncRecord('priceRecord', pr.priceId, 'create');
      }
    }

    await _saveLedger();
    await _savePriceHistory();
    notifyListeners();
  }

  // ── Lot actions ───────────────────────────────────────────────────────────

  Future<void> confirmHandover() async {
    assert(draftLot != null);
    final confirmed = draftLot!.copyWith(status: LotStatus.confirmed);
    ledger.insert(0, confirmed);
    draftLot = null;
    await _saveLedger();
    _enqueueSyncRecord('lot', confirmed.id, 'create');
    notifyListeners();
  }

  Future<void> recordConfirmedLot(Lot lot) async {
    final confirmed = lot.copyWith(status: LotStatus.confirmed);
    final existingIdx =
        ledger.indexWhere((l) => l.referenceCode == lot.referenceCode || l.id == lot.id);
    if (existingIdx != -1) {
      ledger[existingIdx] = confirmed;
    } else {
      ledger.insert(0, confirmed);
    }
    if (draftLot?.referenceCode == lot.referenceCode) {
      draftLot = null;
    }
    await _saveLedger();
    _enqueueSyncRecord('lot', confirmed.id, 'update');
    notifyListeners();
  }

  Future<void> markLotPaid(
    String lotId, {
    PaymentMethod method = PaymentMethod.cash,
    String? upiRef,
  }) async {
    final idx =
        ledger.indexWhere((l) => l.id == lotId || l.referenceCode == lotId);
    if (idx == -1) return;
    ledger[idx] = ledger[idx].copyWith(
      status: LotStatus.paid,
      paymentMethod: method,
      upiRef: upiRef,
    );
    await _saveLedger();
    _enqueueSyncRecord('lot', ledger[idx].id, 'update');
    notifyListeners();
  }

  // ── Price record helpers ──────────────────────────────────────────────────

  /// Returns the most recent price record for a category.
  PriceRecord? latestPriceFor(String categoryId) {
    final matching = priceHistory
        .where((p) => p.materialCategory == categoryId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return matching.isEmpty ? null : matching.first;
  }

  /// Returns price records for a category sorted newest-first.
  List<PriceRecord> historyForCategory(String categoryId) {
    return priceHistory
        .where((p) => p.materialCategory == categoryId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Simple rule-based anomaly check: is the given price below 70% of the
  /// stored market minimum for this category?
  /// NOTE: This is NOT machine learning. It's a transparent rule-based check.
  bool isPriceAnomalous(String categoryId, int offeredPricePerKg) {
    final latest = latestPriceFor(categoryId);
    if (latest == null || latest.marketMin == null) return false;
    return offeredPricePerKg < (latest.marketMin! * 0.70).round();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _newId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();

  String _newRef() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Returns the Category object for [id], or null if not found.
  cat_model.Category? categoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Earnings in the current ISO week (Monday–Sunday).
  int get weeklyTotal {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    return ledger
        .where((l) =>
            l.createdAt.isAfter(weekStart) &&
            (l.status == LotStatus.confirmed || l.status == LotStatus.paid))
        .fold(0, (sum, l) => sum + (l.agreedPrice ?? l.indicativeValue));
  }

  /// Total lifetime earnings across all paid lots.
  int get totalEarnings => ledger
      .where((l) => l.status == LotStatus.paid)
      .fold(0, (sum, l) => sum + (l.agreedPrice ?? l.indicativeValue));

  /// Pending amount (confirmed but not yet paid).
  int get pendingEarnings => ledger
      .where((l) => l.status == LotStatus.confirmed)
      .fold(0, (sum, l) => sum + (l.agreedPrice ?? l.indicativeValue));

  /// Total number of completed transactions.
  int get completedTransactionCount =>
      ledger.where((l) => l.status == LotStatus.paid).length;

  /// Returns recycler by ID.
  Recycler? recyclerById(String id) {
    try {
      return recyclers.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
