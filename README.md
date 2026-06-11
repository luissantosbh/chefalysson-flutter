# Chef Alysson — Flutter

Migração do app iOS nativo para Flutter.

---

## Pré-requisitos

- Flutter SDK ≥ 3.3 — https://docs.flutter.dev/get-started/install
- Conta no Firebase com o mesmo projeto do app iOS
- Xcode (para build iOS) e Android Studio (para build Android)

---

## Setup em 5 passos

### 1. Copiar as imagens de assets

Crie a pasta `assets/images/` na raiz do projeto e copie as imagens do app iOS:

```
assets/images/
  biografia.jpg
  cardapioPrincipal.jpg
  combinadoSalmao.jpg
  inauguracao.jpg
  sorteioBarca.jpg
```

As imagens estão em `AppChefAlysson/Cardapio/` e `AppChefAlysson/ChefAlysson/ChefAlysson/Assets.xcassets/`.

### 2. Instalar as dependências

```bash
flutter pub get
```

### 3. Configurar o Firebase (FlutterFire CLI)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Isso vai gerar o arquivo `lib/firebase_options.dart` com as chaves reais do seu projeto.

> O comando detecta automaticamente o `GoogleService-Info.plist` do projeto iOS existente.

### 4. Configurar Google Sign-In no iOS

No arquivo `ios/Runner/Info.plist`, adicione o `REVERSED_CLIENT_ID` do seu Google:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.SEU_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

O valor está em `client_3429544640-r15i9n1r2orqprbqjstvkdr063jnen9c.apps.googleusercontent.com.plist` do projeto iOS.

### 5. Rodar o app

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

---

## Estrutura do projeto

```
lib/
  main.dart               # Entry point + RootView + MainTabView
  firebase_options.dart   # Gerado pelo flutterfire configure
  models/
    app_user.dart         # AppUser + AuthProvider
    food_category.dart    # FoodCategory (enum)
    menu_item.dart        # MenuItem + MenuData
    cart_item.dart        # CartItem
    order.dart            # Order + OrderStatus + OrderLineItem
  services/
    auth_service.dart     # Firebase Auth (Google + Apple + Guest)
    cart_store.dart       # Estado local do carrinho
    order_service.dart    # Firestore — pedidos em tempo real
    pix_payload.dart      # Gerador de BR Code PIX (EMV/CRC16)
  views/
    login_view.dart
    menu_view.dart
    cart_view.dart
    pix_checkout_view.dart
    biografia_view.dart
    promocoes_view.dart
    profile_view.dart
    meus_pedidos_view.dart
    admin_orders_view.dart
```

---

## Equivalências iOS → Flutter

| iOS / Swift                | Flutter / Dart                         |
|----------------------------|----------------------------------------|
| `ObservableObject`         | `ChangeNotifier`                       |
| `@Published`               | `notifyListeners()`                    |
| `@EnvironmentObject`       | `context.watch<T>()` (Provider)        |
| `@StateObject`             | `ChangeNotifierProvider`               |
| `TabView`                  | `NavigationBar` + `IndexedStack`       |
| `NavigationStack`          | `Navigator` + `MaterialPageRoute`      |
| `List` (SwiftUI)           | `ListView.builder`                     |
| `sheet`                    | `Navigator.push(fullscreenDialog: true)`|
| `AsyncImage`               | `CachedNetworkImage`                   |
| `CoreImage` QR Code        | `QrImageView` (qr_flutter)             |
| `UIPasteboard`             | `Clipboard.setData`                    |

---

## Admin

O UID do admin está em `lib/services/auth_service.dart`:

```dart
static const _adminUIDs = {
  '4tHhHjgKQrOz1hPRhh9kziyEueC2', // Luis (developer)
  // 'UID_DO_ALYSSON',             // descomente quando o Alysson fizer login
};
```
