import 'package:flutter/material.dart';

/// Ikon stand dan menu disimpan sebagai nama (String) agar mudah dikirim ke
/// Firestore. Fungsi ini memetakan nama itu ke [IconData].
const List<String> foodIconOptions = [
  'lunch_dining',
  'dinner_dining',
  'rice_bowl',
  'ramen_dining',
  'tapas',
  'local_cafe',
];

IconData iconFor(String name) {
  switch (name) {
    case 'lunch_dining':
      return Icons.lunch_dining_rounded;
    case 'dinner_dining':
      return Icons.dinner_dining_rounded;
    case 'rice_bowl':
      return Icons.rice_bowl_rounded;
    case 'ramen_dining':
      return Icons.ramen_dining_rounded;
    case 'tapas':
      return Icons.tapas_rounded;
    case 'local_cafe':
      return Icons.local_cafe_rounded;
    case 'local_bar':
      return Icons.local_bar_rounded;
    case 'coffee':
      return Icons.coffee_rounded;
    case 'skillet':
      return Icons.restaurant_rounded;
    case 'bakery_dining':
      return Icons.bakery_dining_rounded;
    case 'soup_kitchen':
      return Icons.soup_kitchen_rounded;
    case 'storefront':
    default:
      return Icons.storefront_rounded;
  }
}
