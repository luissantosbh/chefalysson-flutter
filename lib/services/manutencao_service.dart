// services/manutencao_service.dart
// Escuta settings/app em tempo real e expõe emManutencao para a plataforma atual.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ManutencaoService extends ChangeNotifier {
  bool _emManutencaoIOS = false;
  bool _emManutencaoAndroid = false;

  ManutencaoService() {
    FirebaseFirestore.instance.doc('settings/app').snapshots().listen((snap) {
      final data = snap.data() ?? {};
      _emManutencaoIOS = data['emManutencaoIOS'] as bool? ?? false;
      _emManutencaoAndroid = data['emManutencaoAndroid'] as bool? ?? false;
      notifyListeners();
    });
  }

  bool get emManutencao =>
      Platform.isIOS ? _emManutencaoIOS : _emManutencaoAndroid;
}
