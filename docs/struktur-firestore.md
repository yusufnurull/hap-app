# Struktur Database Firestore — Hap!

Penanggung jawab: Rafli (Backend & Database)
Status: diperbarui Minggu 3 (pesanan, admin, Security Rules)

Dokumen ini menyesuaikan rancangan di _Hap! — Rancangan Dasar Aplikasi_ dengan model
yang sudah ada di `lib/models/`, supaya layar buatan Aya tidak perlu banyak diubah
saat data dipindah dari `mock_data.dart` ke Firestore.

## Gambaran koleksi

```
users/{uid}
stands/{standId}
  └─ menus/{menuId}
orders/{orderId}
counters/{tanggal}        # penomoran pesanan harian (dipakai Minggu 3)
```

Nama koleksi ada di `lib/core/constants/firestore_collections.dart`.

## users/{uid}

ID dokumen = `uid` dari Firebase Auth.

| Field              | Tipe      | Keterangan                                      | Model (`UserModel`)              |
| ------------------ | --------- | ----------------------------------------------- | -------------------------------- |
| nama               | string    | Nama lengkap                                    | `name`                           |
| email              | string    | Email login                                     | `email`                          |
| noHp               | string    | Nomor yang bisa dihubungi                       | `phone`                          |
| role               | string    | `pembeli` / `penjual` / `admin`                 | `role` (enum `UserRole`)         |
| status             | string    | `aktif` / `menunggu` / `nonaktif`               | `isActive` = (status == `aktif`) |
| standId            | string    | Hanya untuk penjual, diisi saat disetujui admin | `standId`                        |
| namaStandUsulan    | string    | Nama stand yang diisi penjual saat daftar       | `proposedStandName`              |
| jumlahTidakDiambil | number    | Berapa kali pesanan tidak diambil               | `noShowCount`                    |
| createdAt          | timestamp | Waktu daftar                                    | –                                |

Aturan isi awal:

- Pembeli daftar → `status: aktif`.
- Penjual daftar → `status: menunggu` sampai disetujui admin.
- Admin dibuat manual di Firebase Console (`role: admin`, `status: aktif`).

## stands/{standId}

| Field     | Tipe            | Keterangan                              | Model (`StandModel`)                |
| --------- | --------------- | --------------------------------------- | ----------------------------------- |
| namaStand | string          | "Warung Bu Sri"                         | `name`                              |
| pemilikId | string          | uid penjual                             | –                                   |
| deskripsi | string          | Jenis makanan yang dijual               | `foodTypes`                         |
| jamBuka   | string          | "07.00"                                 | `openHours` = `jamBuka–jamTutup`    |
| jamTutup  | string          | "15.00"                                 | (digabung saat dibaca)              |
| lokasi    | string          | "Kios 1 · Kiri tangga"                  | `locationNote`                      |
| kategori  | array of string | `makananBerat`, `minuman`, `camilan`    | `categories` (enum `StandCategory`) |
| ikon      | string          | Nama ikon Material, mis. `lunch_dining` | `icon`                              |
| isOpen    | boolean         | Diubah penjual saat buka/tutup          | `isOpen`                            |
| createdAt | timestamp       |                                         | –                                   |

`todayOrders` tidak disimpan; dihitung dari koleksi `orders` hari ini.

## stands/{standId}/menus/{menuId}

| Field     | Tipe      | Keterangan                         | Model (`MenuModel`)              |
| --------- | --------- | ---------------------------------- | -------------------------------- |
| nama      | string    | "Nasi ayam geprek"                 | `name`                           |
| harga     | number    | 12000                              | `price`                          |
| kategori  | string    | `makanan` / `minuman` / `camilan`  | `category` (enum `MenuCategory`) |
| deskripsi | string    |                                    | `description`                    |
| stok      | number    | Jumlah porsi tersisa               | `stock`                          |
| tersedia  | boolean   | `false` = tampil "Habis"           | `isAvailable`                    |
| fotoUrl   | string    | URL dari Cloudinary (boleh kosong) | `photoUrl`                       |
| ikon      | string    | Ikon cadangan bila belum ada foto  | `icon`                           |
| updatedAt | timestamp |                                    | –                                |

`standId` dan `standName` di `MenuModel` diisi dari dokumen induk (stand), tidak
disimpan ulang di menu.

## orders/{orderId}

| Field         | Tipe         | Keterangan                                    | Model (`OrderModel`)      |
| ------------- | ------------ | --------------------------------------------- | ------------------------- |
| nomorPesanan  | string       | "A-017"                                       | `orderCode`               |
| pembeliId     | string       | uid pembeli                                   | –                         |
| namaPembeli   | string       | Disalin saat checkout                         | `buyerName`               |
| standId       | string       |                                               | `standId`                 |
| namaStand     | string       | Disalin saat checkout                         | `standName`               |
| items         | array of map | `{menuId, nama, harga, jumlah, catatan}`      | `items` (`OrderLineItem`) |
| total         | number       | Jumlah semua item                             | –                         |
| jamAmbil      | string       | "12.10"                                       | `pickupTime`              |
| metodeBayar   | string       | `tunai`                                       | `paymentMethod`           |
| status        | string       | lihat tabel status di bawah                   | `status`                  |
| alasanBatal   | string       | Diisi bila dibatalkan/ditolak                 | `cancelReason`            |
| sudahDirating | boolean      |                                               | `ratingSubmitted`         |
| rating        | number       | 1–5, diisi pembeli setelah selesai            | –                         |
| ulasan        | string       | Ulasan singkat pembeli                        | –                         |
| waktuStatus   | map          | `{menunggu: ts, diproses: ts, siap: ts, ...}` | `timeline[].time`         |
| createdAt     | timestamp    | Waktu pesan                                   | –                         |

