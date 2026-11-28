// Detail status dan informasi pesanan, termasuk stepper progres.

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
import '../../widgets/order_ticket.dart';
import 'rating_screen.dart';

const List<OrderStatus> _stepOrder = [
  OrderStatus.menunggu,
  OrderStatus.diproses,
  OrderStatus.siapDiambil,
  OrderStatus.selesai,
];

const List<String> _cancelReasons = [
  'Salah pesan',
  'Jadwal berubah',
  'Lainnya',
];

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  void _orderAgain(BuildContext context) {
    context.read<AppStore>().setBuyerTab(0);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _cancel(BuildContext context, OrderModel order) async {
    final store = context.read<AppStore>();
    final result = await showHapSheet<_CancelResult>(
      context,
      builder: (_) => const _CancelSheet(),
    );
    if (result != null) {
      final error = await store.cancelBuyerOrder(
        order.id,
        reason: result.reason,
      );
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final order = store.buyerOrderById(orderId);
    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('Pesanan tidak ditemukan')),
      );
    }

    final total = calculateOrderTotal(order.items);
    final stepIndex =
        (order.status == OrderStatus.dibatalkan ||
            order.status == OrderStatus.tidakDiambil)
        ? -1
        : _stepOrder.indexOf(order.status);
    final location = store.standById(order.standId)?.locationNote;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Detail Pesanan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  OrderTicket(
                    orderCode: order.orderCode,
                    standName: order.standName,
                    pickupTime: '${order.pickupTime} WIB',
                    status: order.status,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Progres Pesanan',
                    style: hapText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _progress(order, stepIndex),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surface),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 22,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lokasi ambil · ${location ?? 'Area Kantin'}',
                                style: hapText(
                                  12,
                                  weight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                order.standName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: hapText(15, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Jam ambil',
                              style: hapText(
                                12,
                                weight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '${order.pickupTime} WIB',
                              style: hapText(
                                15,
                                weight: FontWeight.w700,
                                tabular: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rincian Pesanan',
                    style: hapText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const RowDivider(),
                  for (final item in order.items) _itemRow(item),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total bayar',
                        style: hapText(15, weight: FontWeight.w600),
                      ),
                      Text(
                        formatRupiah(total),
                        style: hapText(
                          18,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                          tabular: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Metode pembayaran',
                        style: hapText(13, color: const Color(0xB3302B27)),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: AppColors.textDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.paymentMethod,
                            style: hapText(13, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ..._actions(context, order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(OrderModel order, int stepIndex) {
    if (order.status == OrderStatus.dibatalkan) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan ini dibatalkan.',
              style: hapText(
                14,
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (order.cancelReason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Alasan: ${order.cancelReason}',
                style: hapText(13, color: AppColors.textSoft),
              ),
            ],
          ],
        ),
      );
    }
    if (order.status == OrderStatus.tidakDiambil) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0D302B27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          'Pesanan melewati batas waktu pengambilan dan ditandai tidak diambil.',
          style: hapText(14),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < order.timeline.length; i++)
          _step(
            order.timeline[i],
            i,
            stepIndex,
            i == order.timeline.length - 1,
          ),
      ],
    );
  }

  Widget _step(OrderTimelineStep step, int index, int current, bool isLast) {
    final isDone = index < current;
    final isCurrent = index == current;
    final isReached = isDone || isCurrent;

    Color bg, fg, border;
    if (step.status == OrderStatus.siapDiambil && isReached) {
      bg = AppColors.success;
      fg = Colors.white;
      border = AppColors.success;
    } else if (isCurrent) {
      bg = AppColors.primary;
      fg = Colors.white;
      border = AppColors.primary;
    } else if (isDone) {
      bg = AppColors.textDark;
      fg = Colors.white;
      border = AppColors.textDark;
    } else {
      bg = Colors.white;
      fg = const Color(0x59302B27);
      border = AppColors.surface;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                ),
                child: isDone
                    ? Icon(Icons.check_rounded, size: 14, color: fg)
                    : isCurrent
                    ? Icon(Icons.schedule_rounded, size: 14, color: fg)
                    : Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: fg,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? const Color(0xA6302B27) : AppColors.surface,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: isReached ? 1 : 0.45,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            step.label,
                            style: hapText(
                              15,
                              weight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (step.time != null && isReached)
                          Text(
                            step.time!,
                            style: hapText(
                              12,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted,
                              tabular: true,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: hapText(13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(OrderLineItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surface)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${item.quantity}x ${item.name}',
                  style: hapText(16, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatRupiah(item.subtotal),
                style: hapText(
                  16,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                  tabular: true,
                ),
              ),
            ],
          ),
          if (item.note != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xA6F2E6D5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: ${item.note}',
                style: hapText(13, color: AppColors.textSoft),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, OrderModel order) {
    final widgets = <Widget>[];

    if (order.status == OrderStatus.siapDiambil) {
      // Penjual yang menandai selesai saat pesanan diambil dan dibayar.
      widgets.add(
        Text(
          'Tunjukkan tiket ${order.orderCode} ke penjual saat mengambil. '
          'Penjual yang akan menandai pesanan selesai.',
          textAlign: TextAlign.center,
          style: hapText(13, color: AppColors.textSoft),
        ),
      );
    } else if (order.status == OrderStatus.selesai && !order.ratingSubmitted) {
      widgets.add(
        PrimaryButton(
          label: 'Beri Rating',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RatingScreen(orderId: order.id),
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
      widgets.add(
        OutlineAction(
          label: 'Pesan Menu Lain',
          height: 44,
          fontSize: 14,
          color: AppColors.textDark,
          borderColor: AppColors.outline,
          onPressed: () => _orderAgain(context),
        ),
      );
    } else {
      widgets.add(
        PrimaryButton(
          label: 'Pesan Menu Lain',
          onPressed: () => _orderAgain(context),
        ),
      );
    }

    if (order.status == OrderStatus.menunggu) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(
        TextAction(
          label: 'Batalkan pesanan',
          onPressed: () => _cancel(context, order),
        ),
      );
    } else if (order.status == OrderStatus.diproses ||
        order.status == OrderStatus.siapDiambil ||
        order.status == OrderStatus.selesai) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(
        Text(
          'Pesanan sedang disiapkan dan tidak bisa dibatalkan. Hubungi penjual langsung jika ada kendala.',
          style: hapText(12, color: AppColors.textMuted, height: 1.5),
        ),
      );
    }
    return widgets;
  }
}

class _CancelResult {
  const _CancelResult(this.reason);
  final String? reason;
}

/// Bottom sheet "Kenapa dibatalkan?".
class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kenapa dibatalkan?',
            style: hapText(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih alasan pembatalan (opsional).',
            style: hapText(13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _cancelReasons)
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
            label: 'Batalkan pesanan',
            onPressed: () => Navigator.of(context).pop(_CancelResult(_reason)),
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
