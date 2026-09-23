import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/scrap_analyzer_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'category_guess_screen.dart';

/// Live camera viewfinder for scrap capture.
/// Uses MobileScanner widget to show the camera preview and samples the live
/// frame's optical characteristics (color dominance & luminance) to classify
/// the scrap type in 100% airplane mode.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late final MobileScannerController _controller;
  final GlobalKey _previewKey = GlobalKey();
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onShutter([ScrapAnalysisResult? sampleResult]) async {
    final appState = context.read<AppState>();
    // Start a new lot only if one doesn't already exist (i.e., first item).
    if (appState.draftLot == null) {
      appState.startNewLot();
    }

    // Perform optical / color heuristic analysis on the live camera preview
    ScrapAnalysisResult result;
    if (sampleResult != null) {
      result = sampleResult;
    } else {
      result = await ScrapAnalyzerService.analyzeViewfinder(_previewKey);
    }

    try {
      await _controller.stop();
    } catch (_) {}

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CategoryGuessScreen(
          initialSuggestions: result.suggestions,
          detectionReasonKey: result.reasonKey,
          capturedImageBytes: result.thumbnailBytes,
        ),
      ),
    );

    if (mounted) {
      try {
        await _controller.start();
      } catch (_) {}
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Live camera preview with optical analysis boundary ────────────
          RepaintBoundary(
            key: _previewKey,
            child: MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: (_) {},
              placeholderBuilder: (context, child) => Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: kBrass),
                      const SizedBox(height: 16),
                      Text(
                        str('camera_loading', lang),
                        style: const TextStyle(color: kChalk, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: IconButton(
                    iconSize: 44,
                    icon: const Icon(Icons.refresh, color: kBrass),
                    onPressed: () {
                      try {
                        _controller.start();
                      } catch (_) {}
                    },
                  ),
                ),
              );
            },
          ),
        ),

          // ── Semi-transparent top bar ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withAlpha(160),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: kChalk),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        str('capture_hint', lang),
                        style: const TextStyle(
                          color: kChalk,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Torch toggle
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? kBrass : kChalk,
                      ),
                      onPressed: _toggleTorch,
                    ),
                    // Skip button in top bar
                    TextButton(
                      onPressed: _onShutter,
                      child: Text(
                        lang == 'en'
                            ? 'Skip'
                            : (lang == 'mr' ? 'पुढे चला' : 'आगे बढ़ें'),
                        style: const TextStyle(
                          color: kBrass,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),

          // ── Corner viewfinder guides ──────────────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(painter: _CornerFramePainter()),
            ),
          ),

          // ── "Point at the item" hint ──────────────────────────────────────
          Positioned(
            bottom: 172,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lang == 'en'
                      ? 'Place item in frame'
                      : (lang == 'mr'
                          ? 'वस्तू फ्रेममध्ये ठेवा'
                          : 'वस्तु को फ्रेम में रखें'),
                  style: const TextStyle(color: kChalk, fontSize: 13),
                ),
              ),
            ),
          ),

          // ── Demo simulation quick samples ─────────────────────────────────
          Positioned(
            bottom: 122,
            left: 0,
            right: 0,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SampleChip(
                      label: '🟩 PCB',
                      onTap: () => _onShutter(
                        const ScrapAnalysisResult(
                          topCategoryId: 'pcb_populated',
                          suggestions: ['pcb_populated', 'bare_board', 'cable'],
                          reasonKey: 'detected_green_pcb',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SampleChip(
                      label: '🟧 Copper Wire',
                      onTap: () => _onShutter(
                        const ScrapAnalysisResult(
                          topCategoryId: 'cable',
                          suggestions: ['cable', 'mixed_cable', 'pcb_populated'],
                          reasonKey: 'detected_copper_cable',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SampleChip(
                      label: '⬛ Li-ion Battery',
                      onTap: () => _onShutter(
                        const ScrapAnalysisResult(
                          topCategoryId: 'battery_liion',
                          suggestions: [
                            'battery_liion',
                            'motor',
                            'battery_leadacid'
                          ],
                          reasonKey: 'detected_dark_battery',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SampleChip(
                      label: '⬜ Plastic / Screen',
                      onTap: () => _onShutter(
                        const ScrapAnalysisResult(
                          topCategoryId: 'mixed_plastic',
                          suggestions: [
                            'mixed_plastic',
                            'lcd_panel',
                            'crt_glass'
                          ],
                          reasonKey: 'detected_light_plastic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Shutter button ────────────────────────────────────────────────
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: GestureDetector(
                  onTap: () => _onShutter(),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: kBrass,
                      shape: BoxShape.circle,
                      border: Border.all(color: kChalk, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: kBrass.withAlpha(120),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: kChalk,
                      size: 34,
                    ),
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

/// Quick demo chip to test different scrap profiles during live evaluation.
class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(160),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kRule.withAlpha(140)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kChalk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Brass corner L-guides for the viewfinder frame.
class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBrass
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square;

    const arm = 32.0;
    final w = size.width;
    final h = size.height;
    const r = 4.0;

    void corner(double x1, double y1, double x2, double y2, double x3,
            double y3) =>
        canvas.drawPath(
            Path()
              ..moveTo(x1, y1)
              ..lineTo(x2, y2)
              ..lineTo(x3, y3),
            paint);

    corner(r, arm, r, r, arm, r); // top-left
    corner(w - arm, r, w - r, r, w - r, arm); // top-right
    corner(r, h - arm, r, h - r, arm, h - r); // bottom-left
    corner(w - arm, h - r, w - r, h - r, w - r, h - arm); // bottom-right
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

