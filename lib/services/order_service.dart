// Layanan pesanan: checkout, stream real-time, perubahan status, rating.
//
// Semua perubahan yang menyentuh stok memakai Firestore transaction,
// supaya dua pembeli yang checkout bersamaan tidak bisa membeli stok yang
// sama (stok tidak bisa minus).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_values.dart';
import '../core/constants/order_status.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';

/// Galat pesanan yang pesannya siap ditampilkan ke pengguna.
class OrderFailure implements Exception {
  const OrderFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Ringkasan pesanan hari ini untuk layar Profil Stand.
class RingkasanHariIni {
  const RingkasanHariIni({
    required this.totalPesanan,
    required this.menunggu,
    required this.diproses,
    required this.siap,
    required this.selesai,
    required this.dibatalkan,
    required this.tidakDiambil,
    required this.pendapatan,
  });

  static const kosong = RingkasanHariIni(
    totalPesanan: 0,
    menunggu: 0,
    diproses: 0,
    siap: 0,
    selesai: 0,
    dibatalkan: 0,
    tidakDiambil: 0,
    pendapatan: 0,
  );

  final int totalPesanan;
  final int menunggu;
  final int diproses;
  final int siap;
  final int selesai;
  final int dibatalkan;
  final int tidakDiambil;

  /// Total uang dari pesanan yang sudah selesai (dibayar di tempat).
  final int pendapatan;

  /// Pesanan yang masih harus ditangani penjual.
  int get aktif => menunggu + diproses + siap;
}

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(FirestoreCollections.orders);

  DocumentReference<Map<String, dynamic>> _stand(String standId) =>
      _db.collection(FirestoreCollections.stands).doc(standId);

