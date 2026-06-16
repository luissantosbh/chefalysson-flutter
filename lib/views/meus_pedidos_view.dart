// views/meus_pedidos_view.dart
// Equivalente a MeusPedidosView.swift

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/models/food_category.dart';
import 'package:chef_alysson/models/menu_item.dart';
import 'package:chef_alysson/models/order.dart';
import 'package:chef_alysson/services/auth_service.dart';
import 'package:chef_alysson/services/cart_store.dart';
import 'package:chef_alysson/services/order_service.dart';

class MeusPedidosView extends StatefulWidget {
  const MeusPedidosView({super.key});

  @override
  State<MeusPedidosView> createState() => _MeusPedidosViewState();
}

class _MeusPedidosViewState extends State<MeusPedidosView> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthService>().user?.id;
    if (uid != null) {
      context.read<OrderService>().startListening(uid);
    }
  }

  @override
  void dispose() {
    context.read<OrderService>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>();

    if (orders.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orders.errorMessage!)),
        );
        orders.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: _buildBody(orders),
    );
  }

  Widget _buildBody(OrderService orders) {
    if (orders.isLoading && orders.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Nenhum pedido ainda',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Seus pedidos aparecem aqui após a confirmação do pagamento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OrderCard(order: orders.orders[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de pedido
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + data
          Row(
            children: [
              StatusBadge(status: order.status),
              const Spacer(),
              Text(
                '${order.createdAt.day.toString().padLeft(2, '0')}/'
                '${order.createdAt.month.toString().padLeft(2, '0')}/'
                '${order.createdAt.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 20),

          // Itens
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(item.emoji),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(item.name,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('×${item.quantity}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
              )),

          const Divider(height: 20),

          // ID + total
          Row(
            children: [
              Text('Pedido ${order.pixOrderId}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              const Spacer(),
              Text(order.totalFormatted,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),

          // Botão repetir pedido
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _repeatOrder(context),
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: const Text('Repetir pedido'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBF1921),
                side: const BorderSide(color: Color(0xFFBF1921)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _repeatOrder(BuildContext context) {
    final cart = context.read<CartStore>();
    cart.clear();

    for (final lineItem in order.items) {
      // Cria um MenuItem sintético a partir do item do pedido
      final menuItem = MenuItem(
        id: lineItem.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
        name: lineItem.name,
        details: '',
        price: lineItem.unitPrice,
        category: FoodCategory.combos,
        emoji: lineItem.emoji,
      );
      for (var i = 0; i < lineItem.quantity; i++) {
        cart.add(menuItem);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Itens adicionados ao carrinho!'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );

    // Volta para a tela principal (tabs)
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}

// ---------------------------------------------------------------------------
// Badge de status (reutilizado em AdminOrdersView)
// ---------------------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: status.color)),
        ],
      ),
    );
  }
}
