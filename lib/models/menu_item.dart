// models/menu_item.dart

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

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'details': details,
        'price': price,
        'category': category.name,
        'emoji': emoji,
      };

  factory MenuItem.fromFirestore(Map<String, dynamic> m, String docId) {
    FoodCategory cat;
    try {
      cat = FoodCategory.values.firstWhere(
        (c) => c.name == (m['category'] as String?),
      );
    } catch (_) {
      cat = FoodCategory.combos;
    }
    return MenuItem(
      id: docId,
      name: m['name'] as String? ?? '',
      details: m['details'] as String? ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0.0,
      category: cat,
      emoji: m['emoji'] as String? ?? '🍣',
    );
  }

  MenuItem copyWith({
    String? name,
    String? details,
    double? price,
    FoodCategory? category,
    String? emoji,
  }) =>
      MenuItem(
        id: id,
        name: name ?? this.name,
        details: details ?? this.details,
        price: price ?? this.price,
        category: category ?? this.category,
        emoji: emoji ?? this.emoji,
      );
}

// ---------------------------------------------------------------------------
// Cardápio real do Chef Alysson
// ---------------------------------------------------------------------------

class MenuData {
  static final List<MenuItem> items = [

    // -------------------------------------------------------------------------
    // COMBINADOS
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'combo_salmao_20',
      name: 'Combinado Salmão – 20 un.',
      details: '10 Hot Roll, 10 Salmão Filadélfia',
      price: 44.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),
    const MenuItem(
      id: 'combo_premium_30',
      name: 'Combinado Premium – 30 un.',
      details: '10 Uramaki Salmão Grelhado, 10 Uramaki Filadélfia, 10 Hot Roll',
      price: 69.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),
    const MenuItem(
      id: 'combo_40',
      name: 'Combinado 40 – 40 un.',
      details: '10 Uramaki Salmão, 10 Uramaki Kani com Nachos, 10 Uramaki Salmão Grelhado, 10 Hot Salmão',
      price: 74.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),
    const MenuItem(
      id: 'combo_hot_especial_30',
      name: 'Combinado Hot Especial – 30 un.',
      details: '10 Hot Salmão com Crisp de Couve, 10 Hot Camarão com Crisp de Alho-Poró, 10 Hot Kani com Nachos',
      price: 69.90,
      category: FoodCategory.combos,
      emoji: '🍱',
    ),
    const MenuItem(
      id: 'barca_sushi_50',
      name: 'Barca Sushi – 50 un.',
      details: '10 Sashimi Salmão, 10 Hossomaki Salmão, 10 Hot Roll, 5 Niguiri Salmão, 5 Joe Salmão, 10 Uramaki Salmão Grelhado',
      price: 129.90,
      category: FoodCategory.combos,
      emoji: '🚢',
    ),

