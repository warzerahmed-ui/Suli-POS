import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// نیشانەکانی بەردەست بۆ پۆلەکان (ناو ← IconData).
/// English: fixed icon set the user can pick for a category.
class CategoryIcons {
  const CategoryIcons._();

  static const Map<String, IconData> values = <String, IconData>{
    'grocery': Icons.local_grocery_store,
    'dairy': Icons.egg_alt_outlined,
    'bakery': Icons.bakery_dining_outlined,
    'beverage': Icons.local_drink_outlined,
    'water': Icons.water_drop_outlined,
    'fruit': Icons.eco_outlined,
    'meat': Icons.set_meal_outlined,
    'snacks': Icons.cookie_outlined,
    'sweets': Icons.icecream_outlined,
    'cleaning': Icons.cleaning_services_outlined,
    'hygiene': Icons.soap_outlined,
    'baby': Icons.child_friendly_outlined,
    'household': Icons.chair_outlined,
    'electronics': Icons.electrical_services_outlined,
    'stationery': Icons.edit_note_outlined,
    'tobacco': Icons.smoking_rooms_outlined,
    'frozen': Icons.ac_unit_outlined,
    'other': Icons.category_outlined,
  };

  static IconData resolve(String key) =>
      values[key] ?? Icons.category_outlined;

  static List<String> get keys => values.keys.toList(growable: false);
}

/// پۆلی کاڵا (بۆ نموونە: شیرەمەنی، بەحەک، خواردنەوە ...).
/// English: product category with an icon key and an accent colour.
class Category {
  const Category({
    required this.id,
    required this.name,
    this.iconKey = 'other',
    this.colorValue = 0xFF14795F,
  });

  /// پۆلی «بێ پۆل» — کاڵای بێ پۆل هەر کاتێک پۆلێک بسڕدرێتەوە بۆ ئەمە دەگوازرێت.
  static const String uncategorizedId = 'uncategorized';

  static const Category uncategorized = Category(
    id: uncategorizedId,
    name: AppStrings.withoutCategory,
    iconKey: 'other',
    colorValue: 0xFF757575,
  );

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;

  bool get isUncategorized => id == uncategorizedId;

  Color get color => Color(colorValue);

  IconData get icon => CategoryIcons.resolve(iconKey);

  Category copyWith({String? id, String? name, String? iconKey, int? colorValue}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        iconKey: json['iconKey'] as String? ?? 'other',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF14795F,
      );
}
