// Enum umum yang dipakai lintas model dan layar.

enum UserRole {
  pembeli('Pembeli'),
  penjual('Penjual'),
  admin('Admin');

  const UserRole(this.label);
  final String label;
}

/// Kategori stand untuk filter di beranda pembeli. `null` berarti "Semua".
enum StandCategory {
  makananBerat('Makanan Berat'),
  minuman('Minuman'),
  camilan('Camilan');

  const StandCategory(this.label);
  final String label;
}

/// Kategori menu di dalam satu stand. `null` berarti "Semua".
enum MenuCategory {
  makanan('Makanan'),
  minuman('Minuman'),
  camilan('Camilan');

  const MenuCategory(this.label);
  final String label;
}
