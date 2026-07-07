// services/order_service.dart
// Equivalente a OrderService.swift

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';

import 'package:chef_alysson/models/address.dart';
import 'package:chef_alysson/models/cart_item.dart';
import 'package:chef_alysson/models/order.dart';

class OrderService extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot>? _subscription;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get activeOrderCount =>
      _orders.where((o) => o.status != OrderStatus.entregue).length;

  // -------------------------------------------------------------------------
  // Criar pedido
  // -------------------------------------------------------------------------

  Future<String> createOrder({
    required String userId,
    required String userName,
    required List<CartItem> cartItems,
    required String pixOrderId,
    DeliveryAddress? deliveryAddress,
    String? nomeCliente,
    String? observacao,
    double deliveryFee = 0,
    double? deliveryDistanceKm,
  }) async {
    final ref = FirebaseFirestore.instance.collection('orders').doc();

    final itemsData = cartItems
        .map((ci) => {
              'name': ci.item.name,
              'emoji': ci.item.emoji,
              'quantity': ci.quantity,
              'unitPrice': ci.item.price,
            })
        .toList();

    final itemsTotal =
        cartItems.fold<double>(0.0, (acc, ci) => acc + ci.item.price * ci.quantity);
    final total = itemsTotal + deliveryFee;

    await ref.set({
      'userId': userId,
      'userName': userName,
      'pixOrderId': pixOrderId,
      'items': itemsData,
      'total': total,
      'deliveryFee': deliveryFee,
      if (deliveryDistanceKm != null) 'deliveryDistanceKm': deliveryDistanceKm,
      'status': OrderStatus.pagamentoConfirmado.rawValue,
      'createdAt': FieldValue.serverTimestamp(),
      if (deliveryAddress != null)
        'deliveryAddress': deliveryAddress.toMap(),
      if (nomeCliente != null && nomeCliente.isNotEmpty)
        'nomeCliente': nomeCliente,
      if (observacao != null && observacao.isNotEmpty)
        'observacao': observacao,
    });

    return ref.id;
  }

  // -------------------------------------------------------------------------
  // Listener em tempo real — pedidos do usuário
  // -------------------------------------------------------------------------

  void startListening(String userId) {
    stopListening();
    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _isLoading = false;
        _orders = snapshot.docs
            .map(_parseDoc)
            .whereType<Order>()
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// Listener de todos os pedidos — exclusivo para o admin
  void startListeningAll() {
    stopListening();
    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _isLoading = false;
        _orders = snapshot.docs
            .map(_parseDoc)
            .whereType<Order>()
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _orders = [];
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Atualizar status
  // -------------------------------------------------------------------------

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': status.rawValue});
  }

  // -------------------------------------------------------------------------
  // Dismiss error
  // -------------------------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Parse do documento Firestore
  // -------------------------------------------------------------------------

  Order? _parseDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>?;
    if (d == null) return null;

    final userId = d['userId'] as String?;
    final userName = d['userName'] as String?;
    final pixId = d['pixOrderId'] as String?;
    final total = (d['total'] as num?)?.toDouble();
    final statusRaw = d['status'] as String?;

    if (userId == null ||
        userName == null ||
        pixId == null ||
        total == null ||
        statusRaw == null) {
      return null;
    }

    final status = OrderStatus.fromRaw(statusRaw);
    if (status == null) return null;

    final createdAt =
        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final rawItems = d['items'] as List<dynamic>? ?? [];
    final items = rawItems.whereType<Map<String, dynamic>>().map((m) {
      final name = m['name'] as String?;
      final emoji = m['emoji'] as String?;
      final quantity = (m['quantity'] as num?)?.toInt();
      final unitPrice = (m['unitPrice'] as num?)?.toDouble();
      if (name == null || emoji == null || quantity == null || unitPrice == null) {
        return null;
      }
      return OrderLineItem(
        name: name,
        emoji: emoji,
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }).whereType<OrderLineItem>().toList();

    DeliveryAddress? deliveryAddress;
    final rawAddr = d['deliveryAddress'];
    if (rawAddr is Map<String, dynamic>) {
      deliveryAddress = DeliveryAddress.fromMap(rawAddr);
    }

    return Order(
      id: doc.id,
      userId: userId,
      userName: userName,
      nomeCliente: d['nomeCliente'] as String?,
      observacao: d['observacao'] as String?,
      pixOrderId: pixId,
      items: items,
      total: total,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0,
      deliveryDistanceKm: (d['deliveryDistanceKm'] as num?)?.toDouble(),
      status: status,
      createdAt: createdAt,
      deliveryAddress: deliveryAddress,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
