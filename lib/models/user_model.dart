// Model data pengguna aplikasi.

import '../core/constants/app_enums.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.noShowCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final int noShowCount;

  UserModel copyWith({bool? isActive, int? noShowCount}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: isActive ?? this.isActive,
      noShowCount: noShowCount ?? this.noShowCount,
    );
  }
}

/// Pendaftar penjual yang menunggu verifikasi admin.
class PendingSellerModel {
  const PendingSellerModel({
    required this.id,
    required this.applicantName,
    required this.standName,
    required this.appliedDate,
    required this.foodTypes,
  });

  final String id;
  final String applicantName;
  final String standName;
  final String appliedDate;
  final String foodTypes;
}
