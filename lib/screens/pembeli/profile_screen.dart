// Profil akun pembeli (tab Profil).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().currentUser;
    final name = user?.name ?? 'Pengguna';
    final email = user?.email ?? '-';
    final phone = user?.phone ?? '-';
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
                    name.isEmpty ? '?' : name.substring(0, 1),
                    style: hapText(18,
                        weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
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
          _info('Nama', name),
          _info('Email', email),
          _info('Nomor HP', phone, tabular: true),
          const Spacer(),
          OutlineAction(
            label: 'Keluar',
            onPressed: () async {
              try {
                await AuthService().keluar();
                if (!context.mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal keluar: $error')));
              }
            },
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
