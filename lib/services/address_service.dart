// services/address_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:chef_alysson/models/address.dart';

class AddressService extends ChangeNotifier {
  DeliveryAddress? _address;
  bool _isLoading = false;

  DeliveryAddress? get address => _address;
  bool get isLoading => _isLoading;
  bool get hasAddress => _address != null && _address!.isValid;

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();
      final raw = data?['deliveryAddress'];
      if (raw is Map<String, dynamic>) {
        _address = DeliveryAddress.fromMap(raw);
      }
    } catch (_) {
      // Silently ignore load errors — user will be prompted to fill in
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(String userId, DeliveryAddress address,
      {String? nomeCliente}) async {
    final Map<String, dynamic> data = {'deliveryAddress': address.toMap()};
    if (nomeCliente != null && nomeCliente.isNotEmpty) {
      data['nomeCliente'] = nomeCliente;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
    _address = address;
    notifyListeners();
  }

  void clear() {
    _address = null;
    notifyListeners();
  }
}
