// Nilai string yang disimpan di Firestore, beserta konversinya ke enum aplikasi.
//
// Firestore hanya menyimpan string, sedangkan layar memakai enum. Semua
// konversi dipusatkan di sini supaya tidak ada teks seperti 'aktif' atau
// 'siap' yang ditulis ulang di banyak file.

import 'app_enums.dart';
import 'order_status.dart';

/// Nilai field `users.role`.
class RoleValue {
  static const String pembeli = 'pembeli';
  static const String penjual = 'penjual';
  static const String admin = 'admin';
}

/// Nilai field `users.status`.
class AccountStatus {
  static const String aktif = 'aktif';
  static const String menunggu = 'menunggu'; // penjual belum disetujui admin
  static const String nonaktif = 'nonaktif';

  static const List<String> semua = [aktif, menunggu, nonaktif];
  static bool isValid(Object? value) => semua.contains(value);
}

/// Nilai field `orders.status`.
class OrderStatusValue {
  static const String menunggu = 'menunggu';
  static const String diproses = 'diproses';
  static const String siap = 'siap';
  static const String selesai = 'selesai';
  static const String dibatalkan = 'dibatalkan';
  static const String tidakDiambil = 'tidakDiambil';
}

/// Nilai field `orders.metodeBayar`.
class PaymentValue {
  static const String tunai = 'tunai';
  static const String labelTunai = 'Bayar di tempat';
}

// ---------------------------------------------------------------------------
// Role
// ---------------------------------------------------------------------------

String roleToValue(UserRole role) => role.name; // pembeli / penjual / admin

UserRole? roleFromValue(Object? value) {
  for (final role in UserRole.values) {
    if (role.name == value) return role;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Kategori menu dan stand (nama enum = nilai di Firestore)
// ---------------------------------------------------------------------------

String menuCategoryToValue(MenuCategory category) => category.name;

MenuCategory menuCategoryFromValue(Object? value) {
  for (final c in MenuCategory.values) {
    if (c.name == value) return c;
  }
  return MenuCategory.makanan;
}

String standCategoryToValue(StandCategory category) => category.name;

StandCategory? standCategoryFromValue(Object? value) {
  for (final c in StandCategory.values) {
    if (c.name == value) return c;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Status pesanan
// ---------------------------------------------------------------------------

String orderStatusToValue(OrderStatus status) {
  switch (status) {
    case OrderStatus.menunggu:
      return OrderStatusValue.menunggu;
    case OrderStatus.diproses:
      return OrderStatusValue.diproses;
    case OrderStatus.siapDiambil:
      return OrderStatusValue.siap;
    case OrderStatus.selesai:
      return OrderStatusValue.selesai;
    case OrderStatus.dibatalkan:
      return OrderStatusValue.dibatalkan;
    case OrderStatus.tidakDiambil:
      return OrderStatusValue.tidakDiambil;
  }
}

OrderStatus orderStatusFromValue(Object? value) {
  switch (value) {
    case OrderStatusValue.diproses:
      return OrderStatus.diproses;
    case OrderStatusValue.siap:
      return OrderStatus.siapDiambil;
    case OrderStatusValue.selesai:
      return OrderStatus.selesai;
    case OrderStatusValue.dibatalkan:
      return OrderStatus.dibatalkan;
    case OrderStatusValue.tidakDiambil:
      return OrderStatus.tidakDiambil;
    default:
      return OrderStatus.menunggu;
  }
}

/// Status yang sama dilihat dari sisi penjual ('menunggu' tampil sebagai "Baru").
SellerOrderStatus sellerStatusFromValue(Object? value) {
  switch (value) {
    case OrderStatusValue.diproses:
      return SellerOrderStatus.diproses;
    case OrderStatusValue.siap:
      return SellerOrderStatus.siap;
    case OrderStatusValue.selesai:
      return SellerOrderStatus.selesai;
    case OrderStatusValue.dibatalkan:
      return SellerOrderStatus.dibatalkan;
    case OrderStatusValue.tidakDiambil:
      return SellerOrderStatus.tidakDiambil;
    default:
      return SellerOrderStatus.baru;
  }
}

String sellerStatusToValue(SellerOrderStatus status) {
  switch (status) {
    case SellerOrderStatus.baru:
      return OrderStatusValue.menunggu;
    case SellerOrderStatus.diproses:
      return OrderStatusValue.diproses;
    case SellerOrderStatus.siap:
      return OrderStatusValue.siap;
    case SellerOrderStatus.selesai:
      return OrderStatusValue.selesai;
    case SellerOrderStatus.dibatalkan:
      return OrderStatusValue.dibatalkan;
    case SellerOrderStatus.tidakDiambil:
      return OrderStatusValue.tidakDiambil;
  }
}
