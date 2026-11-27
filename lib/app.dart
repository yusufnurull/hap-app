// Konfigurasi utama aplikasi Hap!.

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_enums.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/app_store.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
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

class _AuthRouter extends StatefulWidget {
  const _AuthRouter();

  @override
  State<_AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<_AuthRouter> {
  static final AuthService _authService = AuthService();
  String? _syncedUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: _authService.authStateChanges(),
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
          _syncedUserId = null;
          return const LoginScreen();
        }

        return StreamBuilder<UserModel?>(
          stream: _authService.streamUser(),
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

            final user = userSnapshot.data;
            if (user == null) {
              return _RouteMessageScreen(
                message: 'Data akun tidak ditemukan',
                onSignOut: () => _signOut(context),
              );
            }
            if (user.id != firebaseUser.uid) {
              return const _LoadingScreen();
            }

            final status = user.status;
            if (!_isKnownStatus(status)) {
              return _RouteMessageScreen(
                message: 'Data akun tidak lengkap atau tidak valid',
                onSignOut: () => _signOut(context),
              );
            }

            _syncAppStoreUser(user);

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

  void _syncAppStoreUser(UserModel user) {
    if (_syncedUserId == user.id) return;

    _syncedUserId = user.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _syncedUserId != user.id) return;

      context.read<AppStore>().syncFirebaseUser(user);
    });
  }

  static bool _isKnownStatus(String status) =>
      status == 'aktif' || status == 'menunggu' || status == 'nonaktif';

  static Future<void> _signOut(BuildContext context) async {
    try {
      await _authService.keluar();
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
