import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/category.dart' as cat_model;
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'capture_screen.dart';
import 'handover_screen.dart';
import 'ledger_screen.dart';

// ── Static demo data ──────────────────────────────────────────────────────────

/// 7-day trend: true = price rising, false = falling.
/// This is fixed demo data — not live market data. See AGENTS.md out-of-scope.
const Map<String, bool> _kTrendUp = {
  'pcb_populated': true,
  'cable': false,
  'battery_liion': true,
  'crt_glass': false,
  'motor': true,
  'mixed_plastic': false,
  'lcd_panel': true,
  'battery_leadacid': false,
  'bare_board': true,
  'mixed_cable': false,
};

/// Material Icons used as stand-in icons for each e-waste category.
const Map<String, IconData> _kIcons = {
  'pcb_populated': Icons.memory,
  'cable': Icons.cable,
  'battery_liion': Icons.battery_charging_full,
  'crt_glass': Icons.tv,
  'motor': Icons.settings_input_component,
  'mixed_plastic': Icons.recycling,
  'lcd_panel': Icons.laptop,
  'battery_leadacid': Icons.battery_alert,
  'bare_board': Icons.developer_board,
  'mixed_cable': Icons.device_hub,
};

// ── Screen ────────────────────────────────────────────────────────────────────

/// Collector home — the rate board.
/// Displays 10 category tiles in a 2-column grid.
/// Each tile speaks name + rate via TTS when tapped.
/// The primary action ("Add material") opens the capture flow.
class CollectorHomeScreen extends StatelessWidget {
  const CollectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final categories = state.categories;

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              str('rate_board_title', lang),
              style: const TextStyle(
                color: kChalk,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              lang == 'mr'
                  ? 'न्याय्य किंमत • सुरक्षित पुनर्वापर • ऑफलाइन'
                  : (lang == 'hi'
                      ? 'उचित मूल्य • सुरक्षित रिसाइकलिंग • ऑफलाइन'
                      : 'Fair prices • Safe recycling • Offline-first'),
              style: TextStyle(
                color: kChalk.withAlpha(140),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // ⚡ Jury Demo Quick-Fill
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: kBrass.withAlpha(35),
                foregroundColor: kBrass,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: kBrass, width: 1),
                ),
              ),
              icon: const Icon(Icons.bolt, size: 16),
              label: Text(
                str('demo_mode', lang),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                state.loadDemoLot();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(str('demo_lot_loaded', lang)),
                    backgroundColor: kBrass,
                    duration: const Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const HandoverScreen(),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: str('ledger_title', lang),
            icon: const Icon(Icons.account_balance_wallet, color: kBrass),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const LedgerScreen()),
            ),
          ),
          // Scan Rate Card QR from a recycler
          IconButton(
            tooltip: lang == 'mr'
                ? 'रेट कार्ड स्कॅन करा'
                : (lang == 'hi' ? 'रेट कार्ड स्कैन करें' : 'Scan Rate Card'),
            icon: const Icon(Icons.document_scanner_outlined, color: kBrass),
            onPressed: () => _openRateCardScanner(context, state, lang),
          ),
          _RoleBadge(label: str('collector', lang)),
          const _OfflinePill(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Rate grid ────────────────────────────────────────────────────
          Expanded(
            child: categories.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: kBrass))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) => _CategoryTile(
                      category: categories[i],
                      lang: lang,
                      effectiveRate:
                          state.effectiveRateForCategory(categories[i].id),
                    ),
                  ),
          ),

          // ── Primary action ────────────────────────────────────────────────
          Container(
            color: kPaper,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CaptureScreen()),
              ),
              icon: const Icon(Icons.camera_alt, size: 22),
              label: Text(
                '${str('add_material', lang)} / Add material',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rate Card scanner helper ────────────────────────────────────────────────

/// Opens a full-screen scanner that specifically looks for a rate-update QR.
/// If it finds one, it calls [AppState.applyRateUpdateFromQr] and shows a
/// confirmation snackbar. Other QR types are ignored so the collector cannot
/// accidentally overwrite a handover flow.
void _openRateCardScanner(BuildContext context, AppState state, String lang) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (ctx) => _RateCardScanPage(state: state, lang: lang),
    ),
  );
}

