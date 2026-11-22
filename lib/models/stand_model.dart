// Model data stand atau kantin penjual.

import '../core/constants/app_enums.dart';

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
  });

  final String id;
  final String name;
  final bool isOpen;
  final String foodTypes;
  final String openHours;
  final String locationNote;
  final List<StandCategory> categories;
  final String icon;
  final int todayOrders;

  StandModel copyWith({
    String? name,
    bool? isOpen,
    String? foodTypes,
    String? openHours,
    String? locationNote,
    List<StandCategory>? categories,
    int? todayOrders,
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
    );
  }
}
