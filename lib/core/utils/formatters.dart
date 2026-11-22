// Fungsi format untuk nilai yang ditampilkan kepada pengguna.

/// 12000 -> "Rp12.000"
String formatRupiah(num amount) {
  final rounded = amount.round();
  final formatted = rounded.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  return 'Rp$formatted';
}
