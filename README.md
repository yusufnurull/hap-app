# Hap!

**Pesan, ambil, hap!**

Hap! adalah aplikasi mobile berbasis Flutter untuk memesan makanan di kantin kampus sebelum datang. Mahasiswa memesan dari kelas, memilih jam ambil, lalu tinggal mengambil pesanan di stand tanpa antre.

Proyek ini merupakan Final Project mata kuliah **Pemrograman Perangkat Bergerak**, Program Studi Pendidikan Teknik Informatika dan Komputer, FKIP Universitas Sebelas Maret.

## Fitur Utama

1. **Katalog menu dan stok real-time**: daftar stand dan menu beserta harga, foto, dan status tersedia/habis.
2. **Pemesanan (pre-order)**: keranjang, catatan per menu, pemilihan jam ambil, dan pembayaran tunai saat mengambil.
3. **Pelacakan status pesanan**: status Menunggu, Diproses, Siap Diambil, dan Selesai yang diperbarui penjual dan langsung terlihat oleh pembeli.

## Teknologi

| Komponen | Kegunaan |
| --- | --- |
| Flutter dan Dart | Pengembangan aplikasi Android |
| Firebase Authentication | Login dan pendaftaran pengguna |
| Firebase Cloud Firestore | Database pengguna, stand, menu, dan pesanan secara real-time |
| Cloudinary | Penyimpanan foto menu |
| Provider | State management |

## Struktur Folder

```
lib/
├─ main.dart
├─ app.dart
├─ core/          # tema, warna, konstanta, utilitas
├─ models/        # model data
├─ services/      # akses Firebase dan Cloudinary
├─ providers/     # state management
├─ screens/       # halaman: auth, pembeli, penjual, admin
└─ widgets/       # komponen yang dipakai ulang
```

## Cara Menjalankan

**Prasyarat:** Flutter SDK, Android Studio (Android SDK dan emulator), dan VS Code dengan extension Flutter.

1. Clone repository:

   ```
   git clone https://github.com/yusufnurull/hap-app.git
   cd hap-app
   ```

2. Ambil dependensi:

   ```
   flutter pub get
   ```

3. Jalankan di emulator atau HP Android:

   ```
   flutter run
   ```

**Konfigurasi Firebase:** file `android/app/google-services.json` dan `lib/firebase_options.dart` sengaja tidak diunggah ke repository karena berisi konfigurasi layanan. Anggota tim mendapatkannya dari grup internal, sedangkan pihak lain dapat membuat proyek Firebase sendiri dan menjalankan `flutterfire configure`.

## Screenshot

Screenshot aplikasi akan ditambahkan seiring pengembangan dan disimpan di folder `docs/screenshots/`.

## Anggota Kelompok

| Nama | NIM | Peran |
| --- | --- | --- |
| Yusuf Nurul Huda | K3524038 | Project Manager dan UI/UX Designer |
| Athaya Alifia Zahra | K3524046 | Frontend Developer |
| Muhammad Rafli Rafsanjani | K3524030 | Backend dan Database Developer |
| Herlina Dwi Septiana | K3524012 | Feature Developer, Testing, dan Dokumentasi |
