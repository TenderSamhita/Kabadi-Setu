import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/category.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';

/// Screen 13: Safety Interstitial Screen
/// Interruption shown before the Quote screen whenever an added item
/// has hazardLevel >= 2 (e.g. Lithium-ion battery, CRT glass, Lead-acid battery).
/// Displays warm alert iconography, instructions, audio readout, and a 64dp continue button.
class SafetyInterstitialScreen extends StatelessWidget {
  final Category category;
  final VoidCallback onContinue;

  const SafetyInterstitialScreen({
    super.key,
    required this.category,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    // Custom copy per category
    final String titleText;
    final String englishTitle;
    final String instructionText;
    final String englishInstruction;
    final IconData hazardIcon;

    if (category.id == 'crt_glass') {
      titleText = str('crt_warning', lang);
      englishTitle = 'Handle CRT Leaded Glass with Care!';
      instructionText = str('crt_instruction', lang);
      englishInstruction =
          'Leaded vacuum glass is toxic. Store in heavy-duty cardboard.';
      hazardIcon = Icons.tv_off;
    } else if (category.id == 'battery_leadacid') {
      titleText = str('lead_warning', lang);
      englishTitle = 'Do Not Tip or Spill Battery Acid!';
      instructionText = str('lead_instruction', lang);
      englishInstruction =
          'Corrosive sulfuric acid burns skin. Use heavy rubber gloves.';
      hazardIcon = Icons.battery_alert;
    } else {
      // Default / Lithium battery
      titleText = str('battery_warning', lang);
      englishTitle = 'Do Not Puncture or Burn Batteries!';
      instructionText = str('battery_instruction', lang);
      englishInstruction =
          'Risk of toxic fumes and fire. Keep separate in a dry crate.';
      hazardIcon = Icons.battery_charging_full;
    }

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(str('safety_title', lang)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              // ── Top Safety Context Strip ─────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kAlert,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          str('hazard_check', lang),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LEVEL ${category.hazardLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Primary Elevated Safety Card ─────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kRule),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Safety Alert Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: kAlert.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning,
                                  size: 18, color: kAlert),
                              const SizedBox(width: 6),
                              Text(
                                str('safety_alert', lang).toUpperCase(),
                                style: const TextStyle(
                                  color: kAlert,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Hazard Graphic Illustration Box
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: kPaper,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: kAlert.withAlpha(50), width: 2),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                hazardIcon,
                                size: 72,
                                color: kAlert,
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kAlert,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category.nameEn.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title with Audio TTS Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: kBoard,
                                    ),
                                  ),
                                  Text(
                                    englishTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kInkSoft,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () {
                                final ttsText = '$titleText $instructionText';
                                TtsService().speak(ttsText, lang);
                              },
                              icon: const Icon(Icons.volume_up, size: 24),
                              style: IconButton.styleFrom(
                                backgroundColor: kPaper,
                                foregroundColor: kInk,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Explanation Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPaper,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kRule),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instructionText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: kInk,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                englishInstruction,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kInkSoft,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Field Micro-checks
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kSignal.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: kSignal.withAlpha(40)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 20, color: kSignal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        lang == 'en'
                                            ? 'Keep in plastic crate'
                                            : (lang == 'mr'
                                                ? 'प्लास्टिक टबमध्ये ठेवा'
                                                : 'प्लास्टिक क्रेट में रखें'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: kInk,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kAlert.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: kAlert.withAlpha(40)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cancel,
                                        size: 20, color: kAlert),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        lang == 'en'
                                            ? 'Keep away from water'
                                            : (lang == 'mr'
                                                ? 'पाण्यापासून दूर ठेवा'
                                                : 'पानी से दूर रखें'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: kInk,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Primary 64dp Continue Button ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.check_circle_outline, size: 24),
                  label: Text(
                    str('safety_ok', lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: kBoard,
                    foregroundColor: kChalk,
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
