// Penentu beranda sesuai peran + helper keluar akun.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_enums.dart';
import '../providers/app_store.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'pembeli/pembeli_home_screen.dart';
import 'penjual/penjual_home_screen.dart';

Widget homeForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const Scaffold(
        body: Center(child: Text('Panel admin dikerjakan Yusuf')),
      );
    case UserRole.penjual:
      return const PenjualHomeScreen();
    case UserRole.pembeli:
      return const PembeliHomeScreen();
  }
}

/// Mengganti seluruh tumpukan layar dengan beranda [role].
void goToRoleHome(BuildContext context, UserRole role) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => homeForRole(role)),
    (_) => false,
  );
}

void logoutToLogin(BuildContext context) {
  context.read<AuthProvider>().logout();
  context.read<AppStore>().logout();
  context.read<AppStore>().setBuyerTab(0);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
