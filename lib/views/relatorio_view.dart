import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chef_alysson/models/order.dart';

class RelatorioView extends StatefulWidget {
  const RelatorioView({super.key});

  @override
  State<RelatorioView> createState() => _RelatorioViewState();
}

class _RelatorioViewState extends State<RelatorioView> {
  bool _loading = true;
  int _totalPedidos = 0;
  double _totalArrecadado = 0;
  List<MapEntry<String, int>> _maisVendidos = [];

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() => _loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.entregue.rawValue)
        .get();

    int totalPedidos = snap.docs.length;
    double totalArrecadado = 0;
    final Map<String, int> contagem = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      totalArrecadado += (data['total'] as num?)?.toDouble() ?? 0;

      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final nome = item['name'] as String? ?? 'Desconhecido';
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        contagem[nome] = (contagem[nome] ?? 0) + qty;
      }
    }

    final maisVendidos = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _totalPedidos = totalPedidos;
      _totalArrecadado = totalArrecadado;
      _maisVendidos = maisVendidos.take(10).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarRelatorio,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarRelatorio,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cards de resumo
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'Pedidos entregues',
                          value: '$_totalPedidos',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.attach_money_rounded,
                          label: 'Total arrecadado',
                          value: 'R\$ ${_totalArrecadado.toStringAsFixed(2).replaceAll('.', ',')}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Produtos mais vendidos
                  const Text(
                    'PRODUTOS MAIS VENDIDOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_maisVendidos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Nenhum pedido entregue ainda.'),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _maisVendidos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final maxQty = _maisVendidos.first.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      '${i + 1}º',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.key,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: item.value / maxQty,
                                            backgroundColor: Colors.grey
                                                .withValues(alpha: 0.15),
                                            color: const Color(0xFFBF1921),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${item.value}x',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _maisVendidos.length - 1)
                                const Divider(height: 1, indent: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
