class Category {
  final String id;
  final String nameEn;
  final String nameHi;
  final String nameMr;
  final int ratePerKg;
  final int hazardLevel;
  final String icon;

  const Category({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.ratePerKg,
    required this.hazardLevel,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameHi: json['nameHi'] as String,
      nameMr: json['nameMr'] as String,
      ratePerKg: json['ratePerKg'] as int,
      hazardLevel: json['hazardLevel'] as int,
      icon: json['icon'] as String,
    );
  }

  /// Returns the localised name for the given language code.
  /// Falls back to English if the language code is unrecognised.
  String nameFor(String lang) {
    switch (lang) {
      case 'hi':
        return nameHi;
      case 'mr':
        return nameMr;
      default:
        return nameEn;
    }
  }
}
