// Beri rating per menu untuk pesanan yang sudah selesai.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _review = TextEditingController();
  final Map<String, int> _ratings = {};

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final order = store.buyerOrderById(widget.orderId);
    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('Pesanan tidak ditemukan')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Beri Rating'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.surface),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesanan ${order.orderCode}',
                            style: hapText(
                              12,
                              weight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            order.standName,
                            style: hapText(18, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    for (final item in order.items)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.surface),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: hapText(16, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (var star = 1; star <= 5; star++)
                                  InkResponse(
                                    onTap: () => setState(
                                      () => _ratings[item.menuId] = star,
                                    ),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        star <= (_ratings[item.menuId] ?? 5)
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 28,
                                        color:
                                            star <= (_ratings[item.menuId] ?? 5)
                                            ? AppColors.accent
                                            : const Color(0x40302B27),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    LabeledField(
                      label: 'Ulasan singkat (opsional)',
                      child: HapField(
                        controller: _review,
                        maxLines: 3,
                        hint: 'Contoh: Porsinya pas, sambalnya mantap.',
                        vertical: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Kirim Ulasan',
                      onPressed: () async {
                        // Rata-rata bintang semua item (default 5).
                        final nilai = order.items
                            .map((i) => _ratings[i.menuId] ?? 5)
                            .toList();
                        final bintang = nilai.isEmpty
                            ? 5
                            : (nilai.reduce((a, b) => a + b) / nilai.length)
                                  .round();
                        final error = await store.submitRating(
                          order.id,
                          bintang: bintang,
                          ulasan: _review.text,
                        );
                        if (!context.mounted) return;
                        if (error != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
