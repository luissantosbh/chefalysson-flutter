// views/address_form_view.dart
// Formulário de endereço de entrega — usado antes do checkout PIX.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:chef_alysson/models/address.dart';
import 'package:chef_alysson/models/app_user.dart';
import 'package:chef_alysson/services/address_service.dart';
import 'package:chef_alysson/services/auth_service.dart';

class AddressFormView extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddressFormView({super.key, this.onSaved});

  @override
  State<AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<AddressFormView> {
  final _formKey = GlobalKey<FormState>();

  static const _cidades = ['Belo Horizonte (MG)', 'Contagem (MG)'];

  late String _cidadeSelecionada;
  late final bool _isGuest;

  late final TextEditingController _cep;
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _bairro;
  late final TextEditingController _rua;
  late final TextEditingController _numero;
  late final TextEditingController _complemento;

  bool _isSaving = false;
  bool _isFetchingCep = false;
  String? _cepError;

  @override
  void initState() {
    super.initState();
    _isGuest =
        context.read<AuthService>().user?.provider == AuthProvider.guest;

    final existing = context.read<AddressService>().address;

    final cidadeExistente = existing?.cidade ?? '';
    _cidadeSelecionada = _cidades.contains(cidadeExistente)
        ? cidadeExistente
        : _cidades.first;

    _cep = TextEditingController(text: existing?.cep ?? '');
    _nome = TextEditingController();
    _telefone = TextEditingController(text: existing?.telefone ?? '');
    _bairro = TextEditingController(text: existing?.bairro ?? '');
    _rua = TextEditingController(text: existing?.rua ?? '');
    _numero = TextEditingController(text: existing?.numero ?? '');
    _complemento = TextEditingController(text: existing?.complemento ?? '');
  }

  @override
  void dispose() {
    _cep.dispose();
    _nome.dispose();
    _telefone.dispose();
    _bairro.dispose();
    _rua.dispose();
    _numero.dispose();
    _complemento.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ViaCEP
  // ---------------------------------------------------------------------------

  Future<void> _fetchCep(String rawCep) async {
    setState(() {
      _isFetchingCep = true;
      _cepError = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$rawCep/json/'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(
            () => _cepError = 'CEP não encontrado. Verifique e tente novamente.');
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data.containsKey('erro')) {
        setState(
            () => _cepError = 'CEP não encontrado. Verifique e tente novamente.');
        return;
      }

      final localidade = data['localidade'] as String? ?? '';
      final isBH = localidade.toLowerCase().contains('belo horizonte');
      final isContagem = localidade.toLowerCase().contains('contagem');

      if (!isBH && !isContagem) {
        _showCityNotSupportedDialog();
        return;
      }

      setState(() {
        _rua.text = data['logradouro'] as String? ?? '';
        _bairro.text = data['bairro'] as String? ?? '';
        _cidadeSelecionada =
            isBH ? 'Belo Horizonte (MG)' : 'Contagem (MG)';
      });
    } on SocketException {
      if (mounted) {
        setState(() => _cepError =
            'Sem conexão. Verifique sua internet e tente novamente.');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _cepError =
            'Sem conexão. Verifique sua internet e tente novamente.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cepError =
            'CEP não encontrado. Verifique e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isFetchingCep = false);
    }
  }

  void _showCityNotSupportedDialog() {
    setState(() {
      _rua.clear();
      _bairro.clear();
    });
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cidade não atendida'),
        content: const Text(
            'Desculpe, no momento entregamos apenas em Belo Horizonte e Contagem (MG).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Salvar
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final rawCep = _cep.text.replaceAll(RegExp(r'\D'), '');
    final cepFormatted = rawCep.length == 8
        ? '${rawCep.substring(0, 5)}-${rawCep.substring(5)}'
        : _cep.text.trim();

    final address = DeliveryAddress(
      cep: cepFormatted,
      telefone: _telefone.text.trim(),
      cidade: _cidadeSelecionada,
      bairro: _bairro.text.trim(),
      rua: _rua.text.trim(),
      numero: _numero.text.trim(),
      complemento: _complemento.text.trim(),
    );

    try {
      await context.read<AddressService>().save(
            userId,
            address,
            nomeCliente: _isGuest ? _nome.text.trim() : null,
          );
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Endereço de entrega')),
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

            // ── CEP ──────────────────────────────────────────────────────────
            TextFormField(
              controller: _cep,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [_CepFormatter()],
              decoration: InputDecoration(
                labelText: 'CEP',
                prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                suffixIcon: _isFetchingCep
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                errorText: _cepError,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                final digits = val.replaceAll(RegExp(r'\D'), '');
                if (digits.length == 8) _fetchCep(digits);
                if (_cepError != null) setState(() => _cepError = null);
              },
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Informe o CEP';
                if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value)) {
                  return 'CEP inválido (formato 00000-000)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Nome (somente convidados) ─────────────────────────────────────
            if (_isGuest) ...[
              _field(
                controller: _nome,
                label: 'Nome',
                icon: Icons.person_rounded,
                required: true,
                validatorMsg: 'Por favor, informe seu nome',
              ),
              const SizedBox(height: 16),
            ],

            // ── Telefone ─────────────────────────────────────────────────────
            _field(
              controller: _telefone,
              label: 'Telefone / WhatsApp',
              icon: Icons.phone_rounded,
              required: true,
              keyboardType: TextInputType.phone,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),

            // ── Cidade picker ─────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              key: ValueKey(_cidadeSelecionada),
              initialValue: _cidadeSelecionada,
              decoration: InputDecoration(
                labelText: 'Cidade *',
                prefixIcon:
                    const Icon(Icons.location_city_rounded, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              items: _cidades
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _cidadeSelecionada = v;
              },
            ),
            const SizedBox(height: 16),

            // ── Bairro ───────────────────────────────────────────────────────
            _field(
              controller: _bairro,
              label: 'Bairro',
              icon: Icons.map_rounded,
              required: true,
            ),
            const SizedBox(height: 16),

            // ── Rua ──────────────────────────────────────────────────────────
            _field(
              controller: _rua,
              label: 'Rua / Avenida',
              icon: Icons.signpost_rounded,
              required: true,
            ),
            const SizedBox(height: 16),

            // ── Número + Complemento ──────────────────────────────────────────
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
    String? validatorMsg,
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
          ? (v) => (v == null || v.trim().isEmpty)
              ? (validatorMsg ?? 'Preencha o $label')
              : null
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Formatter CEP: 00000-000
// ---------------------------------------------------------------------------

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5) buf.write('-');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
