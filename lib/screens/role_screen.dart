import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../strings.dart';
import '../theme.dart';
import 'collector_home_screen.dart';
import 'recycler_home_screen.dart';

/// Screen 2 — role selection.
/// Two square tiles: Collector / Recycler.
/// Brass border highlights the currently-selected role.
/// Tapping navigates to the appropriate home screen.
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    return Scaffold(
      backgroundColor: kBoard,
      appBar: AppBar(
        leading: const BackButton(color: kChalk),
        title: Text(str('role_prompt', lang)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _RoleTile(
                      key: const ValueKey('role_collector'),
                      icon: Icons.shopping_cart_outlined,
                      labelPrimary: str('collector', lang),
                      labelEnglish: 'Collector',
                      role: 'collector',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleTile(
                      key: const ValueKey('role_recycler'),
                      icon: Icons.factory_outlined,
                      labelPrimary: str('recycler', lang),
                      labelEnglish: 'Recycler',
                      role: 'recycler',
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String labelPrimary;
  final String labelEnglish;
  final String role;

  const _RoleTile({
    super.key,
    required this.icon,
    required this.labelPrimary,
    required this.labelEnglish,
    required this.role,
  });

  void _onSelect(BuildContext context) {
    context.read<AppState>().setRole(role);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => role == 'collector'
            ? const CollectorHomeScreen()
            : const RecyclerHomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<AppState>().role == role;

    return AspectRatio(
      aspectRatio: 0.85,
      child: Material(
        color: selected ? kBrass.withAlpha(30) : kCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onSelect(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? kBrass : kRule,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 56,
                  color: selected ? kBrass : kInkSoft,
                ),
                const SizedBox(height: 16),
                Text(
                  labelPrimary,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: selected ? kBrass : kInk,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  labelEnglish,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: kInkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
