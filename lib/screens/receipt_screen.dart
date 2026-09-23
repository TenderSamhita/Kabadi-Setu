import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/lot.dart';
import '../services/eco_impact_service.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/circular_impact_card.dart';
import 'collector_home_screen.dart';
import 'ledger_screen.dart';
import 'recycler_home_screen.dart';

/// Screen 11: Receipt & Confirmation Screen
/// Displayed after a successful QR handover scan or when viewing a completed lot.
/// Shows reference code, final payout amount, items breakdown, TTS readout,
/// and a 64dp primary button to "Mark Paid (Cash)".
class ReceiptScreen extends StatefulWidget {
  final Lot lot;

  const ReceiptScreen({super.key, required this.lot});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late Lot _currentLot;

  @override
  void initState() {
    super.initState();
    _currentLot = widget.lot;
  }

  void _markPaid() {
    final state = context.read<AppState>();
    final lang = state.language;
    state.markLotPaid(_currentLot.referenceCode);
    setState(() {
      _currentLot = _currentLot.copyWith(status: LotStatus.paid);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang == 'en'
              ? 'Cash payment recorded as paid and updated in ledger!'
              : (lang == 'mr'
                  ? 'रोख चुकता नोंदवली आणि नोंदवहीत अद्ययावत झाली!'
                  : 'नकद भुगतान दर्ज किया गया और बही-खाते में अपडेट हुआ!'),
        ),
        backgroundColor: kSignal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final isPaid = _currentLot.status == LotStatus.paid;
    final amount = _currentLot.agreedPrice ?? _currentLot.indicativeValue;
    final ref = _currentLot.referenceCode;
    final recyclerName = _currentLot.matchedRecyclerName ??
        (lang == 'en'
            ? 'Vidarbha E-Waste Recyclers'
            : (lang == 'mr'
                ? 'विदर्भ ई-वेस्ट रिसायकलर्स'
                : 'विदर्भ ई-वेस्ट रिसायकलर्स'));
    final ecoImpact = EcoImpactService.compute(_currentLot);

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(lang == 'en' ? 'Receipt Summary' : (lang == 'mr' ? 'पावती सारांश' : 'रसीद सारांश')),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              final isRecycler = state.role == 'recycler';
              Navigator.of(context).pushAndRemoveUntil<void>(
                MaterialPageRoute<void>(
                  builder: (_) => isRecycler
                      ? const RecyclerHomeScreen()
                      : const CollectorHomeScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    // ── Success Celebration Icon ─────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: kSignal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x332F6E4E),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title with Voice Cue Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang == 'en'
                              ? 'Handover Complete!'
                              : (lang == 'mr'
                                  ? 'हस्तांतरण पूर्ण!'
                                  : 'हस्तांतरण पूर्ण!'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () {
                            final statusText = isPaid
                                ? (lang == 'en'
                                    ? 'Paid'
                                    : (lang == 'mr' ? 'रोख चुकता' : 'नकद प्राप्त'))
                                : (lang == 'en'
                                    ? 'Cash Pending'
                                    : (lang == 'mr'
                                        ? 'रोख प्रलंबित'
                                        : 'नकद बकाया'));
                            final ttsText = lang == 'en'
                                ? 'Handover complete. Reference code $ref. Total payout $amount rupees. $statusText.'
                                : (lang == 'mr'
                                    ? 'हस्तांतरण पूर्ण. संदर्भ कोड $ref. एकूण रक्कम $amount रुपये. $statusText.'
                                    : 'हस्तांतरण पूर्ण. संदर्भ कोड $ref. कुल राशि $amount रुपये. $statusText.');
                            TtsService().speak(ttsText, lang);
                          },
                          icon: const Icon(Icons.volume_up, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: kCard,
                            foregroundColor: kInk,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      lang == 'en'
                          ? 'Transaction recorded successfully offline'
                          : (lang == 'mr'
                              ? 'व्यवहार यशस्वीरित्या नोंदवला गेला आहे'
                              : 'लेन-देन सफलतापूर्वक दर्ज कर लिया गया है'),
                      style: const TextStyle(fontSize: 14, color: kInkSoft),
                    ),
                    const SizedBox(height: 16),

                    // ── Central Digital Ledger Receipt Card ───────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kRule),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Ref code & Timestamp row
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                      str('ref_code', lang),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: kInkSoft,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      ref,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        letterSpacing: 2.0,
                                        color: kInk,
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
                                  ),
                                  child: const Text(
                                    'OFFLINE LEDGER',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kInkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Recycler Partner
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: kSignal.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.recycling,
                                    color: kSignal, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recyclerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kInk,
                                      ),
                                    ),
                                    Text(
                                      lang == 'en'
                                          ? 'Authorized Center • Nagpur'
                                          : (lang == 'mr'
                                              ? 'अधिकृत केंद्र • नागपूर'
                                              : 'अधिकृत केंद्र • नागपुर'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: kSignal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: kRule),
                          const SizedBox(height: 8),

                          // Items List
                          ..._currentLot.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.categoryNameEn} (${item.weightKg.toStringAsFixed(1)} kg)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: kInk,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${item.indicativeValue}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: kRule),
                          const SizedBox(height: 12),

                          // Massive Payout Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: kBoard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  str('total_payout', lang).toUpperCase(),
                                  style: TextStyle(
                                    color: kChalk.withAlpha(180),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹$amount',
                                  style: const TextStyle(
                                    color: kBrass,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid ? kSignal : kAlert,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPaid
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPaid
                                            ? (lang == 'en'
                                                ? 'Paid / Cash Cleared'
                                                : (lang == 'mr'
                                                    ? 'रोख चुकता / Paid'
                                                    : 'नकद प्राप्त / Paid'))
                                            : (lang == 'en'
                                                ? 'Cash Pending'
                                                : (lang == 'mr'
                                                    ? 'रोख प्रलंबित / Cash Pending'
                                                    : 'नकद बकाया / Cash Pending')),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Voice assist readout button ─────────────────────────
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final statusText = isPaid
                              ? (lang == 'en' ? 'Paid in cash.' : (lang == 'mr' ? 'रोख रक्कम मिळाली.' : 'नकद भुगतान प्राप्त।'))
                              : (lang == 'en' ? 'Payment pending in cash.' : (lang == 'mr' ? 'रोख रक्कम बाकी आहे.' : 'नकद भुगतान बाकी है।'));
                          final tts = lang == 'en'
                              ? 'Handover complete. Reference $ref. Payout $amount rupees at $recyclerName. $statusText'
                              : (lang == 'mr'
                                  ? 'हस्तांतरण पूर्ण. संदर्भ $ref. $recyclerName कडून $amount रुपये. $statusText'
                                  : 'हस्तांतरण पूरा हुआ। संदर्भ $ref। $recyclerName से $amount रुपये। $statusText');
                          TtsService().speak(tts, lang);
                        },
                        icon: const Icon(Icons.volume_up, size: 20, color: kInk),
                        label: Text(
                          str('listen_receipt', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kInk),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kRule, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Circular Economy Impact Card ────────────────────────
                    CircularImpactCard(impact: ecoImpact, lang: lang),
                  ],
                ),
              ),
            ),

