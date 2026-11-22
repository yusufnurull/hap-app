// Tiket pesanan berlubang (perforasi) dengan nomor pesanan besar.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/order_status.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'status_badge.dart';

class OrderTicket extends StatelessWidget {
  const OrderTicket({
    super.key,
    required this.orderCode,
    required this.standName,
    required this.pickupTime,
    required this.status,
    this.buyerName,
  });

  final String orderCode;
  final String standName;
  final String pickupTime;
  final OrderStatus status;
  final String? buyerName;

  static const _edge = Color(0x33302B27); // 20%

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _edge),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nomor pesanan',
                          style: hapText(12,
                              weight: FontWeight.w500,
                              color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        orderCode,
                        style: hapText(32,
                            weight: FontWeight.w800,
                            color: AppColors.primary,
                            tabular: true,
                            height: 1.15,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: StatusBadge(status: status),
                ),
              ],
            ),
          ),
          // Garis putus-putus dengan takik di kiri dan kanan.
          SizedBox(
            height: 24,
            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-1, 0),
                  child: _Notch(left: true),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: CustomPaint(
                      size: Size(double.infinity, 1),
                      painter: _DashedLinePainter(),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(1, 0),
                  child: _Notch(left: false),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stand',
                          style: hapText(12,
                              weight: FontWeight.w500,
                              color: AppColors.textMuted)),
                      Text(
                        standName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hapText(14, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (buyerName != null) ...[
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pemesan',
                          style: hapText(12,
                              weight: FontWeight.w500,
                              color: AppColors.textMuted)),
                      Text(buyerName!,
                          style: hapText(14, weight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Jam ambil',
                        style: hapText(12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted)),
                    Text(pickupTime,
                        style: hapText(16, weight: FontWeight.w700, tabular: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Setengah lingkaran putih di tepi tiket.
class _Notch extends StatelessWidget {
  const _Notch({required this.left});
  final bool left;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 24,
      child: ClipRect(
        child: Align(
          alignment: left ? Alignment.centerRight : Alignment.centerLeft,
          widthFactor: 0.5,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: OrderTicket._edge),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
