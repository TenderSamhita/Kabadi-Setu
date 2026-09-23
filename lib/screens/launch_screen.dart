import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/tts_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'role_screen.dart';

/// Screen 1 — language selection.
/// Left zone of each tile: tap to select language and navigate to RoleScreen.
/// Right zone (speaker icon): tap to hear the language name pronounced.
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    return Scaffold(
      backgroundColor: kBoard,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Logo ──────────────────────────────────────────────────────
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── App name ──────────────────────────────────────────────────
              Center(
                child: Text(
                  str('app_name', lang),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: kChalk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'E-waste Direct Sale Centre',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kBrass,
                      ),
                ),
              ),

              const Spacer(),

              // ── Language prompt ───────────────────────────────────────────
              Center(
                child: Text(
                  'भाषा निवडा / भाषा चुनें / Choose Language',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kChalk.withAlpha(160),
                      ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Marathi ───────────────────────────────────────────────────
              _LanguageTile(
                key: const ValueKey('lang_mr'),
                primary: 'मराठी',
                secondary: 'Marathi',
                languageCode: 'mr',
              ),
              const SizedBox(height: 12),

              // ── Hindi ─────────────────────────────────────────────────────
              _LanguageTile(
                key: const ValueKey('lang_hi'),
                primary: 'हिंदी',
                secondary: 'Hindi',
                languageCode: 'hi',
              ),
              const SizedBox(height: 12),

              // ── English ───────────────────────────────────────────────────
              _LanguageTile(
                key: const ValueKey('lang_en'),
                primary: 'English',
                secondary: 'इंग्रजी / अंग्रेज़ी',
                languageCode: 'en',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

/// Full-width tile split into two tappable zones:
/// - Left (main area): select language + navigate to RoleScreen
/// - Right (speaker): speak the language name via TTS only, no navigation
class _LanguageTile extends StatelessWidget {
  final String primary;
  final String secondary;
  final String languageCode;

  const _LanguageTile({
    super.key,
    required this.primary,
    required this.secondary,
    required this.languageCode,
  });

  void _navigate(BuildContext context) {
    context.read<AppState>().setLanguage(languageCode);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RoleScreen()),
    );
  }

  void _speakName() {
    TtsService().speak(primary, languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Main tap zone (select + navigate) ──────────────────────────
            Expanded(
              child: Material(
                color: kCard,
                child: InkWell(
                  onTap: () => _navigate(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primary,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: kInk),
                        ),
                        Text(
                          secondary,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Speaker tap zone (TTS only, no navigation) ─────────────────
            Material(
              color: kRule,
              child: InkWell(
                onTap: _speakName,
                child: const SizedBox(
                  width: 64,
                  child: Center(
                    child: Icon(Icons.volume_up, color: kInkSoft, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