            // ── Stacked Buttons ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  // Primary 64dp Button: Mark Paid (Cash)
                  if (!isPaid)
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: _markPaid,
                        icon: const Icon(Icons.payments, size: 24),
                        label: Text(
                          str('mark_paid', lang),
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
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: () {
                          final isRecycler = state.role == 'recycler';
                          Navigator.of(context).pushAndRemoveUntil<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => isRecycler
                                  ? const RecyclerHomeScreen()
                                  : const CollectorHomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home, size: 24),
                        label: Text(
                          lang == 'en'
                              ? 'Return to Home'
                              : (lang == 'mr'
                                  ? 'मुख्यपृष्ठावर परत जा'
                                  : 'मुख्य पृष्ठ पर लौटें'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: kSignal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Secondary Button: Share receipt
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    lang == 'en'
                                        ? 'Receipt saved offline (Ref: $ref)'
                                        : (lang == 'mr'
                                            ? 'पावती ऑफलाइन जतन केली (Ref: $ref)'
                                            : 'रसीद ऑफलाइन सुरक्षित की (Ref: $ref)'),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: Text(
                              str('share_receipt', lang),
                              style: const TextStyle(fontSize: 13),
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
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const LedgerScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.account_balance_wallet,
                                size: 18),
                            label: Text(
                              lang == 'en' ? 'View Ledger' : (lang == 'mr' ? 'नोंदवही पहा' : 'बही-खाता देखें'),
                              style: const TextStyle(fontSize: 13),
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
                      ),
                    ],
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
