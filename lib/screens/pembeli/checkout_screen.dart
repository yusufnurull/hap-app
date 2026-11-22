// Konfirmasi dan pembayaran pesanan (bayar di tempat).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import 'order_detail_screen.dart';

const List<String> _pickupSlots = ['11.30', '11.45', '12.00', '12.10', '12.30'];

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _pickupTime = '12.00';

  void _placeOrder() {
    final store = context.read<AppStore>();
    final order = store.placeOrder(_pickupTime);
    if (order == null) return; // stok berubah: peringatan tampil di layar ini

    final nav = Navigator.of(context);
    store.setBuyerTab(1); // Pesanan
    nav.popUntil((r) => r.isFirst);
    nav.push(MaterialPageRoute<void>(
      builder: (_) => OrderDetailScreen(orderId: order.id),
    ));
  }

  void _goHome() {
    context.read<AppStore>().setBuyerTab(0);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final summary = store.cartSummary;
    final warnings = store.checkoutWarnings;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Checkout'),
            if (summary.totalItems == 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (warnings.isNotEmpty) ...[
                        WarningBox(messages: warnings),
                        const SizedBox(height: 12),
                      ],
                      Text('Belum ada item di keranjang',
                          style: hapText(16, weight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Pilih Menu di Beranda',
                        onPressed: _goHome,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    if (warnings.isNotEmpty) ...[
                      WarningBox(messages: warnings),
                      const SizedBox(height: 24),
                    ],
                    SectionHeading(
                      title: 'Ringkasan Pesanan',
                      trailing: summary.standName,
                    ),
                    const SizedBox(height: 10),
                    const RowDivider(),
                    for (final line in summary.lines)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: AppColors.surface)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${line.quantity}x ${line.name}',
                                    style: hapText(14, weight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(formatRupiah(line.subtotal),
                                    style: hapText(14,
                                        weight: FontWeight.w700,
                                        color: AppColors.primary,
                                        tabular: true)),
                              ],
                            ),
                            if (line.note != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Catatan: ${line.note}',
                                    style: hapText(12,
                                        color: AppColors.textMuted)),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text('Jam Ambil',
                        style: hapText(18, weight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text('Pilih waktu kamu datang ke ${summary.standName}.',
                        style: hapText(13, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in _pickupSlots)
                          SizedBox(
                            height: 40,
                            child: HapChip(
                              label: slot,
                              selected: _pickupTime == slot,
                              horizontal: 16,
                              vertical: 11,
                              fontSize: 13,
                              tabular: true,
                              onTap: () => setState(() => _pickupTime = slot),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Metode Pembayaran',
                        style: hapText(18, weight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: Row(
                        children: [
                          const IconTile(
                            icon: Icons.payments_rounded,
                            size: 40,
                            iconSize: 22,
                            radius: 10,
                            color: AppColors.textDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bayar di tempat',
                                    style: hapText(15, weight: FontWeight.w600)),
                                Text(
                                  'Bayar langsung di stand saat mengambil pesanan.',
                                  style: hapText(12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.surface)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total bayar',
                            style: hapText(14,
                                weight: FontWeight.w500,
                                color: const Color(0xB3302B27))),
                        Text(formatRupiah(summary.totalPrice),
                            style: hapText(18,
                                weight: FontWeight.w800,
                                color: AppColors.primary,
                                tabular: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                        label: 'Pesan sekarang', onPressed: _placeOrder),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
