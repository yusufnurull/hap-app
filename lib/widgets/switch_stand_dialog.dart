// Konfirmasi ganti stand: keranjang hanya boleh berisi satu stand.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/menu_model.dart';
import '../providers/app_store.dart';

/// Menambah [item] ke keranjang. Bila keranjang berisi stand lain, tanya dulu
/// apakah mau mulai keranjang baru. Mengembalikan true bila item berhasil masuk.
Future<bool> addToCartWithConfirm(
  BuildContext context,
  MenuModel item, {
  int qty = 1,
  String? note,
}) async {
  final store = context.read<AppStore>();
  if (store.canAddDirectly(item)) {
    store.addToCart(item, qty: qty, note: note);
    return true;
  }

  final currentStandName = store.cartSummary.standName;
  final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: AppColors.scrim,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.surface),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          title: Text('Mulai keranjang baru?',
              style: hapText(18, weight: FontWeight.w700)),
          content: Text(
            'Keranjangmu berisi menu dari $currentStandName.',
            style: hapText(14, color: AppColors.textSoft, height: 1.4),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.outline),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: hapText(14, weight: FontWeight.w600),
              ),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: hapText(14, weight: FontWeight.w700),
              ),
              child: const Text('Mulai baru'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return false;
  store.replaceCart(item, qty: qty, note: note);
  return true;
}
