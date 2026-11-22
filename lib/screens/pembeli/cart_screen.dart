// Daftar menu dalam keranjang pembeli.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final summary = store.cartSummary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Keranjang',
              trailing: summary.totalItems > 0
                  ? TextButton(
                      onPressed: store.clearCart,
                      child: Text('Kosongkan',
                          style: hapText(13,
                              weight: FontWeight.w600,
                              color: AppColors.primary)),
                    )
                  : null,
            ),
            if (summary.totalItems == 0)
              Expanded(child: _EmptyCart(onGoHome: () => _goHome(context)))
            else ...[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.surface)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pesanan dari satu stand',
                              style: hapText(12,
                                  weight: FontWeight.w500,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(summary.standName,
                              style: hapText(18, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    for (final line in summary.lines)
                      _CartLine(
                        key: ValueKey(line.menuId),
                        menuId: line.menuId,
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
                        Text('Subtotal (${summary.totalItems} item)',
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
                      label: 'Lanjut',
                      onPressed: () {
                        store.refreshCartForCheckout();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    context.read<AppStore>().setBuyerTab(0);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onGoHome});
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(
              icon: Icons.shopping_bag_rounded, size: 64, iconSize: 32),
          const SizedBox(height: 16),
          Text('Keranjang masih kosong',
              style: hapText(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Pilih menu dari stand di kantin dulu sebelum lanjut memesan.',
              style: hapText(14, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Ke Beranda', onPressed: onGoHome),
        ],
      ),
    );
  }
}

/// Satu baris keranjang. Dipisah agar field catatan punya controller sendiri.
class _CartLine extends StatefulWidget {
  const _CartLine({super.key, required this.menuId});
  final String menuId;

  @override
  State<_CartLine> createState() => _CartLineState();
}

class _CartLineState extends State<_CartLine> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(
      text: context.read<AppStore>().cart.notes[widget.menuId] ?? '',
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final menu = store.menuById(widget.menuId);
    final qty = store.cart.items[widget.menuId] ?? 0;
    if (menu == null || qty <= 0) return const SizedBox.shrink();

    final reachedMax = menu.isOutOfStock || qty >= menu.stock;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surface)),
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
                    Text(menu.name, style: hapText(16, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(formatRupiah(menu.price * qty),
                        style: hapText(15,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                            tabular: true)),
                    if (!menu.isOutOfStock && menu.stock <= 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Sisa ${menu.stock}',
                            style: hapText(12,
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                                tabular: true)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              QtyStepper(
                quantity: qty,
                onMinus: () => store.removeFromCart(menu),
                onPlus: reachedMax ? null : () => store.addToCart(menu),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HapField(
            controller: _note,
            hint: 'Tambah catatan (contoh: sambal pisah)',
            fontSize: 13,
            radius: 10,
            vertical: 11,
            onChanged: (v) => store.updateCartNote(menu.id, v),
          ),
        ],
      ),
    );
  }
}
