import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/lot.dart';
import '../services/eco_impact_service.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/circular_impact_card.dart';
import 'capture_screen.dart';
import 'fair_price_screen.dart';
import 'recycler_match_screen.dart';

/// Quote screen — shows the full draft lot summary with a ±15% price range.
/// "Add another item" navigates to a fresh CaptureScreen (lot stays open).
/// "Find Recycler" navigates to the Recycler Match screen (Milestone 4).
class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final lot = state.draftLot;

    if (lot == null || lot.items.isEmpty) {
      // Guard: should never happen in normal flow
      return Scaffold(
        appBar: AppBar(title: Text(str('your_quote', lang))),
        body: Center(
          child: Text(
            lang == 'en' ? 'No items in quote' : (lang == 'mr' ? 'कोणतेही साहित्य नाही' : 'कोई सामग्री नहीं'),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final base = lot.indicativeValue;
    final low = (base * 0.85).round();
    final high = (base * 1.15).round();
    final ecoImpact = EcoImpactService.compute(lot);

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(str('your_quote', lang)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Item list ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Items
                    ...lot.items.map(
                      (item) => _ItemRow(item: item, lang: lang),
                    ),

                    const SizedBox(height: 4),
                    const Divider(color: kRule, thickness: 1),
                    const SizedBox(height: 4),

                    // Total weight
                    Row(
                      children: [
                        const Icon(Icons.scale_outlined,
                            size: 18, color: kInkSoft),
                        const SizedBox(width: 8),
                        Text(
                          '${lang == 'en' ? 'Total weight' : (lang == 'mr' ? 'एकूण वजन' : 'कुल वज़न')}  ${lot.totalWeightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            color: kInkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Price range card ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kBoard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            lang == 'en'
                                ? 'Expected Value'
                                : (lang == 'mr'
                                    ? 'अपेक्षित किंमत'
                                    : 'अपेक्षित मूल्य'),
                            style: TextStyle(
                              color: kChalk.withAlpha(180),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Note stack + price range side by side
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _NoteStack(value: base),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Large price range
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: kBrass,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 36,
                                        fontFamily: 'sans-serif',
                                      ),
                                      children: [
                                        const TextSpan(text: '₹'),
                                        TextSpan(
                                            text:
                                                '$low'),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '– ₹$high',
                                    style: const TextStyle(
                                      color: kBrass,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '±15%  •  ${lot.items.length} ${lang == 'en' ? (lot.items.length == 1 ? 'item' : 'items') : (lang == 'mr' ? 'वस्तू' : 'वस्तु')}',
                                    style: TextStyle(
                                      color: kChalk.withAlpha(140),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Voice assist readout button
                          SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final text = lang == 'en'
                                    ? 'Expected value $low to $high rupees for ${lot.totalWeightKg.toStringAsFixed(1)} kilograms of e-waste.'
                                    : (lang == 'mr'
                                        ? '${lot.totalWeightKg.toStringAsFixed(1)} किलो ई-कचऱ्यासाठी अंदाजे किंमत $low ते $high रुपये.'
                                        : '${lot.totalWeightKg.toStringAsFixed(1)} किलो ई-कचरे के लिए अनुमानित मूल्य ₹$low से ₹$high तक है।');
                                TtsService().speak(text, lang);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kBrass,
                                side: const BorderSide(color: kBrass, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.volume_up, size: 18),
                              label: Text(
                                str('listen_quote', lang),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Circular Economy & Mineral Recovery Impact Card ─────
                    CircularImpactCard(impact: ecoImpact, lang: lang),

                    const SizedBox(height: 12),

                    // ── Calculation breakdown (expandable) ─────────────────
                    _CalculationBreakdown(lot: lot, lang: lang),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Action buttons ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                      builder: (_) => const CaptureScreen()),
                ),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  lang == 'en'
                      ? 'Add Another Item'
                      : (lang == 'mr'
                          ? 'आणखी साहित्य जोडा'
                          : 'और सामग्री जोड़ें'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kInk,
                  side: const BorderSide(color: kRule, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            // Compare Prices — new P1 feature
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                      builder: (_) => const FairPriceScreen()),
                ),
                icon: const Icon(Icons.compare_arrows, color: kSignal),
                label: Text(
                  lang == 'mr'
                      ? 'किंमत तुलना करा'
                      : (lang == 'hi' ? 'कीमत तुलना करें' : 'Compare Prices'),
                  style: const TextStyle(fontSize: 16, color: kSignal),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kSignal,
                  side: const BorderSide(color: kSignal, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                      builder: (_) => const RecyclerMatchScreen()),
                ),
                icon: const Icon(Icons.search),
                label: Text(str('find_recycler', lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final LotItem item;
  final String lang;

  const _ItemRow({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    // LotItem stores the English name at capture time; Category is not re-looked
    // up here to avoid coupling QuoteScreen to AppState for display only.
    final name = item.categoryNameEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kRule),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: kBrass, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
                Text(
                  '${item.weightKg.toStringAsFixed(1)} kg  ×  ₹${item.ratePerKg}/kg',
                  style: const TextStyle(fontSize: 14, color: kInkSoft),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.indicativeValue}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kBrass,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Note stack visual ─────────────────────────────────────────────────────────

/// Draws stacked "currency note" shapes to visualise the lot value.
class _NoteStack extends StatelessWidget {
  final int value;

  const _NoteStack({required this.value});

  @override
  Widget build(BuildContext context) {
    final count = value < 200
        ? 2
        : value < 500
            ? 3
            : value < 1000
                ? 4
                : 5;

    return SizedBox(
      width: 72,
      height: 44 + (count - 1) * 9.0,
      child: Stack(
        children: List.generate(count, (i) {
          final alpha = (60 + i * 40).clamp(0, 255);
          return Positioned(
            top: (count - 1 - i) * 9.0,
            child: Container(
              width: 72,
              height: 40,
              decoration: BoxDecoration(
                color: kBrass.withAlpha(alpha),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: kBrass, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(Icons.currency_rupee,
                      color: kChalk, size: 14),
                  Container(width: 20, height: 2,
                      color: kChalk.withAlpha(120)),
                  Container(width: 12, height: 2,
                      color: kChalk.withAlpha(120)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Calculation Breakdown (P3) ────────────────────────────────────────────────

/// Expandable "How is this calculated?" section.
/// Uses existing lot data — no new state required.
/// Clearly labels this as a prototype using weight × rate.
class _CalculationBreakdown extends StatefulWidget {
  final Lot lot;
  final String lang;

  const _CalculationBreakdown({required this.lot, required this.lang});

  @override
  State<_CalculationBreakdown> createState() => _CalculationBreakdownState();
}

class _CalculationBreakdownState extends State<_CalculationBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final lot = widget.lot;
    final base = lot.indicativeValue;
    final low = (base * 0.85).round();
    final high = (base * 1.15).round();

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRule),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, size: 18, color: kBrass),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == 'mr'
                          ? 'हे कसे मोजले जाते?'
                          : (lang == 'hi'
                              ? 'यह कैसे गणना की जाती है?'
                              : 'How is this calculated?'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: kInkSoft,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: kRule),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...lot.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.categoryNameEn,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _CalcRow(
                              label: lang == 'mr' ? 'वजन' : (lang == 'hi' ? 'वज़न' : 'Weight'),
                              value: '${item.weightKg.toStringAsFixed(1)} kg',
                            ),
                            _CalcRow(
                              label: lang == 'mr' ? 'दर' : (lang == 'hi' ? 'दर' : 'Rate'),
                              value: '₹${item.ratePerKg}/kg',
                            ),
                            _CalcRow(
                              label: lang == 'mr' ? 'गणना' : (lang == 'hi' ? 'गणना' : 'Calculation'),
                              value: '${item.weightKg.toStringAsFixed(1)} × ₹${item.ratePerKg} = ₹${item.indicativeValue}',
                              highlight: true,
                            ),
                          ],
                        ),
                      )),
                  if (lot.items.length > 1) ...[
                    const Divider(color: kRule, height: 16),
                    _CalcRow(
                      label: lang == 'mr' ? 'एकूण' : (lang == 'hi' ? 'कुल' : 'Total'),
                      value: '₹$base',
                      highlight: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(color: kRule, height: 8),
                  const SizedBox(height: 4),
                  _CalcRow(
                    label: lang == 'mr' ? 'बाजार श्रेणी' : (lang == 'hi' ? 'बाजार सीमा' : 'Market range'),
                    value: '±15% → ₹$low – ₹$high',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBrass.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBrass.withAlpha(60)),
                    ),
                    child: Text(
                      lang == 'mr'
                          ? 'वजन × साहित्य दर वापरून अंदाज. हे प्रोटोटाइप आहे; उत्पादन आवृत्ती प्रमाणित वजन यंत्र डेटा वापरेल.'
                          : (lang == 'hi'
                              ? 'वज़न × सामग्री दर से अनुमान। यह प्रोटोटाइप है; उत्पादन संस्करण प्रमाणित तौल डेटा उपयोग करेगा।'
                              : 'Estimate = weight × material rate. This is a prototype — production will use certified weighbridge data.'),
                      style: const TextStyle(fontSize: 11, color: kInk, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _CalcRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: kInkSoft,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    color: highlight ? kBrass : kInk,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}
