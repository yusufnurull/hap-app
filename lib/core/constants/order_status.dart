// Status-status pesanan dalam aplikasi.

/// Status pesanan dari sisi pembeli.
enum OrderStatus {
  menunggu('Menunggu'),
  diproses('Diproses'),
  siapDiambil('Siap Diambil'),
  selesai('Selesai'),
  dibatalkan('Dibatalkan'),
  tidakDiambil('Tidak diambil');

  const OrderStatus(this.label);
  final String label;

  /// Pesanan yang masih berjalan (tab "Aktif").
  bool get isActive =>
      this == menunggu || this == diproses || this == siapDiambil;
}

/// Status pesanan dari sisi penjual.
enum SellerOrderStatus {
  baru('Baru'),
  diproses('Diproses'),
  siap('Siap'),
  selesai('Selesai'),
  dibatalkan('Dibatalkan'),
  tidakDiambil('Tidak diambil');

  const SellerOrderStatus(this.label);
  final String label;
}
