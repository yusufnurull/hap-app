// Lencana visual untuk status pesanan.

import 'package:flutter/material.dart';

import '../core/constants/order_status.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color? fill;
    Color? border;
    Color text = AppColors.textDark;

    switch (status) {
      case OrderStatus.menunggu:
        border = AppColors.textDark;
      case OrderStatus.diproses:
        fill = AppColors.accent;
      case OrderStatus.siapDiambil:
        fill = AppColors.success;
        text = Colors.white;
      case OrderStatus.selesai:
        fill = AppColors.surface;
      case OrderStatus.dibatalkan:
        border = AppColors.primary;
        text = AppColors.primary;
      case OrderStatus.tidakDiambil:
        fill = const Color(0x1A302B27);
        border = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        style: hapText(12, weight: FontWeight.w500, color: text, height: 1),
      ),
    );
  }
}
