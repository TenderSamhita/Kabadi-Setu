import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/category.dart' as cat_model;
import '../theme.dart';
import 'rate_card_qr_screen.dart';

/// RateEditorScreen — Recycler role only.
///
/// Lets the recycler raise or lower their offered buy-price for each of the
/// 10 e-waste categories. Changes are saved to shared_preferences (overrides
/// the seed JSON at runtime, never writes to it). After saving, the recycler
/// can generate a Rate Card QR for collectors to scan.
class RateEditorScreen extends StatefulWidget {
  /// The recycler ID whose rates are being edited.
  final String recyclerId;
  final String recyclerName;

  const RateEditorScreen({
    super.key,
    required this.recyclerId,
    required this.recyclerName,
  });

  @override
  State<RateEditorScreen> createState() => _RateEditorScreenState();
}

class _RateEditorScreenState extends State<RateEditorScreen> {
  late Map<String, int> _editedRates;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    // Initialise from existing overrides or from seed values
    _editedRates = {
      for (final cat in state.categories)
        cat.id: state.effectiveRecyclerRate(widget.recyclerId, cat.id),
    };
  }

  void _adjustRate(String categoryId, int delta) {
    setState(() {
      final current = _editedRates[categoryId] ?? 0;
      _editedRates[categoryId] = (current + delta).clamp(1, 9999);
    });
  }

  Future<void> _saveAndGenerate() async {
    final state = context.read<AppState>();
    await state.updateRecyclerRates(widget.recyclerId, _editedRates);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RateCardQrScreen(
          recyclerId: widget.recyclerId,
          recyclerName: widget.recyclerName,
          rates: Map<String, int>.from(_editedRates),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final categories = state.categories;

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'mr'
                  ? 'दर संपादित करा'
                  : (lang == 'hi' ? 'दर संपादित करें' : 'Update My Rates'),
              style: const TextStyle(
                color: kChalk,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.recyclerName,
              style: TextStyle(
                color: kChalk.withAlpha(160),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBrass),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: Column(
        children: [
          // ── Info banner ───────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrass.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBrass.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kBrass, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == 'mr'
                        ? 'दर बदला, QR तयार करा, आणि संग्राहकाला स्कॅन करायला द्या.'
                        : (lang == 'hi'
                            ? 'दर बदलें, QR बनाएं, और संग्राहक को स्कैन कराएं।'
                            : 'Edit rates, generate a Rate Card QR, then ask the collector to scan it.'),
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Category list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _RateRow(
                  category: cat,
                  currentRate: _editedRates[cat.id] ?? cat.ratePerKg,
                  seedRate: cat.ratePerKg,
                  lang: lang,
                  onDecrease: () => _adjustRate(cat.id, -5),
                  onIncrease: () => _adjustRate(cat.id, 5),
                );
              },
            ),
          ),

          // ── Primary action — 64dp tall ────────────────────────────────────
          Container(
            color: kPaper,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton.icon(
                onPressed: _saveAndGenerate,
                icon: const Icon(Icons.qr_code, size: 26),
                label: Text(
                  lang == 'mr'
                      ? 'जतन करा आणि QR तयार करा'
                      : (lang == 'hi'
                          ? 'सहेजें और QR बनाएं'
                          : 'Save & Generate Rate Card QR'),
                  style: const TextStyle(
                    fontSize: 17,
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
    );
  }
}

// ── Per-category rate row ─────────────────────────────────────────────────────

class _RateRow extends StatelessWidget {
  final cat_model.Category category;
  final int currentRate;
  final int seedRate;
  final String lang;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _RateRow({
    required this.category,
    required this.currentRate,
    required this.seedRate,
    required this.lang,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final isAbove = currentRate > seedRate;
    final isBelow = currentRate < seedRate;
    final delta = currentRate - seedRate;
    final deltaColor = isAbove ? kSignal : (isBelow ? kAlert : kInkSoft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAbove
              ? kSignal.withAlpha(80)
              : (isBelow ? kAlert.withAlpha(80) : kRule),
          width: (isAbove || isBelow) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Category name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.nameFor(lang),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
                if (delta != 0)
                  Text(
                    '${isAbove ? '+' : ''}₹$delta vs seed',
                    style: TextStyle(
                      fontSize: 11,
                      color: deltaColor,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    lang == 'mr'
                        ? 'बीज दर'
                        : (lang == 'hi' ? 'बीज दर' : 'Seed rate'),
                    style: const TextStyle(fontSize: 11, color: kInkSoft),
                  ),
              ],
            ),
          ),

          // Stepper
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: onDecrease,
              ),
              Container(
                width: 72,
                alignment: Alignment.center,
                child: Text(
                  '₹$currentRate',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: deltaColor == kInkSoft ? kBrass : deltaColor,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onTap: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: kBoard,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: kBrass, size: 20),
          ),
        ),
      );
}
