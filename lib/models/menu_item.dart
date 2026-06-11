// models/menu_item.dart
// Equivalente a MenuItem + MenuData de Models.swift

import 'package:chef_alysson/models/food_category.dart';

class MenuItem {
  final String id;
  final String name;
  final String details;
  final double price;
  final FoodCategory category;
  final String emoji;

  const MenuItem({
    required this.id,
    required this.name,
    required this.details,
    required this.price,
    required this.category,
    required this.emoji,
  });

  String get priceFormatted {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Valor no formato exigido pelo PIX: "12.34"
  String get pixAmount => price.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Cardápio padrão
// ---------------------------------------------------------------------------

class MenuData {
  static final List<MenuItem> items = [
    // Combos
    const MenuItem(
      id: 'combo_toquio',
      name: 'Combo Tóquio (20 peças)',
      details: '8 hossomaki, 8 uramaki, 4 niguiri de salmão',
      price: 49.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),
    const MenuItem(
      id: 'combo_osaka',
      name: 'Combo Osaka (30 peças)',
      details: 'Mix de sushi, sashimi e hot roll',
      price: 74.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),
    const MenuItem(
      id: 'combo_familia',
      name: 'Combo Família (50 peças)',
      details: 'Seleção completa do chef para compartilhar',
      price: 119.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),

    // Sushi
    const MenuItem(
      id: 'niguiri_salmao',
      name: 'Niguiri de Salmão (4 un)',
      details: 'Arroz com fatia de salmão fresco',
      price: 18.90,
      category: FoodCategory.sushi,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'niguiri_atum',
      name: 'Niguiri de Atum (4 un)',
      details: 'Arroz com fatia de atum',
      price: 21.90,
      category: FoodCategory.sushi,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'uramaki_filadelfia',
      name: 'Uramaki Filadélfia (8 un)',
      details: 'Salmão, cream cheese e cebolinha',
      price: 26.90,
      category: FoodCategory.sushi,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'hossomaki_pepino',
      name: 'Hossomaki de Pepino (8 un)',
      details: 'Kappamaki tradicional',
      price: 14.90,
      category: FoodCategory.sushi,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'hot_roll',
      name: 'Hot Roll (10 un)',
      details: 'Enrolado empanado e frito com salmão',
      price: 24.90,
      category: FoodCategory.sushi,
      emoji: '🍤',
    ),

    // Sashimi
    const MenuItem(
      id: 'sashimi_salmao',
      name: 'Sashimi de Salmão (10 fatias)',
      details: 'Salmão fresco fatiado',
      price: 34.90,
      category: FoodCategory.sashimi,
      emoji: '🐟',
    ),
    const MenuItem(
      id: 'sashimi_atum',
      name: 'Sashimi de Atum (10 fatias)',
      details: 'Atum fresco fatiado',
      price: 38.90,
      category: FoodCategory.sashimi,
      emoji: '🐟',
    ),
    const MenuItem(
      id: 'sashimi_misto',
      name: 'Sashimi Misto (15 fatias)',
      details: 'Salmão, atum e peixe branco',
      price: 49.90,
      category: FoodCategory.sashimi,
      emoji: '🐟',
    ),

    // Temaki
    const MenuItem(
      id: 'temaki_filadelfia',
      name: 'Temaki Filadélfia',
      details: 'Cone de alga com salmão e cream cheese',
      price: 22.90,
      category: FoodCategory.temaki,
      emoji: '🌯',
    ),
    const MenuItem(
      id: 'temaki_salmao_grelhado',
      name: 'Temaki de Salmão Grelhado',
      details: 'Salmão grelhado com gergelim',
      price: 24.90,
      category: FoodCategory.temaki,
      emoji: '🌯',
    ),
    const MenuItem(
      id: 'temaki_hot',
      name: 'Temaki Hot',
      details: 'Salmão empanado com molho tarê',
      price: 23.90,
      category: FoodCategory.temaki,
      emoji: '🌯',
    ),

    // Pratos quentes
    const MenuItem(
      id: 'yakisoba_frango',
      name: 'Yakisoba de Frango',
      details: 'Macarrão oriental com legumes',
      price: 29.90,
      category: FoodCategory.hot,
      emoji: '🍜',
    ),
    const MenuItem(
      id: 'tempura_camarao',
      name: 'Tempurá de Camarão (6 un)',
      details: 'Camarões empanados crocantes',
      price: 32.90,
      category: FoodCategory.hot,
      emoji: '🍤',
    ),
    const MenuItem(
      id: 'guioza',
      name: 'Guioza (6 un)',
      details: 'Pastelzinho japonês de carne suína',
      price: 21.90,
      category: FoodCategory.hot,
      emoji: '🥟',
    ),
    const MenuItem(
      id: 'missoshiru',
      name: 'Missoshiru',
      details: 'Sopa de missô com tofu e cebolinha',
      price: 12.90,
      category: FoodCategory.hot,
      emoji: '🍲',
    ),

    // Bebidas
    const MenuItem(
      id: 'refrigerante_lata',
      name: 'Refrigerante Lata',
      details: 'Coca-Cola, Guaraná ou Sprite',
      price: 6.90,
      category: FoodCategory.bebidas,
      emoji: '🥤',
    ),
    const MenuItem(
      id: 'suco_natural',
      name: 'Suco Natural 500ml',
      details: 'Laranja, abacaxi ou maracujá',
      price: 9.90,
      category: FoodCategory.bebidas,
      emoji: '🧃',
    ),
    const MenuItem(
      id: 'cha_verde',
      name: 'Chá Verde Gelado',
      details: 'Tradicional japonês',
      price: 8.90,
      category: FoodCategory.bebidas,
      emoji: '🍵',
    ),
    const MenuItem(
      id: 'agua_mineral',
      name: 'Água Mineral 500ml',
      details: 'Com ou sem gás',
      price: 4.90,
      category: FoodCategory.bebidas,
      emoji: '💧',
    ),
  ];
}
