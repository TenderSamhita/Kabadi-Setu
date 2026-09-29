import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/price_record.dart';
import '../theme.dart';

/// Price Board Screen — shows current market vs recycler prices for all
/// material categories. Also shows price trend over the last 5 data points
/// and flags any anomalously-low recycler quotes.
///
/// DEMO DATA NOTICE: Market prices are seeded estimates (~55–65% of recycler
/// rate). Real field prices would come from agent data collection.
class PriceBoardScreen extends StatelessWidget {
  const PriceBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final categories = state.categories;

    final title = lang == 'mr'
        ? 'भाव पत्रक'
        : (lang == 'hi' ? 'मूल्य बोर्ड' : 'Price Board');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kPaper,
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            labelColor: kBrass,
            unselectedLabelColor: kInkSoft,
            indicatorColor: kBrass,
            tabs: [
              Tab(
                text: lang == 'mr'
                    ? 'सध्याचे भाव'
                    : (lang == 'hi' ? 'वर्तमान भाव' : 'Current Prices'),
              ),
              Tab(
                text: lang == 'mr'
                    ? 'भाव इतिहास'
                    : (lang == 'hi' ? 'मूल्य इतिहास' : 'Price History'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CurrentPricesTab(lang: lang, state: state, categories: categories),
            _PriceHistoryTab(lang: lang, state: state),
          ],
        ),
      ),
    );
  }
}

// ── Current Prices Tab ────────────────────────────────────────────────────────

class _CurrentPricesTab extends StatelessWidget {
  final String lang;
  final AppState state;
  final List categories;

