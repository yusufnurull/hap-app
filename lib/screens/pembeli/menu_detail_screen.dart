// Detail menu yang dipilih pembeli: jumlah, catatan, dan tambah ke keranjang.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_map.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/switch_stand_dialog.dart';

class MenuDetailScreen extends StatefulWidget {
  const MenuDetailScreen({super.key, required this.menuId});
  final String menuId;

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  final _note = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final menu = store.menuById(widget.menuId);
    if (menu == null) {
      return const Scaffold(body: Center(child: Text('Menu tidak ditemukan')));
    }
    final standOpen = store.standById(menu.standId)?.isOpen ?? false;
    final outOfStock = menu.isOutOfStock;
    final orderable = !outOfStock && standOpen;
    final int qty =
        orderable ? math.max(1, math.min(_quantity, menu.stock)) : 1;
    final reachedMax = orderable && qty >= menu.stock;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Detail Menu'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: orderable ? 1 : 0.55,
                      child: Container(
                        width: double.infinity,
                        height: 192,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconFor(menu.icon),
                            size: 56, color: const Color(0x8C302B27)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('${menu.standName} · ${menu.category.label}',
                        style: hapText(12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(menu.name,
                        style: hapText(24, weight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(formatRupiah(menu.price),
                        style: hapText(18,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                            tabular: true)),
                    if (orderable && menu.stock <= 5) ...[
                      const SizedBox(height: 6),
                      Text('Sisa ${menu.stock}',
                          style: hapText(12,
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                              tabular: true)),
                    ] else if (outOfStock) ...[
                      const SizedBox(height: 6),
                      Text('Habis',
                          style: hapText(12,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted)),
                    ],
                    const SizedBox(height: 10),
                    Text(menu.description,
                        style: hapText(14, color: AppColors.textSoft, height: 1.55)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: AppColors.surface),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jumlah',
                              style: hapText(15, weight: FontWeight.w600)),
                          QtyStepper(
                            quantity: qty,
                            gap: 8,
                            onMinus: (!orderable || qty <= 1)
                                ? null
                                : () => setState(() => _quantity = qty - 1),
                            onPlus: (!orderable || reachedMax)
                                ? null
                                : () => setState(() => _quantity = qty + 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    LabeledField(
                      label: 'Catatan untuk penjual (opsional)',
                      child: HapField(
                        controller: _note,
                        enabled: orderable,
                        hint: 'Contoh: pedas, tanpa bawang',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.surface)),
              ),
              child: PrimaryButton(
                label: orderable
                    ? 'Tambah · ${formatRupiah(menu.price * qty)}'
                    : (outOfStock ? 'Menu sedang habis' : 'Stand sedang tutup'),
                onPressed: orderable
                    ? () async {
                        final added = await addToCartWithConfirm(
                          context,
                          menu,
                          qty: qty,
                          note: _note.text,
                        );
                        if (added && mounted) Navigator.of(context).pop();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
