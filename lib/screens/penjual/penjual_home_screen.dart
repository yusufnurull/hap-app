// Beranda penjual: kerangka dengan navigasi bawah (Pesanan, Menu, Stand).

import 'package:flutter/material.dart';

import '../../widgets/role_bottom_nav.dart';
import 'incoming_orders_screen.dart';
import 'manage_menu_screen.dart';
import 'stand_profile_screen.dart';

class PenjualHomeScreen extends StatefulWidget {
  const PenjualHomeScreen({super.key});

  @override
  State<PenjualHomeScreen> createState() => _PenjualHomeScreenState();
}

class _PenjualHomeScreenState extends State<PenjualHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [
            IncomingOrdersScreen(),
            ManageMenuScreen(),
            StandProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
        items: const [
          NavItem('Pesanan', Icons.receipt_long_rounded),
          NavItem('Menu', Icons.restaurant_menu_rounded),
          NavItem('Stand', Icons.storefront_rounded),
        ],
      ),
    );
  }
}