class _RateCardScanPage extends StatefulWidget {
  final AppState state;
  final String lang;
  const _RateCardScanPage({required this.state, required this.lang});

  @override
  State<_RateCardScanPage> createState() => _RateCardScanPageState();
}

class _RateCardScanPageState extends State<_RateCardScanPage> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      try {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        if (payload['type'] != 'rate_update') continue;
        _handled = true;
        widget.state.applyRateUpdateFromQr(payload).then((_) {
          if (!mounted) return;
          final recyclerName =
              (payload['recyclerName'] as String?) ?? 'Recycler';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.lang == 'mr'
                    ? 'दर अपडेट: $recyclerName'
                    : (widget.lang == 'hi'
                        ? 'दर अपडेट: $recyclerName'
                        : 'Rates updated from $recyclerName'),
              ),
              backgroundColor: kSignal,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        });
        return;
      } catch (_) {
        // Not a rate-update QR — ignore and keep scanning.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBoard,
      appBar: AppBar(
        backgroundColor: kBoardDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBrass),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.lang == 'mr'
              ? 'रेट कार्ड स्कॅन करा'
              : (widget.lang == 'hi'
                  ? 'रेट कार्ड स्कैन करें'
                  : 'Scan Rate Card'),
          style: const TextStyle(
              color: kChalk, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: kBrass, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              widget.lang == 'mr'
                  ? 'रेसायलरच्या रेट कार्ड QR वर ठेवा'
                  : (widget.lang == 'hi'
                      ? 'रिसायकलर के रेट कार्ड QR पर रखें'
                      : 'Point at the recycler’s Rate Card QR'),
              style: const TextStyle(color: kChalk, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4, top: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: kBrass),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: kBrass,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// P2 — Offline mode pill. Always visible — the app is always offline by design.
/// Color: kSignal (green) to communicate offline mode as a feature, not a failure.
class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 10, top: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kSignal.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kSignal.withAlpha(120)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 11, color: kSignal),
            SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                color: kSignal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final cat_model.Category category;
  final String lang;
  /// The effective rate: categoryRateOverrides (from QR) > seed ratePerKg.
  final int effectiveRate;

  const _CategoryTile({
    required this.category,
    required this.lang,
    required this.effectiveRate,
  });

  void _speak() {
    final name = category.nameFor(lang);
    final unit = lang == 'en'
        ? 'rupees per kilogram'
        : 'रुपये प्रति किलो';
    TtsService().speak('$name, $effectiveRate $unit', lang);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _kIcons[category.id] ?? Icons.inventory_2;
    final trendUp = _kTrendUp[category.id] ?? true;
    final isHazard = category.hazardLevel >= 2;

    return Card(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHazard ? kAlert.withAlpha(100) : kRule,
          width: isHazard ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _speak,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: category icon + speaker ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 30,
                    color: isHazard ? kAlert : kBrass,
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _speak,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: kInkSoft,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Category name in selected language ────────────────────────
              Text(
                category.nameFor(lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kInk,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),

              // ── Price + trend ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$effectiveRate',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: kBrass,
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      '/kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: kInkSoft,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // Show updated badge if rate differs from seed
                  if (effectiveRate != category.ratePerKg)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: kSignal.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: kSignal.withAlpha(100), width: 1),
                        ),
                        child: const Text(
                          'Updated',
                          style: TextStyle(
                            fontSize: 9,
                            color: kSignal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  // 7-day trend arrow (static demo data)
                  Icon(
                    trendUp ? Icons.trending_up : Icons.trending_down,
                    size: 18,
                    color: trendUp ? kSignal : kAlert,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
