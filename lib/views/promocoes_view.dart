// views/promocoes_view.dart
// Equivalente a PromocoesView.swift

import 'package:flutter/material.dart';

class _Promo {
  final String title;
  final String imageName;
  const _Promo(this.title, this.imageName);
}

const _promos = [
  _Promo('Cardápio completo', 'cardapioPrincipal'),
  _Promo('Combinado Salmão', 'combinadoSalmao'),
  _Promo('Inauguração', 'inauguracao'),
  _Promo('Sorteio Barca 50un', 'sorteioBarca'),
];

class PromocoesView extends StatelessWidget {
  const PromocoesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎉 Promoções')),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _promos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (_, index) => _PromoCard(promo: _promos[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de promoção
// ---------------------------------------------------------------------------

class _PromoCard extends StatelessWidget {
  final _Promo promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(promo.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _ExpandedPromoView(
                imageName: promo.imageName,
                title: promo.title,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/${promo.imageName}.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text('📷 ${promo.title}',
                    style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tela expandida (fullscreen)
// ---------------------------------------------------------------------------

class _ExpandedPromoView extends StatelessWidget {
  final String imageName;
  final String title;

  const _ExpandedPromoView({required this.imageName, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 80),
            child: Image.asset(
              'assets/images/$imageName.jpg',
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 400,
                child: Center(
                    child: Icon(Icons.image_not_supported,
                        color: Colors.white54, size: 64)),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
