// Model data stand atau kantin penjual.
//
// Dokumen Firestore: stands/{standId}

import '../core/constants/app_enums.dart';
import '../core/constants/firestore_values.dart';

class StandModel {
  const StandModel({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.foodTypes,
    required this.openHours,
    required this.locationNote,
    required this.categories,
    required this.icon,
    this.todayOrders = 0,
    this.ownerId = '',
  });

  final String id;
  final String name;
  final bool isOpen;
  final String foodTypes;

  /// Gabungan jamBuka dan jamTutup, mis. "07.00–15.00".
  final String openHours;
  final String locationNote;
  final List<StandCategory> categories;
  final String icon;

  /// Tidak disimpan di Firestore; dihitung dari koleksi orders.
  final int todayOrders;

  /// uid penjual pemilik stand (field `pemilikId`).
  final String ownerId;

  /// Jam buka, mis. "07.00".
  String get openTime => _splitHours(openHours).$1;

  /// Jam tutup, mis. "15.00".
  String get closeTime => _splitHours(openHours).$2;

  factory StandModel.fromMap(String id, Map<String, dynamic> data) {
    final jamBuka = (data['jamBuka'] as String?) ?? '';
    final jamTutup = (data['jamTutup'] as String?) ?? '';
    final kategori = (data['kategori'] as List<dynamic>?) ?? const [];
    return StandModel(
      id: id,
      name: (data['namaStand'] as String?) ?? '',
      isOpen: (data['isOpen'] as bool?) ?? false,
      foodTypes: (data['deskripsi'] as String?) ?? '',
      openHours: jamBuka.isEmpty && jamTutup.isEmpty
          ? ''
          : '$jamBuka–$jamTutup',
      locationNote: (data['lokasi'] as String?) ?? '',
      categories: kategori
          .map(standCategoryFromValue)
          .whereType<StandCategory>()
          .toList(),
      icon: (data['ikon'] as String?) ?? 'storefront',
      ownerId: (data['pemilikId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaStand': name,
      'pemilikId': ownerId,
      'deskripsi': foodTypes,
      'jamBuka': openTime,
      'jamTutup': closeTime,
      'lokasi': locationNote,
      'kategori': categories.map(standCategoryToValue).toList(),
      'ikon': icon,
      'isOpen': isOpen,
    };
  }

  StandModel copyWith({
    String? name,
    bool? isOpen,
    String? foodTypes,
    String? openHours,
    String? locationNote,
    List<StandCategory>? categories,
    int? todayOrders,
    String? ownerId,
  }) {
    return StandModel(
      id: id,
      name: name ?? this.name,
      isOpen: isOpen ?? this.isOpen,
      foodTypes: foodTypes ?? this.foodTypes,
      openHours: openHours ?? this.openHours,
      locationNote: locationNote ?? this.locationNote,
      categories: categories ?? this.categories,
      icon: icon,
      todayOrders: todayOrders ?? this.todayOrders,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}

/// Memecah "07.00–15.00" (atau "07.00-15.00") menjadi ("07.00", "15.00").
(String, String) _splitHours(String hours) {
  final parts = hours.split(RegExp(r'\s*[–-]\s*'));
  if (parts.length < 2) return (hours.trim(), '');
  return (parts[0].trim(), parts[1].trim());
}
