// Layanan khusus admin: rekap, verifikasi penjual, kelola stand, pengguna.
//
// Security Rules hanya mengizinkan fungsi-fungsi ini bila yang login
// adalah admin berstatus aktif.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_values.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';

/// Angka untuk layar Rekap admin.
class RekapAdmin {
  const RekapAdmin({
    required this.pesananHariIni,
    required this.selesaiHariIni,
    required this.standBuka,
    required this.totalStand,
    required this.penjualMenunggu,
  });

  static const kosong = RekapAdmin(
    pesananHariIni: 0,
    selesaiHariIni: 0,
    standBuka: 0,
    totalStand: 0,
    penjualMenunggu: 0,
  );

  final int pesananHariIni;
  final int selesaiHariIni;
  final int standBuka;
  final int totalStand;
  final int penjualMenunggu;
}

class AdminService {
  AdminService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _stands =>
      _db.collection(FirestoreCollections.stands);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(FirestoreCollections.orders);

  // ===========================================================================
  // Rekap
  // ===========================================================================

  /// Pesanan hari ini, selesai, stand buka, dan penjual menunggu.
  /// Menggabungkan tiga stream; nilai dikirim ulang setiap ada perubahan.
  Stream<RekapAdmin> streamRekap() {
    late final StreamController<RekapAdmin> controller;
    final subs = <StreamSubscription<dynamic>>[];
    var pesanan = 0, selesai = 0, buka = 0, totalStand = 0, menunggu = 0;

    void kirim() => controller.add(
      RekapAdmin(
        pesananHariIni: pesanan,
        selesaiHariIni: selesai,
        standBuka: buka,
        totalStand: totalStand,
        penjualMenunggu: menunggu,
      ),
    );

    controller = StreamController<RekapAdmin>(
      onListen: () {
        final n = DateTime.now();
        subs.add(
          _orders
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(n.year, n.month, n.day),
                ),
              )
              .snapshots()
              .listen((s) {
                pesanan = s.docs.length;
                selesai = s.docs
                    .where(
                      (d) => d.data()['status'] == OrderStatusValue.selesai,
                    )
                    .length;
                kirim();
              }, onError: controller.addError),
        );

        subs.add(
          _stands.snapshots().listen((s) {
            totalStand = s.docs.length;
            buka = s.docs.where((d) => d.data()['isOpen'] == true).length;
            kirim();
          }, onError: controller.addError),
        );

        subs.add(
          streamPenjualMenunggu().listen((list) {
            menunggu = list.length;
            kirim();
          }, onError: controller.addError),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  // ===========================================================================
  // Verifikasi penjual
  // ===========================================================================

  /// Penjual yang baru daftar dan belum disetujui.
  Stream<List<UserModel>> streamPenjualMenunggu() {
    return _users
        .where('role', isEqualTo: RoleValue.penjual)
        .where('status', isEqualTo: AccountStatus.menunggu)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Menyetujui penjual: membuat dokumen stand miliknya, lalu mengaktifkan
  /// akunnya. Keduanya dalam satu batch (berhasil bersama atau gagal bersama).
  /// Mengembalikan id stand yang dibuat.
  Future<String> setujuiPenjual(
    UserModel penjual, {
    String? namaStand,
    String deskripsi = '',
    String jamBuka = '07.00',
    String jamTutup = '15.00',
    String lokasi = '',
    List<StandCategory> kategori = const [StandCategory.makananBerat],
    String ikon = 'storefront',
  }) async {
    if (penjual.role != UserRole.penjual) {
      throw Exception('Akun ini bukan penjual.');
    }
    final nama = (namaStand ?? penjual.proposedStandName).trim();
    if (nama.isEmpty) throw Exception('Nama stand belum diisi.');

    final standRef = _stands.doc();
    final stand = StandModel(
      id: standRef.id,
      name: nama,
      isOpen: false,
      foodTypes: deskripsi,
      openHours: '$jamBuka–$jamTutup',
      locationNote: lokasi,
      categories: kategori,
      icon: ikon,
      ownerId: penjual.id,
    );

    final batch = _db.batch();
    batch.set(standRef, {
      ...stand.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_users.doc(penjual.id), {
      'status': AccountStatus.aktif,
      'standId': standRef.id,
    });
    await batch.commit();
    return standRef.id;
  }

  /// Menolak pendaftaran penjual (akun menjadi nonaktif).
  Future<void> tolakPenjual(String uid) {
    return _users.doc(uid).update({'status': AccountStatus.nonaktif});
  }

  // ===========================================================================
  // Pengguna
  // ===========================================================================

  /// Semua pengguna, bisa difilter per peran. Urut nama.
  /// Filter peran butuh composite index: role ASC, nama ASC.
  Stream<List<UserModel>> streamPengguna({UserRole? role}) {
    Query<Map<String, dynamic>> q = _users;
    if (role != null) q = q.where('role', isEqualTo: roleToValue(role));
    return q
        .orderBy('nama')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Mengaktifkan atau menonaktifkan akun.
  /// [uidAdmin] = uid admin yang login, supaya admin tidak menonaktifkan
  /// dirinya sendiri.
  Future<void> ubahStatusAkun(
    String uid, {
    required bool aktif,
    required String uidAdmin,
  }) {
    if (uid == uidAdmin && !aktif) {
      throw Exception('Tidak bisa menonaktifkan akun sendiri.');
    }
    return _users.doc(uid).update({
      'status': aktif ? AccountStatus.aktif : AccountStatus.nonaktif,
    });
  }

  /// Mengatur ulang catatan tidak diambil (mis. setelah pembeli ditegur).
  Future<void> resetTidakDiambil(String uid) {
    return _users.doc(uid).update({'jumlahTidakDiambil': 0});
  }

  // ===========================================================================
  // Kelola stand
  // ===========================================================================

  /// Admin menambah stand secara langsung. Mengembalikan id stand.
  Future<String> tambahStand(StandModel stand) async {
    final ref = _stands.doc();
    await ref.set({
      ...stand.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (stand.ownerId.isNotEmpty) {
      await _users.doc(stand.ownerId).update({'standId': ref.id});
    }
    return ref.id;
  }

  /// Menyimpan perubahan data stand.
  Future<void> ubahStand(StandModel stand) {
    return _stands.doc(stand.id).update(stand.toMap());
  }

  Future<void> ubahStatusBuka(String standId, bool isOpen) {
    return _stands.doc(standId).update({'isOpen': isOpen});
  }
}
