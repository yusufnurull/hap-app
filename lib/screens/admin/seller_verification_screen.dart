// Layar verifikasi akun penjual.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class SellerVerificationScreen extends StatelessWidget {
  const SellerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pending = store.pendingSellers;

    return Column(
      children: [
        RoleHeader(
          subtitle: 'Menunggu persetujuan',
          badge: 'Hap! Admin',
          title: 'Verifikasi Penjual',
          trailing: Text('${pending.length} pendaftar',
              style: hapText(12,
                  weight: FontWeight.w500,
                  color: AppColors.textMuted,
                  tabular: true)),
        ),
        Expanded(
          child: pending.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconTile(
                          icon: Icons.task_alt_rounded, size: 56, iconSize: 28),
                      const SizedBox(height: 12),
                      Text('Semua pendaftar sudah diperiksa',
                          style: hapText(16, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Pendaftar penjual baru akan muncul di sini.',
                          style: hapText(14, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = pending[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(s.standName,
                                    style: hapText(17, weight: FontWeight.w700)),
                              ),
                              Text(s.appliedDate,
                                  style: hapText(12,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Pemilik: ${s.applicantName}',
                              style: hapText(14, color: AppColors.textSoft)),
                          Text(s.foodTypes,
                              style: hapText(13, color: AppColors.textMuted)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: i == 0
                                    ? PrimaryButton(
                                        label: 'Setujui',
                                        height: 44,
                                        fontSize: 14,
                                        onPressed: () =>
                                            store.approveSeller(s.id))
                                    : OutlineAction(
                                        label: 'Setujui',
                                        height: 44,
                                        fontSize: 14,
                                        onPressed: () =>
                                            store.approveSeller(s.id)),
                              ),
                              const SizedBox(width: 8),
                              TextAction(
                                label: 'Tolak',
                                fullWidth: false,
                                color: AppColors.textSoft,
                                weight: FontWeight.w600,
                                onPressed: () => store.rejectSeller(s.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
