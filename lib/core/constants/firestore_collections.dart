// Nama koleksi Firestore yang digunakan aplikasi.

class FirestoreCollections {
  static const String users = 'users';
  static const String stands = 'stands';
  static const String menus = 'menus'; // subkoleksi di dalam stands/{standId}
  static const String orders = 'orders';
  static const String counters = 'counters'; // nomor pesanan harian (Minggu 3)
}
