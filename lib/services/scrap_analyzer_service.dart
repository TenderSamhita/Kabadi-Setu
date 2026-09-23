import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Result of color and luminance heuristic scrap analysis.
class ScrapAnalysisResult {
  final String topCategoryId;
  final List<String> suggestions;
  final String reasonKey;
  final Uint8List? thumbnailBytes;

  const ScrapAnalysisResult({
    required this.topCategoryId,
    required this.suggestions,
    required this.reasonKey,
    this.thumbnailBytes,
  });
}

/// Lightweight, 100% offline image scanner that samples viewfinder pixels
/// to estimate e-waste material type based on optical properties.
class ScrapAnalyzerService {
  /// Captures and analyzes the current frame from a [RepaintBoundary].
  static Future<ScrapAnalysisResult> analyzeViewfinder(
    GlobalKey boundaryKey,
  ) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        return _fallbackResult();
      }

      // Capture at 0.25 scale for instant analysis with zero lag.
      final ui.Image image = await boundary.toImage(pixelRatio: 0.25);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      Uint8List? pngBytes;
      try {
        final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = pngData?.buffer.asUint8List();
      } catch (_) {}

      if (byteData == null) {
        return _fallbackResult(thumbnailBytes: pngBytes);
      }

      return analyzeRgba(
        rgbaBytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
        thumbnailBytes: pngBytes,
      );
    } catch (_) {
      return _fallbackResult();
    }
  }

  /// Analyzes raw RGBA pixel buffer to classify scrap category.
  static ScrapAnalysisResult analyzeRgba({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    Uint8List? thumbnailBytes,
  }) {
    if (rgbaBytes.isEmpty || width <= 0 || height <= 0) {
      return _fallbackResult(thumbnailBytes: thumbnailBytes);
    }

    // Sample center area (20% to 80% coordinates) to focus on viewfinder center
    final startX = (width * 0.2).round();
    final endX = (width * 0.8).round();
    final startY = (height * 0.2).round();
    final endY = (height * 0.8).round();

    double totalR = 0;
    double totalG = 0;
    double totalB = 0;
    int sampleCount = 0;

    final stepX = ((endX - startX) ~/ 20).clamp(1, 100);
    final stepY = ((endY - startY) ~/ 20).clamp(1, 100);

    for (int y = startY; y < endY; y += stepY) {
      for (int x = startX; x < endX; x += stepX) {
        final index = (y * width + x) * 4;
        if (index + 2 < rgbaBytes.length) {
          totalR += rgbaBytes[index];
          totalG += rgbaBytes[index + 1];
          totalB += rgbaBytes[index + 2];
          sampleCount++;
        }
      }
    }

    if (sampleCount == 0) {
      return _fallbackResult(thumbnailBytes: thumbnailBytes);
    }

    final avgR = totalR / sampleCount;
    final avgG = totalG / sampleCount;
    final avgB = totalB / sampleCount;
    final avgLuminance = 0.299 * avgR + 0.587 * avgG + 0.114 * avgB;

    // 1. Green dominance -> Populated PCB or Bare Board
    if (avgG > avgR * 1.12 && avgG > avgB * 1.08 && avgG > 35) {
      return ScrapAnalysisResult(
        topCategoryId: 'pcb_populated',
        suggestions: const ['pcb_populated', 'bare_board', 'cable'],
        reasonKey: 'detected_green_pcb',
        thumbnailBytes: thumbnailBytes,
      );
    }

    // 2. Red / Copper dominance -> Copper Wire / Cable
    if (avgR > avgG * 1.15 && avgR > avgB * 1.15 && avgR > 35) {
      return ScrapAnalysisResult(
        topCategoryId: 'cable',
        suggestions: const ['cable', 'mixed_cable', 'pcb_populated'],
        reasonKey: 'detected_copper_cable',
        thumbnailBytes: thumbnailBytes,
      );
    }

    // 3. Dark / Metallic / Low Light -> Battery or Motor
    if (avgLuminance < 80) {
      return ScrapAnalysisResult(
        topCategoryId: 'battery_liion',
        suggestions: const ['battery_liion', 'motor', 'battery_leadacid'],
        reasonKey: 'detected_dark_battery',
        thumbnailBytes: thumbnailBytes,
      );
    }

    // 4. Bright / Light Grey / White -> Mixed Plastic or LCD
    if (avgLuminance > 160) {
      return ScrapAnalysisResult(
        topCategoryId: 'mixed_plastic',
        suggestions: const ['mixed_plastic', 'lcd_panel', 'crt_glass'],
        reasonKey: 'detected_light_plastic',
        thumbnailBytes: thumbnailBytes,
      );
    }

    // 5. Blue dominance -> Blue plastic or electronic components
    if (avgB > avgR * 1.15 && avgB > avgG * 1.10) {
      return ScrapAnalysisResult(
        topCategoryId: 'mixed_plastic',
        suggestions: const ['mixed_plastic', 'lcd_panel', 'pcb_populated'],
        reasonKey: 'detected_light_plastic',
        thumbnailBytes: thumbnailBytes,
      );
    }

    // Balanced default
    return _fallbackResult(thumbnailBytes: thumbnailBytes);
  }

  static ScrapAnalysisResult _fallbackResult({Uint8List? thumbnailBytes}) {
    return ScrapAnalysisResult(
      topCategoryId: 'pcb_populated',
      suggestions: const ['pcb_populated', 'cable', 'mixed_plastic'],
      reasonKey: 'detected_default',
      thumbnailBytes: thumbnailBytes,
    );
  }
}
