// models/cart_item.dart
// Equivalente a CartItem de Models.swift

import 'package:chef_alysson/models/menu_item.dart';

class CartItem {
  final String id;
  final MenuItem item;
  int quantity;

  CartItem({
    required this.item,
    required this.quantity,
  }) : id = item.id;

  double get subtotal => item.price * quantity;

  String get subtotalFormatted =>
      'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}';
}
