// Model data pengguna aplikasi.
//
// Dokumen Firestore: users/{uid}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/firestore_values.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.noShowCount = 0,
    this.status = AccountStatus.aktif,
    this.standId,
    this.proposedStandName = '',
  });

  final String id; // = uid Firebase Auth
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final int noShowCount;

  /// 'aktif', 'menunggu', atau 'nonaktif'.
  final String status;

  /// Hanya terisi untuk penjual.
  final String? standId;

  /// Nama stand yang diisi penjual saat daftar (`namaStandUsulan`).
  /// Dipakai admin saat menyetujui penjual.
  final String proposedStandName;

  bool get isWaitingApproval => status == AccountStatus.menunggu;

  /// Membaca dokumen `users/{uid}`. Field yang kosong diberi nilai aman.
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    final status = AccountStatus.isValid(data['status'])
        ? data['status'] as String
        : AccountStatus.aktif;
    return UserModel(
      id: id,
      name: (data['nama'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['noHp'] as String?) ?? '',
      role: roleFromValue(data['role']) ?? UserRole.pembeli,
      status: status,
      isActive: status != AccountStatus.nonaktif,
      noShowCount: (data['jumlahTidakDiambil'] as num?)?.toInt() ?? 0,
      standId: data['standId'] as String?,
      proposedStandName: (data['namaStandUsulan'] as String?) ?? '',
    );
  }

  /// Data untuk disimpan ke Firestore. `createdAt` diisi oleh service.
  Map<String, dynamic> toMap() {
    return {
      'nama': name,
      'email': email,
      'noHp': phone,
      'role': roleToValue(role),
      'status': status,
      'jumlahTidakDiambil': noShowCount,
      if (standId != null) 'standId': standId,
      if (proposedStandName.isNotEmpty) 'namaStandUsulan': proposedStandName,
    };
  }

  UserModel copyWith({
    bool? isActive,
    int? noShowCount,
    String? status,
    String? standId,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: isActive ?? this.isActive,
      noShowCount: noShowCount ?? this.noShowCount,
      status: status ?? this.status,
      standId: standId ?? this.standId,
      proposedStandName: proposedStandName,
    );
  }
}

/// Mengubah Timestamp Firestore menjadi teks jam "HH.mm" (mis. "11.55").
String formatJamTimestamp(Object? value) {
  if (value is! Timestamp) return '';
  final t = value.toDate();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh.$mm';
}
