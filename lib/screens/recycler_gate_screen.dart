import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/lot.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'receipt_screen.dart';

/// Screen 10: Recycler Gate Scan Screen
/// Uses MobileScanner to scan collector handover QR tokens.
/// Decodes the payload, presents a one-tap verification bottom sheet,
/// writes a cash-pending payment record to the ledger, and transitions to receipt.
class RecyclerGateScreen extends StatefulWidget {
  const RecyclerGateScreen({super.key});

  @override
  State<RecyclerGateScreen> createState() => _RecyclerGateScreenState();
}

class _RecyclerGateScreenState extends State<RecyclerGateScreen> {
  late final MobileScannerController _controller;
  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  final TextEditingController _manualPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _manualPinController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _handleBarcodeData(rawValue);
        break;
      }
    }
  }

  void _handleBarcodeData(String rawData) {
    setState(() => _isProcessingScan = true);
    _controller.stop();

    final state = context.read<AppState>();
    Lot? lot = Lot.fromQrPayload(
      rawData,
      categoryNameResolver: (catId) =>
          state.categoryById(catId)?.nameEn ?? catId,
      matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
    );

    // If payload is not JSON but a plain 6-char ref code
    if (lot == null) {
      final trimmed = rawData.trim().toUpperCase();
      // Check if matches active draft lot or ledger
      if (state.draftLot != null &&
          (state.draftLot!.referenceCode == trimmed ||
              trimmed.contains(state.draftLot!.referenceCode))) {
        lot = state.draftLot!;
      } else {
        // Fallback demo lot with this reference code
        lot = Lot(
          id: 'lot_$trimmed',
          referenceCode: trimmed.isNotEmpty ? trimmed : 'KS-8942',
          status: LotStatus.matched,
          createdAt: DateTime.now(),
          agreedPrice: 1890,
          matchedRecyclerName: 'Vidarbha E-Waste Recyclers',
          items: const [
            LotItem(
              categoryId: 'cable',
              categoryNameEn: 'Copper Wire',
              weightKg: 4.5,
              ratePerKg: 420,
            ),
          ],
        );
      }
    }

    _showConfirmationSheet(lot);
  }

  void _showConfirmationSheet(Lot lot) {
    final lang = context.read<AppState>().language;
    final amount = lot.agreedPrice ?? lot.indicativeValue;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: kRule,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet title & Voice assist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'en'
                          ? 'Intake Token Found'
                          : (lang == 'mr'
                              ? 'आवक टोकन आढळले'
                              : 'आवक टोकन प्राप्त हुआ'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                    Text(
                      'Ref: ${lot.referenceCode}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: kBrass,
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    final ttsText = lang == 'en'
                        ? 'Token ${lot.referenceCode}. Total weight ${lot.totalWeightKg.toStringAsFixed(1)} kg. Payout $amount rupees.'
                        : (lang == 'mr'
                            ? 'टोकन ${lot.referenceCode}. एकूण वजन ${lot.totalWeightKg.toStringAsFixed(1)} किलो. देय रक्कम $amount रुपये.'
                            : 'टोकन ${lot.referenceCode}. कुल वज़न ${lot.totalWeightKg.toStringAsFixed(1)} किलो. देय राशि $amount रुपये.');
                    TtsService().speak(ttsText, lang);
                  },
                  icon: const Icon(Icons.volume_up),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kRule),
              ),
              child: Column(
                children: [
                  ...lot.items.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${i.categoryNameEn} (${i.weightKg.toStringAsFixed(1)} kg)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                          Text(
                            '₹${i.indicativeValue}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: kRule),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'en' ? 'Total Payout:' : (lang == 'mr' ? 'एकूण देय रक्कम:' : 'कुल देय राशि:'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kInk,
                        ),
                      ),
                      Text(
                        '₹$amount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kSignal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Cash-pending status indicator
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: kInkSoft),
                const SizedBox(width: 6),
                Text(
                  lang == 'en'
                      ? 'After acceptance, cash will be logged as pending'
                      : (lang == 'mr'
                          ? 'स्वीकारल्यानंतर नोंदवहीत रोख प्रलंबित राहील'
                          : 'स्वीकारने के बाद बही-खाते में नकद बकाया दर्ज होगा'),
                  style: const TextStyle(fontSize: 12, color: kInkSoft),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirm button (64dp)
            SizedBox(
              height: 64,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  final appState = context.read<AppState>();
                  await appState.recordConfirmedLot(lot);

                  if (!mounted) return;
                  Navigator.of(context).pushReplacement<void, void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ReceiptScreen(lot: lot),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_user, size: 26),
                label: Text(
                  lang == 'en'
                      ? 'ACCEPT INTAKE'
                      : (lang == 'mr'
                          ? 'आवक स्वीकारा (ACCEPT INTAKE)'
                          : 'आवक स्वीकारें (ACCEPT INTAKE)'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: kBrass,
                  foregroundColor: kBoardDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                setState(() => _isProcessingScan = false);
                _controller.start();
              },
              child: Text(
                lang == 'en' ? 'Cancel' : (lang == 'mr' ? 'रद्द करा' : 'रद्द करें'),
                style: const TextStyle(color: kInkSoft, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final lang = context.read<AppState>().language;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          lang == 'en' ? 'Enter Reference Code' : (lang == 'mr' ? 'संदर्भ कोड प्रविष्ट करा' : 'संदर्भ कोड दर्ज करें'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _manualPinController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
          decoration: const InputDecoration(
            hintText: 'उदा. KS-8942',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang == 'en' ? 'Cancel' : (lang == 'mr' ? 'रद्द करा' : 'रद्द करें')),
          ),
          FilledButton(
            onPressed: () {
              final code = _manualPinController.text.trim();
              Navigator.of(ctx).pop();
              if (code.isNotEmpty) {
                _handleBarcodeData(code);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: kBrass),
            child: Text(
              lang == 'en' ? 'Verify' : (lang == 'mr' ? 'तपासा' : 'जाँचें'),
              style: const TextStyle(color: kBoardDeep, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    return Scaffold(
      backgroundColor: kBoardDeep,
      appBar: AppBar(
        title: Text(
          lang == 'en' ? 'Gate Scanner' : (lang == 'mr' ? 'गेट स्कॅनर' : 'गेट स्कैनर'),
        ),
        actions: [
          // Torch button
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? kBrass : kChalk,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Live Camera Viewfinder ─────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: kBoardDeep,
                child: Center(
                  child: IconButton(
                    iconSize: 44,
                    icon: const Icon(Icons.refresh, color: kBrass),
                    onPressed: () {
                      try {
                        _controller.start();
                      } catch (_) {}
                    },
                  ),
                ),
              );
            },
          ),

          // ── Semi-transparent vignette ──────────────────────────────────
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(80),
            ),
          ),

          // ── Reticle Target with Brass L-brackets ───────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      // Top-Left L-bracket
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: kBrass, width: 4),
                              left: BorderSide(color: kBrass, width: 4),
                            ),
                          ),
                        ),
                      ),
                      // Top-Right L-bracket
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: kBrass, width: 4),
                              right: BorderSide(color: kBrass, width: 4),
                            ),
                          ),
                        ),
                      ),
                      // Bottom-Left L-bracket
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: kBrass, width: 4),
                              left: BorderSide(color: kBrass, width: 4),
                            ),
                          ),
                        ),
                      ),
                      // Bottom-Right L-bracket
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: kBrass, width: 4),
                              right: BorderSide(color: kBrass, width: 4),
                            ),
                          ),
                        ),
                      ),
                      // Center Crosshair
                      const Center(
                        child: Icon(
                          Icons.center_focus_strong,
                          color: kBrass,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBoardDeep.withAlpha(220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lang == 'en'
                        ? 'Align collector\'s QR code within the frame'
                        : (lang == 'mr'
                            ? 'कलेक्टरच्या फोनमधील QR कोड चौकटीत आणा'
                            : 'कलेक्टर के फोन का QR कोड फ्रेम में लाएँ'),
                    style: const TextStyle(
                      color: kChalk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Drawer / Utility Panel ──────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              decoration: const BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Waiting status banner
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: kSignal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          str('waiting_scan', lang),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                      ),
                      // Simulation / Test trigger button for emulator
                      TextButton.icon(
                        onPressed: () {
                          // Simulate test scan
                          final testPayload = jsonEncode({
                            'ref': 'KS-8942',
                            'items': [
                              {
                                'cat': 'cable',
                                'kg': 4.5,
                                'rate': 420,
                              }
                            ],
                            'total': 1890,
                            'ts': DateTime.now().millisecondsSinceEpoch,
                          });
                          _handleBarcodeData(testPayload);
                        },
                        icon: const Icon(Icons.science, size: 16, color: kBrass),
                        label: Text(
                          lang == 'en' ? 'Test Scan' : (lang == 'mr' ? 'चाचणी स्कॅन' : 'परीक्षण स्कैन'),
                          style: const TextStyle(
                            color: kBrass,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Manual Pin / Code Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.dialpad, size: 20),
                      label: Text(
                        lang == 'en'
                            ? 'Or type 6-character code'
                            : (lang == 'mr'
                                ? 'किंवा 6-अंकी कोड टाइप करा'
                                : 'या 6-अंकीय कोड दर्ज करें'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kInk,
                        side: const BorderSide(color: kRule, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
