// views/biografia_view.dart
// Equivalente a BiografiaView.swift

import 'package:flutter/material.dart';

class BiografiaView extends StatelessWidget {
  const BiografiaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👨‍🍳 Sobre o Chef')),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/biografia.jpg',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('📷 Imagem não encontrada',
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }
}
