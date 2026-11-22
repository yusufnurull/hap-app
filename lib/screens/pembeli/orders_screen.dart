// Riwayat pesanan pembeli (tab Pesanan): Aktif dan Riwayat.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/order_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/hap_logic.dart';
import '../../models/order_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import 'order_detail_screen.dart';
import 'rating_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _tab = 0; // 0 Aktif, 1 Riwayat

  void _openDetail(OrderModel order) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(orderId: order.id),
        ),
      );

  void _openRating(OrderModel order) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RatingScreen(orderId: order.id),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final split = splitBuyerOrders(store.buyerOrders);
    final visible = _tab == 0 ? split.active : split.history;
    final tabName = _tab == 0 ? 'aktif' : 'riwayat';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surface)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pesanan Saya',
                  style: hapText(24, weight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 12),
              SegmentPills(
                labels: [
                  'Aktif (${split.active.length})',
                  'Riwayat (${split.history.length})',
                ],
                selectedIndex: _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconTile(
                          icon: Icons.receipt_long_rounded,
                          size: 56,
                          iconSize: 28),
                      const SizedBox(height: 12),
                      Text('Belum ada pesanan $tabName',
                          style: hapText(16, weight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Pesan makanan dari stand kantin dan pantau statusnya di sini.',
                        style: hapText(14, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Pesan Sekarang',
                        onPressed: () => store.setBuyerTab(0),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const RowDivider(),
                  itemBuilder: (context, i) {
                    final order = visible[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _openDetail(order),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${order.orderCode} · ${order.standName}',
                                          style: hapText(16,
                                              weight: FontWeight.w700,
                                              tabular: true)),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${order.items.length} menu · Ambil ${order.pickupTime} WIB',
                                          style: hapText(13,
                                              color: AppColors.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                          formatRupiah(
                                              calculateOrderTotal(order.items)),
                                          style: hapText(16,
                                              weight: FontWeight.w700,
                                              color: AppColors.primary,
                                              tabular: true)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatusBadge(status: order.status),
                              ],
                            ),
                          ),
                          if (order.status == OrderStatus.selesai) ...[
                            const SizedBox(height: 10),
                            if (order.ratingSubmitted)
                              Text('Rating sudah dikirim',
                                  style: hapText(12,
                                      weight: FontWeight.w500,
                                      color: AppColors.textMuted))
                            else
                              OutlineAction(
                                label: 'Beri rating',
                                fullWidth: false,
                                height: 36,
                                fontSize: 13,
                                horizontalPadding: 14,
                                onPressed: () => _openRating(order),
                              ),
                          ],
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
