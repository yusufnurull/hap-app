// Layanan autentikasi pengguna.
//
// Menangani daftar, masuk, keluar, dan stream data akun (users/{uid}).
// Layar tidak memanggil FirebaseAuth langsung; semua lewat file ini.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_values.dart';
import '../models/user_model.dart';

/// Galat yang pesannya sudah siap ditampilkan ke pengguna.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  /// Akun Firebase yang sedang login, atau null.
  User? get currentFirebaseUser => _auth.currentUser;

  /// Berubah setiap kali pengguna masuk atau keluar.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Daftar
  // ---------------------------------------------------------------------------

  /// Membuat akun di Firebase Auth lalu dokumen users/{uid}.
  /// Pembeli langsung 'aktif'; penjual 'menunggu' sampai disetujui admin.
  /// Admin tidak bisa daftar dari aplikasi (dibuat manual di Console).
  Future<UserModel> daftar({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required UserRole role,
  }) async {
    if (role == UserRole.admin) {
      throw const AuthFailure(
        'Akun admin tidak bisa didaftarkan dari aplikasi.',
      );
    }

    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(pesanError(e));
    }

    final uid = credential.user!.uid;
    final user = UserModel(
      id: uid,
      name: nama.trim(),
      email: email.trim(),
      phone: noHp.trim(),
      role: role,
      status: role == UserRole.penjual
          ? AccountStatus.menunggu
          : AccountStatus.aktif,
    );

    try {
      await _users.doc(uid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Dokumen gagal dibuat: hapus akun Auth supaya tidak ada akun "yatim"
      // yang bisa login tapi tidak punya data.
      try {
        await credential.user?.delete();
      } catch (_) {}
      throw const AuthFailure('Gagal menyimpan data akun. Coba lagi.');
    }

    return user;
  }

  // ---------------------------------------------------------------------------
  // Masuk dan keluar
  // ---------------------------------------------------------------------------

  Future<void> masuk({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(pesanError(e));
    }
  }

  Future<void> keluar() => _auth.signOut();

  // ---------------------------------------------------------------------------
  // Data user
  // ---------------------------------------------------------------------------

  /// Mengambil data user sekali (bukan real-time).
  Future<UserModel?> ambilUser(String uid) async {
    final snap = await _users.doc(uid).get();
    final data = snap.data();
    return data == null ? null : UserModel.fromMap(snap.id, data);
  }

  /// Stream data akun yang sedang login. Mengirim null saat belum login
  /// atau dokumennya belum ada. Ikut berubah saat admin mengubah status/role.
  Stream<UserModel?> streamUser() {
    late final StreamController<UserModel?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;

    controller = StreamController<UserModel?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((firebaseUser) {
          // Ganti akun: hentikan pemantauan dokumen akun sebelumnya.
          docSub?.cancel();
          docSub = null;
          if (firebaseUser == null) {
            controller.add(null);
            return;
          }
          docSub = _users.doc(firebaseUser.uid).snapshots().listen((snap) {
            final data = snap.data();
            controller.add(
              data == null ? null : UserModel.fromMap(snap.id, data),
            );
          }, onError: controller.addError);
        }, onError: controller.addError);
      },
      onCancel: () async {
        await docSub?.cancel();
        await authSub?.cancel();
      },
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Pesan galat
  // ---------------------------------------------------------------------------

  static String pesanError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return e.message ?? 'Terjadi kesalahan. Coba lagi.';
    }
  }
}
