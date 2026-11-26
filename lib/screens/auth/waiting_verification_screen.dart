// Layar menunggu verifikasi penjual.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class WaitingVerificationScreen extends StatelessWidget {
  const WaitingVerificationScreen({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.hourglass_top_rounded,
                          size: 32, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 20),
                    Text('Menunggu Verifikasi',
                        style: hapText(24, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Akun penjualmu sedang diperiksa admin kantin sebelum stand dapat dibuka.',
                      style: hapText(14, color: AppColors.textSoft, height: 1.45),
                    ),
                  ],
                ),
              ),
              OutlineAction(
                label: 'Keluar',
                color: AppColors.textDark,
                borderColor: AppColors.outline,
                onPressed: () async {
                  try {
                    await AuthService().keluar();
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal keluar: $error')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
