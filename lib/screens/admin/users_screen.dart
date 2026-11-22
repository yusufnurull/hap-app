// Daftar pengguna aplikasi untuk administrator.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hap_logic.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  UserRole? _role; // null = Semua

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final users = filterUsersByRole(store.users, _role);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surface)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Pengguna',
                      style: hapText(24, weight: FontWeight.w800, height: 1.15)),
                  Text('${users.length} akun',
                      style: hapText(12,
                          weight: FontWeight.w500,
                          color: AppColors.textMuted,
                          tabular: true)),
                ],
              ),
              const SizedBox(height: 12),
              ChipRow(
                gap: 8,
                children: [
                  HapChip(
                    label: 'Semua',
                    selected: _role == null,
                    horizontal: 14,
                    onTap: () => setState(() => _role = null),
                  ),
                  for (final r in UserRole.values)
                    HapChip(
                      label: r.label,
                      selected: _role == r,
                      horizontal: 14,
                      onTap: () => setState(() => _role = r),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const RowDivider(),
            itemBuilder: (context, i) {
              final u = users[i];
              return Opacity(
                opacity: u.isActive ? 1 : 0.6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                style: hapText(15, weight: FontWeight.w600)),
                            Text(u.email,
                                style: hapText(12, color: AppColors.textMuted)),
                            Text(
                                '${u.role.label} · ${u.isActive ? 'Aktif' : 'Nonaktif'}',
                                style: hapText(12,
                                    weight: FontWeight.w500,
                                    color: AppColors.textSoft)),
                            if (u.role == UserRole.pembeli && u.noShowCount >= 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                    'Tidak diambil: ${u.noShowCount} kali',
                                    style: hapText(12,
                                        weight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlineAction(
                        label: u.isActive ? 'Nonaktifkan' : 'Aktifkan',
                        fullWidth: false,
                        height: 36,
                        fontSize: 12,
                        horizontalPadding: 12,
                        color: u.isActive ? AppColors.primary : AppColors.textDark,
                        borderColor:
                            u.isActive ? AppColors.primary : AppColors.outline,
                        onPressed: () => store.toggleUserActive(u.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
