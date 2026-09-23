import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/lot.dart';
import '../strings.dart';
import '../theme.dart';
import 'rate_editor_screen.dart';
import 'receipt_screen.dart';
import 'recycler_gate_screen.dart';
import 'role_screen.dart';

/// Recycler Home Dashboard Screen
/// Displays intake statistics, recent scanned batches from the ledger,
/// role switcher, and a primary 64dp button to launch the Gate Scanner.
class RecyclerHomeScreen extends StatelessWidget {
  const RecyclerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final ledger = state.ledger;

    // Filter confirmed and paid lots
    final confirmedLots = ledger
        .where((l) =>
            l.status == LotStatus.confirmed || l.status == LotStatus.paid)
        .toList();

    final totalIntakes = confirmedLots.length;
    final totalKg = confirmedLots.fold(
        0.0, (double sum, l) => sum + l.totalWeightKg);
    final pendingCash = confirmedLots
        .where((l) => l.status == LotStatus.confirmed)
        .fold(0, (int sum, l) => sum + (l.agreedPrice ?? l.indicativeValue));

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.factory_outlined, color: kBrass, size: 24),
            const SizedBox(width: 8),
            Text(str('app_name', lang)),
          ],
        ),
        actions: [
          // Role toggle button
          IconButton(
            tooltip: 'Switch Role',
            icon: const Icon(Icons.swap_horiz, color: kBrass),
            onPressed: () => Navigator.of(context).pushReplacement<void, void>(
              MaterialPageRoute<void>(builder: (_) => const RoleScreen()),
            ),
          ),
          // Recycler role badge
          Container(
            margin: const EdgeInsets.only(right: 4, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: kSignal.withAlpha(25),
              border: Border.all(color: kSignal),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              str('recycler', lang),
              style: const TextStyle(
                color: kSignal,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // P2 — Offline pill
          Container(
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
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Facility Header Bar ───────────────────────────────────────
            Container(
              color: kBoard,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kBoardDeep,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBrass),
                    ),
                    child: const Icon(Icons.warehouse, color: kBrass, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vidarbha E-Waste Depot',
                          style: TextStyle(
                            color: kChalk,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.verified,
                                size: 14, color: kSignal),
                            const SizedBox(width: 4),
                            Text(
                              'CPCB Verified Gate #04',
                              style: TextStyle(
                                color: kChalk.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Operational Metrics Chips ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Total lots chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kRule),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'en'
                                ? 'Total Intakes'
                                : (lang == 'mr' ? 'एकूण आवक' : 'कुल आवक'),
                            style: const TextStyle(
                                fontSize: 12, color: kInkSoft),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalIntakes',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Total mass chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kRule),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'en'
                                ? 'Total Weight'
                                : (lang == 'mr' ? 'एकूण वजन' : 'कुल वज़न'),
                            style: const TextStyle(
                                fontSize: 12, color: kInkSoft),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${totalKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Pending payout chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kRule),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'en'
                                ? 'Cash Pending'
                                : (lang == 'mr' ? 'रोख प्रलंबित' : 'नकद बकाया'),
                            style: const TextStyle(
                                fontSize: 12, color: kAlert),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$pendingCash',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kAlert,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Recent Intakes Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang == 'en'
                        ? 'Ledger / Recent Intakes'
                        : (lang == 'mr' ? 'नोंदवही / अलीकडील आवक' : 'बही-खाता / हालिया आवक'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  Text(
                    '${confirmedLots.length} ${lang == 'en' ? (confirmedLots.length == 1 ? 'entry' : 'entries') : (lang == 'mr' ? 'नोंदी' : 'प्रविष्टियाँ')}',
                    style: const TextStyle(fontSize: 13, color: kInkSoft),
                  ),
                ],
              ),
            ),

            // ── Recent Intakes List ────────────────────────────────────────
            Expanded(
              child: confirmedLots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_scanner,
                              size: 48, color: kRule),
                          const SizedBox(height: 12),
                          Text(
                            str('scan_hint', lang),
                            style: const TextStyle(
                              fontSize: 16,
                              color: kInkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: confirmedLots.length,
                      itemBuilder: (context, index) {
                        final lot = confirmedLots[index];
                        final isPaid = lot.status == LotStatus.paid;
                        final amount = lot.agreedPrice ?? lot.indicativeValue;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kRule),
                          ),
                          child: ListTile(
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => ReceiptScreen(lot: lot),
                              ),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? kSignal.withAlpha(20)
                                    : kAlert.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPaid ? Icons.check : Icons.access_time,
                                color: isPaid ? kSignal : kAlert,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Ref: ${lot.referenceCode}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${lot.totalWeightKg.toStringAsFixed(1)} kg  •  ${lot.items.length} items',
                              style: const TextStyle(
                                  fontSize: 13, color: kInkSoft),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹$amount',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: kInk,
                                  ),
                                ),
                                Text(
                                  isPaid
                                      ? (lang == 'en'
                                          ? 'Paid'
                                          : (lang == 'mr' ? 'रोख चुकता' : 'नकद प्राप्त'))
                                      : (lang == 'en'
                                          ? 'Pending'
                                          : (lang == 'mr'
                                              ? 'रोख प्रलंबित'
                                              : 'नकद बकाया')),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isPaid ? kSignal : kAlert,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Secondary action: Update My Rates ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => RateEditorScreen(
                        // Use the first seeded recycler as this depot's identity.
                        // In production this would come from the logged-in recycler profile.
                        recyclerId: state.recyclers.isNotEmpty
                            ? state.recyclers.first.id
                            : 'r1',
                        recyclerName: state.recyclers.isNotEmpty
                            ? state.recyclers.first.name
                            : 'Vidarbha E-Waste Depot',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.price_change_outlined, color: kBrass),
                  label: Text(
                    lang == 'mr'
                        ? 'माझे दर अपडेट करा'
                        : (lang == 'hi'
                            ? 'मेरे दर अपडेट करें'
                            : 'Update My Rates'),
                    style: const TextStyle(
                      color: kBrass,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kBrass),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // ── Primary 64dp Action Button: Start Gate Scanner ──────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecyclerGateScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 28),
                  label: Text(
                    lang == 'en'
                        ? 'OPEN GATE SCANNER'
                        : (lang == 'mr'
                            ? 'गेट स्कॅनर उघडा (OPEN SCANNER)'
                            : 'गेट स्कैनर खोलें (OPEN SCANNER)'),
                    style: const TextStyle(
                      fontSize: 18,
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
            ),
          ],
        ),
      ),
    );
  }
}