  DocumentReference<Map<String, dynamic>> _menu(String standId, String id) =>
      _stand(standId).collection(FirestoreCollections.menus).doc(id);

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid);

  // ===========================================================================
  // Checkout
  // ===========================================================================

  /// Membuat pesanan dalam satu transaction:
  /// 1. cek akun pembeli aktif dan stand buka,
  /// 2. cek stok setiap menu,
  /// 3. kurangi stok,
  /// 4. ambil nomor pesanan harian (A-001, A-002, ...),
  /// 5. simpan pesanan.
  /// Bila satu langkah gagal, tidak ada yang berubah.
  ///
  /// [items] berasal dari keranjang (CartSummary.lines), catatan sudah
  /// menempel di item. Mengembalikan pesanan yang dibuat.
  Future<OrderModel> buatPesanan({
    required UserModel pembeli,
    required StandModel stand,
    required List<OrderLineItem> items,
    required String jamAmbil,
  }) async {
    final daftarItem = items.where((i) => i.quantity > 0).toList();
    if (daftarItem.isEmpty) {
      throw const OrderFailure('Keranjang masih kosong.');
    }
    if (pembeli.status != AccountStatus.aktif) {
      throw const OrderFailure('Akunmu tidak aktif, tidak bisa memesan.');
    }

    final orderRef = _orders.doc();
    final counterRef = _db
        .collection(FirestoreCollections.counters)
        .doc(_tanggalHariIni());

    final pesanan = await _db.runTransaction<OrderModel>((tx) async {
      // --- BACA (semua pembacaan harus sebelum penulisan) ---
      final standSnap = await tx.get(_stand(stand.id));
      final standData = standSnap.data();
      if (standData == null) {
        throw const OrderFailure('Stand tidak ditemukan.');
      }
      if (standData['isOpen'] != true) {
        throw OrderFailure('${stand.name} sedang tutup.');
      }

      final menuSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in daftarItem) {
        menuSnaps.add(await tx.get(_menu(stand.id, item.menuId)));
      }
      final counterSnap = await tx.get(counterRef);

      // --- CEK STOK, dan pakai harga terbaru dari Firestore ---
      final itemFinal = <OrderLineItem>[];
      final stokBaru = <String, int>{};
      for (var i = 0; i < daftarItem.length; i++) {
        final item = daftarItem[i];
        final data = menuSnaps[i].data();
        if (data == null) {
          throw OrderFailure('${item.name} sudah tidak dijual.');
        }
        final stok = (data['stok'] as num?)?.toInt() ?? 0;
        final tersedia = (data['tersedia'] as bool?) ?? false;
        if (!tersedia || stok <= 0) {
          throw OrderFailure('${item.name} sudah habis.');
        }
        if (item.quantity > stok) {
          throw OrderFailure('Stok ${item.name} tinggal $stok.');
        }
        stokBaru[item.menuId] = stok - item.quantity;
        itemFinal.add(
          OrderLineItem(
            menuId: item.menuId,
            name: (data['nama'] as String?) ?? item.name,
            quantity: item.quantity,
            price: (data['harga'] as num?)?.toInt() ?? item.price,
            note: item.note,
          ),
        );
      }

      // --- NOMOR PESANAN HARIAN ---
      final nomorKe = ((counterSnap.data()?['next'] as num?)?.toInt() ?? 1);
      final nomorPesanan = 'A-${nomorKe.toString().padLeft(3, '0')}';

      // --- TULIS ---
      stokBaru.forEach((menuId, stok) {
        tx.update(_menu(stand.id, menuId), {
          'stok': stok,
          'tersedia': stok > 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      tx.set(counterRef, {'next': nomorKe + 1});

      final baru = OrderModel(
        id: orderRef.id,
        orderCode: nomorPesanan,
        buyerName: pembeli.name,
        standId: stand.id,
        standName: (standData['namaStand'] as String?) ?? stand.name,
        pickupTime: jamAmbil,
        status: OrderStatus.menunggu,
        paymentMethod: PaymentValue.labelTunai,
        items: itemFinal,
        timeline: const [],
      );
      final data = {
        ...baru.toMap(buyerId: pembeli.id),
        'createdAt': FieldValue.serverTimestamp(),
        'waktuStatus': {
          OrderStatusValue.menunggu: FieldValue.serverTimestamp(),
        },
      };
      tx.set(orderRef, data);
      return baru;
    });

    // Lengkapi stepper status untuk layar konfirmasi pesanan.
    return pesanan.copyWith(
      timeline: buildOrderTimeline(
        standName: pesanan.standName,
        orderCode: pesanan.orderCode,
        times: {OrderStatus.menunggu: formatJamTimestamp(Timestamp.now())},
      ),
    );
  }

  // ===========================================================================
  // Stream real-time
  // ===========================================================================

  /// Semua pesanan milik pembeli, terbaru di atas.
  /// Layar Pesanan Saya memisahkan tab Aktif dan Riwayat dari status.
  /// Butuh composite index: pembeliId ASC, createdAt DESC.
  Stream<List<OrderModel>> streamPesananPembeli(String pembeliId) {
    return _orders
        .where('pembeliId', isEqualTo: pembeliId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Satu pesanan (layar Detail Pesanan / stepper status).
  Stream<OrderModel?> streamPesanan(String orderId) {
    return _orders.doc(orderId).snapshots().map((s) {
      final data = s.data();
      return data == null ? null : OrderModel.fromMap(s.id, data);
    });
  }

  /// Pesanan masuk hari ini untuk satu stand, terbaru di atas.
  /// Butuh composite index: standId ASC, createdAt DESC.
  Stream<List<SellerOrderModel>> streamPesananStand(String standId) {
    return _queryHariIni(standId).snapshots().map(
      (s) =>
          s.docs.map((d) => SellerOrderModel.fromMap(d.id, d.data())).toList(),
    );
  }

  /// Ringkasan hari ini untuk layar Profil Stand.
  Stream<RingkasanHariIni> streamRingkasanHariIni(String standId) {
    return _queryHariIni(standId).snapshots().map((s) {
      var menunggu = 0, diproses = 0, siap = 0, selesai = 0;
      var batal = 0, tidakDiambil = 0, pendapatan = 0;
      for (final d in s.docs) {
        switch (d.data()['status']) {
          case OrderStatusValue.menunggu:
            menunggu++;
          case OrderStatusValue.diproses:
            diproses++;
          case OrderStatusValue.siap:
            siap++;
          case OrderStatusValue.selesai:
            selesai++;
            pendapatan += (d.data()['total'] as num?)?.toInt() ?? 0;
          case OrderStatusValue.dibatalkan:
            batal++;
          case OrderStatusValue.tidakDiambil:
            tidakDiambil++;
        }
      }
      return RingkasanHariIni(
        totalPesanan: s.docs.length,
        menunggu: menunggu,
        diproses: diproses,
        siap: siap,
        selesai: selesai,
        dibatalkan: batal,
        tidakDiambil: tidakDiambil,
        pendapatan: pendapatan,
      );
    });
  }

  Query<Map<String, dynamic>> _queryHariIni(String standId) {
    return _orders
        .where('standId', isEqualTo: standId)
        .where('createdAt', isGreaterThanOrEqualTo: _awalHariIni())
        .orderBy('createdAt', descending: true);
  }

  // ===========================================================================
  // Status oleh penjual
  // ===========================================================================

  /// Baru -> Diproses.
  Future<void> terimaPesanan(String orderId) => _ubahStatus(
    orderId,
    dari: OrderStatusValue.menunggu,
    ke: OrderStatus.diproses,
  );

  /// Diproses -> Siap diambil.
  Future<void> tandaiSiap(String orderId) => _ubahStatus(
    orderId,
    dari: OrderStatusValue.diproses,
    ke: OrderStatus.siapDiambil,
  );

  /// Siap -> Selesai (sudah diambil dan dibayar).
  Future<void> selesaikanPesanan(String orderId) => _ubahStatus(
    orderId,
    dari: OrderStatusValue.siap,
    ke: OrderStatus.selesai,
  );

  /// Penjual menolak pesanan baru. Stok dikembalikan.
  Future<void> tolakPesanan(String orderId, {required String alasan}) =>
      _batalDanKembalikanStok(orderId, alasan: alasan);

  /// Siap -> Tidak diambil. Menambah jumlahTidakDiambil pembeli.
  /// Stok tidak dikembalikan karena makanan sudah dibuat.
  Future<void> tandaiTidakDiambil(String orderId) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_orders.doc(orderId));
      final data = _wajibAda(snap);
      _wajibStatus(data, OrderStatusValue.siap);

      tx.update(_orders.doc(orderId), {
        'status': OrderStatusValue.tidakDiambil,
        ...waktuStatusUpdate(OrderStatus.tidakDiambil),
      });
      final pembeliId = data['pembeliId'] as String?;
      if (pembeliId != null && pembeliId.isNotEmpty) {
        tx.update(_user(pembeliId), {
          'jumlahTidakDiambil': FieldValue.increment(1),
        });
      }
    });
  }

  // ===========================================================================
  // Aksi pembeli
  // ===========================================================================

  /// Pembeli membatalkan pesanan. Hanya boleh saat masih Menunggu.
  /// Stok dikembalikan.
  Future<void> batalkanPesanan(String orderId, {String? alasan}) =>
      _batalDanKembalikanStok(
        orderId,
        alasan: (alasan == null || alasan.trim().isEmpty)
            ? 'Dibatalkan pembeli'
            : alasan.trim(),
      );

  /// Rating 1-5 dan ulasan, hanya untuk pesanan yang sudah selesai.
  Future<void> beriRating(
    String orderId, {
    required int bintang,
    String ulasan = '',
  }) async {
    if (bintang < 1 || bintang > 5) {
      throw const OrderFailure('Rating harus 1 sampai 5 bintang.');
    }
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_orders.doc(orderId));
      final data = _wajibAda(snap);
      _wajibStatus(data, OrderStatusValue.selesai);
      if (data['sudahDirating'] == true) {
        throw const OrderFailure('Pesanan ini sudah diberi rating.');
      }
      tx.update(_orders.doc(orderId), {
        'rating': bintang,
        'ulasan': ulasan.trim(),
        'sudahDirating': true,
      });
    });
  }

  // ===========================================================================
  // Bantuan internal
  // ===========================================================================

  Future<void> _ubahStatus(
    String orderId, {
    required String dari,
    required OrderStatus ke,
  }) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_orders.doc(orderId));
      _wajibStatus(_wajibAda(snap), dari);
      tx.update(_orders.doc(orderId), {
        'status': orderStatusToValue(ke),
        ...waktuStatusUpdate(ke),
      });
    });
  }

  Future<void> _batalDanKembalikanStok(
    String orderId, {
    required String alasan,
  }) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_orders.doc(orderId));
      final data = _wajibAda(snap);
      if (data['status'] != OrderStatusValue.menunggu) {
        throw const OrderFailure(
          'Pesanan sudah diproses penjual, tidak bisa dibatalkan.',
        );
      }

      final standId = (data['standId'] as String?) ?? '';
      final items = (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((m) => OrderLineItem.fromMap(Map<String, dynamic>.from(m)))
          .toList();

      // Baca semua menu dulu (aturan transaction: baca sebelum tulis).
      final menuSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in items) {
        menuSnaps.add(await tx.get(_menu(standId, item.menuId)));
      }

      for (var i = 0; i < items.length; i++) {
        final menuData = menuSnaps[i].data();
        if (menuData == null) continue; // menu sudah dihapus penjual
        final stok =
            ((menuData['stok'] as num?)?.toInt() ?? 0) + items[i].quantity;
        tx.update(menuSnaps[i].reference, {
          'stok': stok,
          'tersedia': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(_orders.doc(orderId), {
        'status': OrderStatusValue.dibatalkan,
        'alasanBatal': alasan,
        ...waktuStatusUpdate(OrderStatus.dibatalkan),
      });
    });
  }

  Map<String, dynamic> _wajibAda(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data();
    if (data == null) throw const OrderFailure('Pesanan tidak ditemukan.');
    return data;
  }

  void _wajibStatus(Map<String, dynamic> data, String statusSeharusnya) {
    if (data['status'] != statusSeharusnya) {
      throw const OrderFailure(
        'Status pesanan sudah berubah. Muat ulang lalu coba lagi.',
      );
    }
  }
}

/// "2026-11-25", dipakai sebagai id dokumen counters.
String _tanggalHariIni() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

Timestamp _awalHariIni() {
  final n = DateTime.now();
  return Timestamp.fromDate(DateTime(n.year, n.month, n.day));
}
