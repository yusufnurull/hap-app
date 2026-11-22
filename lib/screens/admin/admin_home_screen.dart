// Beranda administrator: kerangka dengan navigasi bawah.

import 'package:flutter/material.dart';

import '../../widgets/role_bottom_nav.dart';
import 'manage_stands_screen.dart';
import 'report_screen.dart';
import 'seller_verification_screen.dart';
import 'users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [
            ReportScreen(),
            SellerVerificationScreen(),
            ManageStandsScreen(),
            UsersScreen(),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
        items: const [
          NavItem('Rekap', Icons.assignment_rounded),
          NavItem('Penjual', Icons.how_to_reg_rounded),
          NavItem('Stand', Icons.storefront_rounded),
          NavItem('Pengguna', Icons.group_rounded),
        ],
      ),
    );
  }
}
