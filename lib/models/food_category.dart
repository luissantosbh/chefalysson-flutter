// models/food_category.dart

import 'package:flutter/material.dart';

enum FoodCategory {
  combos,
  entradas,
  hotroll,
  uramaki,
  temaki,
  sashimi,
  especiais,
  yakisoba,
  bebidas;

  String get label {
    switch (this) {
      case FoodCategory.combos:
        return 'Combinados';
      case FoodCategory.entradas:
        return 'Entradas';
      case FoodCategory.hotroll:
        return 'Hot Roll';
      case FoodCategory.uramaki:
        return 'Uramaki';
      case FoodCategory.temaki:
        return 'Temaki';
      case FoodCategory.sashimi:
        return 'Sashimi & Joe';
      case FoodCategory.especiais:
        return 'Especiais';
      case FoodCategory.yakisoba:
        return 'Yakisoba';
      case FoodCategory.bebidas:
        return 'Bebidas';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.combos:
        return Icons.grid_view_rounded;
      case FoodCategory.entradas:
        return Icons.restaurant_rounded;
      case FoodCategory.hotroll:
        return Icons.local_fire_department_rounded;
      case FoodCategory.uramaki:
        return Icons.rice_bowl_rounded;
      case FoodCategory.temaki:
        return Icons.lunch_dining_rounded;
      case FoodCategory.sashimi:
        return Icons.set_meal_rounded;
      case FoodCategory.especiais:
        return Icons.star_rounded;
      case FoodCategory.yakisoba:
        return Icons.ramen_dining_rounded;
      case FoodCategory.bebidas:
        return Icons.local_cafe_rounded;
    }
  }
}
