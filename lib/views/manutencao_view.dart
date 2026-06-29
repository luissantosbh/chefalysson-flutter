// manutencao_view.dart
// Tela exibida quando o app está em manutenção para a plataforma do usuário.

import 'package:flutter/material.dart';

class ManutencaoView extends StatelessWidget {
  const ManutencaoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🍣',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 24),
                Text(
                  'Em Manutenção',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFBF1921),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'O app está temporariamente fora do ar para melhorias.\n\nVoltaremos em breve com novidades! 🎉',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Chef Alysson',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBF1921),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
