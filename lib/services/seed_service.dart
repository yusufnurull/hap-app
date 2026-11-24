// Pengisi data awal Firestore untuk pengujian (dipakai sekali).
//
// Menyalin 4 stand dan menu dari mock_data.dart ke Firestore, lalu
// menghubungkan stand dengan akun penjual uji. Jalankan lewat:
//   flutter run -t lib/seed_main.dart
// Aman dijalankan ulang: dokumen ditimpa dengan id yang sama.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_values.dart';
import '../data/mock_data.dart';

class SeedService {
  SeedService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// [pemilikStand] berisi pasangan standId -> uid penjual.
  /// Stand tanpa pemilik tetap dibuat dengan pemilikId kosong.
  /// Mengembalikan ringkasan hasil.
  Future<String> isiDataAwal({
    Map<String, String> pemilikStand = const {},
  }) async {
    final batch = _db.batch();
    final stands = _db.collection(FirestoreCollections.stands);
    final users = _db.collection(FirestoreCollections.users);

    for (final stand in mockStands) {
      final pemilikId = pemilikStand[stand.id] ?? '';
      batch.set(stands.doc(stand.id), {
        ...stand.copyWith(ownerId: pemilikId).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Hubungkan akun penjual ke stand-nya dan langsung aktifkan,
      // karena fitur persetujuan admin baru dibuat di Minggu 3.
      if (pemilikId.isNotEmpty) {
        batch.set(users.doc(pemilikId), {
          'standId': stand.id,
          'status': AccountStatus.aktif,
        }, SetOptions(merge: true));
      }
    }

    var jumlahMenu = 0;
    for (final menu in mockMenus) {
      batch.set(
        stands
            .doc(menu.standId)
            .collection(FirestoreCollections.menus)
            .doc(menu.id),
        {...menu.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
      );
      jumlahMenu++;
    }

    await batch.commit();
    return 'Berhasil: ${mockStands.length} stand, $jumlahMenu menu, '
        '${pemilikStand.values.where((v) => v.isNotEmpty).length} penjual terhubung.';
  }
}
