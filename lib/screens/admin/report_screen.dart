// Rekap aktivitas dan transaksi hari ini.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final metrics = [
      ('Pesanan hari ini', store.totalOrdersToday),
      ('Selesai', store.completedOrdersToday),
      ('Stand buka', store.stands.where((s) => s.isOpen).length),
      ('Penjual menunggu', store.pendingSellers.length),
    ];

    Widget metricCard((String, int) m) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.$1,
                    style: hapText(12,
                        weight: FontWeight.w500, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('${m.$2}',
                    style: hapText(28, weight: FontWeight.w800, tabular: true)),
              ],
            ),
          ),
        );

    return Column(
      children: [
        const RoleHeader(
          subtitle: 'Kantin Pusat Kampus',
          badge: 'Hap! Admin',
          title: 'Rekap Hari Ini',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                metricCard(metrics[0]),
                const SizedBox(width: 10),
                metricCard(metrics[1]),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                metricCard(metrics[2]),
                const SizedBox(width: 10),
                metricCard(metrics[3]),
              ]),
              const SizedBox(height: 24),
              Text('Pesanan per Stand',
                  style: hapText(18, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              const RowDivider(),
              for (final s in store.stands)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.surface)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: hapText(15, weight: FontWeight.w600)),
                            Text('${s.isOpen ? 'Buka' : 'Tutup'} · ${s.openHours}',
                                style: hapText(12,
                                    color: AppColors.textMuted, tabular: true)),
                          ],
                        ),
                      ),
                      Text('${s.todayOrders} pesanan',
                          style: hapText(14,
                              weight: FontWeight.w700, tabular: true)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
