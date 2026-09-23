import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/lot.dart';
import '../strings.dart';
import '../theme.dart';
import 'quote_screen.dart';
import 'safety_interstitial_screen.dart';

/// Weight entry screen.
/// Supports direct numeric typing, quick-add preset chips (+2, +5, +10, +25 kg),
/// and circular +/− stepper buttons (0.5 kg increments).
class WeighScreen extends StatefulWidget {
  final String categoryId;

  const WeighScreen({super.key, required this.categoryId});

  @override
  State<WeighScreen> createState() => _WeighScreenState();
}

class _WeighScreenState extends State<WeighScreen> {
  double _weightKg = 1.0;
  static const double _step = 0.5;
  static const double _min = 0.1;
  static const double _max = 9999.0;

  late final TextEditingController _weightController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _formatWeight(_weightKg));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _onEditingComplete();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatWeight(double val) {
    if (val == val.roundToDouble()) {
      return val.toStringAsFixed(0);
    }
    return val.toStringAsFixed(1);
  }

  void _increment([double amount = _step]) {
    setState(() {
      _weightKg = (_weightKg + amount).clamp(_min, _max);
      _weightController.text = _formatWeight(_weightKg);
    });
  }

  void _decrement([double amount = _step]) {
    setState(() {
      _weightKg = (_weightKg - amount).clamp(_min, _max);
      _weightController.text = _formatWeight(_weightKg);
    });
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _weightKg = 0.0;
      });
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed != null && parsed >= 0) {
      setState(() {
        _weightKg = parsed > _max ? _max : parsed;
      });
    }
  }

  void _onEditingComplete() {
    if (_weightKg < _min) {
      setState(() {
        _weightKg = _min;
        _weightController.text = _formatWeight(_min);
      });
    } else {
      _weightController.text = _formatWeight(_weightKg);
    }
    _focusNode.unfocus();
  }

  void _confirm(BuildContext context) {
    _focusNode.unfocus();
    final text = _weightController.text.trim();
    final parsed = double.tryParse(text);
    double finalWeight = _weightKg;
    if (parsed != null && parsed > 0) {
      finalWeight = parsed.clamp(_min, _max);
    } else if (finalWeight < _min) {
      finalWeight = _min;
    }

    final appState = context.read<AppState>();
    final cat = appState.categoryById(widget.categoryId);
    if (cat == null) return;

    appState.addItemToDraft(
      LotItem(
        categoryId: cat.id,
        categoryNameEn: cat.nameEn,
        weightKg: finalWeight,
        ratePerKg: cat.ratePerKg,
        photoPath: null, // Photo path placeholder — see capture_screen.dart
      ),
    );

    // If item has hazardLevel >= 2, show safety interstitial before quote screen
    if (cat.hazardLevel >= 2) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SafetyInterstitialScreen(
            category: cat,
            onContinue: () {
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute<void>(builder: (_) => const QuoteScreen()),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const QuoteScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final cat = state.categoryById(widget.categoryId);

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(str('record_weight', lang)),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // ── Category header ────────────────────────────────────
                      if (cat != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kRule),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  color: kBrass, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.nameFor(lang),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: kInk,
                                      ),
                                    ),
                                    Text(
                                      '₹${cat.ratePerKg}/kg',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: kInkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── Weight Box with Direct Typing ──────────────────────
                      GestureDetector(
                        onTap: () {
                          _focusNode.requestFocus();
                          _weightController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _weightController.text.length,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _focusNode.hasFocus ? kBrass : kRule,
                              width: _focusNode.hasFocus ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _focusNode.hasFocus
                                    ? kBrass.withAlpha(35)
                                    : Colors.black.withAlpha(8),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  IntrinsicWidth(
                                    child: TextField(
                                      key: const ValueKey('weight_input_field'),
                                      controller: _weightController,
                                      focusNode: _focusNode,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.w900,
                                        color: kInk,
                                        fontFamily: 'sans-serif',
                                        height: 1.1,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: '0',
                                      ),
                                      onChanged: _onTextChanged,
                                      onSubmitted: (_) => _onEditingComplete(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'kg',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: kInkSoft,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_note_rounded,
                                      size: 18, color: kBrass),
                                  const SizedBox(width: 4),
                                  Text(
                                    str('type_weight', lang),
                                    style: const TextStyle(
                                      color: kBrass,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Quick Add Preset Chips ─────────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _QuickAddChip(
                            label: '+2 kg',
                            onTap: () => _increment(2.0),
                          ),
                          _QuickAddChip(
                            label: '+5 kg',
                            onTap: () => _increment(5.0),
                          ),
                          _QuickAddChip(
                            label: '+10 kg',
                            onTap: () => _increment(10.0),
                          ),
                          _QuickAddChip(
                            label: '+25 kg',
                            onTap: () => _increment(25.0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Fine-tuning Stepper Buttons ────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StepButton(
                              icon: Icons.remove,
                              onTap: () => _decrement(_step),
                              enabled: _weightKg > _min,
                            ),
                            Column(
                              children: [
                                Text(
                                  '±${_step.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    color: kInk,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  lang == 'en'
                                      ? 'Fine tune'
                                      : (lang == 'mr'
                                          ? 'बारीक समायोजन'
                                          : 'सूक्ष्म समायोजन'),
                                  style: const TextStyle(
                                      color: kInkSoft, fontSize: 12),
                                ),
                              ],
                            ),
                            _StepButton(
                              icon: Icons.add,
                              onTap: () => _increment(_step),
                              enabled: _weightKg < _max,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Indicative value preview ───────────────────────────
                      if (cat != null)
                        Center(
                          child: Text(
                            '≈ ₹${(_weightKg * cat.ratePerKg).round()}',
                            style: const TextStyle(
                              color: kBrass,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Primary 64dp action ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: () => _confirm(context),
                    child: Text(
                      lang == 'en'
                          ? 'View Rates →'
                          : (lang == 'mr' ? 'भाव पाहा →' : 'दर देखें →'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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

/// Quick addition chip for bulk weighing (+2kg, +5kg, etc.)
class _QuickAddChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAddChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kRule),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kInk,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular +/− stepper button with brass accent.
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? kBrass : kRule,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            icon,
            size: 28,
            color: enabled ? kChalk : kInkSoft,
          ),
        ),
      ),
    );
  }
}

