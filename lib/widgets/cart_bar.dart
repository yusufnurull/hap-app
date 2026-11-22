// Bilah krem "Lihat keranjang" di atas navigasi bawah.

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.standName,
    required this.totalItems,
    required this.totalPrice,
    required this.onOpenCart,
  });

  final String standName;
  final int totalItems;
  final int totalPrice;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$standName · $totalItems item · '),
                  TextSpan(
                    text: formatRupiah(totalPrice),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hapText(12, weight: FontWeight.w700, tabular: true),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: onOpenCart,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: hapText(12, weight: FontWeight.w700),
              ),
              child: const Text('Lihat keranjang'),
            ),
          ),
        ],
      ),
    );
  }
}