    // -------------------------------------------------------------------------
    // ENTRADAS
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'poke',
      name: 'Poke',
      details: 'Salmão, kani, sunomono, manga, cream cheese e crisp de batata doce',
      price: 34.90,
      category: FoodCategory.entradas,
      emoji: '🥗',
    ),
    const MenuItem(
      id: 'sunomono',
      name: 'Sunomono',
      details: 'Salada japonesa de pepino ao molho agridoce com gergelim',
      price: 14.90,
      category: FoodCategory.entradas,
      emoji: '🥒',
    ),
    const MenuItem(
      id: 'rolinho_queijo',
      name: 'Rolinho Primavera Queijo – 2 un.',
      details: '',
      price: 9.90,
      category: FoodCategory.entradas,
      emoji: '🌯',
    ),
    const MenuItem(
      id: 'rolinho_camarao',
      name: 'Rolinho Primavera Camarão – 2 un.',
      details: '',
      price: 14.90,
      category: FoodCategory.entradas,
      emoji: '🌯',
    ),
    const MenuItem(
      id: 'par_perfeito',
      name: 'Par Perfeito – 2 un.',
      details: 'Queijo e goiabada',
      price: 12.90,
      category: FoodCategory.entradas,
      emoji: '🧀',
    ),
    const MenuItem(
      id: 'ceviche_salmao',
      name: 'Ceviche de Salmão – 250g',
      details: 'Molho peruano artesanal levemente apimentado, acompanha crisp de batata-doce',
      price: 39.90,
      category: FoodCategory.entradas,
      emoji: '🐟',
    ),
    const MenuItem(
      id: 'carpaccio_salmao',
      name: 'Carpaccio de Salmão – 10 un.',
      details: 'Azeite trufado, flor de sal e raspas de limão',
      price: 39.90,
      category: FoodCategory.entradas,
      emoji: '🐟',
    ),

    // -------------------------------------------------------------------------
    // HOT ROLL – 10 un.
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'hot_roll_salmao',
      name: 'Hot Roll Salmão – 10 un.',
      details: '',
      price: 24.90,
      category: FoodCategory.hotroll,
      emoji: '🍤',
    ),
    const MenuItem(
      id: 'hot_roll_camarao',
      name: 'Hot Roll Camarão – 10 un.',
      details: '',
      price: 29.90,
      category: FoodCategory.hotroll,
      emoji: '🍤',
    ),
    const MenuItem(
      id: 'hot_amor_meu',
      name: 'Hot Amor Meu – 10 un.',
      details: 'Feitas na massa de rolinho primavera, recheadas com Sonho de Valsa e cobertas com Nutella e morangos',
      price: 29.90,
      category: FoodCategory.hotroll,
      emoji: '❤️',
    ),

    // -------------------------------------------------------------------------
    // TEMAKI
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'temaki_salmao_filadelfia',
      name: 'Temaki Salmão Filadélfia',
      details: '',
      price: 26.90,
      category: FoodCategory.temaki,
      emoji: '🌮',
    ),
    const MenuItem(
      id: 'temaki_camarao',
      name: 'Temaki Camarão',
      details: '',
      price: 29.90,
      category: FoodCategory.temaki,
      emoji: '🌮',
    ),
    const MenuItem(
      id: 'temaki_hot_salmao',
      name: 'Temaki Hot Salmão',
      details: '',
      price: 29.90,
      category: FoodCategory.temaki,
      emoji: '🌮',
    ),
    const MenuItem(
      id: 'temaki_hot_camarao',
      name: 'Temaki Hot Camarão',
      details: '',
      price: 32.90,
      category: FoodCategory.temaki,
      emoji: '🌮',
    ),
    const MenuItem(
      id: 'temaki_especial_chef',
      name: 'Temaki Especial Chef',
      details: 'Salmão, camarão, kani e cream cheese',
      price: 29.90,
      category: FoodCategory.temaki,
      emoji: '🌮',
    ),

    // -------------------------------------------------------------------------
    // URAMAKI – 10 un.
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'uramaki_california',
      name: 'Uramaki Califórnia – 10 un.',
      details: '',
      price: 24.90,
      category: FoodCategory.uramaki,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'uramaki_filadelfia',
      name: 'Uramaki Filadélfia – 10 un.',
      details: '',
      price: 27.90,
      category: FoodCategory.uramaki,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'uramaki_salmao_grelhado',
      name: 'Uramaki Salmão Grelhado – 10 un.',
      details: '',
      price: 27.90,
      category: FoodCategory.uramaki,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'uramaki_do_chef',
      name: 'Uramaki do Chef – 10 un.',
      details: 'Salmão, camarão, kani e cream cheese',
      price: 29.90,
      category: FoodCategory.uramaki,
      emoji: '🍣',
    ),
    const MenuItem(
      id: 'uramaki_especial',
      name: 'Uramaki Especial – 10 un.',
      details: 'Coberto com lâminas de salmão e finalizado com crisp de couve ou alho-poró',
      price: 29.90,
      category: FoodCategory.uramaki,
      emoji: '🍣',
    ),

    // -------------------------------------------------------------------------
    // SASHIMI & JOE
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'sashimi_salmao_5',
      name: 'Sashimi Salmão – 5 un.',
      details: '',
      price: 24.90,
      category: FoodCategory.sashimi,
      emoji: '🐟',
    ),
    const MenuItem(
      id: 'joe_salmao_4',
      name: 'Joe Salmão – 4 un.',
      details: '',
      price: 19.90,
      category: FoodCategory.sashimi,
      emoji: '🍣',
    ),

    // -------------------------------------------------------------------------
    // ESPECIAIS
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'big_hot_salmao',
      name: 'Big Hot Salmão',
      details: 'Coberto com geleia de pimenta e molho tarê',
      price: 29.90,
      category: FoodCategory.especiais,
      emoji: '🔥',
    ),
    const MenuItem(
      id: 'big_hot_camarao',
      name: 'Big Hot Camarão',
      details: 'Coberto com geleia de pimenta e molho tarê',
      price: 34.90,
      category: FoodCategory.especiais,
      emoji: '🔥',
    ),

    // -------------------------------------------------------------------------
    // YAKISOBA
    // -------------------------------------------------------------------------
    const MenuItem(
      id: 'yakisoba_frango',
      name: 'Yakisoba Frango',
      details: '',
      price: 24.90,
      category: FoodCategory.yakisoba,
      emoji: '🍜',
    ),
    const MenuItem(
      id: 'yakisoba_carne',
      name: 'Yakisoba Carne',
      details: '',
      price: 29.90,
      category: FoodCategory.yakisoba,
      emoji: '🍜',
    ),
    const MenuItem(
      id: 'yakisoba_camarao',
      name: 'Yakisoba Camarão',
      details: '',
      price: 34.90,
      category: FoodCategory.yakisoba,
      emoji: '🍜',
    ),
  ];
}
