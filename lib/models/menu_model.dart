// Model data item menu.
//
// Dokumen Firestore: stands/{standId}/menus/{menuId}

import '../core/constants/app_enums.dart';
import '../core/constants/firestore_values.dart';

class MenuModel {
  const MenuModel({
    required this.id,
    required this.name,
    required this.standId,
    required this.standName,
    required this.category,
    required this.price,
    required this.description,
    required this.icon,
    required this.stock,
    required this.isAvailable,
    this.photoUrl = '',
  });

  final String id;
  final String name;

  /// Diambil dari dokumen induk (stand), tidak disimpan di dokumen menu.
  final String standId;
  final String standName;

  final MenuCategory category;
  final int price;
  final String description;
  final String icon;
  final int stock;
  final bool isAvailable;

  /// URL foto dari Cloudinary. Kosong = tampilkan ikon.
  final String photoUrl;

  /// Habis bila dimatikan penjual atau stok nol.
  bool get isOutOfStock => !isAvailable || stock <= 0;

  bool get hasPhoto => photoUrl.isNotEmpty;

  factory MenuModel.fromMap(
    String id,
    Map<String, dynamic> data, {
    required String standId,
    String standName = '',
  }) {
    return MenuModel(
      id: id,
      name: (data['nama'] as String?) ?? '',
      standId: standId,
      standName: standName,
      category: menuCategoryFromValue(data['kategori']),
      price: (data['harga'] as num?)?.toInt() ?? 0,
      description: (data['deskripsi'] as String?) ?? '',
      icon: (data['ikon'] as String?) ?? 'restaurant',
      stock: (data['stok'] as num?)?.toInt() ?? 0,
      isAvailable: (data['tersedia'] as bool?) ?? false,
      photoUrl: (data['fotoUrl'] as String?) ?? '',
    );
  }

  /// `updatedAt` diisi oleh service.
  Map<String, dynamic> toMap() {
    return {
      'nama': name,
      'harga': price,
      'kategori': menuCategoryToValue(category),
      'deskripsi': description,
      'stok': stock,
      'tersedia': isAvailable,
      'fotoUrl': photoUrl,
      'ikon': icon,
    };
  }

  MenuModel copyWith({
    String? name,
    String? standName,
    MenuCategory? category,
    int? price,
    String? description,
    String? icon,
    int? stock,
    bool? isAvailable,
    String? photoUrl,
  }) {
    return MenuModel(
      id: id,
      name: name ?? this.name,
      standId: standId,
      standName: standName ?? this.standName,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
