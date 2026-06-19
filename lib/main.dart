// main.dart
// Equivalente a ChefAlyssonApp.swift + RootView + MainTabView

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/firebase_options.dart';
import 'package:chef_alysson/services/address_service.dart';
import 'package:chef_alysson/services/admin_alert_service.dart';
import 'package:chef_alysson/services/auth_service.dart';
import 'package:chef_alysson/services/cart_store.dart';
import 'package:chef_alysson/services/menu_service.dart';
import 'package:chef_alysson/services/order_service.dart';
import 'package:chef_alysson/views/biografia_view.dart';
import 'package:chef_alysson/views/cart_view.dart';
import 'package:chef_alysson/views/login_view.dart';
import 'package:chef_alysson/views/mais_view.dart';
import 'package:chef_alysson/views/menu_view.dart';
import 'package:chef_alysson/views/profile_view.dart';
import 'package:chef_alysson/views/promocoes_view.dart';

/// Handler de mensagens FCM em background (obrigatório fora do isolate principal)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM: pede permissão e registra handler de background
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartStore()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => AddressService()),
        ChangeNotifierProvider(create: (_) => MenuService()..startListening()),
        ChangeNotifierProvider(create: (_) => AdminAlertService()),
      ],
      child: const ChefAlyssonApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// App root
// ---------------------------------------------------------------------------

class ChefAlyssonApp extends StatelessWidget {
  const ChefAlyssonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chef Alysson',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFBF1921), // AccentRed
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const RootView(),
    );
  }
}

// ---------------------------------------------------------------------------
// RootView — decide entre Login e o app principal
// ---------------------------------------------------------------------------

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  String? _lastUserId;
  bool _adminAlertStarted = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userId = auth.user?.id;

    // Load address whenever a new user logs in
    if (userId != null && userId != _lastUserId) {
      _lastUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AddressService>().load(userId);
      });
    } else if (userId == null && _lastUserId != null) {
      _lastUserId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AddressService>().clear();
      });
    }

    // Inicia/para o serviço de alerta sonoro conforme o status de admin
    if (auth.isAdmin && !_adminAlertStarted) {
      _adminAlertStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminAlertService>().startForAdmin();
      });
    } else if (!auth.isAdmin && _adminAlertStarted) {
      _adminAlertStarted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminAlertService>().stop();
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: auth.isLoggedIn
          ? const MainTabView(key: ValueKey('main'))
          : const LoginView(key: ValueKey('login')),
    );
  }
}

// ---------------------------------------------------------------------------
// MainTabView — barra de abas principal
// ---------------------------------------------------------------------------

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cart = context.watch<CartStore>();
    final orders = context.watch<OrderService>();

    final tabs = <_TabItem>[
      const _TabItem(
        label: 'Cardápio',
        icon: Icon(Icons.restaurant_menu_rounded),
        view: MenuView(),
      ),
      _TabItem(
        label: 'Carrinho',
        icon: Badge(
          isLabelVisible: cart.totalQuantity > 0,
          label: Text('${cart.totalQuantity}'),
          child: const Icon(Icons.shopping_cart_rounded),
        ),
        view: const CartView(),
      ),
      const _TabItem(
        label: 'Biografia',
        icon: Icon(Icons.person_pin_rounded),
        view: BiografiaView(),
      ),
      const _TabItem(
        label: 'Promoções',
        icon: Icon(Icons.local_offer_rounded),
        view: PromocoesView(),
      ),
      // Admin: substitui Perfil + Admin por uma única aba "Mais"
      if (auth.isAdmin)
        _TabItem(
          label: 'Mais',
          icon: Badge(
            isLabelVisible: orders.activeOrderCount > 0,
            label: Text('${orders.activeOrderCount}'),
            child: const Icon(Icons.more_horiz_rounded),
          ),
          view: const MaisView(),
        )
      else
        const _TabItem(
          label: 'Perfil',
          icon: Icon(Icons.account_circle_rounded),
          view: ProfileView(),
        ),
    ];

    // Garante que o índice não ultrapasse o número de abas disponíveis
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.view).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: t.icon,
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final Widget icon;
  final Widget view;
  const _TabItem({required this.label, required this.icon, required this.view});
}
