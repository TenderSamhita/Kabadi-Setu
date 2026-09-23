import '../models/lot.dart';

/// Circular economy impact metrics calculated from e-waste lots.
/// Aligned with JNARDDC and Ministry of Mines secondary raw material recovery norms.
class EcoImpact {
  final double co2SavedKg;
  final double copperGrams;
  final double preciousMetalsMg;
  final double totalScrapKg;

  const EcoImpact({
    required this.co2SavedKg,
    required this.copperGrams,
    required this.preciousMetalsMg,
    required this.totalScrapKg,
  });

  /// Formatted CO2 string (e.g., "14.5 kg CO₂")
  String get co2String => '${co2SavedKg.toStringAsFixed(1)} kg CO₂';

  /// Formatted copper string (e.g., "3.2 kg Copper" or "450 g Copper")
  String get copperString {
    if (copperGrams >= 1000) {
      return '${(copperGrams / 1000).toStringAsFixed(1)} kg Copper';
    }
    return '${copperGrams.round()} g Copper';
  }

  /// Formatted precious metals string (e.g., "120 mg Gold/Ag")
  String get preciousMetalsString {
    if (preciousMetalsMg >= 1000) {
      return '${(preciousMetalsMg / 1000).toStringAsFixed(2)} g Gold/Ag';
    }
    return '${preciousMetalsMg.round()} mg Gold/Ag';
  }
}

class EcoImpactService {
  /// Computes the environmental and mineral recovery impact for a given [Lot].
  static EcoImpact compute(Lot lot) {
    double totalCo2 = 0.0;
    double totalCopper = 0.0;
    double totalPrecious = 0.0;
    double totalWeight = 0.0;

    for (final item in lot.items) {
      final kg = item.weightKg;
      totalWeight += kg;

      switch (item.categoryId) {
        case 'pcb_populated':
          totalCo2 += kg * 1.8;
          totalCopper += kg * 140.0;
          totalPrecious += kg * 25.0; // 25 mg gold/silver per kg
          break;
        case 'bare_board':
          totalCo2 += kg * 1.2;
          totalCopper += kg * 90.0;
          totalPrecious += kg * 5.0;
          break;
        case 'cable':
          totalCo2 += kg * 2.5;
          totalCopper += kg * 450.0;
          break;
        case 'mixed_cable':
          totalCo2 += kg * 2.0;
          totalCopper += kg * 320.0;
          break;
        case 'motor':
          totalCo2 += kg * 2.2;
          totalCopper += kg * 220.0;
          break;
        case 'battery_liion':
          totalCo2 += kg * 3.0;
          totalCopper += kg * 80.0;
          break;
        case 'battery_leadacid':
          totalCo2 += kg * 1.9;
          break;
        case 'lcd_panel':
          totalCo2 += kg * 1.5;
          totalCopper += kg * 40.0;
          break;
        case 'mixed_plastic':
          totalCo2 += kg * 1.4;
          break;
        case 'crt_glass':
          totalCo2 += kg * 0.8;
          break;
        default:
          totalCo2 += kg * 1.5;
          totalCopper += kg * 50.0;
      }
    }

    return EcoImpact(
      co2SavedKg: totalCo2,
      copperGrams: totalCopper,
      preciousMetalsMg: totalPrecious,
      totalScrapKg: totalWeight,
    );
  }
}
