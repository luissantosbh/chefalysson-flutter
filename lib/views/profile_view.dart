// views/profile_view.dart
// Equivalente a ProfileView.swift

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/models/app_user.dart';
import 'package:chef_alysson/services/auth_service.dart';
import 'package:chef_alysson/views/meus_pedidos_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          // Cabeçalho do usuário
          _Section(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Foto de perfil
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: user?.photoURL != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user!.photoURL.toString(),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 32, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Cliente',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        if (user?.email.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(user!.email,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                        if (user?.provider != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.verified,
                                  size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Conectado via ${user!.provider.label}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Minha conta
          const _SectionHeader(label: 'Minha conta'),
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Meus Pedidos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MeusPedidosView(),
                  ),
                ),
              ),
            ],
          ),

          // Info da loja
          const _SectionHeader(label: 'Chef Alysson'),
          const _Section(
            children: [
              ListTile(
                leading: Icon(Icons.access_time_rounded),
                title: Text('Seg a Dom • 18h30 às 23h30'),
                dense: true,
              ),
              ListTile(
                leading: Icon(Icons.pedal_bike_rounded),
                title: Text('Entrega em Belo Horizonte e região'),
                dense: true,
              ),
              ListTile(
                leading: Icon(Icons.qr_code_rounded),
                title: Text('Pagamento via PIX'),
                dense: true,
              ),
            ],
          ),

          // Sair
          const _SectionHeader(label: ''),
          _Section(
            children: [
              ListTile(
                leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red),
                title: const Text('Sair da conta',
                    style: TextStyle(color: Colors.red)),
                onTap: () => auth.signOut(),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers de layout (imita seções do List do SwiftUI)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5)),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}
