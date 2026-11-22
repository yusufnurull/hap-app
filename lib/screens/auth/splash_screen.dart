// Layar pembuka aplikasi.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hap_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HapLogo(height: 140),
                    const SizedBox(height: 16),
                    Text('Pesan, ambil, hap!',
                        style: hapText(16, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Pre-order Kantin Pusat Kampus tanpa antre.',
                      textAlign: TextAlign.center,
                      style: hapText(14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'Mulai',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