Nama dan harga menu disalin ke `items`, supaya riwayat pesanan tidak berubah ketika
penjual mengganti harga. `namaPembeli` dan `namaStand` juga disalin supaya penjual
tidak perlu membaca dokumen `users` milik pembeli.

### Pemetaan status

| Firestore (`status`) | Pembeli (`OrderStatus`) | Penjual (`SellerOrderStatus`) |
| -------------------- | ----------------------- | ----------------------------- |
| menunggu             | menunggu                | baru                          |
| diproses             | diproses                | diproses                      |
| siap                 | siapDiambil             | siap                          |
| selesai              | selesai                 | selesai                       |
| dibatalkan           | dibatalkan              | dibatalkan                    |
| tidakDiambil         | tidakDiambil            | tidakDiambil                  |

Satu dokumen pesanan dipakai bersama oleh pembeli dan penjual, jadi tidak ada lagi
dua daftar terpisah seperti di `app_store.dart`.

## counters/{yyyy-MM-dd}

| Field | Tipe   | Keterangan                        |
| ----- | ------ | --------------------------------- |
| next  | number | Nomor pesanan berikutnya hari itu |

Dinaikkan di dalam transaction checkout (`OrderService.buatPesanan`), lalu
dibentuk menjadi `A-001`, `A-002`, dst. Nomor kembali ke 1 setiap hari.

## Perbedaan dari rancangan awal

1. `users.status` tetap string, tapi di model dibaca sebagai `isActive`.
2. Tambahan `users.jumlahTidakDiambil` karena model punya `noShowCount`.
3. Tambahan field stand: `lokasi`, `kategori`, `ikon` (dipakai di UI beranda).
4. Tambahan field menu: `deskripsi`, `stok`, `ikon`.
5. Tambahan field order: `namaPembeli`, `namaStand`, `metodeBayar`, `alasanBatal`,
   `sudahDirating`, `waktuStatus`.
6. Tambahan status `tidakDiambil` (sudah ada di `order_status.dart`).
7. Koleksi baru `counters` untuk nomor pesanan.

## Alur pesanan dan stok (Minggu 3)

| Aksi            | Fungsi (`OrderService`)     | Perubahan status      | Stok                                                |
| --------------- | --------------------------- | --------------------- | --------------------------------------------------- |
| Checkout        | `buatPesanan` (transaction) | – → menunggu          | dikurangi                                           |
| Terima          | `terimaPesanan`             | menunggu → diproses   | –                                                   |
| Siap            | `tandaiSiap`                | diproses → siap       | –                                                   |
| Selesai         | `selesaikanPesanan`         | siap → selesai        | –                                                   |
| Tolak (penjual) | `tolakPesanan`              | menunggu → dibatalkan | dikembalikan                                        |
| Batal (pembeli) | `batalkanPesanan`           | menunggu → dibatalkan | dikembalikan                                        |
| Tidak diambil   | `tandaiTidakDiambil`        | siap → tidakDiambil   | tidak dikembalikan; `jumlahTidakDiambil` pembeli +1 |
| Rating          | `beriRating`                | (tetap selesai)       | –                                                   |

Setiap perubahan status memeriksa status sebelumnya di dalam transaction,
jadi dua orang yang menekan tombol bersamaan tidak membuat status melompat.

## Composite index

Ada di `firestore.indexes.json`:

| Koleksi | Field                         | Dipakai oleh                                   |
| ------- | ----------------------------- | ---------------------------------------------- |
| orders  | pembeliId ASC, createdAt DESC | `streamPesananPembeli`                         |
| orders  | standId ASC, createdAt DESC   | `streamPesananStand`, `streamRingkasanHariIni` |
| users   | role ASC, nama ASC            | `AdminService.streamPengguna(role: ...)`       |

## Security Rules

Ada di `firestore.rules`. Ringkasnya:

- Semua akses wajib login.
- `users`: pemilik akun hanya bisa membaca miliknya dan mengubah `nama`/`noHp`.
  Saat daftar, pembeli harus `aktif` dan penjual harus `menunggu`. Penjual hanya
  boleh menambah `jumlahTidakDiambil` sebanyak 1. Admin boleh semuanya.
- `stands`: semua yang login bisa membaca. Penjual aktif hanya bisa mengubah
  info dan status buka stand miliknya. Membuat dan menghapus stand hanya admin.
- `menus`: penjual mengelola menu standnya. Pembeli hanya boleh mengubah
  `stok`/`tersedia` (dipakai transaction checkout dan pembatalan).
- `orders`: pembeli membuat dan membaca pesanannya sendiri, membatalkan saat
  `menunggu`, dan memberi rating sekali setelah `selesai`. Penjual membaca dan
  mengubah status pesanan standnya. Pesanan tidak bisa dihapus.
- Akun `menunggu` atau `nonaktif` tidak bisa memesan atau mengelola stand.

Catatan: setelah Rules ini dipasang, `seed_main.dart` tidak bisa dipakai lagi
karena membuat penjual yang langsung aktif. Jalankan seed sebelum Rules dipasang.
