import 'package:flutter/material.dart';

import '../services/eco_impact_service.dart';
import '../strings.dart';
import '../theme.dart';

/// Reusable Circular Economy Impact widget for Quote and Receipt screens.
/// Displays CO2 emissions avoided and critical secondary metals recovered
/// in accordance with Ministry of Mines and JNARDDC norms.
class CircularImpactCard extends StatelessWidget {
  final EcoImpact impact;
  final String lang;

  const CircularImpactCard({
    super.key,
    required this.impact,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSignal.withAlpha(90), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: kSignal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  str('eco_impact_title', lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ImpactStat(
                  icon: Icons.cloud_outlined,
                  value: impact.co2String,
                  label: str('co2_saved', lang),
                  color: kSignal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImpactStat(
                  icon: Icons.hardware,
                  value: impact.copperString,
                  label: str('copper_recovered', lang),
                  color: kBrass,
                ),
              ),
              if (impact.preciousMetalsMg > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ImpactStat(
                    icon: Icons.stars,
                    value: impact.preciousMetalsString,
                    label: str('precious_metals', lang),
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: kInkSoft,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
