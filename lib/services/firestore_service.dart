// Layanan akses data Firestore: stand dan menu.
//
// Fungsi pesanan (buatPesanan, ubah status, batal) ditambahkan di Minggu 3.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/menu_model.dart';
import '../models/stand_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _stands =>
      _db.collection(FirestoreCollections.stands);

  CollectionReference<Map<String, dynamic>> _menus(String standId) =>
      _stands.doc(standId).collection(FirestoreCollections.menus);

  // ---------------------------------------------------------------------------
  // Stand
  // ---------------------------------------------------------------------------

  /// Semua stand, urut nama. Real-time.
  Stream<List<StandModel>> streamStands() {
    return _stands
        .orderBy('namaStand')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => StandModel.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Satu stand (mis. stand milik penjual yang login). Real-time.
  Stream<StandModel?> streamStand(String standId) {
    return _stands.doc(standId).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : StandModel.fromMap(snap.id, data);
    });
  }

  /// Penjual membuka/menutup stand.
  Future<void> ubahStatusBuka(String standId, bool isOpen) {
    return _stands.doc(standId).update({'isOpen': isOpen});
  }

  /// Mengubah info stand dari layar Profil Stand.
  Future<void> ubahInfoStand(
    String standId, {
    required String namaStand,
    required String deskripsi,
    required String jamBuka,
    required String jamTutup,
  }) {
    return _stands.doc(standId).update({
      'namaStand': namaStand.trim(),
      'deskripsi': deskripsi.trim(),
      'jamBuka': jamBuka.trim(),
      'jamTutup': jamTutup.trim(),
    });
  }

  // ---------------------------------------------------------------------------
  // Menu: baca
  // ---------------------------------------------------------------------------

  /// Menu satu stand, urut nama. Real-time (stok langsung ter-update).
  Stream<List<MenuModel>> streamMenus(StandModel stand) {
    return _menus(stand.id)
        .orderBy('nama')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => MenuModel.fromMap(
                  d.id,
                  d.data(),
                  standId: stand.id,
                  standName: stand.name,
                ),
              )
              .toList(),
        );
  }

  /// Semua menu dari semua stand (untuk pencarian di beranda pembeli).
  /// Memakai collectionGroup lalu menempelkan nama stand dari streamStands.
  Stream<List<MenuModel>> streamSemuaMenu() {
    late final StreamController<List<MenuModel>> controller;
    StreamSubscription<List<StandModel>>? standSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? menuSub;
    Map<String, String> namaStand = {};
    List<QueryDocumentSnapshot<Map<String, dynamic>>> menuDocs = [];

    void kirim() {
      controller.add(
        menuDocs.map((d) {
          final standId = d.reference.parent.parent?.id ?? '';
          return MenuModel.fromMap(
            d.id,
            d.data(),
            standId: standId,
            standName: namaStand[standId] ?? '',
          );
        }).toList(),
      );
    }

    controller = StreamController<List<MenuModel>>(
      onListen: () {
        standSub = streamStands().listen((stands) {
          namaStand = {for (final s in stands) s.id: s.name};
          kirim();
        }, onError: controller.addError);
        menuSub = _db
            .collectionGroup(FirestoreCollections.menus)
            .snapshots()
            .listen((snap) {
              menuDocs = snap.docs;
              kirim();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await standSub?.cancel();
        await menuSub?.cancel();
      },
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Menu: tambah, ubah, hapus
  // ---------------------------------------------------------------------------

  /// Menambah menu baru. Mengembalikan id dokumen yang dibuat.
  Future<String> tambahMenu(String standId, MenuModel menu) async {
    final ref = await _menus(standId).add({
      ...menu.toMap(),
      'tersedia': menu.stock > 0 && menu.isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Menyimpan perubahan menu (nama, harga, kategori, stok, foto, dll.).
  Future<void> ubahMenu(String standId, MenuModel menu) {
    return _menus(standId).doc(menu.id).update({
      ...menu.toMap(),
      // stok 0 selalu dianggap habis
      if (menu.stock <= 0) 'tersedia': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> hapusMenu(String standId, String menuId) {
    return _menus(standId).doc(menuId).delete();
  }

  // ---------------------------------------------------------------------------
  // Stok
  // ---------------------------------------------------------------------------

  /// Mengubah stok satu menu. Stok 0 otomatis membuat menu "Habis".
  Future<void> ubahStok(String standId, String menuId, int stok) {
    final s = stok < 0 ? 0 : stok;
    return _menus(standId).doc(menuId).update({
      'stok': s,
      'tersedia': s > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saklar tersedia/habis dari layar Kelola Menu.
  /// Mengaktifkan menu yang stoknya 0 akan mengisi stok menjadi 1.
  Future<void> ubahKetersediaan(String standId, MenuModel menu, bool tersedia) {
    return _menus(standId).doc(menu.id).update({
      'tersedia': tersedia,
      if (tersedia && menu.stock <= 0) 'stok': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// "Atur stok hari ini": mengubah banyak stok sekaligus dalam satu batch,
  /// jadi semuanya berhasil atau semuanya gagal.
  /// [stokBaru] berisi pasangan menuId -> stok.
  Future<void> aturStokHariIni(String standId, Map<String, int> stokBaru) {
    final batch = _db.batch();
    stokBaru.forEach((menuId, stok) {
      final s = stok < 0 ? 0 : stok;
      batch.update(_menus(standId).doc(menuId), {
        'stok': s,
        'tersedia': s > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return batch.commit();
  }
}
