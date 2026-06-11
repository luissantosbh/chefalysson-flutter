// views/login_view.dart
// Equivalente a LoginView.swift

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chef_alysson/services/auth_service.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Mostrar erro se houver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: auth.clearError,
            ),
          ),
        );
        auth.clearError();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFBF1921), // vermelho escarlate
              Color(0xFF720D14), // vermelho escuro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),

                // Logo
                Column(
                  children: [
                    const Text('🍣', style: TextStyle(fontSize: 88)),
                    const SizedBox(height: 12),
                    const Text(
                      'Chef Alysson',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comida japonesa fresquinha na sua casa',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Botões
                Column(
                  children: [
                    // Google
                    _LoginButton(
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                      label: 'Continuar com Google',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      onTap: () => context.read<AuthService>().signInWithGoogle(),
                    ),
                    const SizedBox(height: 14),

                    // Apple
                    _LoginButton(
                      icon: const Icon(Icons.apple_rounded, size: 22),
                      label: 'Continuar com Apple',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      onTap: () => context.read<AuthService>().signInWithApple(),
                    ),
                    const SizedBox(height: 14),

                    // Convidado
                    TextButton(
                      onPressed: () =>
                          context.read<AuthService>().continueAsGuest(),
                      child: Text(
                        'Continuar sem cadastro',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Termos
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.6),
                    ),
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

class _LoginButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _LoginButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
