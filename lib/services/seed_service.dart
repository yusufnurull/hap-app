// Pengisi data awal Firebase untuk pengujian (dipakai sekali).
//
// Membuat akun uji (Firebase Auth + users/{uid}), lalu menyalin 4 stand dan
// menu dari mock_data.dart ke Firestore, dan menghubungkan penjual dengan
// stand-nya. Jalankan lewat:
//   flutter run -t lib/seed_main.dart
//
// Aman dijalankan ulang: akun yang sudah ada tidak dibuat dua kali, dan
// dokumen stand/menu ditimpa dengan id yang sama.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_values.dart';
import '../data/mock_data.dart';

/// Data satu akun uji.
class SeedAccount {
  const SeedAccount({
    required this.nama,
    required this.email,
    required this.password,
    required this.noHp,
    required this.role,
    this.standId,
  });

  final String nama;
  final String email;
  final String password;
  final String noHp;
  final UserRole role;

  /// Hanya untuk penjual: id stand dari mock_data.dart (mis. 'bu-sri').
  final String? standId;
}

class SeedService {
  SeedService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Menjalankan seluruh pengisian. [onProgress] menerima pesan per langkah.
  Future<String> isiDataAwal({
    required List<SeedAccount> akun,
    void Function(String pesan)? onProgress,
  }) async {
    final log = onProgress ?? (_) {};

    // 1. Akun uji
    final uidPerEmail = await _buatAkun(akun, log);

    // 2. Stand, menu, dan penghubung penjual
    log('Menyimpan stand dan menu...');
    final pemilikStand = <String, String>{
      for (final a in akun)
        if (a.role == UserRole.penjual && a.standId != null)
          a.standId!: uidPerEmail[a.email]!,
    };
    final jumlahMenu = await _isiStandDanMenu(pemilikStand);

    return 'Berhasil!\n'
        '${uidPerEmail.length} akun, ${mockStands.length} stand, '
        '$jumlahMenu menu, ${pemilikStand.length} penjual terhubung ke stand.';
  }

  /// Membuat akun di Auth dan dokumen users/{uid}. Mengembalikan email -> uid.
  ///
  /// Memakai Firebase app kedua bernama 'seed', supaya pembuatan akun tidak
  /// mengganti akun yang sedang login di aplikasi utama.
  Future<Map<String, String>> _buatAkun(
    List<SeedAccount> akun,
    void Function(String) log,
  ) async {
    FirebaseApp app;
    try {
      app = Firebase.app('seed');
    } on FirebaseException {
      // Belum ada: buat dengan konfigurasi yang sama dengan app utama.
      app = await Firebase.initializeApp(
        name: 'seed',
        options: Firebase.app().options,
      );
    }
    return _buatAkunDenganApp(app, akun, log);
  }

  Future<Map<String, String>> _buatAkunDenganApp(
    FirebaseApp app,
    List<SeedAccount> akun,
    void Function(String) log,
  ) async {
    final auth = FirebaseAuth.instanceFor(app: app);
    final users = _db.collection(FirestoreCollections.users);
    final hasil = <String, String>{};

    try {
      for (final a in akun) {
        log('Membuat akun ${a.email}...');
        final uid = await _uidAkun(auth, a);
        hasil[a.email] = uid;

        await users.doc(uid).set({
          'nama': a.nama,
          'email': a.email,
          'noHp': a.noHp,
          'role': roleToValue(a.role),
          // Semua akun uji langsung aktif, termasuk penjual,
          // karena persetujuan admin baru dibuat di Minggu 3.
          'status': AccountStatus.aktif,
          'jumlahTidakDiambil': 0,
          if (a.standId != null) 'standId': a.standId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } finally {
      await auth.signOut();
      await app.delete();
    }
    return hasil;
  }

  /// Membuat akun baru, atau masuk bila email sudah terdaftar.
  Future<String> _uidAkun(FirebaseAuth auth, SeedAccount a) async {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: a.email,
        password: a.password,
      );
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') {
        throw Exception('Gagal membuat ${a.email}: ${e.code}');
      }
      try {
        final cred = await auth.signInWithEmailAndPassword(
          email: a.email,
          password: a.password,
        );
        return cred.user!.uid;
      } on FirebaseAuthException {
        throw Exception(
          '${a.email} sudah terdaftar dengan password lain. '
          'Hapus akunnya di Console atau samakan password-nya.',
        );
      }
    }
  }

  /// Menyalin stand dan menu dari mock_data.dart. Mengembalikan jumlah menu.
  Future<int> _isiStandDanMenu(Map<String, String> pemilikStand) async {
    final batch = _db.batch();
    final stands = _db.collection(FirestoreCollections.stands);

    for (final stand in mockStands) {
      batch.set(stands.doc(stand.id), {
        ...stand.copyWith(ownerId: pemilikStand[stand.id] ?? '').toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    for (final menu in mockMenus) {
      batch.set(
        stands
            .doc(menu.standId)
            .collection(FirestoreCollections.menus)
            .doc(menu.id),
        {...menu.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
      );
    }

    await batch.commit();
    return mockMenus.length;
  }
}
