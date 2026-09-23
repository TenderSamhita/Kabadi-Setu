import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme.dart';

/// RateCardQrScreen — Recycler role only.
///
/// Displays a QR code encoding a rate-update payload.
/// The Collector scans this QR using the "Scan Rate Card" button on their
/// home screen, which calls AppState.applyRateUpdateFromQr().
///
/// QR payload shape:
/// {
///   "type": "rate_update",
///   "recyclerId": "r1",
///   "recyclerName": "Vidarbha E-Waste Recyclers",
///   "rates": { "pcb_populated": 210, "cable": 50, ... },
///   "effectiveFrom": "2026-09-23T18:00:00Z"
/// }
class RateCardQrScreen extends StatelessWidget {
  final String recyclerId;
  final String recyclerName;
  final Map<String, int> rates;

  const RateCardQrScreen({
    super.key,
    required this.recyclerId,
    required this.recyclerName,
    required this.rates,
  });

  String _buildPayload() {
    return jsonEncode({
      'type': 'rate_update',
      'recyclerId': recyclerId,
      'recyclerName': recyclerName,
      'rates': rates,
      'effectiveFrom': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final payload = _buildPayload();
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: kBoard,
      appBar: AppBar(
        backgroundColor: kBoardDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBrass),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rate Card QR',
          style: TextStyle(color: kChalk, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              // ── Instruction ───────────────────────────────────────────────
              Text(
                recyclerName,
                style: const TextStyle(
                  color: kChalk,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Ask the collector to scan this QR\nto receive today\'s rates',
                style: TextStyle(color: kChalk.withAlpha(160), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── QR Code ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kChalk,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: kChalk,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: kBoard,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: kBoard,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Timestamp ─────────────────────────────────────────────────
              Text(
                'Generated: $timestamp',
                style: TextStyle(
                  color: kChalk.withAlpha(120),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 28),

              // ── Rate summary table ────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: kBoardDeep,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBrass.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.price_change, color: kBrass, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Rates encoded in this QR',
                            style: TextStyle(
                              color: kChalk,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: kRule, height: 1),

                    // Rate rows
                    ...rates.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  color: kChalk.withAlpha(180),
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '₹${e.value} / kg',
                                style: const TextStyle(
                                  color: kBrass,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Back button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.edit, color: kBrass),
                  label: const Text(
                    'Edit rates again',
                    style: TextStyle(color: kBrass, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kBrass),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
