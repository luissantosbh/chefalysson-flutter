// services/geocoding_service.dart
// Converte CEP em latitude/longitude usando duas APIs públicas e gratuitas:
//   1. ViaCEP    — CEP -> endereço (logradouro, bairro, cidade, UF)
//   2. Nominatim — endereço -> latitude/longitude (OpenStreetMap)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GeoPoint {
  final double latitude;
  final double longitude;
  const GeoPoint(this.latitude, this.longitude);
}

/// Erro amigável — a mensagem já vem pronta para exibição ao usuário.
class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);

  @override
  String toString() => message;
}

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  /// Nominatim exige um User-Agent identificável (política de uso da API).
  static const _nominatimUserAgent =
      'ChefAlyssonApp/1.0 (contato@chefalysson.com.br)';

  static const _timeout = Duration(seconds: 10);

  /// Cache em memória (válido durante a sessão do app) — evita repetir
  /// chamadas às APIs externas para o mesmo CEP.
  final Map<String, GeoPoint> _cache = {};

  Future<GeoPoint> geocodeCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw const GeocodingException(
          'CEP inválido. Verifique e tente novamente.');
    }

    final cached = _cache[digits];
    if (cached != null) return cached;

    final endereco = await _fetchViaCep(digits);
    final point = await _fetchNominatim(endereco);

    _cache[digits] = point;
    return point;
  }

  void clearCache() => _cache.clear();

  // ---------------------------------------------------------------------
  // ViaCEP
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchViaCep(String digits) async {
    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw const GeocodingException(
            'CEP não encontrado. Verifique e tente novamente.');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('erro')) {
        throw const GeocodingException(
            'CEP não encontrado. Verifique e tente novamente.');
      }
      return data;
    } on GeocodingException {
      rethrow;
    } on SocketException {
      throw const GeocodingException(
          'Sem conexão. Verifique sua internet e tente novamente.');
    } on TimeoutException {
      throw const GeocodingException(
          'Sem conexão. Verifique sua internet e tente novamente.');
    } catch (_) {
      throw const GeocodingException(
          'CEP não encontrado. Verifique e tente novamente.');
    }
  }

  // ---------------------------------------------------------------------
  // Nominatim (OpenStreetMap)
  // ---------------------------------------------------------------------

  Future<GeoPoint> _fetchNominatim(Map<String, dynamic> viaCepData) async {
    final logradouro = viaCepData['logradouro'] as String? ?? '';
    final bairro = viaCepData['bairro'] as String? ?? '';
    final localidade = viaCepData['localidade'] as String? ?? '';
    final uf = viaCepData['uf'] as String? ?? '';

    final query = [logradouro, bairro, localidade, uf, 'Brasil']
        .where((p) => p.trim().isNotEmpty)
        .join(', ');

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'br',
    });

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _nominatimUserAgent})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw const GeocodingException(
            'Não foi possível localizar seu endereço. Tente novamente ou '
            'digite o endereço manualmente.');
      }

      final results = json.decode(response.body) as List<dynamic>;
      if (results.isEmpty) {
        throw const GeocodingException(
            'Não foi possível localizar seu endereço. Tente novamente ou '
            'digite o endereço manualmente.');
      }

      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) {
        throw const GeocodingException(
            'Não foi possível localizar seu endereço. Tente novamente ou '
            'digite o endereço manualmente.');
      }

      return GeoPoint(lat, lon);
    } on GeocodingException {
      rethrow;
    } on SocketException {
      throw const GeocodingException(
          'Sem conexão. Verifique sua internet e tente novamente.');
    } on TimeoutException {
      throw const GeocodingException(
          'Sem conexão. Verifique sua internet e tente novamente.');
    } catch (_) {
      throw const GeocodingException(
          'Não foi possível localizar seu endereço. Tente novamente ou '
          'digite o endereço manualmente.');
    }
  }
}
