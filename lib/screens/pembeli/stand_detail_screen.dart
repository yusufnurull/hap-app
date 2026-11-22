// Halaman satu stand: info, filter kategori, dan daftar menu.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hap_logic.dart';
import '../../core/utils/icon_map.dart';
import '../../models/menu_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/switch_stand_dialog.dart';
import 'cart_screen.dart';
import 'menu_detail_screen.dart';

class StandDetailScreen extends StatefulWidget {
  const StandDetailScreen({super.key, required this.standId});
  final String standId;

  @override
  State<StandDetailScreen> createState() => _StandDetailScreenState();
}

class _StandDetailScreenState extends State<StandDetailScreen> {
  MenuCategory? _category;

  void _openMenu(MenuModel item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuDetailScreen(menuId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stand = store.standById(widget.standId);
    if (stand == null) {
      return const Scaffold(body: Center(child: Text('Stand tidak ditemukan')));
    }

    final menus = filterMenusForStand(store.menus, stand.id, _category);
    final summary = store.cartSummary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: stand.isOpen ? 1 : 0.6,
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconFor(stand.icon),
                                size: 48, color: const Color(0x8C302B27)),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface),
                            ),
                            child: CircleIconButton(
                              icon: Icons.arrow_back_rounded,
                              iconSize: 22,
                              size: 40,
                              tooltip: 'Kembali ke beranda',
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.surface),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(stand.name,
                                  style: hapText(24,
                                      weight: FontWeight.w800, height: 1.2)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: stand.isOpen
                                    ? AppColors.success
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                stand.isOpen ? 'Buka' : 'Tutup',
                                style: hapText(
                                  12,
                                  weight: FontWeight.w600,
                                  color: stand.isOpen
                                      ? Colors.white
                                      : AppColors.textSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(stand.foodTypes,
                            style: hapText(14, color: AppColors.textSoft)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _meta(Icons.schedule_rounded, stand.openHours,
                                tabular: true),
                            Text('·',
                                style: hapText(12, color: AppColors.textMuted)),
                            _meta(Icons.storefront_rounded, stand.locationNote),
                          ],
                        ),
                        if (!stand.isOpen) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xB3F2E6D5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Stand sedang tutup. Kamu tetap bisa melihat daftar menu, namun pemesanan belum dibuka.',
                              style: hapText(13, height: 1.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: ChipRow(
                      gap: 8,
                      children: [
                        HapChip(
                          label: 'Semua',
                          selected: _category == null,
                          horizontal: 14,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final c in MenuCategory.values)
                          HapChip(
                            label: c.label,
                            selected: _category == c,
                            horizontal: 14,
                            onTap: () => setState(() => _category = c),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeading(
                            title: 'Daftar Menu',
                            trailing: '${menus.length} menu'),
                        const SizedBox(height: 4),
                        const RowDivider(),
                        if (menus.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tidak ada menu di kategori ${_category?.label ?? 'Semua'}',
                                  style: hapText(15, weight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                OutlineAction(
                                  label: 'Tampilkan semua menu',
                                  fullWidth: false,
                                  height: 40,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  borderColor: AppColors.surface,
                                  onPressed: () =>
                                      setState(() => _category = null),
                                ),
                              ],
                            ),
                          )
                        else
                          for (var i = 0; i < menus.length; i++)
                            MenuCard(
                              item: menus[i],
                              standOpen: stand.isOpen,
                              quantity: store.cart.items[menus[i].id] ?? 0,
                              onTap: _openMenu,
                              onAdd: (item) =>
                                  addToCartWithConfirm(context, item),
                              onRemove: store.removeFromCart,
                              showStandName: false,
                              showDivider: i < menus.length - 1,
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CartBar(
              standName: summary.standName,
              totalItems: summary.totalItems,
              totalPrice: summary.totalPrice,
              onOpenCart: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, {bool tabular = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: hapText(12,
                weight: FontWeight.w500,
                color: AppColors.textMuted,
                tabular: tabular)),
      ],
    );
  }
}
