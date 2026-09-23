import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/geo_service.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'handover_screen.dart';

/// Screen 8: Recycler Match Screen
/// Displays the 5 seed recyclers ranked by net in pocket and distance.
/// Features prominent net-payout numerals, CPCB badges, transport cost indicators,
/// TTS audio cues, and selection leading to the Handover QR screen.
class RecyclerMatchScreen extends StatefulWidget {
  const RecyclerMatchScreen({super.key});

  @override
  State<RecyclerMatchScreen> createState() => _RecyclerMatchScreenState();
}

class _RecyclerMatchScreenState extends State<RecyclerMatchScreen> {
  String? _selectedRecyclerId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final lot = state.draftLot;
    final recyclers = state.recyclers;

    if (lot == null || recyclers.isEmpty) {
      return Scaffold(
        backgroundColor: kPaper,
        appBar: AppBar(title: Text(str('find_recycler', lang))),
        body: Center(
          child: Text(
            lang == 'en'
                ? 'No recyclers available'
                : (lang == 'mr' ? 'पुनर्चक्रक उपलब्ध नाहीत' : 'पुनर्चक्रक उपलब्ध नहीं हैं'),
            style: const TextStyle(fontSize: 18, color: kInk),
          ),
        ),
      );
    }

    // Rank recyclers offline using Haversine distance and transport deduction
    final rankedMatches = rankRecyclers(recyclers: recyclers, lot: lot);

    // Default selection to top match
    _selectedRecyclerId ??= rankedMatches.first.recycler.id;
    final selectedMatch = rankedMatches.firstWhere(
      (m) => m.recycler.id == _selectedRecyclerId,
      orElse: () => rankedMatches.first,
    );

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        title: Text(str('find_recycler', lang)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Offline status alert bar ──────────────────────────────────
            Container(
              color: kBoardDeep,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: kSignal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        str('verified_centers', lang),
                        style: const TextStyle(
                          color: kChalk,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'GPS (Nagpur)',
                    style: TextStyle(
                      color: kBrass,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Header context ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str('recyclers_near_you', lang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        Text(
                          lang == 'en'
                              ? 'Direct Guaranteed Price • Cash or Bank'
                              : (lang == 'mr'
                                  ? 'थेट हमीभाव • रोख किंवा बँक'
                                  : 'सीधा गारंटी भाव • नकद या बैंक'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: kInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kRule),
                    ),
                    child: Text(
                      '${rankedMatches.length} Centers',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kInkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Ranked Recycler Cards List ────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                itemCount: rankedMatches.length,
                itemBuilder: (context, index) {
                  final match = rankedMatches[index];
                  final isTopMatch = index == 0;
                  final isSelected = match.recycler.id == _selectedRecyclerId;

                  return _RecyclerCard(
                    match: match,
                    isTopMatch: isTopMatch,
                    isSelected: isSelected,
                    lang: lang,
                    onTap: () {
                      setState(() {
                        _selectedRecyclerId = match.recycler.id;
                      });
                    },
                  );
                },
              ),
            ),

            // ── Bottom Action Button (64dp tall) ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: () {
                    // Match the draft lot to the selected recycler
                    state.matchDraftToRecycler(
                      recyclerId: selectedMatch.recycler.id,
                      recyclerName: selectedMatch.recycler.name,
                      agreedPrice: selectedMatch.netInPocket,
                    );

                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const HandoverScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2, size: 26),
                  label: Text(
                    str('proceed_handover', lang),
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

// ── Recycler Card Widget ──────────────────────────────────────────────────────

class _RecyclerCard extends StatelessWidget {
  final RecyclerMatch match;
  final bool isTopMatch;
  final bool isSelected;
  final String lang;
  final VoidCallback onTap;

  const _RecyclerCard({
    required this.match,
    required this.isTopMatch,
    required this.isSelected,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final recycler = match.recycler;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kBrass : kRule,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kBrass.withAlpha(35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top tag bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // CPCB Authorised Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: recycler.authorised
                        ? kSignal.withAlpha(25)
                        : kAlert.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        recycler.authorised ? Icons.verified : Icons.warning_amber,
                        size: 15,
                        color: recycler.authorised ? kSignal : kAlert,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recycler.authorised
                            ? str('cpcb_authorised', lang)
                            : str('not_authorised', lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: recycler.authorised ? kSignal : kAlert,
                        ),
                      ),
                    ],
                  ),
                ),

                // Best Value Badge
                if (isTopMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kBrass.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, size: 15, color: kBrass),
                        const SizedBox(width: 4),
                        Text(
                          str('best_value', lang),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kBrass,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Recycler name & TTS button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recycler.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Distance and Pickup status
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 16, color: kInkSoft),
                          const SizedBox(width: 2),
                          Text(
                            '${match.distanceKm.toStringAsFixed(1)} ${str('km_away', lang)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kInkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('•',
                              style: TextStyle(color: kRule)),
                          const SizedBox(width: 8),
                          Icon(
                            recycler.pickupAvailable
                                ? Icons.local_shipping
                                : Icons.directions_car_outlined,
                            size: 16,
                            color: recycler.pickupAvailable
                                ? kSignal
                                : kInkSoft,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recycler.pickupAvailable
                                ? str('free_pickup', lang)
                                : '${str('self_transport', lang)} (-₹${match.transportCost})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: recycler.pickupAvailable
                                  ? kSignal
                                  : kInkSoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // TTS Audio Cue Button
                IconButton.filledTonal(
                  onPressed: () {
                    final pickupText = recycler.pickupAvailable
                        ? (lang == 'en'
                            ? 'Free pickup'
                            : (lang == 'mr' ? 'मोफत पिकअप' : 'मुफ़्त पिकअप'))
                        : (lang == 'en'
                            ? 'Transport deducted'
                            : (lang == 'mr' ? 'वाहतूक खर्च वजा' : 'परिवहन कटौती'));
                    final ttsText = lang == 'en'
                        ? '${recycler.name}. Distance ${match.distanceKm.toStringAsFixed(1)} kilometers. Payout ${match.netInPocket} rupees. $pickupText.'
                        : (lang == 'mr'
                            ? '${recycler.name}. अंतर ${match.distanceKm.toStringAsFixed(1)} किलोमीटर. मिळतील ${match.netInPocket} रुपये. $pickupText.'
                            : '${recycler.name}. दूरी ${match.distanceKm.toStringAsFixed(1)} किलोमीटर. मिलेंगे ${match.netInPocket} रुपये. $pickupText.');
                    TtsService().speak(ttsText, lang);
                  },
                  icon: const Icon(Icons.volume_up, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: kPaper,
                    foregroundColor: kInk,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payout Section: Largest figure on card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        str('you_keep', lang).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kInkSoft,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${match.netInPocket}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: kInk,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lang == 'en'
                                ? 'Net In Hand'
                                : (lang == 'mr' ? 'निव्वळ रक्कम' : 'शुद्ध राशि'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: kInkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Radio selection indicator
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? kBrass : kRule,
                    size: 28,
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
