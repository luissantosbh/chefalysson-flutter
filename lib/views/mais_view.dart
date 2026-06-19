// mais_view.dart
// Aba "Mais" exibida apenas para admins — agrupa Perfil e Admin em um menu.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/services/admin_alert_service.dart';
import 'package:chef_alysson/services/order_service.dart';
import 'package:chef_alysson/views/admin_orders_view.dart';
import 'package:chef_alysson/views/admin_products_view.dart';
import 'package:chef_alysson/views/profile_view.dart';
import 'package:chef_alysson/views/relatorio_view.dart';

class MaisView extends StatelessWidget {
  const MaisView({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>();
    final count = orders.activeOrderCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: const Text('Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileView()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.assignment_rounded),
            ),
            title: const Text('Admin — Pedidos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersView()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.restaurant_menu_rounded),
            title: const Text('Gerenciar Produtos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProductsView()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Relatório de Vendas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RelatorioView()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.volume_up_rounded, color: Colors.orange),
            title: const Text('Testar Som de Alerta'),
            subtitle: const Text('Toca o alerta por 3 segundos'),
            onTap: () => context.read<AdminAlertService>().testSound(),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}
