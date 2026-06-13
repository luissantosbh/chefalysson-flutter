// views/address_form_view.dart
// Formulário de endereço de entrega — usado antes do checkout PIX.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/models/address.dart';
import 'package:chef_alysson/services/address_service.dart';
import 'package:chef_alysson/services/auth_service.dart';

class AddressFormView extends StatefulWidget {
  /// Se [onSaved] for fornecido, é chamado após salvar com sucesso.
  final VoidCallback? onSaved;

  const AddressFormView({super.key, this.onSaved});

  @override
  State<AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<AddressFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _telefone;
  late final TextEditingController _cidade;
  late final TextEditingController _bairro;
  late final TextEditingController _rua;
  late final TextEditingController _numero;
  late final TextEditingController _complemento;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<AddressService>().address;
    _telefone = TextEditingController(text: existing?.telefone ?? '');
    _cidade = TextEditingController(text: existing?.cidade ?? '');
    _bairro = TextEditingController(text: existing?.bairro ?? '');
    _rua = TextEditingController(text: existing?.rua ?? '');
    _numero = TextEditingController(text: existing?.numero ?? '');
    _complemento = TextEditingController(text: existing?.complemento ?? '');
  }

  @override
  void dispose() {
    _telefone.dispose();
    _cidade.dispose();
    _bairro.dispose();
    _rua.dispose();
    _numero.dispose();
    _complemento.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final address = DeliveryAddress(
      telefone: _telefone.text.trim(),
      cidade: _cidade.text.trim(),
      bairro: _bairro.text.trim(),
      rua: _rua.text.trim(),
      numero: _numero.text.trim(),
      complemento: _complemento.text.trim(),
    );

    try {
      await context.read<AddressService>().save(userId, address);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endereço de entrega'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Informe o endereço e telefone para receber seu pedido.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _field(
              controller: _telefone,
              label: 'Telefone / WhatsApp',
              icon: Icons.phone_rounded,
              required: true,
              keyboardType: TextInputType.phone,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _cidade,
              label: 'Cidade',
              icon: Icons.location_city_rounded,
              required: true,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _bairro,
              label: 'Bairro',
              icon: Icons.map_rounded,
              required: true,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _rua,
              label: 'Rua / Avenida',
              icon: Icons.signpost_rounded,
              required: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _field(
                    controller: _numero,
                    label: 'Número',
                    icon: Icons.tag_rounded,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _field(
                    controller: _complemento,
                    label: 'Complemento',
                    icon: Icons.apartment_rounded,
                    required: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF1921),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar endereço',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool required,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Preencha o $label' : null
          : null,
    );
  }
}
