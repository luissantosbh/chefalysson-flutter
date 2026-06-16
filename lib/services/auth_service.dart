// services/auth_service.dart
// Equivalente a AuthService.swift
// Firebase Auth com Google, Apple e modo convidado (anônimo).

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:chef_alysson/models/app_user.dart';

class AuthService extends ChangeNotifier {
  AppUser? _user;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "3429544640-rbeq0uhf2gdhpr0ctospmdhflmf5591q.apps.googleusercontent.com",
  );

  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // UIDs com acesso admin
  static const _adminUIDs = {
    '4tHhHjgKQrOz1hPRhh9kziyEueC2', // Luis (developer)
    // 'UID_DO_ALYSSON',             // Alysson (chef)
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
      final rawNonce = _randomNonce();
      final hashedNonce = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        _errorMessage =
            'Apple não retornou identity token. Tente novamente.';
        notifyListeners();
        return;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final givenName = appleCredential.givenName ?? '';
      final familyName = appleCredential.familyName ?? '';
      final fullName = '$givenName $familyName'.trim();

      // Apple só envia o nome no primeiro login — persiste no Firebase Auth
      final firebaseUser = authResult.user!;
      if (fullName.isNotEmpty && firebaseUser.displayName == null) {
        await firebaseUser.updateDisplayName(fullName);
      }

      _user = AppUser(
        id: firebaseUser.uid,
        name: fullName.isNotEmpty
            ? fullName
            : (firebaseUser.displayName ?? 'Cliente'),
        email: appleCredential.email ?? firebaseUser.email ?? '',
        provider: AuthProvider.apple,
      );
      _errorMessage = null;
      notifyListeners();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        _errorMessage = 'Falha no login com Apple (${e.code}): ${e.message}';
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = 'Erro Firebase [${e.code}]: ${e.message}';
      notifyListeners();
    } catch (e) {
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
  // Dismiss error
  // -------------------------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Helpers criptográficos (Apple Sign In)
  // -------------------------------------------------------------------------

  String _randomNonce({int length = 32}) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
