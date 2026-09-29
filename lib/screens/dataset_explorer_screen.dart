import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/category.dart' as cat_model;
import '../models/lot.dart';
import '../models/price_record.dart';
import '../models/recycler.dart';
import '../models/sync_record.dart';
import '../theme.dart';

/// Dataset Explorer & Ministry Demo Screen — SIH 2026 PS 26229
///
/// Implements Sections 24 ("DEMO ADMIN / ANALYTICS DASHBOARD") and 25
/// ("Dataset Explorer" with Material, Price, Recycler, Transaction, Traceability,
/// and Sync Queue tabs) to demonstrate how data is captured, stored offline,
/// validated, and aggregated for policy analysis.
class DatasetExplorerScreen extends StatefulWidget {
  const DatasetExplorerScreen({super.key});

  @override
  State<DatasetExplorerScreen> createState() => _DatasetExplorerScreenState();
}

class _DatasetExplorerScreenState extends State<DatasetExplorerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loadingDemo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDemoDataset() async {
    setState(() => _loadingDemo = true);
    await context.read<AppState>().loadDemoDataset();
    if (!mounted) return;
    setState(() => _loadingDemo = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Demo dataset loaded — 5 lots + 5 price records seeded'),
        backgroundColor: kSignal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'mr'
                  ? 'डेटासेट एक्सप्लोरर'
                  : (lang == 'hi' ? 'डेटासेट एक्सप्लोरर' : 'Dataset Explorer'),
            ),
            Text(
              'DEMO ADMIN / ANALYTICS DASHBOARD — PS 26229',
              style: TextStyle(
                fontSize: 10,
                color: kChalk.withAlpha(180),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Demo data loader
          TextButton.icon(
            onPressed: _loadingDemo ? null : _loadDemoDataset,
            icon: _loadingDemo
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kBrass),
                  )
                : const Icon(Icons.science, size: 16, color: kBrass),
            label: const Text(
              'Load Demo Data',
              style: TextStyle(color: kBrass, fontSize: 12),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: kBrass,
          unselectedLabelColor: kInkSoft,
          indicatorColor: kBrass,
          tabs: const [
            Tab(text: 'Admin Dashboard'),
            Tab(text: 'Material'),
            Tab(text: 'Price'),
            Tab(text: 'Recycler'),
            Tab(text: 'Transaction'),
            Tab(text: 'Traceability'),
            Tab(text: 'Sync Queue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Ministry / Admin Dashboard
          _AdminDashboardTab(state: state),
          // Tab 2: Material Dataset
          _MaterialDatasetTab(categories: state.categories, lang: lang),
          // Tab 3: Price Dataset
          _PriceDataTab(records: state.priceHistory, lang: lang),
          // Tab 4: Recycler Dataset
          _RecyclerDatasetTab(recyclers: state.recyclers),
          // Tab 5: Transaction Dataset
          _TransactionsTab(ledger: state.ledger, lang: lang),
          // Tab 6: Traceability Dataset
          _TraceabilityTab(ledger: state.ledger, lang: lang),
          // Tab 7: Sync Queue
          _SyncQueueTab(
            queue: state.syncQueue,
            lang: lang,
            isOnline: state.isOnline,
            lastSync: state.lastSyncTime,
            onSimulateSync: () => state.simulateSync(),
            onSetOffline: () => state.setOffline(),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Admin / Analytics Dashboard ──────────────────────────────────────

class _AdminDashboardTab extends StatelessWidget {
  final AppState state;

  const _AdminDashboardTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final ledger = state.ledger;
    final totalLots = ledger.length;
    final completedTxns = ledger.where((l) => l.status == LotStatus.paid).length;
    final pendingTxns = ledger.where((l) => l.status == LotStatus.confirmed).length;
    final totalKg = ledger.fold<double>(0.0, (sum, l) => sum + l.totalWeightKg);
    final totalVal = ledger.fold<int>(0, (sum, l) => sum + (l.agreedPrice ?? l.indicativeValue));
    final pendingSync = state.pendingSyncCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Notice banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBoard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kRule.withAlpha(50)),
          ),
          child: const Row(
            children: [
              Icon(Icons.analytics_outlined, color: kBrass, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEMO ADMIN / ANALYTICS DASHBOARD',
                      style: TextStyle(
                        color: kChalk,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Simulated Ministry of Mines & JNARDDC oversight view based on local offline dataset.',
                      style: TextStyle(color: kRule, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // KPI summary cards
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Handover Lots',
                value: '$totalLots',
                subtitle: '$totalKg kg e-waste captured',
                icon: Icons.inventory_2_outlined,
                color: kBrass,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Formal Value Transacted',
                value: '₹$totalVal',
                subtitle: '$completedTxns paid · $pendingTxns pending',
                icon: Icons.payments_outlined,
                color: kSignal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Authorized Recyclers',
                value: '${state.recyclers.length}',
                subtitle: '5 CPCB registered units',
                icon: Icons.factory_outlined,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Sync Queue Status',
                value: '$pendingSync Pending',
                subtitle: state.isOnline ? 'Online (Simulated)' : 'Offline Store Active',
                icon: Icons.sync_problem_outlined,
                color: pendingSync > 0 ? kAlert : kSignal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Material Distribution breakdown
        const Text(
          'E-Waste Stream Breakdown by Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kInk),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kRule),
          ),
          child: Column(
            children: state.categories.map((cat) {
              final lotsWithCat = ledger.where((l) => l.items.any((i) => i.categoryId == cat.id));
              final count = lotsWithCat.length;
              final weight = lotsWithCat.fold<double>(
                0.0,
                (s, l) => s + l.items.where((i) => i.categoryId == cat.id).fold<double>(0.0, (isum, item) => isum + item.weightKg),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat.hazardLevel >= 2 ? kAlert : kBrass,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.nameEn,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk),
                      ),
                    ),
                    Text(
                      '$count lots (${weight.toStringAsFixed(1)} kg)',
                      style: const TextStyle(fontSize: 12, color: kInkSoft, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Critical Mineral Recovery Estimation
        const Text(
          'Strategic Mineral Recovery Potential (JNARDDC Norms)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kInk),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kRule),
          ),
          child: Column(
            children: [
              _RecoveryRow(
                metal: 'Copper (Cu)',
                amount: '${(totalKg * 0.14).toStringAsFixed(2)} kg',
                desc: 'Extracted from cables, motor armatures, and PCB traces',
              ),
              const Divider(color: kRule, height: 16),
              _RecoveryRow(
                metal: 'Gold / Precious Metals (Au/Ag)',
                amount: '${(totalKg * 0.025 * 1000).toStringAsFixed(0)} mg',
                desc: 'Refined from populated PCB finger contacts & IC bond wires',
              ),
              const Divider(color: kRule, height: 16),
              _RecoveryRow(
                metal: 'CO₂ Lifecycle Offset',
                amount: '${(totalKg * 1.85).toStringAsFixed(1)} kg CO₂e',
                desc: 'Primary smelting emissions prevented through formal secondary recovery',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: kInkSoft)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: kInkSoft)),
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  final String metal;
  final String amount;
  final String desc;

  const _RecoveryRow({required this.metal, required this.amount, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metal, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kInk)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: kInkSoft)),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSignal, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

// ── Tab 2: Material Dataset ─────────────────────────────────────────────────

class _MaterialDatasetTab extends StatelessWidget {
  final List<cat_model.Category> categories;
  final String lang;

  const _MaterialDatasetTab({required this.categories, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isHazard = cat.hazardLevel >= 2;

        return Card(
          color: kCard,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kRule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kBoard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cat.id,
                        style: const TextStyle(color: kBrass, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.nameEn,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kInk),
                      ),
                    ),
                    if (isHazard)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAlert.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: kAlert),
                        ),
                        child: Text(
                          'Hazard Level ${cat.hazardLevel}',
                          style: const TextStyle(color: kAlert, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Hindi: ${cat.nameHi}  ·  Marathi: ${cat.nameMr}',
                        style: const TextStyle(fontSize: 12, color: kInkSoft)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Floor Rate: ₹${cat.ratePerKg}/kg',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBrass),
                    ),
                    Text(
                      'Icon: ${cat.icon}',
                      style: const TextStyle(fontSize: 11, color: kInkSoft, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 3: Price Data Tab ───────────────────────────────────────────────────

class _PriceDataTab extends StatelessWidget {
  final List<PriceRecord> records;
  final String lang;

  const _PriceDataTab({required this.records, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyState(
        icon: Icons.price_check,
        message: 'No price records found.\nTap "Load Demo Data" above.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (context, i) {
        final pr = records[i];
        final gain = pr.potentialGainPerKg;
        final isAnomaly = pr.isPriceAnomaly;

        return Card(
          color: kCard,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isAnomaly ? kAlert : kRule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pr.materialCategory,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kInk),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pr.source == 'demo' ? kBrass.withAlpha(20) : kBoard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pr.source.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: pr.source == 'demo' ? kBrass : kChalk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Location: ${pr.location}', style: const TextStyle(fontSize: 11, color: kInkSoft)),
                    const Spacer(),
                    Text(
                      '${pr.date.day}/${pr.date.month}/${pr.date.year}',
                      style: const TextStyle(fontSize: 11, color: kInkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Market: ₹${pr.marketPrice}/${pr.unit}',
                        style: const TextStyle(fontSize: 12, color: kInkSoft)),
                    Text('Recycler: ₹${pr.recyclerPrice}/${pr.unit}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSignal)),
                    Text(
                      '+₹$gain/${pr.unit} Gain',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrass),
                    ),
                  ],
                ),
                if (isAnomaly) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kAlert.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: kAlert),
                        SizedBox(width: 4),
                        Text(
                          '⚠ Anomaly: Rate < 70% of market min',
                          style: TextStyle(fontSize: 11, color: kAlert, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 4: Recycler Dataset Tab ─────────────────────────────────────────────

class _RecyclerDatasetTab extends StatelessWidget {
  final List<Recycler> recyclers;

  const _RecyclerDatasetTab({required this.recyclers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: recyclers.length,
      itemBuilder: (context, i) {
        final r = recyclers[i];

        return Card(
          color: kCard,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kRule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kInk),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.authorised ? kSignal.withAlpha(20) : kAlert.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: r.authorised ? kSignal : kAlert),
                      ),
                      child: Text(
                        r.authorised ? 'CPCB Authorised' : 'Unauthorised',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: r.authorised ? kSignal : kAlert,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: ${r.id}  ·  Coords: (${r.lat.toStringAsFixed(4)}, ${r.lng.toStringAsFixed(4)})',
                  style: const TextStyle(fontSize: 11, color: kInkSoft, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      r.pickupAvailable ? Icons.local_shipping_outlined : Icons.directions_walk_outlined,
                      size: 14,
                      color: kInkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.pickupAvailable ? 'Pickup Available' : 'Self-transport required',
                      style: const TextStyle(fontSize: 11, color: kInkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Offered Rates by Category:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kInk)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  children: r.ratesByCategory.entries.map((e) {
                    return Chip(
                      label: Text('${e.key}: ₹${e.value}/kg', style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: kPaper,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 5: Transactions Tab ─────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  final List<Lot> ledger;
  final String lang;

  const _TransactionsTab({required this.ledger, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (ledger.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long,
        message: 'No transactions recorded yet.\nTap "Load Demo Data" above.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ledger.length,
      itemBuilder: (context, i) {
        final lot = ledger[i];
        return _LotCard(lot: lot, lang: lang);
      },
    );
  }
}

// ── Tab 6: Traceability Tab ─────────────────────────────────────────────────

class _TraceabilityTab extends StatelessWidget {
  final List<Lot> ledger;
  final String lang;

  const _TraceabilityTab({required this.ledger, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (ledger.isEmpty) {
      return const _EmptyState(
        icon: Icons.qr_code_scanner,
        message: 'No traceability records.\nTap "Load Demo Data" above.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ledger.length,
      itemBuilder: (context, i) {
        final lot = ledger[i];
        final qrPayload = lot.toQrPayload();

        return Card(
          color: kCard,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kRule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: kBoard, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        lot.lotRef ?? 'LOT-REF-N/A',
                        style: const TextStyle(color: kBrass, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ref: ${lot.referenceCode}',
                      style: const TextStyle(fontSize: 11, color: kInkSoft, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Collector ID: ${lot.collectorId ?? 'KS-ANON'}',
                    style: const TextStyle(fontSize: 11, color: kInkSoft, fontFamily: 'monospace')),
                Text(
                  'Collection Lat/Lng: (${lot.collectionLat?.toStringAsFixed(4) ?? '21.1350'}, ${lot.collectionLng?.toStringAsFixed(4) ?? '79.0750'})',
                  style: const TextStyle(fontSize: 11, color: kInkSoft, fontFamily: 'monospace'),
                ),
                Text('Location Source: ${lot.locationSource ?? 'manual'}',
                    style: const TextStyle(fontSize: 11, color: kInkSoft)),
                const SizedBox(height: 8),
                const Text('QR Payload (Plain JSON Traceability Manifest):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kInk)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBoardDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    qrPayload,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: kChalk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 7: Sync Queue Tab ───────────────────────────────────────────────────

class _SyncQueueTab extends StatelessWidget {
  final List<SyncRecord> queue;
  final String lang;
  final bool isOnline;
  final DateTime? lastSync;
  final VoidCallback onSimulateSync;
  final VoidCallback onSetOffline;

  const _SyncQueueTab({
    required this.queue,
    required this.lang,
    required this.isOnline,
    required this.lastSync,
    required this.onSimulateSync,
    required this.onSetOffline,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = queue.where((s) => s.syncStatus == 'pending').length;
    final syncedCount = queue.where((s) => s.syncStatus == 'synced').length;

    return Column(
      children: [
        // Controls banner
        Container(
          color: kBoard,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? kSignal : kAlert,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Online (Simulated)' : 'Offline Mode (Active)',
                        style: const TextStyle(color: kChalk, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    lastSync != null
                        ? 'Last sync: ${lastSync!.hour.toString().padLeft(2, '0')}:${lastSync!.minute.toString().padLeft(2, '0')}'
                        : 'Never synced',
                    style: TextStyle(color: kChalk.withAlpha(160), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBrass),
                        foregroundColor: kBrass,
                      ),
                      onPressed: onSimulateSync,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: Text('Simulate Sync ($pendingCount)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kRule),
                      foregroundColor: kChalk,
                    ),
                    onPressed: onSetOffline,
                    child: const Text('Go Offline'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Counts strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: kCard,
          child: Row(
            children: [
              Text('Pending: $pendingCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kAlert)),
              const SizedBox(width: 16),
              Text('Synced: $syncedCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kSignal)),
              const Spacer(),
              Text('Total in Queue: ${queue.length}',
                  style: const TextStyle(fontSize: 11, color: kInkSoft)),
            ],
          ),
        ),

        Expanded(
          child: queue.isEmpty
              ? const _EmptyState(
                  icon: Icons.sync,
                  message: 'Sync queue is empty.\nCreate lots or load demo data to populate.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: queue.length,
                  itemBuilder: (context, i) {
                    final item = queue[i];
                    final isPending = item.syncStatus == 'pending';

                    return Card(
                      color: kCard,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isPending ? kAlert.withAlpha(80) : kRule),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isPending ? Icons.pending_outlined : Icons.check_circle_outline,
                          color: isPending ? kAlert : kSignal,
                          size: 20,
                        ),
                        title: Text(
                          '${item.operation.toUpperCase()} ${item.entityType} #${item.entityId}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Created: ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}:${item.createdAt.second.toString().padLeft(2, '0')} · Status: ${item.syncStatus}',
                          style: const TextStyle(fontSize: 10, color: kInkSoft),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Reusable Lot Card for Transactions ──────────────────────────────────────

class _LotCard extends StatefulWidget {
  final Lot lot;
  final String lang;

  const _LotCard({required this.lot, required this.lang});

  @override
  State<_LotCard> createState() => _LotCardState();
}

class _LotCardState extends State<_LotCard> {
  bool _showJson = false;

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    final isPaid = lot.status == LotStatus.paid;

    return Card(
      color: kCard,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kRule),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid ? kSignal.withAlpha(20) : kBrass.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isPaid ? kSignal : kBrass),
                  ),
                  child: Text(
                    isPaid ? 'PAID (${lot.paymentMethod?.name.toUpperCase() ?? 'CASH'})' : 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? kSignal : kBrass,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lot.referenceCode,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                const Spacer(),
                Text(
                  '₹${lot.agreedPrice ?? lot.indicativeValue}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrass),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Lot Ref: ${lot.lotRef ?? 'LOT-REF-N/A'}  ·  ${lot.totalWeightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 11, color: kInkSoft, fontFamily: 'monospace'),
            ),
            if (lot.upiRef != null)
              Text(
                'UPI Ref: ${lot.upiRef}',
                style: const TextStyle(fontSize: 11, color: kSignal, fontFamily: 'monospace'),
              ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _showJson = !_showJson),
              child: Row(
                children: [
                  Icon(_showJson ? Icons.expand_less : Icons.code, size: 14, color: kBrass),
                  const SizedBox(width: 4),
                  Text(
                    _showJson ? 'Hide JSON Payload' : 'View Raw JSON Payload',
                    style: const TextStyle(fontSize: 11, color: kBrass, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (_showJson) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kBoardDeep, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(lot.toJson()),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: kChalk),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: kRule),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kInkSoft)),
        ],
      ),
    );
  }
}
