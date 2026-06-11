// models/food_category.dart
// Equivalente a FoodCategory de Models.swift

import 'package:flutter/material.dart';

enum FoodCategory {
  combos,
  sushi,
  sashimi,
  temaki,
  hot,
  bebidas;

  String get label {
    switch (this) {
      case FoodCategory.combos:
        return 'Combos';
      case FoodCategory.sushi:
        return 'Sushi';
      case FoodCategory.sashimi:
        return 'Sashimi';
      case FoodCategory.temaki:
        return 'Temaki';
      case FoodCategory.hot:
        return 'Pratos quentes';
      case FoodCategory.bebidas:
        return 'Bebidas';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.combos:
        return Icons.grid_view_rounded;
      case FoodCategory.sushi:
        return Icons.rice_bowl_rounded;
      case FoodCategory.sashimi:
        return Icons.set_meal_rounded;
      case FoodCategory.temaki:
        return Icons.lunch_dining_rounded;
      case FoodCategory.hot:
        return Icons.local_fire_department_rounded;
      case FoodCategory.bebidas:
        return Icons.local_cafe_rounded;
    }
  }
}
