// Daftar pesanan masuk untuk penjual: Baru, Diproses, Siap.

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

const List<String> _rejectReasons = ['Stok habis', 'Stand segera tutup', 'Lainnya'];

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  static const _tabs = [
    SellerOrderStatus.baru,
    SellerOrderStatus.diproses,
    SellerOrderStatus.siap,
  ];
  int _tab = 0;

  Future<void> _reject(SellerOrderModel order) async {
    final store = context.read<AppStore>();
    final result = await showHapSheet<_RejectResult>(
      context,
      builder: (_) => _RejectSheet(orderCode: order.orderCode),
    );
    if (result != null) {
      store.rejectSellerOrder(order.id, reason: result.reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stand = store.sellerStand;
    final counts = getOrderCounts(store.sellerOrders);
    final active = _tabs[_tab];
    final orders = sortOrdersByPickupTime(
      store.sellerOrders.where((o) => o.status == active).toList(),
    );

    return Column(
      children: [
        RoleHeader(
          subtitle: '${stand.name} · ${stand.locationNote}',
          badge: 'Hap! Penjual',
          title: 'Pesanan Masuk',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentPills(
            labels: [
              'Baru (${counts.baru})',
              'Diproses (${counts.diproses})',
              'Siap (${counts.siap})',
            ],
            selectedIndex: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.sort_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Diurutkan dari jam ambil terdekat',
                  style: hapText(12,
                      weight: FontWeight.w500, color: AppColors.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Belum ada pesanan di tab ${active.label}',
                          style: hapText(16, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'Pesanan yang masuk akan muncul berurutan berdasarkan jam ambil.',
                        style: hapText(14, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      OutlineAction(
                        label: 'Muat ulang contoh pesanan',
                        fullWidth: false,
                        height: 40,
                        fontSize: 13,
                        color: AppColors.textDark,
                        borderColor: AppColors.surface,
                        onPressed: store.resetDemoSellerOrders,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _OrderCard(
                    order: orders[i],
                    status: active,
                    isTopPriority: i == 0,
                    onReject: () => _reject(orders[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.status,
    required this.isTopPriority,
    required this.onReject,
  });

  final SellerOrderModel order;
  final SellerOrderStatus status;
  final bool isTopPriority;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final total = calculateOrderTotal(order.items);
    final isOverdue = status == SellerOrderStatus.siap &&
        isPickupOverdue(order.pickupTime,
            nowTime: '11.55', overdueFlag: order.isOverduePickup);

    Widget primaryOrOutline(String label, VoidCallback onTap) {
      return isTopPriority
          ? PrimaryButton(label: label, onPressed: onTap, height: 44, fontSize: 14)
          : OutlineAction(label: label, onPressed: onTap, height: 44, fontSize: 14);
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderCode,
                        style: hapText(22,
                            weight: FontWeight.w800,
                            color: AppColors.primary,
                            tabular: true,
                            height: 1.1)),
                    const SizedBox(height: 2),
                    Text(order.buyerName,
                        style: hapText(13, color: AppColors.textSoft)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Ambil ${order.pickupTime}',
                          style: hapText(15,
                              weight: FontWeight.w700, tabular: true)),
                    ],
                  ),
                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Lewat 30 menit',
                          style: hapText(12,
                              weight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const RowDivider(),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text('${item.quantity}x ${item.name}',
                            style: hapText(15, weight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(formatRupiah(item.subtotal),
                          style: hapText(13,
                              color: AppColors.textSoft, tabular: true)),
                    ],
                  ),
                  if (item.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xA6F2E6D5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(Icons.edit_note_rounded,
                                  size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(item.note!,
                                  style: hapText(13,
                                      weight: FontWeight.w600, height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bayar di tempat',
                  style: hapText(12,
                      weight: FontWeight.w500, color: AppColors.textMuted)),
              Text('Total ${formatRupiah(total)}',
                  style: hapText(15, weight: FontWeight.w800, tabular: true)),
            ],
          ),
          const SizedBox(height: 12),
          if (status == SellerOrderStatus.baru)
            Row(
              children: [
                Expanded(
                  child: primaryOrOutline(
                      'Terima', () => store.acceptSellerOrder(order.id)),
                ),
                const SizedBox(width: 8),
                TextAction(
                  label: 'Tolak',
                  fullWidth: false,
                  color: AppColors.textSoft,
                  weight: FontWeight.w600,
                  onPressed: onReject,
                ),
              ],
            )
          else if (status == SellerOrderStatus.diproses)
            primaryOrOutline(
                'Siap Diambil', () => store.markReadySellerOrder(order.id))
          else ...[
            PrimaryButton(
              label: 'Tandai Sudah Diambil',
              height: 44,
              fontSize: 14,
              onPressed: () => store.completeSellerOrder(order.id),
            ),
            if (isOverdue)
              TextAction(
                label: 'Tandai tidak diambil',
                height: 40,
                fontSize: 13,
                onPressed: () => store.markNoShowSellerOrder(order.id),
              ),
          ],
        ],
      ),
    );
  }
}

class _RejectResult {
  const _RejectResult(this.reason);
  final String? reason;
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.orderCode});
  final String orderCode;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tolak pesanan ${widget.orderCode}?',
              style: hapText(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Pilih alasan penolakan untuk pembeli.',
              style: hapText(13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _rejectReasons)
                HapChip(
                  label: r,
                  selected: _reason == r,
                  horizontal: 16,
                  vertical: 8,
                  fontSize: 13,
                  onTap: () =>
                      setState(() => _reason = _reason == r ? null : r),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Tolak pesanan',
            onPressed: () => Navigator.of(context).pop(_RejectResult(_reason)),
          ),
          const SizedBox(height: 8),
          OutlineAction(
            label: 'Kembali',
            height: 44,
            fontSize: 14,
            color: AppColors.textDark,
            borderColor: AppColors.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
