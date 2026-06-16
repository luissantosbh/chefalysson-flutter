// models/app_user.dart
// Equivalente a AppUser + AuthProvider de Models.swift

enum AuthProvider { google, apple, guest }

extension AuthProviderLabel on AuthProvider {
  String get label {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.guest:
        return 'Convidado';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final Uri? photoURL;
  final AuthProvider provider;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    required this.provider,
  });
}
