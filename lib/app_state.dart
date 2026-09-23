import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/category.dart' as cat_model;
import 'models/lot.dart';
import 'models/recycler.dart';

const _kLedgerKey = 'kabadi_ledger_v1';

/// Recycler-specific rate overrides: { recyclerId -> { categoryId -> rate } }
const _kRecyclerRatesKey = 'kabadi_recycler_rates_v1';

/// Floor / reference rate overrides broadcast via Rate Card QR: { categoryId -> rate }
const _kCategoryRatesKey = 'kabadi_category_rates_v1';

/// Single source of truth for runtime app state.
/// One ChangeNotifier is enough — do not introduce Riverpod, Bloc, or any
/// DI framework. See AGENTS.md.
class AppState extends ChangeNotifier {
  // ── Identity ────────────────────────────────────────────────────────────

  /// 'collector' or 'recycler'. Toggled on the role screen.
  String role = 'collector';

  /// 'mr' (Marathi) | 'hi' (Hindi) | 'en' (English fallback).
  String language = 'mr';

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

  // ── In-progress lot ─────────────────────────────────────────────────────

  Lot? draftLot;

  // ── Ledger (persisted) ───────────────────────────────────────────────────

  List<Lot> ledger = [];

  // ── Initialisation ───────────────────────────────────────────────────────

  /// Call once from main() before runApp(), or lazily on first screen load.
  Future<void> init() async {
    await Future.wait([
      _loadSeedData(),
      _loadLedger(),
      _loadRateOverrides(),
    ]);
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
      // Corrupted prefs — start fresh rather than crashing.
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

  void setLanguage(String lang) {
    assert(lang == 'mr' || lang == 'hi' || lang == 'en');
    language = lang;
    notifyListeners();
  }

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

  /// Called by the Recycler role when they save updated rates in RateEditorScreen.
  /// Persists to shared_preferences; never touches seed JSON.
  Future<void> updateRecyclerRates(
      String recyclerId, Map<String, int> rates) async {
    recyclerRateOverrides[recyclerId] = Map<String, int>.from(rates);
    await _saveRecyclerRateOverrides();
    notifyListeners();
  }

  /// Called when the Collector scans a Rate Card QR.
  /// The QR payload must have { "type": "rate_update", "rates": { ... } }.
  /// Saves floor-rate overrides so the rate board reflects the recycler's offer.
  Future<void> applyRateUpdateFromQr(Map<String, dynamic> payload) async {
    assert(payload['type'] == 'rate_update');
    final ratesRaw = payload['rates'] as Map<String, dynamic>;
    final newRates = ratesRaw.map((k, v) => MapEntry(k, v as int));
    categoryRateOverrides.addAll(newRates);
    await _saveCategoryRateOverrides();
    // Also update recycler-specific overrides if recyclerId is present
    final rid = payload['recyclerId'] as String?;
    if (rid != null) {
      recyclerRateOverrides[rid] = newRates;
      await _saveRecyclerRateOverrides();
    }
    notifyListeners();
  }

  // ── Draft lot management ─────────────────────────────────────────────────

  /// Starts a fresh draft lot with a new ID and 6-char reference code.
  void startNewLot() {
    draftLot = Lot(
      id: _newId(),
      items: const [],
      status: LotStatus.draft,
      createdAt: DateTime.now(),
      referenceCode: _newRef(),
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

  /// Called by the recycler-side scan confirm. Moves lot to confirmed and
  /// writes it to the ledger.
  Future<void> confirmHandover() async {
    assert(draftLot != null);
    final confirmed = draftLot!.copyWith(status: LotStatus.confirmed);
    ledger.insert(0, confirmed);
    draftLot = null;
    await _saveLedger();
    notifyListeners();
  }

  /// Records a confirmed lot (scanned by recycler or collector) to the ledger
  /// and marks status as confirmed (cash-pending).
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
    notifyListeners();
  }

  Future<void> markLotPaid(String lotId) async {
    final idx =
        ledger.indexWhere((l) => l.id == lotId || l.referenceCode == lotId);
    if (idx == -1) return;
    ledger[idx] = ledger[idx].copyWith(status: LotStatus.paid);
    await _saveLedger();
    notifyListeners();
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
}