  const _CurrentPricesTab({
    required this.lang,
    required this.state,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Demo data notice
        Container(
          color: kBrass.withAlpha(25),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: kBrass),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang == 'mr'
                      ? 'DEMO DATA — बाजार भाव अंदाजे आहेत'
                      : (lang == 'hi'
                          ? 'DEMO DATA — बाजार भाव अनुमानित हैं'
                          : 'DEMO DATA — Market prices are estimates'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: kBrass,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table header
        Container(
          color: kBoard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                flex: 3,
                child: Text(
                  lang == 'mr' ? 'साहित्य' : (lang == 'hi' ? 'सामग्री' : 'Material'),
                  style: const TextStyle(color: kChalk, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  lang == 'mr' ? 'बाजार' : (lang == 'hi' ? 'बाजार' : 'Market'),
                  style: const TextStyle(color: kChalk, fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  lang == 'mr' ? 'पुनर्चक्रक' : (lang == 'hi' ? 'रिसायकलर' : 'Recycler'),
                  style: const TextStyle(color: kBrass, fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  lang == 'mr' ? 'फायदा' : (lang == 'hi' ? 'फायदा' : 'Gain'),
                  style: const TextStyle(color: kSignal, fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Price rows
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final latest = state.latestPriceFor(cat.id);
              final recyclerRate = state.effectiveRateForCategory(cat.id);
              final marketPrice = latest?.marketPrice ?? (recyclerRate * 0.55).round();
              final gain = recyclerRate - marketPrice;

              return Container(
                decoration: BoxDecoration(
                  color: i.isEven ? kCard : kPaper,
                  border: const Border(bottom: BorderSide(color: kRule, width: 0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Hazard indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat.hazardLevel >= 2
                            ? kAlert
                            : (cat.hazardLevel == 1 ? kBrass : kSignal),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.nameFor(lang),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                          Text(
                            '/kg',
                            style: const TextStyle(fontSize: 10, color: kInkSoft),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹$marketPrice',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kInkSoft,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹$recyclerRate',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kBrass,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '+₹$gain',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: gain > 0 ? kSignal : kInkSoft,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Price History Tab ─────────────────────────────────────────────────────────

class _PriceHistoryTab extends StatefulWidget {
  final String lang;
  final AppState state;

  const _PriceHistoryTab({required this.lang, required this.state});

  @override
  State<_PriceHistoryTab> createState() => _PriceHistoryTabState();
}

class _PriceHistoryTabState extends State<_PriceHistoryTab> {
  String _selectedCategoryId = 'pcb_populated';

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final state = widget.state;
    final allRecords = state.priceHistory;

    // Category filter chips
    final availableCategories = state.categories.where(
      (c) => allRecords.any((r) => r.materialCategory == c.id),
    ).toList();

    final records = state.historyForCategory(_selectedCategoryId).take(10).toList();

    return Column(
      children: [
        // Category selector
        Container(
          height: 48,
          color: kCard,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: availableCategories.length,
            itemBuilder: (context, i) {
              final cat = availableCategories[i];
              final isSelected = cat.id == _selectedCategoryId;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? kBrass : kPaper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? kBrass : kRule),
                  ),
                  child: Text(
                    cat.nameFor(lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? kBoardDeep : kInk,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Simple bar chart (sparkline)
        if (records.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kRule),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'mr'
                      ? 'भाव इतिहास (₹/kg)'
                      : (lang == 'hi' ? 'मूल्य इतिहास (₹/kg)' : 'Price Trend (₹/kg)'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 12),
                _SimpleTrendChart(records: records),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: kBrass),
                    const SizedBox(width: 4),
                    Text(
                      lang == 'mr' ? 'पुनर्चक्रक भाव' : (lang == 'hi' ? 'रिसायकलर भाव' : 'Recycler Price'),
                      style: const TextStyle(fontSize: 11, color: kInkSoft),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.circle, size: 10, color: kInkSoft),
                    const SizedBox(width: 4),
                    Text(
                      lang == 'mr' ? 'बाजार भाव' : (lang == 'hi' ? 'बाजार भाव' : 'Market Price'),
                      style: const TextStyle(fontSize: 11, color: kInkSoft),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // History list
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Text(
                    lang == 'mr'
                        ? 'या श्रेणीचा इतिहास उपलब्ध नाही'
                        : (lang == 'hi'
                            ? 'इस श्रेणी का इतिहास उपलब्ध नहीं है'
                            : 'No history for this category'),
                    style: const TextStyle(color: kInkSoft, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: records.length,
                  itemBuilder: (context, i) {
                    final rec = records[i];
                    final dateStr =
                        '${rec.date.day}/${rec.date.month}/${rec.date.year}';
                    final isAnomaly = rec.isPriceAnomaly;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAnomaly ? kAlert.withAlpha(15) : kCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAnomaly ? kAlert.withAlpha(80) : kRule,
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kInkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                rec.location,
                                style: const TextStyle(fontSize: 11, color: kInkSoft),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${rec.recyclerPrice}/kg',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kBrass,
                                ),
                              ),
                              Text(
                                'Market: ₹${rec.marketPrice}/kg',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kInkSoft,
                                ),
                              ),
                            ],
                          ),
                          if (isAnomaly) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.warning, size: 16, color: kAlert),
                          ],
                          // Source badge
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rec.source == 'demo'
                                  ? kBrass.withAlpha(30)
                                  : kSignal.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rec.source.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: rec.source == 'demo' ? kBrass : kSignal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Simple trend chart ────────────────────────────────────────────────────────

class _SimpleTrendChart extends StatelessWidget {
  final List<PriceRecord> records;

  const _SimpleTrendChart({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.length < 2) {
      return const SizedBox(height: 60);
    }
    // Show last 5 records
    final visible = records.reversed.take(5).toList();
    final maxVal = visible.fold<int>(
      0,
      (max, r) => r.recyclerPrice > max ? r.recyclerPrice : max,
    );
    if (maxVal == 0) return const SizedBox(height: 60);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: visible.map((rec) {
          final recyclerH = (rec.recyclerPrice / maxVal * 50).clamp(4.0, 50.0);
          final marketH = (rec.marketPrice / maxVal * 50).clamp(4.0, 50.0);
          final dateLabel = '${rec.date.day}/${rec.date.month}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 12,
                    height: recyclerH,
                    color: kBrass,
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 12,
                    height: marketH,
                    color: kInkSoft.withAlpha(80),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 9, color: kInkSoft),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
