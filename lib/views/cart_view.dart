// views/cart_view.dart
// Equivalente a CartView.swift

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/models/cart_item.dart';
import 'package:chef_alysson/services/cart_store.dart';
import 'package:chef_alysson/views/pix_checkout_view.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Carrinho'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                cart.clear();
              },
              child: const Text('Limpar',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty ? _buildEmpty(context) : _buildCart(context, cart),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('Seu carrinho está vazio',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Escolha algo delicioso no cardápio para começar.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCart(BuildContext context, CartStore cart) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: cart.items.length + 1, // +1 para linha de total
            itemBuilder: (context, index) {
              if (index < cart.items.length) {
                return _CartRow(cartItem: cart.items[index], index: index);
              }
              // Total
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(cart.totalFormatted,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.red)),
                  ],
                ),
              );
            },
          ),
        ),

        // Botão PIX
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const PixCheckoutView(),
                ),
              ),
              icon: const Icon(Icons.qr_code_rounded),
              label: Text(
                'Pagar com PIX • ${cart.totalFormatted}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Linha do carrinho
// ---------------------------------------------------------------------------

class _CartRow extends StatelessWidget {
  final CartItem cartItem;
  final int index;

  const _CartRow({required this.cartItem, required this.index});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartStore>();

    return Dismissible(
      key: ValueKey(cartItem.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => cart.removeAt(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(cartItem.item.emoji,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cartItem.item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${cartItem.item.priceFormatted} cada',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            // Controles de quantidade
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 22),
                  onPressed: () => cart.remove(cartItem.item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('${cartItem.quantity}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.red, size: 22),
                  onPressed: () => cart.add(cartItem.item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(
              width: 70,
              child: Text(cartItem.subtotalFormatted,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
