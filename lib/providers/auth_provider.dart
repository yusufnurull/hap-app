// State autentikasi pengguna.
//
// Prototipe: peran ditentukan dari email. Ganti dengan FirebaseAuth lewat
// services/auth_service.dart saat backend siap.

import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';

class AuthProvider extends ChangeNotifier {
  UserRole? _role;
  UserRole? get role => _role;
  bool get isLoggedIn => _role != null;

  static UserRole roleForEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) return UserRole.admin;
    if (lower.contains('penjual') ||
        lower.contains('busri') ||
        lower.contains('joko')) {
      return UserRole.penjual;
    }
    return UserRole.pembeli;
  }

  UserRole login(String email) {
    _role = roleForEmail(email);
    notifyListeners();
    return _role!;
  }

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void logout() {
    _role = null;
    notifyListeners();
  }
}
