// Baris menu: ikon, nama, harga, dan tombol tambah / stepper.

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/utils/icon_map.dart';
import '../models/menu_model.dart';
import 'common.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.item,
    required this.standOpen,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.onTap,
    this.showStandName = true,
    this.showDivider = true,
  });

  final MenuModel item;
  final bool standOpen;
  final int quantity;
  final ValueChanged<MenuModel> onAdd;
  final ValueChanged<MenuModel> onRemove;
  final ValueChanged<MenuModel>? onTap;
  final bool showStandName;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final outOfStock = item.isOutOfStock;
    final orderable = !outOfStock && standOpen;
    final unavailableLabel =
        outOfStock ? 'Habis' : (!standOpen ? 'Stand tutup' : null);
    final showLowStock = orderable && item.stock <= 5;
    final reachedMax = quantity >= item.stock;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: hapText(16, weight: FontWeight.w600, height: 1.25),
        ),
        if (showStandName)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.standName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hapText(12,
                  weight: FontWeight.w500, color: AppColors.textMuted),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatRupiah(item.price),
                  style: hapText(16,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                      tabular: true),
                ),
                if (unavailableLabel != null)
                  TextSpan(
                    text: '  · $unavailableLabel',
                    style: hapText(12,
                        weight: FontWeight.w500, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
        if (showLowStock)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Sisa ${item.stock}',
              style: hapText(12,
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                  tabular: true),
            ),
          ),
      ],
    );

    Widget control;
    if (!orderable) {
      control = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface),
        ),
        child: const Icon(Icons.block_rounded,
            size: 20, color: AppColors.textFaint),
      );
    } else if (quantity > 0) {
      control = QtyStepper(
        quantity: quantity,
        onMinus: () => onRemove(item),
        onPlus: reachedMax ? null : () => onAdd(item),
      );
    } else {
      control = CircleIconButton(
        icon: Icons.add_rounded,
        iconSize: 22,
        size: 40,
        background: AppColors.primary,
        foreground: Colors.white,
        tooltip: 'Tambah ${item.name} ke keranjang',
        onTap: () => onAdd(item),
      );
    }

    return Opacity(
      opacity: orderable ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.surface))
              : null,
        ),
        child: Row(
          children: [
            IconTile(icon: iconFor(item.icon)),
            const SizedBox(width: 12),
            Expanded(
              child: onTap == null
                  ? info
                  : InkWell(onTap: () => onTap!(item), child: info),
            ),
            const SizedBox(width: 12),
            control,
          ],
        ),
      ),
    );
  }
}
