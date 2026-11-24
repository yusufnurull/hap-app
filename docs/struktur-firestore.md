# Struktur Database Firestore — Hap!

Penanggung jawab: Rafli (Backend & Database)
Status: final Minggu 1 (boleh disesuaikan lagi selama tim diberi tahu)

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

| Field              | Tipe      | Keterangan                        | Model (`UserModel`)              |
| ------------------ | --------- | --------------------------------- | -------------------------------- |
| nama               | string    | Nama lengkap                      | `name`                           |
| email              | string    | Email login                       | `email`                          |
| noHp               | string    | Nomor yang bisa dihubungi         | `phone`                          |
| role               | string    | `pembeli` / `penjual` / `admin`   | `role` (enum `UserRole`)         |
| status             | string    | `aktif` / `menunggu` / `nonaktif` | `isActive` = (status == `aktif`) |
| standId            | string    | Hanya untuk penjual               | –                                |
| jumlahTidakDiambil | number    | Berapa kali pesanan tidak diambil | `noShowCount`                    |
| createdAt          | timestamp | Waktu daftar                      | –                                |

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

Dinaikkan di dalam transaksi Firestore saat checkout, lalu dibentuk menjadi
`A-001`, `A-002`, dst. Dikerjakan di Minggu 3.

## Perbedaan dari rancangan awal

1. `users.status` tetap string, tapi di model dibaca sebagai `isActive`.
2. Tambahan `users.jumlahTidakDiambil` karena model punya `noShowCount`.
3. Tambahan field stand: `lokasi`, `kategori`, `ikon` (dipakai di UI beranda).
4. Tambahan field menu: `deskripsi`, `stok`, `ikon`.
5. Tambahan field order: `namaPembeli`, `namaStand`, `metodeBayar`, `alasanBatal`,
   `sudahDirating`, `waktuStatus`.
6. Tambahan status `tidakDiambil` (sudah ada di `order_status.dart`).
7. Koleksi baru `counters` untuk nomor pesanan.

## Garis besar Security Rules (diterapkan Minggu 3)

- Pembeli hanya bisa membaca dan membuat pesanan miliknya sendiri.
- Penjual hanya bisa mengubah menu dan status pesanan untuk stand miliknya, dan hanya
  jika `status` akunnya `aktif`.
- Admin bisa mengubah `status` dan `role` pengguna serta data stand.
- Selama Minggu 1–2, Firestore memakai **test mode** (aturan terbuka sementara).
