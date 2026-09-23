import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin singleton wrapper around flutter_tts.
///
/// All public methods silently swallow exceptions — TTS failure must
/// never crash the app. The device may not have the requested voice
/// installed; that is acceptable for the demo.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.48); // Slightly slower for low-literacy users
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint('[TtsService] init failed: $e');
    }
  }

  /// Speaks [text] in the appropriate locale for [lang].
  /// lang: 'mr' → mr-IN, 'hi' → hi-IN, 'en' → en-IN.
  Future<void> speak(String text, String lang) async {
    try {
      await _ensureInit();
      final locale = lang == 'mr'
          ? 'mr-IN'
          : (lang == 'hi' ? 'hi-IN' : 'en-IN');
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[TtsService] stop failed: $e');
    }
  }
}
