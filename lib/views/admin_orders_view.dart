// views/admin_orders_view.dart
// Equivalente a AdminOrdersView.swift

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chef_alysson/models/order.dart';
import 'package:chef_alysson/services/admin_alert_service.dart';
import 'package:chef_alysson/services/order_service.dart';
import 'package:chef_alysson/views/meus_pedidos_view.dart'; // StatusBadge

class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  OrderStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderService>().startListeningAll();
      context.read<AdminAlertService>().acknowledge();
    });
  }

  @override
  void dispose() {
    context.read<OrderService>().stopListening();
    super.dispose();
  }

  List<Order> get _filtered {
    final all = context.read<OrderService>().orders;
    if (_selectedFilter == null) return all;
    return all.where((o) => o.status == _selectedFilter).toList();
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
      appBar: AppBar(title: const Text('Painel Admin')),
      body: Column(
        children: [
          _buildFilterBar(orders),
          const Divider(height: 1),
          Expanded(child: _buildBody(orders)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(OrderService orders) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _FilterChip(
            label: 'Todos',
            count: orders.orders.length,
            isSelected: _selectedFilter == null,
            onTap: () => setState(() => _selectedFilter = null),
          ),
          ...OrderStatus.values.map((s) => _FilterChip(
                label: s.label,
                count: orders.orders.where((o) => o.status == s).length,
                isSelected: _selectedFilter == s,
                onTap: () => setState(() => _selectedFilter = s),
              )),
        ],
      ),
    );
  }

  Widget _buildBody(OrderService orders) {
    if (orders.isLoading && orders.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Sem pedidos',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == null
                  ? 'Nenhum pedido recebido ainda.'
                  : 'Nenhum pedido com este status.',
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
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AdminOrderCard(order: list[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFBF1921)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : null)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin order card
// ---------------------------------------------------------------------------

class _AdminOrderCard extends StatelessWidget {
  final Order order;
  const _AdminOrderCard({required this.order});

  String _nome() {
    final raw = order.nomeCliente?.isNotEmpty == true
        ? order.nomeCliente!
        : order.userName;
    return (raw == 'Convidado' || raw.isEmpty) ? 'Cliente' : raw;
  }

  String _buildWhatsappText() {
    final addr = order.deliveryAddress;
    final nome = _nome();

    final enderecoLines = addr == null
        ? '   (endereço não informado)'
        : [
            '   ${addr.rua}, ${addr.numero}${addr.complemento.isNotEmpty ? ' ${addr.complemento}' : ''}',
            '   ${addr.bairro}, ${addr.cidade}',
            if (addr.cep.isNotEmpty) '   CEP: ${addr.cep}',
            '   📞 ${addr.telefone}',
          ].join('\n');

    final itensList = order.items
        .map((i) => '   ${i.quantity}× ${i.name}')
        .join('\n');

    final obs = order.observacao;
    final obsLine = (obs != null && obs.isNotEmpty)
        ? '\n📝 *Observação:* $obs'
        : '';

    return '''🛵 *Novo pedido para entrega*

👤 *Cliente:* $nome
📍 *Endereço:*
$enderecoLines

🍣 *Pedido:*
$itensList$obsLine

💰 *Total:* ${order.totalFormatted}
💳 *Pagamento:* PIX''';
  }

  String _buildPrintText() {
    final addr = order.deliveryAddress;
    final nome = _nome();
    final obs = order.observacao;

    final buf = StringBuffer();
    buf.writeln('================================');
    buf.writeln('   NOVO PEDIDO PARA ENTREGA');
    buf.writeln('================================');
    buf.writeln('CLIENTE: $nome');
    if (addr != null && addr.telefone.isNotEmpty) {
      buf.writeln('TELEFONE: ${addr.telefone}');
    }
    buf.writeln();
    if (addr != null) {
      buf.writeln('ENDERECO:');
      final comp =
          addr.complemento.isNotEmpty ? ' ${addr.complemento}' : '';
      buf.writeln('${addr.rua}, ${addr.numero}$comp');
      buf.writeln('${addr.bairro}, ${addr.cidade} (MG)');
      if (addr.cep.isNotEmpty) buf.writeln('CEP: ${addr.cep}');
    } else {
      buf.writeln('ENDERECO: (nao informado)');
    }
    buf.writeln();
    buf.writeln('--------------------------------');
    buf.writeln('PEDIDO:');
    for (final item in order.items) {
      buf.writeln('${item.quantity}x ${item.name}');
    }
    if (obs != null && obs.isNotEmpty) {
      buf.writeln();
      buf.writeln('OBSERVACAO: $obs');
    }
    buf.writeln('--------------------------------');
    buf.writeln('TOTAL: ${order.totalFormatted}');
    buf.writeln('PAGAMENTO: PIX');
    buf.write('================================');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final next = order.status.next;
    final isReadyToDeliver = order.status == OrderStatus.pronto;

    return Container(
      padding: const EdgeInsets.all(14),
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
          // Nome + hora + status
          Row(
            children: [
              Text(order.userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text(
                '${order.createdAt.hour.toString().padLeft(2, '0')}:'
                '${order.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: order.status),
            ],
          ),
          const Divider(height: 16),

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

          // Observação (fundo amarelo, só se preenchida)
          if (order.observacao != null &&
              order.observacao!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEB3B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      order.observacao!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 16),

          // Total + botão de avançar status
          Row(
            children: [
              Text(order.totalFormatted,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              if (next != null)
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await context
                          .read<OrderService>()
                          .updateStatus(order.id, next);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    }
                  },
                  icon: Icon(next.icon, size: 14),
                  label: Text(next.label,
                      style: const TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBF1921),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('Concluído',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
            ],
          ),

          // Botões motoqueiro — apenas quando "Pronto para entrega"
          if (isReadyToDeliver) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (btnCtx) {
                Future<void> share(String text) async {
                  final box = btnCtx.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : const Rect.fromLTWH(0, 0, 10, 10);
                  await Share.share(text, sharePositionOrigin: origin);
                }

                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => share(_buildWhatsappText()),
                        icon: const Text('📱',
                            style: TextStyle(fontSize: 14)),
                        label: const Text('WhatsApp',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE67E22),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => share(_buildPrintText()),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('Imprimir',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF37474F),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
