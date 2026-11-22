// Konfigurasi utama aplikasi Hap!.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_store.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';

class HapApp extends StatelessWidget {
  const HapApp({super.key});

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
        home: const SplashScreen(),
      ),
    );
  }
}
