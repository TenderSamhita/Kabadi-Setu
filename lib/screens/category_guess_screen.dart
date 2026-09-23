import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/category.dart' as cat_model;
import '../strings.dart';
import '../theme.dart';
import 'weigh_screen.dart';

const List<String> _kGuessIds = ['pcb_populated', 'cable', 'mixed_plastic'];

/// Screen shown after the shutter is tapped.
/// Displays the captured scrap thumbnail, optical analysis feedback, and
/// dynamically ranks the top categories while allowing selection from all 10.
class CategoryGuessScreen extends StatefulWidget {
  final List<String>? initialSuggestions;
  final String? detectionReasonKey;
  final Uint8List? capturedImageBytes;

  const CategoryGuessScreen({
    super.key,
    this.initialSuggestions,
    this.detectionReasonKey,
    this.capturedImageBytes,
  });

  @override
  State<CategoryGuessScreen> createState() => _CategoryGuessScreenState();
}

class _CategoryGuessScreenState extends State<CategoryGuessScreen> {
  bool _loading = true;
  late List<String> _guessIds;
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _guessIds = widget.initialSuggestions != null &&
            widget.initialSuggestions!.isNotEmpty
        ? widget.initialSuggestions!
        : _kGuessIds;
    _selectedId = _guessIds.first;

    // NOTE (Hackathon prototype): Per AGENTS.md, this is a short delay
    // followed by placeholder category suggestions, not a trained ML model.
    // Production roadmap: on-device TFLite model.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _confirm() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WeighScreen(categoryId: _selectedId),
      ),
    );
  }

  void _openAllCategoriesSheet(
    BuildContext context,
    AppState state,
    String lang,
  ) {
    final allCats = state.categories.isNotEmpty
        ? state.categories
        : _kGuessIds
            .map((id) => state.categoryById(id))
            .whereType<cat_model.Category>()
            .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: kRule,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet title & close
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: kBrass, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        str('all_categories_title', lang),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kInk,
                        ),
                      ),
                      Text(
                        str('tap_to_select', lang),
                        style: const TextStyle(fontSize: 13, color: kInkSoft),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kInkSoft),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: kRule, height: 1),
            const SizedBox(height: 8),

            // Scrollable list of categories
            Expanded(
              child: ListView.separated(
                itemCount: allCats.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = allCats[index];
                  final isSelected = cat.id == _selectedId;
                  final isHazard = cat.hazardLevel >= 2;

                  return InkWell(
                    key: ValueKey('sheet_cat_${cat.id}'),
                    onTap: () {
                      setState(() => _selectedId = cat.id);
                      Navigator.of(sheetContext).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kBrass.withAlpha(25) : kPaper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kBrass : kRule,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kBrass
                                  : kRule.withAlpha(80),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isHazard
                                  ? Icons.warning_amber_rounded
                                  : Icons.recycling_rounded,
                              color: isSelected
                                  ? kChalk
                                  : (isHazard ? kAlert : kInkSoft),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat.nameFor(lang),
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected ? kBrass : kInk,
                                        ),
                                      ),
                                    ),
                                    if (isHazard)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kAlert.withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: kAlert, width: 1),
                                        ),
                                        child: Text(
                                          '⚠️ ${str('hazard_badge', lang)}',
                                          style: const TextStyle(
                                            color: kAlert,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${cat.ratePerKg}/kg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: kInkSoft,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? kBrass : kInkSoft,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final guessCats = _guessIds
        .map((id) => state.categoryById(id))
        .whereType<cat_model.Category>()
        .toList();

    final customSelectedCat = !_guessIds.contains(_selectedId)
        ? state.categoryById(_selectedId)
        : null;

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          lang == 'en'
              ? 'What is this scrap?'
              : (lang == 'mr' ? 'हे काय आहे?' : 'यह क्या है?'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo thumbnail with live captured image ───────────────────
            Container(
              height: 80,
              color: kBoardDeep,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kBoard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kRule),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.capturedImageBytes != null
                        ? Image.memory(
                            widget.capturedImageBytes!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: kInkSoft,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _loading
                          ? (lang == 'en'
                              ? 'Analyzing scrap...'
                              : (lang == 'mr'
                                  ? 'विश्लेषण चालू...'
                                  : 'विश्लेषण हो रहा है...'))
                          : str(
                              widget.detectionReasonKey ?? 'detected_default',
                              lang,
                            ),
                      style: const TextStyle(
                        color: kChalk,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                lang == 'en'
                    ? 'Select Category'
                    : (lang == 'mr' ? 'श्रेणी निवडा' : 'श्रेणी चुनें'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),

            // ── Category selection area ─────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _loading
                    ? const _LoadingShimmer(key: ValueKey('loading'))
                    : SingleChildScrollView(
                        key: const ValueKey('picker_scroll'),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section header
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    color: kBrass, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    lang == 'mr'
                                        ? 'श्रेणी सूचना — पुष्टी करा किंवा स्वतः निवडा'
                                        : (lang == 'hi'
                                            ? 'श्रेणी सुझाव — पुष्टि करें या मैन्युअल रूप से चुनें'
                                            : 'Category suggestion — confirm or choose manually'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kInkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Top 3 AI Guess cards
                            ...guessCats.map((cat) {
                              final isSelected = cat.id == _selectedId;
                              return GestureDetector(
                                key: ValueKey('guess_tile_${cat.id}'),
                                onTap: () =>
                                    setState(() => _selectedId = cat.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kBrass.withAlpha(20)
                                        : kCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? kBrass : kRule,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isSelected ? kBrass : kRule,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.nameFor(lang),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color:
                                                    isSelected ? kBrass : kInk,
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
                                      if (isSelected)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(right: 16),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: kBrass,
                                            size: 26,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            // Custom selection (if user selected something outside the 3 suggestions)
                            if (customSelectedCat != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                key: const ValueKey('custom_selected_tile'),
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: kBrass.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBrass, width: 2.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: kBrass, size: 26),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  customSelectedCat
                                                      .nameFor(lang),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: kBrass,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      kBrass.withAlpha(40),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  str('selected_badge', lang),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: kBrass,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '₹${customSelectedCat.ratePerKg}/kg',
                                            style: const TextStyle(
                                                fontSize: 14, color: kInkSoft),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (customSelectedCat.hazardLevel >= 2) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kAlert.withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: kAlert, width: 1),
                                        ),
                                        child: Text(
                                          '⚠️ ${str('hazard_badge', lang)}',
                                          style: const TextStyle(
                                            color: kAlert,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 6),

                            // "Something else? View all 10 categories" button
                            OutlinedButton.icon(
                              key: const ValueKey('view_all_categories_btn'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                side: const BorderSide(
                                    color: kBrass, width: 1.5),
                                backgroundColor: kCard,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                color: kBrass,
                                size: 20,
                              ),
                              label: Text(
                                str('choose_other_category', lang),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kBrass,
                                ),
                              ),
                              onPressed: () => _openAllCategoriesSheet(
                                  context, state, lang),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
              ),
            ),

            // ── Confirm button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: FilledButton(
                onPressed: _loading ? null : _confirm,
                child: Text(
                  lang == 'en'
                      ? 'Confirm Category'
                      : (lang == 'mr'
                          ? 'श्रेणी निश्चित करा'
                          : 'श्रेणी की पुष्टि करें'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer({super.key});

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 74,
              decoration: BoxDecoration(
                color: kRule.withAlpha((_anim.value * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

