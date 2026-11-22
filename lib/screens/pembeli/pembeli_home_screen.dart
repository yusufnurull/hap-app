// Beranda pembeli: kerangka dengan navigasi bawah (Beranda, Pesanan, Profil).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_store.dart';
import '../../widgets/role_bottom_nav.dart';
import 'katalog_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class PembeliHomeScreen extends StatelessWidget {
  const PembeliHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = context.select<AppStore, int>((s) => s.buyerTab);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: const [
            KatalogScreen(),
            OrdersScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: tab,
        onSelect: context.read<AppStore>().setBuyerTab,
        items: const [
          NavItem('Beranda', Icons.home_rounded),
          NavItem('Pesanan', Icons.receipt_long_rounded),
          NavItem('Profil', Icons.person_rounded),
        ],
      ),
    );
  }
}
