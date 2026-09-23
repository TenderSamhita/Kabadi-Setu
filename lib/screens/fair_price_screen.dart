import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/geo_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'recycler_match_screen.dart';

/// FairPriceScreen — P1 feature.
///
/// Shows side-by-side price comparison:
///   • Local dealer / middleman estimate (55% of seed rate — labeled as estimate)
///   • Each authorised recycler's offered price for this exact lot
///
/// All data comes from existing AppState (seed + overrides). No network calls.
/// Tapping "Find Recycler" navigates to the existing RecyclerMatchScreen.
class FairPriceScreen extends StatelessWidget {
  const FairPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final lot = state.draftLot;

    if (lot == null || lot.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fair Price')),
        body: const Center(child: Text('No items to compare')),
      );
    }

    // Middleman / local dealer reference: 55% of the lot's indicative value.
    // Labeled explicitly as a local dealer estimate — not presented as a fact.
    final middlemanTotal = (lot.indicativeValue * 0.55).round();

    // Build ranked recycler list using existing geo service
    final rankedMatches = rankRecyclers(recyclers: state.recyclers, lot: lot);

    // Best recycler net payout
    final bestNet = rankedMatches.isEmpty ? 0 : rankedMatches.first.netInPocket;
    final gain = bestNet - middlemanTotal;

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        title: Text(
          lang == 'mr'
              ? 'न्याय्य किंमत तुलना'
              : (lang == 'hi' ? 'उचित मूल्य तुलना' : 'Fair Price Comparison'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Lot summary strip ─────────────────────────────────────────
            Container(
              color: kBoard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: kBrass, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${lot.items.map((i) => i.categoryNameEn).join(', ')} — ${lot.totalWeightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: kChalk,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Gain callout ────────────────────────────────────────
                    if (gain > 0)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: kSignal.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kSignal.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: kSignal, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang == 'mr'
                                        ? 'जास्त मिळू शकते'
                                        : (lang == 'hi'
                                            ? 'अधिक मिल सकता है'
                                            : 'You could earn more'),
                                    style: const TextStyle(
                                      color: kSignal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '+ ₹$gain',
                                    style: const TextStyle(
                                      color: kSignal,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    lang == 'mr'
                                        ? 'अधिकृत पुनर्चक्रक निवडल्यास'
                                        : (lang == 'hi'
                                            ? 'अधिकृत रिसायकलर चुनने पर'
                                            : 'by choosing an authorised recycler'),
                                    style: TextStyle(
                                      color: kSignal.withAlpha(180),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Section label ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        lang == 'mr'
                            ? 'YOUR LOT साठी किंमत'
                            : (lang == 'hi'
                                ? 'आपके लॉट के लिए मूल्य'
                                : 'PRICE FOR YOUR LOT'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kInkSoft,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    // ── Local dealer row ────────────────────────────────────
                    _PriceRow(
                      rank: null,
                      label: lang == 'mr'
                          ? 'स्थानिक डीलर (अंदाज)'
                          : (lang == 'hi'
                              ? 'स्थानीय डीलर (अनुमान)'
                              : 'Local Dealer (estimate)'),
                      sublabel: lang == 'mr'
                          ? 'मध्यस्थ — बाजारभावापेक्षा कमी'
                          : (lang == 'hi'
                              ? 'बिचौलिया — बाजार दर से कम'
                              : 'Middleman — typically below market'),
                      totalValue: middlemanTotal,
                      isAuthorised: false,
                      isBest: false,
                      isMiddleman: true,
                    ),

                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: kRule)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kInkSoft,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: kRule)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ── Recycler rows ───────────────────────────────────────
                    ...rankedMatches.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final match = entry.value;
                      return _PriceRow(
                        rank: idx + 1,
                        label: match.recycler.name,
                        sublabel: match.recycler.pickupAvailable
                            ? (lang == 'mr'
                                ? 'मोफत पिकअप · ${match.distanceKm.toStringAsFixed(1)} km'
                                : (lang == 'hi'
                                    ? 'मुफ़्त पिकअप · ${match.distanceKm.toStringAsFixed(1)} km'
                                    : 'Free pickup · ${match.distanceKm.toStringAsFixed(1)} km away'))
                            : (lang == 'mr'
                                ? 'स्वतः जा · वाहतूक -₹${match.transportCost}'
                                : (lang == 'hi'
                                    ? 'खुद जाएं · परिवहन -₹${match.transportCost}'
                                    : 'Self-transport · -₹${match.transportCost} cost')),
                        totalValue: match.netInPocket,
                        isAuthorised: match.recycler.authorised,
                        isBest: idx == 0,
                        isMiddleman: false,
                      );
                    }),

                    const SizedBox(height: 12),

                    // ── Disclaimer ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kRule),
                      ),
                      child: Text(
                        lang == 'mr'
                            ? '* स्थानिक डीलर अंदाज बाजारभावाच्या ~55% वर आधारित आहे. वास्तविक दर वेगळे असू शकतात. अधिकृत पुनर्चक्रक दर थेट त्यांच्याकडून आहेत.'
                            : (lang == 'hi'
                                ? '* स्थानीय डीलर अनुमान बाजार दर के ~55% पर आधारित है। वास्तविक दर भिन्न हो सकते हैं। अधिकृत रिसायकलर दर सीधे उनके स्रोत से हैं।'
                                : '* Local dealer estimate is based on ~55% of market rate. Actual rates vary. Authorised recycler rates are sourced directly from them.'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: kInkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Primary CTA ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecyclerMatchScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.search, size: 24),
                  label: Text(
                    str('find_recycler', lang),
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

// ── Price row widget ──────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final int? rank;
  final String label;
  final String sublabel;
  final int totalValue;
  final bool isAuthorised;
  final bool isBest;
  final bool isMiddleman;

  const _PriceRow({
    required this.rank,
    required this.label,
    required this.sublabel,
    required this.totalValue,
    required this.isAuthorised,
    required this.isBest,
    required this.isMiddleman,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isMiddleman
        ? kRule
        : (isBest ? kBrass : kRule);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBest ? kBrass.withAlpha(15) : kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isBest ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank circle or middleman icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isMiddleman
                  ? kAlert.withAlpha(20)
                  : (isBest ? kBrass : kBoard.withAlpha(30)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isMiddleman
                  ? const Icon(Icons.storefront, size: 18, color: kAlert)
                  : (rank != null
                      ? Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isBest ? kBoardDeep : kChalk,
                          ),
                        )
                      : const Icon(Icons.storefront,
                          size: 18, color: kInkSoft)),
            ),
          ),
          const SizedBox(width: 12),

          // Name + sublabel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isMiddleman ? kInkSoft : kInk,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAuthorised && !isMiddleman) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 13, color: kSignal),
                    ],
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: kBrass,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BEST',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: kBoardDeep,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMiddleman ? kAlert : kInkSoft,
                  ),
                ),
              ],
            ),
          ),

          // Total value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$totalValue',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isMiddleman
                      ? kInkSoft
                      : (isBest ? kBrass : kInk),
                ),
              ),
              Text(
                'total',
                style: TextStyle(
                  fontSize: 10,
                  color: isMiddleman ? kRule : kInkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
