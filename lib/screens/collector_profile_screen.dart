import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_state.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'ledger_screen.dart';
import 'price_board_screen.dart';

/// Collector Profile Screen
/// Shows:
///   - Collector ID (copyable / QR)
///   - Lifetime stats (total earned, transactions, pending)
///   - Manual location entry with city quick-select
///   - Navigation to Price Board and Ledger
class CollectorProfileScreen extends StatefulWidget {
  const CollectorProfileScreen({super.key});

  @override
  State<CollectorProfileScreen> createState() => _CollectorProfileScreenState();
}

class _CollectorProfileScreenState extends State<CollectorProfileScreen> {
  bool _showQr = false;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  static const List<Map<String, dynamic>> _kCities = [
    {'name': 'Nagpur', 'lat': 21.1458, 'lng': 79.0882},
    {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
    {'name': 'Pune', 'lat': 18.5204, 'lng': 73.8567},
    {'name': 'Amravati', 'lat': 20.9320, 'lng': 77.7523},
    {'name': 'Yavatmal', 'lat': 20.3891, 'lng': 78.1204},
  ];

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Collector ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setLocation(AppState state, double lat, double lng) {
    state.setCollectorLocation(lat, lng, source: 'manual');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Location set: ${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E'),
        backgroundColor: kSignal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showManualLocationDialog(AppState state) {
    _latController.text = state.collectorLat.toStringAsFixed(4);
    _lngController.text = state.collectorLng.toStringAsFixed(4);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Set Your Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick city select
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _kCities.map((city) {
                return GestureDetector(
                  onTap: () {
                    _latController.text =
                        (city['lat'] as double).toStringAsFixed(4);
                    _lngController.text =
                        (city['lng'] as double).toStringAsFixed(4);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBoard.withAlpha(20),
                      border: Border.all(color: kBrass),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      city['name'] as String,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No GPS permission needed — location is set manually for demo.',
              style: const TextStyle(fontSize: 11, color: kInkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(_latController.text);
              final lng = double.tryParse(_lngController.text);
              Navigator.of(ctx).pop();
              if (lat != null && lng != null) {
                _setLocation(state, lat, lng);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: kBrass),
            child: const Text('Set', style: TextStyle(color: kBoardDeep)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final id = state.collectorId;

    final title = lang == 'mr'
        ? 'माझी प्रोफाइल'
        : (lang == 'hi' ? 'मेरी प्रोफ़ाइल' : 'My Profile');

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Collector ID Card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBoard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: kBrass.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: kBrass, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 36,
                        color: kBrass,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang == 'mr'
                          ? 'संग्रहक'
                          : (lang == 'hi' ? 'संग्रहकर्ता' : 'Collector'),
                      style: TextStyle(
                        color: kChalk.withAlpha(180),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Collector ID with copy
                    GestureDetector(
                      onTap: () => _copyId(id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: kBoardDeep,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              id,
                              style: const TextStyle(
                                color: kBrass,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy, size: 16, color: kBrass),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // QR toggle
                    TextButton.icon(
                      onPressed: () => setState(() => _showQr = !_showQr),
                      icon: Icon(
                        _showQr ? Icons.qr_code_2 : Icons.qr_code,
                        size: 18,
                        color: kBrass,
                      ),
                      label: Text(
                        _showQr ? 'Hide QR' : 'Show ID as QR',
                        style: const TextStyle(color: kBrass, fontSize: 13),
                      ),
                    ),
                    if (_showQr) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: id,
                          version: QrVersions.auto,
                          size: 140.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: kBoard,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: kBoard,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats Cards ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: lang == 'mr'
                          ? 'एकूण कमाई'
                          : (lang == 'hi' ? 'कुल कमाई' : 'Total Earned'),
                      value: '₹${state.totalEarnings}',
                      icon: Icons.account_balance_wallet,
                      color: kSignal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: lang == 'mr'
                          ? 'व्यवहार'
                          : (lang == 'hi' ? 'लेन-देन' : 'Transactions'),
                      value: '${state.completedTransactionCount}',
                      icon: Icons.swap_horiz,
                      color: kBrass,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: lang == 'mr'
                          ? 'प्रलंबित'
                          : (lang == 'hi' ? 'बकाया' : 'Pending'),
                      value: '₹${state.pendingEarnings}',
                      icon: Icons.pending,
                      color: kAlert,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Location Card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kRule),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: kBrass),
                        const SizedBox(width: 8),
                        Text(
                          lang == 'mr'
                              ? 'माझे स्थान'
                              : (lang == 'hi' ? 'मेरा स्थान' : 'My Location'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kBrass.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.locationSource.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: kBrass,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.collectorLat.toStringAsFixed(4)}°N, ${state.collectorLng.toStringAsFixed(4)}°E',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang == 'mr'
                          ? 'पुनर्चक्रक जुळणीसाठी वापरले'
                          : (lang == 'hi'
                              ? 'रिसायकलर मिलान के लिए उपयोग किया'
                              : 'Used for recycler matching & proximity'),
                      style: const TextStyle(fontSize: 12, color: kInkSoft),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _showManualLocationDialog(state),
                        icon: const Icon(Icons.edit_location_alt, size: 18),
                        label: Text(
                          lang == 'mr'
                              ? 'स्थान बदला'
                              : (lang == 'hi' ? 'स्थान बदलें' : 'Change Location'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kBrass,
                          side: const BorderSide(color: kBrass),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── TTS Button ────────────────────────────────────────────────
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final ttsText = lang == 'mr'
                        ? 'माझा संग्रहक आयडी $id आहे. एकूण कमाई ${state.totalEarnings} रुपये.'
                        : (lang == 'hi'
                            ? 'मेरा संग्रहकर्ता आईडी $id है। कुल कमाई ${state.totalEarnings} रुपये।'
                            : 'My Collector ID is $id. Total earnings ${state.totalEarnings} rupees.');
                    TtsService().speak(ttsText, lang);
                  },
                  icon: const Icon(Icons.volume_up, size: 20, color: kInk),
                  label: Text(
                    lang == 'mr'
                        ? 'माहिती ऐका'
                        : (lang == 'hi' ? 'जानकारी सुनें' : 'Listen to Profile'),
                    style: const TextStyle(color: kInk, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kRule),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Quick links ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.price_change,
                      label: lang == 'mr'
                          ? 'भाव पत्रक'
                          : (lang == 'hi' ? 'मूल्य बोर्ड' : 'Price Board'),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const PriceBoardScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.account_balance_wallet,
                      label: lang == 'mr'
                          ? 'नोंदवही'
                          : (lang == 'hi' ? 'बही-खाता' : 'Ledger'),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LedgerScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
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
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: kInkSoft),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kRule),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kBrass),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kInk,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: kInkSoft),
          ],
        ),
      ),
    );
  }
}
