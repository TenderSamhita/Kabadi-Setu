import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/lot.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'receipt_screen.dart';

/// Screen 12: Collector Ledger / Passbook Screen
/// Displays the running weekly total in rupees at the top, a weekly velocity sparkline,
/// and a reverse-chronological list of past transactions from shared_preferences.
/// Tapping a row reads it aloud via TTS and allows viewing the full receipt.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final ledger = state.ledger;

    // Filter to confirmed and paid lots
    final pastTransactions = ledger
        .where((l) =>
            l.status == LotStatus.confirmed || l.status == LotStatus.paid)
        .toList();

    final weeklyTotal = state.weeklyTotal;
    final totalKg = pastTransactions.fold(
        0.0, (double sum, l) => sum + l.totalWeightKg);

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        title: Text(str('ledger_title', lang)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Weekly Total Hero Card (Board & Brass) ─────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kBoard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet,
                                      color: kBrass, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    str('weekly_earnings', lang),
                                    style: TextStyle(
                                      color: kChalk.withAlpha(220),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // TTS speaker for Weekly Total
                              IconButton.filledTonal(
                                onPressed: () {
                                  final ttsText = lang == 'en'
                                      ? 'This week\'s total earnings $weeklyTotal rupees. Total ${totalKg.toStringAsFixed(1)} kg scrap.'
                                      : (lang == 'mr'
                                          ? 'या आठवड्याची एकूण कमाई $weeklyTotal रुपये. एकूण ${totalKg.toStringAsFixed(1)} किलो भंगार.'
                                          : 'इस सप्ताह की कुल कमाई $weeklyTotal रुपये. कुल ${totalKg.toStringAsFixed(1)} किलो कबाड़.');
                                  TtsService().speak(ttsText, lang);
                                },
                                icon: const Icon(Icons.volume_up, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: kBoardDeep,
                                  foregroundColor: kBrass,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Large Rupee Numeral
                          Text(
                            '₹$weeklyTotal',
                            style: const TextStyle(
                              color: kBrass,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Weight & Progress Chips
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kBoardDeep,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${str('total_scrap', lang)} ${totalKg.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    color: kChalk,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kSignal.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified,
                                        size: 13, color: kSignal),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pastTransactions.length} ${lang == 'en' ? (pastTransactions.length == 1 ? 'transaction' : 'transactions') : (lang == 'mr' ? 'व्यवहार' : 'लेन-देन')}',
                                      style: const TextStyle(
                                        color: kSignal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Daily Velocity Sparkline Bar Chart ─────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kRule),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang == 'en'
                                    ? 'Daily Collection'
                                    : (lang == 'mr'
                                        ? 'दैनिक संकलन'
                                        : 'दैनिक संकलन'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kInk,
                                ),
                              ),
                              Text(
                                str('this_week', lang),
                                style: const TextStyle(
                                    fontSize: 12, color: kInkSoft),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // 7-day sparkline bar visual
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _DayBar(day: lang == 'en' ? 'Mon' : (lang == 'mr' ? 'सोम' : 'सोम'), height: 28, isToday: false),
                              _DayBar(day: lang == 'en' ? 'Tue' : (lang == 'mr' ? 'मंगळ' : 'मंगल'), height: 38, isToday: false),
                              _DayBar(day: lang == 'en' ? 'Wed' : (lang == 'mr' ? 'बुध' : 'बुध'), height: 48, isToday: true),
                              _DayBar(day: lang == 'en' ? 'Thu' : (lang == 'mr' ? 'गुरू' : 'गुरु'), height: 32, isToday: false),
                              _DayBar(day: lang == 'en' ? 'Fri' : (lang == 'mr' ? 'शुक्र' : 'शुक्र'), height: 42, isToday: false),
                              _DayBar(day: lang == 'en' ? 'Sat' : (lang == 'mr' ? 'शनि' : 'शनि'), height: 22, isToday: false),
                              _DayBar(day: lang == 'en' ? 'Sun' : (lang == 'mr' ? 'रवि' : 'रवि'), height: 16, isToday: false),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Past Transactions Section Header ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history, size: 20, color: kInk),
                            const SizedBox(width: 6),
                            Text(
                              str('past_transactions', lang),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: kInk,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${pastTransactions.length} ${lang == 'en' ? (pastTransactions.length == 1 ? 'entry' : 'entries') : (lang == 'mr' ? 'नोंदी' : 'प्रविष्टियाँ')}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: kInkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Transactions List ──────────────────────────────────
                    if (pastTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 48, color: kRule),
                            const SizedBox(height: 10),
                            Text(
                              lang == 'en'
                                  ? 'No transactions yet'
                                  : (lang == 'mr'
                                      ? 'अद्याप कोणतेही व्यवहार नाहीत'
                                      : 'अभी तक कोई लेन-देन नहीं है'),
                              style: const TextStyle(
                                  fontSize: 15, color: kInkSoft),
                            ),
                          ],
                        ),
                      )
                    else
                      ...pastTransactions.map(
                        (lot) => _TransactionTile(lot: lot, lang: lang),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day Bar Widget for Sparkline ──────────────────────────────────────────────

class _DayBar extends StatelessWidget {
  final String day;
  final double height;
  final bool isToday;

  const _DayBar({
    required this.day,
    required this.height,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: isToday ? kBrass : const Color(0xFFCBD2CB),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            color: isToday ? kInk : kInkSoft,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Lot lot;
  final String lang;

  const _TransactionTile({required this.lot, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isPaid = lot.status == LotStatus.paid;
    final amount = lot.agreedPrice ?? lot.indicativeValue;
    final primaryItemName = lot.items.isNotEmpty
        ? lot.items.first.categoryNameEn
        : 'E-Waste Scrap';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRule),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          // Tap row to open receipt
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ReceiptScreen(lot: lot),
            ),
          );
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kBrass.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2, color: kBrass, size: 22),
        ),
        title: Text(
          '$primaryItemName (${lot.totalWeightKg.toStringAsFixed(1)} kg)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: kInk,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              'Ref: ${lot.referenceCode}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kInkSoft,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isPaid ? kSignal.withAlpha(20) : kAlert.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle : Icons.access_time,
                    size: 11,
                    color: isPaid ? kSignal : kAlert,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isPaid
                        ? (lang == 'en'
                            ? 'Paid'
                            : (lang == 'mr' ? 'रोख चुकता' : 'नकद प्राप्त'))
                        : (lang == 'en'
                            ? 'Pending'
                            : (lang == 'mr' ? 'रोख प्रलंबित' : 'नकद बकाया')),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? kSignal : kAlert,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$amount',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: kInk,
                  ),
                ),
                if (!isPaid)
                  GestureDetector(
                    onTap: () {
                      context.read<AppState>().markLotPaid(lot.referenceCode);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == 'en'
                                ? 'Lot ${lot.referenceCode} marked as Paid!'
                                : (lang == 'mr'
                                    ? 'लॉट ${lot.referenceCode} रोख चुकता नोंदवला गेला!'
                                    : 'लॉट ${lot.referenceCode} नकद भुगतान दर्ज हुआ!'),
                          ),
                          backgroundColor: kSignal,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kBrass,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lang == 'en' ? 'Mark Paid' : (lang == 'mr' ? 'चुकता करा' : 'भुगतान दर्ज'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kBoardDeep,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            // Tapping TTS icon reads row aloud
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20, color: kInkSoft),
              onPressed: () {
                final statusStr = isPaid
                    ? (lang == 'en'
                        ? 'Paid'
                        : (lang == 'mr' ? 'रोख चुकता' : 'नकद प्राप्त'))
                    : (lang == 'en'
                        ? 'Pending'
                        : (lang == 'mr' ? 'रोख प्रलंबित' : 'नकद बकाया'));
                final tts = lang == 'en'
                    ? 'Reference ${lot.referenceCode}. $primaryItemName ${lot.totalWeightKg.toStringAsFixed(1)} kg. Amount $amount rupees. $statusStr.'
                    : (lang == 'mr'
                        ? 'संदर्भ ${lot.referenceCode}. $primaryItemName ${lot.totalWeightKg.toStringAsFixed(1)} किलो. रक्कम $amount रुपये. $statusStr.'
                        : 'संदर्भ ${lot.referenceCode}. $primaryItemName ${lot.totalWeightKg.toStringAsFixed(1)} किलो. राशि $amount रुपये. $statusStr.');
                TtsService().speak(tts, lang);
              },
            ),
          ],
        ),
      ),
    );
  }
}
