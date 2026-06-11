// services/pix_payload.dart
// Equivalente a PixPayload.swift
// Gera o "PIX Copia e Cola" (BR Code) no padrão EMV® QRCPS-MPM
// definido pelo Banco Central do Brasil, incluindo o CRC16 obrigatório.

class PixPayload {
  /// Chave PIX do estabelecimento (telefone no formato +55DDDNÚMERO)
  static const pixKey = '+5531988848354';

  /// Nome do recebedor (máx. 25 caracteres, sem acentos)
  static const merchantName = 'CHEF ALYSSON';

  /// Cidade do recebedor (máx. 15 caracteres, sem acentos)
  static const merchantCity = 'BELO HORIZONTE';

  /// Monta o payload completo do PIX com valor e identificador do pedido.
  static String generate({required double amount, String txid = '***'}) {
    // Sanitiza o txid (aceita apenas letras e números, máx. 25)
    var cleanTxid = txid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleanTxid.isEmpty) cleanTxid = '***';
    if (cleanTxid.length > 25) cleanTxid = cleanTxid.substring(0, 25);

    // Campo 26: Merchant Account Information
    final merchantAccount =
        _field('00', 'br.gov.bcb.pix') + _field('01', pixKey);

    // Campo 62: Additional Data Field (txid)
    final additionalData = _field('05', cleanTxid);

    var payload = _field('00', '01') +
        _field('26', merchantAccount) +
        _field('52', '0000') +
        _field('53', '986') +
        _field('54', amount.toStringAsFixed(2)) +
        _field('58', 'BR') +
        _field('59', merchantName) +
        _field('60', merchantCity) +
        _field('62', additionalData);

    // Campo 63: CRC16
    payload += '6304';
    payload += _crc16(payload);

    return payload;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Formata campo EMV: ID + tamanho 2 dígitos + valor
  static String _field(String id, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$id$len$value';
  }

  /// CRC16-CCITT (polinômio 0x1021, valor inicial 0xFFFF)
  static String _crc16(String text) {
    var crc = 0xFFFF;
    for (final byte in text.codeUnits) {
      crc ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        if (crc & 0x8000 != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
