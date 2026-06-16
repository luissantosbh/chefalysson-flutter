// services/menu_service.dart
// Gerencia o cardápio no Firestore — lê, cria, edita e deleta produtos.
// Na primeira execução (coleção vazia), faz seed com MenuData.items.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:chef_alysson/models/food_category.dart';
import 'package:chef_alysson/models/menu_item.dart';

class MenuService extends ChangeNotifier {
  static const _collection = 'menu_items';

  List<MenuItem> _items = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _sub;

  List<MenuItem> get items => _items;
  bool get isLoading => _isLoading;

  List<MenuItem> byCategory(FoodCategory cat) =>
      _items.where((i) => i.category == cat).toList();

  List<MenuItem> search(String q) {
    final lower = q.toLowerCase();
    return _items
        .where((i) =>
            i.name.toLowerCase().contains(lower) ||
            i.details.toLowerCase().contains(lower))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Listener em tempo real
  // -------------------------------------------------------------------------

  void startListening() {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .listen((snap) async {
      if (snap.docs.isEmpty) {
        await _seed();
        return; // seed dispara nova snapshot automaticamente
      }
      _items = snap.docs
          .map((d) => MenuItem.fromFirestore(
              d.data(), d.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  // -------------------------------------------------------------------------
  // Seed inicial
  // -------------------------------------------------------------------------

  Future<void> _seed() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final item in MenuData.items) {
      final ref =
          FirebaseFirestore.instance.collection(_collection).doc(item.id);
      batch.set(ref, item.toFirestore());
    }
    await batch.commit();
  }

  // -------------------------------------------------------------------------
  // CRUD
  // -------------------------------------------------------------------------

  Future<void> addItem(MenuItem item) async {
    final ref =
        FirebaseFirestore.instance.collection(_collection).doc(item.id);
    await ref.set(item.toFirestore());
  }

  Future<void> updateItem(MenuItem item) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(item.id)
        .update(item.toFirestore());
  }

  Future<void> deleteItem(String id) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
