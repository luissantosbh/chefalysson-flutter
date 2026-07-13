// views/pix_checkout_view.dart
// Equivalente a PixCheckoutView.swift

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:chef_alysson/services/address_service.dart';
import 'package:chef_alysson/services/auth_service.dart';
import 'package:chef_alysson/services/cart_store.dart';
import 'package:chef_alysson/services/delivery_fee_calculator.dart';
import 'package:chef_alysson/services/geocoding_service.dart';
import 'package:chef_alysson/services/order_service.dart';
import 'package:chef_alysson/services/pix_payload.dart';
import 'package:chef_alysson/views/address_form_view.dart';

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

  // Taxa de entrega ------------------------------------------------------
  bool _isLoadingFee = true;
  String? _feeError;
  double? _deliveryFee;
  double? _distanciaKm;

  @override
  void initState() {
    super.initState();
    // Equivalente ao orderId gerado no init do SwiftUI view
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000000;
    _orderId = 'CA$ts';
    _computeDeliveryFee();
  }

  // -------------------------------------------------------------------------
  // Cálculo da taxa de entrega (distância até o restaurante)
  // -------------------------------------------------------------------------

  Future<void> _computeDeliveryFee() async {
    setState(() {
      _isLoadingFee = true;
      _feeError = null;
    });

    try {
      final address = context.read<AddressService>().address;
      if (address == null) {
        throw const GeocodingException(
            'Endereço de entrega não informado.');
      }
      if (address.cep.trim().isEmpty) {
        throw const GeocodingException(
            'CEP não informado no endereço de entrega. '
            'Edite o endereço e informe o CEP para calcular a entrega.');
      }

      final point = await GeocodingService.instance.geocodeCep(address.cep);
      final metros = DeliveryFeeCalculator.distanciaMetros(
          point.latitude, point.longitude);
      final taxa = DeliveryFeeCalculator.calcularTaxaEntrega(metros);

      if (!mounted) return;
      setState(() {
        _distanciaKm = metros / 1000;
        _deliveryFee = taxa;
        _isLoadingFee = false;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _feeError = e.message;
        _isLoadingFee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feeError =
            'Não foi possível calcular a taxa de entrega. Tente novamente.';
        _isLoadingFee = false;
      });
    }
  }

  Future<void> _editAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddressFormView(onSaved: () {})),
    );
    if (mounted) _computeDeliveryFee();
  }

  // -------------------------------------------------------------------------
  // PIX
  // -------------------------------------------------------------------------

  double _totalWithDelivery(CartStore cart) => cart.total + (_deliveryFee ?? 0);

  String get _pixCode {
    final cart = context.read<CartStore>();
    return PixPayload.generate(
        amount: _totalWithDelivery(cart), txid: _orderId);
  }

  String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _confirmPayment() async {
    final auth = context.read<AuthService>();
    final cart = context.read<CartStore>();
    final orders = context.read<OrderService>();

    if (auth.user == null) return;
    if (_deliveryFee == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final addrService = context.read<AddressService>();
      await orders.createOrder(
        userId: auth.user!.id,
        userName: auth.user!.name,
        cartItems: cart.items,
        pixOrderId: _orderId,
        deliveryAddress: addrService.address,
        nomeCliente: addrService.nomeCliente,
        observacao: cart.observacao.isNotEmpty ? cart.observacao : null,
        deliveryFee: _deliveryFee!,
        deliveryDistanceKm: _distanciaKm,
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
        child: _orderConfirmed
            ? _buildConfirmation(cart)
            : _isLoadingFee
                ? _buildFeeLoading()
                : _feeError != null
                    ? _buildFeeError()
                    : _buildPayment(cart),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Estado: calculando taxa de entrega
  // -------------------------------------------------------------------------

  Widget _buildFeeLoading() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text('Calculando a taxa de entrega...',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Estado: erro ao calcular a taxa
  // -------------------------------------------------------------------------

  Widget _buildFeeError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(_feeError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _computeDeliveryFee,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _editAddress,
            child: const Text('Editar endereço de entrega'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tela de pagamento
  // -------------------------------------------------------------------------

  Widget _buildPayment(CartStore cart) {
    final code = _pixCode;
    final total = _totalWithDelivery(cart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Valor
        Column(
          children: [
            const Text('Valor a pagar',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(_formatCurrency(total),
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.red)),
            Text('Pedido $_orderId',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 22),

        // Resumo do pedido (itens + entrega)
        _buildFeeSummary(cart),
        const SizedBox(height: 18),

        // QR Code
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
              _infoRow('Chave PIX (celular)', '(31) 99267-6460'),
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
          icon:
              Icon(_copied ? Icons.check_circle : Icons.copy_rounded, size: 18),
          label: Text(
              _copied ? 'Código copiado!' : 'Copiar código PIX (copia e cola)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _copied
                ? Colors.green
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: _copied
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
  // Resumo: pedido + entrega + total
  // -------------------------------------------------------------------------

  Widget _buildFeeSummary(CartStore cart) {
    final distanciaStr = _distanciaKm!.toStringAsFixed(1).replaceAll('.', ',');
    final total = _totalWithDelivery(cart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _summaryRow('Pedido', cart.totalFormatted),
          const SizedBox(height: 6),
          _summaryRow(
              'Entrega ($distanciaStr km)', _formatCurrency(_deliveryFee!)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _summaryRow('Total', _formatCurrency(total), bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? null : Colors.grey[700],
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
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
          const Center(child: Text('🎉', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 18),
          const Text('Pedido recebido!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
