// Konfigurasi utama aplikasi Hap!.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_enums.dart';
import 'core/constants/firestore_collections.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/app_store.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/waiting_verification_screen.dart';
import 'screens/pembeli/pembeli_home_screen.dart';
import 'screens/penjual/penjual_home_screen.dart';

class HapApp extends StatelessWidget {
  const HapApp({super.key});

  static final Future<FirebaseApp> _firebaseInitialization =
      Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hap!',
        theme: AppTheme.light,
        home: FutureBuilder<FirebaseApp>(
          future: _firebaseInitialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SplashScreen();
            }
            if (snapshot.hasError) {
              return _RouteMessageScreen(
                message: 'Firebase gagal diinisialisasi: ${snapshot.error}',
              );
            }
            return const _AuthRouter();
          },
        ),
      ),
    );
  }
}

class _AuthRouter extends StatelessWidget {
  const _AuthRouter();

  @override
  Widget build(BuildContext context) {
    // TODO: ganti dengan auth_service dari Rafli.
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return _RouteMessageScreen(
            message: 'Gagal memeriksa status login: ${authSnapshot.error}',
            onSignOut: () => _signOut(context),
          );
        }
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return _RouteMessageScreen(
                message: 'Gagal memuat data akun: ${userSnapshot.error}',
                onSignOut: () => _signOut(context),
              );
            }
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final document = userSnapshot.data;
            if (document == null || !document.exists) {
              return _RouteMessageScreen(
                message: 'Data akun tidak ditemukan',
                onSignOut: () => _signOut(context),
              );
            }

            final data = document.data();
            if (data == null) {
              return _RouteMessageScreen(
                message: 'Data akun tidak ditemukan',
                onSignOut: () => _signOut(context),
              );
            }

            final status = data['status'];
            final user = _userFromDocument(document.id, data);
            if (user == null || !_isKnownStatus(status)) {
              return _RouteMessageScreen(
                message: 'Data akun tidak lengkap atau tidak valid',
                onSignOut: () => _signOut(context),
              );
            }

            // TODO: pindahkan nilai status ke konstanta saat sudah tersedia.
            if (status == 'nonaktif') {
              return _RouteMessageScreen(
                message: 'Akun kamu dinonaktifkan admin',
                onSignOut: () => _signOut(context),
              );
            }

            switch (user.role) {
              case UserRole.admin:
                return const AdminHomeScreen();
              case UserRole.penjual:
                if (status == 'menunggu') {
                  return const WaitingVerificationScreen();
                }
                if (status == 'aktif') {
                  return const PenjualHomeScreen();
                }
                return _RouteMessageScreen(
                  message: 'Status akun penjual tidak valid',
                  onSignOut: () => _signOut(context),
                );
              case UserRole.pembeli:
                return const PembeliHomeScreen();
            }
          },
        );
      },
    );
  }

  static UserModel? _userFromDocument(String id, Map<String, dynamic> data) {
    final name = data['nama'];
    final email = data['email'];
    final phone = data['noHp'];
    final role = _roleFromValue(data['role']);
    final status = data['status'];
    final noShowCount = data['jumlahTidakDiambil'];

    if (name is! String ||
        email is! String ||
        phone is! String ||
        role == null ||
        !_isKnownStatus(status) ||
        (noShowCount != null && noShowCount is! num)) {
      return null;
    }

    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: status != 'nonaktif',
      noShowCount: (noShowCount as num?)?.toInt() ?? 0,
    );
  }

  static UserRole? _roleFromValue(Object? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'penjual':
        return UserRole.penjual;
      case 'pembeli':
        return UserRole.pembeli;
      default:
        return null;
    }
  }

  static bool _isKnownStatus(Object? status) =>
      status == 'aktif' || status == 'menunggu' || status == 'nonaktif';

  static Future<void> _signOut(BuildContext context) async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Tidak dapat keluar dari akun.'),
          ),
        );
      }
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _RouteMessageScreen extends StatelessWidget {
  const _RouteMessageScreen({required this.message, this.onSignOut});

  final String message;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onSignOut,
                    child: const Text('Keluar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
