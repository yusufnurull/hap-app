// Model data item menu.

import '../core/constants/app_enums.dart';

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
  });

  final String id;
  final String name;
  final String standId;
  final String standName;
  final MenuCategory category;
  final int price;
  final String description;
  final String icon;
  final int stock;
  final bool isAvailable;

  /// Habis bila dimatikan penjual atau stok nol.
  bool get isOutOfStock => !isAvailable || stock <= 0;

  MenuModel copyWith({
    String? name,
    String? standName,
    MenuCategory? category,
    int? price,
    String? description,
    String? icon,
    int? stock,
    bool? isAvailable,
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
    );
  }
}
