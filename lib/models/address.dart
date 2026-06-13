// models/address.dart

class DeliveryAddress {
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String complemento;
  final String telefone;

  const DeliveryAddress({
    required this.cidade,
    required this.bairro,
    required this.rua,
    required this.numero,
    required this.telefone,
    this.complemento = '',
  });

  Map<String, dynamic> toMap() => {
        'cidade': cidade,
        'bairro': bairro,
        'rua': rua,
        'numero': numero,
        'complemento': complemento,
        'telefone': telefone,
      };

  factory DeliveryAddress.fromMap(Map<String, dynamic> m) => DeliveryAddress(
        cidade: m['cidade'] as String? ?? '',
        bairro: m['bairro'] as String? ?? '',
        rua: m['rua'] as String? ?? '',
        numero: m['numero'] as String? ?? '',
        complemento: m['complemento'] as String? ?? '',
        telefone: m['telefone'] as String? ?? '',
      );

  bool get isValid =>
      cidade.trim().isNotEmpty &&
      bairro.trim().isNotEmpty &&
      rua.trim().isNotEmpty &&
      numero.trim().isNotEmpty &&
      telefone.trim().isNotEmpty;

  String get summary =>
      '$rua, $numero${complemento.isNotEmpty ? ' – $complemento' : ''}\n$bairro – $cidade';
}
