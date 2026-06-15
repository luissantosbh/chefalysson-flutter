// services/cart_store.dart
// Equivalente a CartStore.swift

import 'package:flutter/foundation.dart';
import 'package:chef_alysson/models/cart_item.dart';
import 'package:chef_alysson/models/menu_item.dart';

class CartStore extends ChangeNotifier {
  final List<CartItem> _items = [];
  String observacao = '';

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQuantity => _items.fold(0, (sum, i) => sum + i.quantity);

  double get total => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  bool get isEmpty => _items.isEmpty;

  String get totalFormatted =>
      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Quantidade atual de um item no carrinho
  int quantity(MenuItem item) =>
      _items.firstWhere((ci) => ci.item.id == item.id,
          orElse: () => CartItem(item: item, quantity: 0)).quantity;

  void add(MenuItem item) {
    final index = _items.indexWhere((ci) => ci.item.id == item.id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(item: item, quantity: 1));
    }
    notifyListeners();
  }

  void remove(MenuItem item) {
    final index = _items.indexWhere((ci) => ci.item.id == item.id);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    observacao = '';
    notifyListeners();
  }
}
