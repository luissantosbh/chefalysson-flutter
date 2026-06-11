// models/order.dart
// Equivalente a Order + OrderStatus + OrderLineItem de OrderService.swift

import 'package:flutter/material.dart';

enum OrderStatus {
  pendente,
  pagamentoConfirmado,
  emPreparo,
  pronto,
  entregue;

  String get rawValue {
    switch (this) {
      case OrderStatus.pendente:
        return 'pendente';
      case OrderStatus.pagamentoConfirmado:
        return 'pagamento_confirmado';
      case OrderStatus.emPreparo:
        return 'em_preparo';
      case OrderStatus.pronto:
        return 'pronto';
      case OrderStatus.entregue:
        return 'entregue';
    }
  }

  static OrderStatus? fromRaw(String raw) {
    for (final s in OrderStatus.values) {
      if (s.rawValue == raw) return s;
    }
    return null;
  }

  String get label {
    switch (this) {
      case OrderStatus.pendente:
        return 'Aguardando pagamento';
      case OrderStatus.pagamentoConfirmado:
        return 'Pagamento confirmado';
      case OrderStatus.emPreparo:
        return 'Em preparo';
      case OrderStatus.pronto:
        return 'Pronto para entrega';
      case OrderStatus.entregue:
        return 'Entregue';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pendente:
        return Icons.access_time_rounded;
      case OrderStatus.pagamentoConfirmado:
        return Icons.verified_rounded;
      case OrderStatus.emPreparo:
        return Icons.local_fire_department_rounded;
      case OrderStatus.pronto:
        return Icons.check_circle_rounded;
      case OrderStatus.entregue:
        return Icons.pedal_bike_rounded;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendente:
        return Colors.orange;
      case OrderStatus.pagamentoConfirmado:
        return Colors.blue;
      case OrderStatus.emPreparo:
        return Colors.red;
      case OrderStatus.pronto:
        return Colors.green;
      case OrderStatus.entregue:
        return Colors.grey;
    }
  }

  OrderStatus? get next {
    switch (this) {
      case OrderStatus.pendente:
        return OrderStatus.pagamentoConfirmado;
      case OrderStatus.pagamentoConfirmado:
        return OrderStatus.emPreparo;
      case OrderStatus.emPreparo:
        return OrderStatus.pronto;
      case OrderStatus.pronto:
        return OrderStatus.entregue;
      case OrderStatus.entregue:
        return null;
    }
  }
}

class OrderLineItem {
  final String name;
  final String emoji;
  final int quantity;
  final double unitPrice;

  const OrderLineItem({
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String pixOrderId;
  final List<OrderLineItem> items;
  final double total;
  OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pixOrderId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  String get totalFormatted =>
      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';
}
