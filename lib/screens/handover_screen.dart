import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_state.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'collector_home_screen.dart';
import 'receipt_screen.dart';

/// Screen 9: Collector Handover QR Screen
/// Shows the serialized Lot payload as an offline-scannable QR code along with
/// the 6-character reference code, agreed payout amount, and TTS playback.
class HandoverScreen extends StatelessWidget {
  const HandoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final lot = state.draftLot;

    if (lot == null) {
      return Scaffold(
        backgroundColor: kBoard,
        body: Center(
          child: Text(
            lang == 'en'
                ? 'No lot active'
                : (lang == 'mr' ? 'कोणतेही साहित्य नाही' : 'कोई सामग्री नहीं'),
            style: const TextStyle(color: kChalk, fontSize: 18),
          ),
        ),
      );
    }

    final amount = lot.agreedPrice ?? lot.indicativeValue;
    final ref = lot.referenceCode;
    final recyclerName = lot.matchedRecyclerName ?? '';

    return Scaffold(
      backgroundColor: kBoard,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Offline badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kBoardDeep,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: kSignal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              str('offline_verified', lang),
                              style: const TextStyle(
                                color: kChalk,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Encryption icon
                      Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 16, color: kRule),
                          const SizedBox(width: 4),
                          Text(
                            'OFFLINE PASS',
                            style: TextStyle(
                              color: kChalk.withAlpha(150),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              str('handover_token', lang),
                              style: const TextStyle(
                                color: kChalk,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (recyclerName.isNotEmpty)
                              Text(
                                recyclerName,
                                style: const TextStyle(
                                  color: kBrass,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // TTS Button
                      IconButton.filledTonal(
                        onPressed: () {
                          final ttsText = lang == 'en'
                              ? 'Handover token. Reference code $ref. Total amount $amount rupees.'
                              : (lang == 'mr'
                                  ? 'हस्तांतरण टोकन. संदर्भ कोड $ref. एकूण रक्कम $amount रुपये.'
                                  : 'हस्तांतरण टोकन. संदर्भ कोड $ref. कुल राशि $amount रुपये.');
                          TtsService().speak(ttsText, lang);
                        },
                        icon: const Icon(Icons.volume_up),
                        style: IconButton.styleFrom(
                          backgroundColor: kBoardDeep,
                          foregroundColor: kChalk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── QR & Reference Card ───────────────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBrass, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kBrass.withAlpha(50),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card Sub-Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified,
                                    size: 18, color: kSignal),
                                SizedBox(width: 4),
                                Text(
                                  'KABADI PASS',
                                  style: TextStyle(
                                    color: kInk,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${lot.totalWeightKg.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: kInkSoft,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // High-contrast Vector QR Code
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kRule),
                          ),
                          child: QrImageView(
                            data: lot.toQrPayload(),
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: kInk,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: kInk,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reference Code
                        Text(
                          str('ref_code', lang).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kInkSoft,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: kPaper,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kRule),
                          ),
                          child: Text(
                            ref,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 4.0,
                              color: kInk,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payout Amount Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: kPaper,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    str('total_payout', lang),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kInkSoft,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹$amount',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: kSignal,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: kRule),
                                ),
                                child: Text(
                                  str('cash_pending', lang),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Instruction label
                        Text(
                          str('scan_instruction', lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kInkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Action Buttons ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton.icon(
                      onPressed: () async {
                        // Confirm lot and navigate to Receipt screen
                        await state.recordConfirmedLot(lot);
                        if (context.mounted) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => ReceiptScreen(lot: lot),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long, size: 22),
                      label: Text(
                        lang == 'en'
                            ? 'VIEW RECEIPT'
                            : (lang == 'mr'
                                ? 'पावती पहा (VIEW RECEIPT)'
                                : 'रसीद देखें (VIEW RECEIPT)'),
                        style: const TextStyle(
                          fontSize: 16,
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        // Return to collector home screen
                        Navigator.of(context).pushAndRemoveUntil<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const CollectorHomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        str('done', lang),
                        style: const TextStyle(
                          color: kChalk,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
