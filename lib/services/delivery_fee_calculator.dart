// services/delivery_fee_calculator.dart
// Calcula a distância até o restaurante e a taxa de entrega correspondente.

import 'package:geolocator/geolocator.dart';

class DeliveryFeeCalculator {
  DeliveryFeeCalculator._();

  /// Endereço fixo do restaurante — Rua Paraúna, 404, Serrano, Belo
  /// Horizonte - MG, 30882-410.
  static const restaurantLatitude = -19.8823661;
  static const restaurantLongitude = -44.0098747;

  /// Distância em linha reta (metros) entre o restaurante e o ponto informado.
  static double distanciaMetros(double latitude, double longitude) {
    return Geolocator.distanceBetween(
      restaurantLatitude,
      restaurantLongitude,
      latitude,
      longitude,
    );
  }

  /// Tabela de taxas por faixa de distância. Ajuste os valores/faixas aqui.
  static double calcularTaxaEntrega(double distanciaMetros) {
    if (distanciaMetros <= 2000) return 5.00;
    if (distanciaMetros <= 3000) return 5.00;
    if (distanciaMetros <= 5000) return 8.00;
    if (distanciaMetros <= 10000) return 10.00;
    return 15.00;
  }
}
