// State autentikasi pengguna.
//
// Sumber data utama: Firebase Auth + dokumen users/{uid} lewat AuthService.
//
// Masa peralihan: layar login/daftar dan AppStore masih memakai alur dummy
// (roleForEmail, login, setRole). Fungsi lama itu dipertahankan sampai
// layar disambungkan ke daftar()/masuk()/keluar(), lalu boleh dihapus
// bersama role_home.dart.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _injectedService = service {
    _mulaiMemantau();
  }

  final AuthService? _injectedService;
  AuthService? _serviceInstance;
  StreamSubscription<UserModel?>? _userSub;

  UserModel? _user;
  bool _isLoading = true;
  UserRole? _dummyRole; // hanya untuk alur prototipe

  /// Data akun yang sedang login (null bila belum login).
  UserModel? get user => _user;

  /// true sampai data akun pertama kali selesai dibaca.
  bool get isLoading => _isLoading;

  UserRole? get role => _user?.role ?? _dummyRole;
  bool get isLoggedIn => role != null;

  /// Penjual yang belum disetujui admin.
  bool get isWaitingApproval => _user?.isWaitingApproval ?? false;

  AuthService get _service =>
      _serviceInstance ??= _injectedService ?? AuthService();

  /// Mulai memantau akun. Aman dipanggil berkali-kali; hanya berjalan
  /// setelah Firebase selesai diinisialisasi.
  void _mulaiMemantau() {
    if (_userSub != null || Firebase.apps.isEmpty) return;
    _userSub = _service.streamUser().listen(
      (user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object _) {
        _user = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Firebase: dipakai layar login/daftar setelah disambungkan
  // ---------------------------------------------------------------------------

  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> daftar({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required UserRole role,
  }) async {
    _mulaiMemantau();
    try {
      await _service.daftar(
        nama: nama,
        email: email,
        noHp: noHp,
        password: password,
        role: role,
      );
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> masuk(String email, String password) async {
    _mulaiMemantau();
    try {
      await _service.masuk(email: email, password: password);
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  Future<void> keluar() async {
    _dummyRole = null;
    await _service.keluar();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Alur prototipe (sementara, hapus setelah layar memakai Firebase)
  // ---------------------------------------------------------------------------

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
    _dummyRole = roleForEmail(email);
    notifyListeners();
    return _dummyRole!;
  }

  void setRole(UserRole role) {
    _dummyRole = role;
    notifyListeners();
  }

  void logout() {
    _dummyRole = null;
    notifyListeners();
    if (Firebase.apps.isNotEmpty) {
      unawaited(_service.keluar());
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
