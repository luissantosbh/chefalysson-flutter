// services/admin_alert_service.dart
// Polling para pedidos com status pagamento_confirmado + alerta sonoro para admin.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminAlertService extends ChangeNotifier {
  Timer? _timer;
  final AudioPlayer _player = AudioPlayer();
  final Set<String> _knownOrderIds = {};
  bool _hasUnviewedAlerts = false;
  bool _active = false;

  bool get hasUnviewedAlerts => _hasUnviewedAlerts;

  void startForAdmin() {
    if (_active) return;
    _active = true;
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _player.stop();
    _hasUnviewedAlerts = false;
    _knownOrderIds.clear();
    notifyListeners();
  }

  // Chamado quando o admin abre a tela de pedidos — para o som.
  void acknowledge() {
    _hasUnviewedAlerts = false;
    _player.stop();
    notifyListeners();
  }

  Future<void> _poll() async {
    if (!_active) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pagamento_confirmado')
          .get();

      bool newOrderFound = false;
      for (final doc in snap.docs) {
        if (!_knownOrderIds.contains(doc.id)) {
          _knownOrderIds.add(doc.id);
          newOrderFound = true;
        }
      }

      if (newOrderFound && !_hasUnviewedAlerts) {
        _hasUnviewedAlerts = true;
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('sounds/alerta.wav'));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AdminAlertService] poll error: $e');
    }
  }

  @override
  void dispose() {
    stop();
    _player.dispose();
    super.dispose();
  }
}
