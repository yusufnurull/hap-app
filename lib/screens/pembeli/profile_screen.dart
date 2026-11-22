// Profil akun pembeli (tab Profil).

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/common.dart';
import '../role_home.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil',
              style: hapText(24, weight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surface)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    buyerProfile.name.substring(0, 1),
                    style: hapText(18,
                        weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(buyerProfile.name,
                        style: hapText(16, weight: FontWeight.w700)),
                    Text('Pembeli · Mahasiswa',
                        style: hapText(12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          _info('Nama', buyerProfile.name),
          _info('Email', buyerProfile.email),
          _info('Nomor HP', buyerProfile.phone, tabular: true),
          const Spacer(),
          OutlineAction(
            label: 'Keluar',
            onPressed: () => logoutToLogin(context),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value, {bool tabular = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surface)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: hapText(12,
                  weight: FontWeight.w500, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: hapText(15, weight: FontWeight.w600, tabular: tabular)),
        ],
      ),
    );
  }
}
