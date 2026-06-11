// views/pix_checkout_view.dart
// Equivalente a PixCheckoutView.swift

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:chef_alysson/services/auth_service.dart';
import 'package:chef_alysson/services/cart_store.dart';
import 'package:chef_alysson/services/order_service.dart';
import 'package:chef_alysson/services/pix_payload.dart';

class PixCheckoutView extends StatefulWidget {
  const PixCheckoutView({super.key});

  @override
  State<PixCheckoutView> createState() => _PixCheckoutViewState();
}

class _PixCheckoutViewState extends State<PixCheckoutView> {
  late final String _orderId;
  bool _copied = false;
  bool _orderConfirmed = false;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    // Equivalente ao orderId gerado no init do SwiftUI view
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000000;
    _orderId = 'CA$ts';
  }

  String get _pixCode {
    final cart = context.read<CartStore>();
    return PixPayload.generate(amount: cart.total, txid: _orderId);
  }

  Future<void> _confirmPayment() async {
    final auth = context.read<AuthService>();
    final cart = context.read<CartStore>();
    final orders = context.read<OrderService>();

    if (auth.user == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await orders.createOrder(
        userId: auth.user!.id,
        userName: auth.user!.name,
        cartItems: cart.items,
        pixOrderId: _orderId,
      );
      if (mounted) setState(() => _orderConfirmed = true);
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento PIX'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _orderConfirmed ? _buildConfirmation(cart) : _buildPayment(cart),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tela de pagamento
  // -------------------------------------------------------------------------

  Widget _buildPayment(CartStore cart) {
    final code = _pixCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Valor
        Column(
          children: [
            const Text('Valor do pedido',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(cart.totalFormatted,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.red)),
            Text('Pedido $_orderId',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 22),

        // QR Code
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 220,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF000000),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('Aponte a câmera do app do seu banco',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 22),

        // Dados do recebedor
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _infoRow('Recebedor', PixPayload.merchantName),
              const SizedBox(height: 6),
              _infoRow('Chave PIX (celular)', '(31) 98884-8354'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Copiar código
        ElevatedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            setState(() => _copied = true);
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) setState(() => _copied = false);
            });
          },
          icon: Icon(_copied ? Icons.check_circle : Icons.copy_rounded,
              size: 18),
          label: Text(_copied
              ? 'Código copiado!'
              : 'Copiar código PIX (copia e cola)'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _copied ? Colors.green : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor:
                _copied ? Colors.white : Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 14),

        // Confirmar pagamento
        ElevatedButton(
          onPressed: _isSaving ? null : _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('Já fiz o pagamento ✓',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),

        if (_saveError != null) ...[
          const SizedBox(height: 10),
          Text(_saveError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center),
        ],

        const SizedBox(height: 12),
        Text(
          'Após o pagamento, seu pedido entra em preparo. Você receberá a confirmação em instantes.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Tela de confirmação
  // -------------------------------------------------------------------------

  Widget _buildConfirmation(CartStore cart) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
              child: Text('🎉', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 18),
          const Text('Pedido recebido!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Obrigado pela preferência! Assim que o PIX for confirmado, começaremos a preparar seu pedido $_orderId.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Voltar ao cardápio',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helper
  // -------------------------------------------------------------------------

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
