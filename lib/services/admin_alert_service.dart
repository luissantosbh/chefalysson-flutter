// services/admin_alert_service.dart
// Polling para pedidos com status pagamento_confirmado + alerta sonoro para admin.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AdminAlertService extends ChangeNotifier {
  Timer? _timer;
  AudioPlayer? _player;
  Uint8List? _alertBytes;
  final Set<String> _knownOrderIds = {};
  bool _hasUnviewedAlerts = false;
  bool _active = false;

  bool get hasUnviewedAlerts => _hasUnviewedAlerts;

  Future<void> startForAdmin() async {
    if (_active) return;
    debugPrint('[AdminAlert] startForAdmin()');
    _active = true;
    await _init();
    await _poll();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
    debugPrint('[AdminAlert] timer iniciado (10s)');
  }

  Future<void> _init() async {
    // Carrega o WAV via rootBundle (caminho garantido pelo Flutter)
    try {
      final data = await rootBundle.load('assets/sounds/alerta.wav');
      _alertBytes = data.buffer.asUint8List();
      debugPrint('[AdminAlert] WAV carregado: ${_alertBytes!.length} bytes');
    } catch (e) {
      debugPrint('[AdminAlert] ERRO ao carregar WAV: $e');
    }

    _player?.dispose();
    _player = AudioPlayer();

    // Configura para tocar no canal de alarme — ignora modo silencioso
    // e não depende do volume de mídia
    try {
      await _player!.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          isSpeakerphoneOn: false,
          stayAwake: false,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
      debugPrint('[AdminAlert] audio context configurado (ALARM)');
    } catch (e) {
      debugPrint('[AdminAlert] aviso audio context: $e');
    }

    _player!.onPlayerStateChanged.listen((s) => debugPrint('[AdminAlert] player state: $s'));
    _player!.onLog.listen((m) => debugPrint('[AdminAlert] player log: $m'));

    await _player!.setReleaseMode(ReleaseMode.loop);
    await _player!.setVolume(1.0);
    debugPrint('[AdminAlert] player pronto');
  }

  void stop() {
    debugPrint('[AdminAlert] stop()');
    _active = false;
    _timer?.cancel();
    _timer = null;
    _player?.stop();
    _player?.dispose();
    _player = null;
    _hasUnviewedAlerts = false;
    _knownOrderIds.clear();
    notifyListeners();
  }

  void acknowledge() {
    debugPrint('[AdminAlert] acknowledge()');
    _hasUnviewedAlerts = false;
    _player?.stop();
    notifyListeners();
  }

  // Toca o som imediatamente — para teste manual pelo admin
  Future<void> testSound() async {
    debugPrint('[AdminAlert] testSound()');
    if (_player == null) await _init();
    await _playAlert();
    // Para após 3s no modo de teste
    Future.delayed(const Duration(seconds: 3), () {
      _player?.stop();
      debugPrint('[AdminAlert] testSound parado');
    });
  }

  Future<void> _poll() async {
    if (!_active) return;
    debugPrint('[AdminAlert] poll()...');

    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pagamento_confirmado')
          .get();

      debugPrint('[AdminAlert] ${snap.docs.length} pedido(s) pagamento_confirmado');

      bool newOrderFound = false;
      for (final doc in snap.docs) {
        if (!_knownOrderIds.contains(doc.id)) {
          _knownOrderIds.add(doc.id);
          newOrderFound = true;
          debugPrint('[AdminAlert] NOVO pedido: ${doc.id}');
        }
      }

      if (newOrderFound && !_hasUnviewedAlerts) {
        _hasUnviewedAlerts = true;
        await _playAlert();
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('[AdminAlert] ERRO poll: $e\n$st');
    }
  }

  Future<void> _playAlert() async {
    debugPrint('[AdminAlert] _playAlert()');
    try {
      if (_player == null) await _init();
      if (_alertBytes == null) {
        debugPrint('[AdminAlert] sem bytes, abortando');
        return;
      }
      await _player!.play(BytesSource(_alertBytes!));
      debugPrint('[AdminAlert] play() OK');
    } catch (e, st) {
      debugPrint('[AdminAlert] ERRO ao tocar: $e\n$st');
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
