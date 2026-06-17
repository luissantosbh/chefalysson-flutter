// services/auth_service.dart
// Equivalente a AuthService.swift
// Firebase Auth com Google, Apple e modo convidado (anônimo).

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:chef_alysson/models/app_user.dart';

class AuthService extends ChangeNotifier {
  AppUser? _user;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "3429544640-rbeq0uhf2gdhpr0ctospmdhflmf5591q.apps.googleusercontent.com",
  );

  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // UIDs com acesso admin
  static const _adminUIDs = {
    '4tHhHjgKQrOz1hPRhh9kziyEueC2', // Luis (developer)
    'fe9NnG39k6QZzrpMwuZf5JM0ZmD3' // Alysson (chef)
  };
  bool get isAdmin => _adminUIDs.contains(_user?.id ?? '');

  AuthService() {
    _restorePreviousSession();
    _listenForFcmToken();
  }

  // -------------------------------------------------------------------------
  // Restaurar sessão
  // -------------------------------------------------------------------------

  void _restorePreviousSession() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    if (firebaseUser.isAnonymous) {
      _user = AppUser(
        id: firebaseUser.uid,
        name: 'Convidado',
        email: '',
        provider: AuthProvider.guest,
      );
      notifyListeners();
      return;
    }

    // Tenta restaurar Google
    _googleSignIn.signInSilently().then((googleUser) {
      if (googleUser != null) {
        _user = AppUser(
          id: firebaseUser.uid,
          name: googleUser.displayName ?? firebaseUser.displayName ?? 'Cliente',
          email: googleUser.email,
          photoURL: googleUser.photoUrl != null
              ? Uri.tryParse(googleUser.photoUrl!)
              : firebaseUser.photoURL != null
                  ? Uri.tryParse(firebaseUser.photoURL!)
                  : null,
          provider: AuthProvider.google,
        );
      } else {
        // Apple ou outro provider
        _user = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Cliente',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL != null
              ? Uri.tryParse(firebaseUser.photoURL!)
              : null,
          provider: AuthProvider.apple,
        );
      }
      notifyListeners();
    });
  }

  // -------------------------------------------------------------------------
  // Google
  // -------------------------------------------------------------------------

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // cancelado

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      _user = AppUser(
        id: authResult.user!.uid,
        name: googleUser.displayName ?? 'Cliente',
        email: googleUser.email,
        photoURL: googleUser.photoUrl != null
            ? Uri.tryParse(googleUser.photoUrl!)
            : null,
        provider: AuthProvider.google,
      );
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha no login com Google: $e';
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Apple
  // -------------------------------------------------------------------------

  Future<void> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final userCredential =
          await FirebaseAuth.instance.signInWithProvider(appleProvider);

      debugPrint('[Apple] Login ok: ${userCredential.user?.email}');

      final firebaseUser = userCredential.user!;
      final profileName =
          userCredential.additionalUserInfo?.profile?['name'] as String?;

      _user = AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? profileName ?? 'Cliente',
        email: firebaseUser.email ?? '',
        provider: AuthProvider.apple,
      );
      _errorMessage = null;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('[Apple] FirebaseAuthException — code: ${e.code}, '
          'message: ${e.message}, credential: ${e.credential}');
      if (e.code != 'canceled' && e.code != 'web-context-canceled') {
        _errorMessage = 'Erro Firebase [${e.code}]: ${e.message}';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Apple] Erro: $e');
      _errorMessage = 'Erro inesperado: $e';
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Convidado (anônimo)
  // -------------------------------------------------------------------------

  Future<void> continueAsGuest() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      _user = AppUser(
        id: result.user!.uid,
        name: 'Convidado',
        email: '',
        provider: AuthProvider.guest,
      );
    } catch (_) {
      // Fallback local
      _user = AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Convidado',
        email: '',
        provider: AuthProvider.guest,
      );
    }
    _errorMessage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Sair
  // -------------------------------------------------------------------------

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // FCM Token
  // -------------------------------------------------------------------------

  void _listenForFcmToken() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _saveFcmToken(token);
    });
    // APNS token may not be available in Simulator — ignore the error
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) _saveFcmToken(token);
    }).catchError((_) {});
  }

  void _saveFcmToken(String token) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // -------------------------------------------------------------------------
  // Excluir conta
  // -------------------------------------------------------------------------

  Future<void> deleteAccount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Remove dados do Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .get()
        .then((snap) {
      for (var doc in snap.docs) {
        doc.reference.delete();
      }
    });

    // Re-autentica e deleta conta Firebase
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.currentUser?.delete();
    await FirebaseAuth.instance.signOut();

    _user = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Dismiss error
  // -------------------------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
