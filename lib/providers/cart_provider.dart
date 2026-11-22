// State keranjang belanja pembeli.
//
// Fungsi-fungsi di sini murni (tidak mengubah objek lama) supaya mudah diuji.
// Penyimpanan state-nya ada di AppStore (app_store.dart).

import 'dart:math' as math;

import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';

/// Keranjang hanya boleh berisi menu dari satu stand.
class CartState {
  const CartState({
    this.standId,
    this.items = const {},
    this.notes = const {},
  });

  static const CartState empty = CartState();

  final String? standId;

  /// menuId -> jumlah
  final Map<String, int> items;

  /// menuId -> catatan untuk penjual
  final Map<String, String> notes;

  bool get hasItems => items.values.any((qty) => qty > 0);
}

class CartSummary {
  const CartSummary({
    required this.standId,
    required this.standName,
    required this.totalItems,
    required this.totalPrice,
    required this.lines,
  });

  final String? standId;
  final String standName;
  final int totalItems;
  final int totalPrice;
  final List<OrderLineItem> lines;
}

class CartAdjustment {
  const CartAdjustment({
    required this.cart,
    required this.warnings,
    required this.changed,
  });

  final CartState cart;
  final List<String> warnings;
  final bool changed;
}

int _sum(Iterable<int> values) => values.fold(0, (s, q) => s + q);

bool canAddDirectlyToCart(CartState cart, String itemStandId) {
  if (!cart.hasItems || cart.standId == null) return true;
  return cart.standId == itemStandId;
}

CartState addItemToCart(
  CartState cart,
  MenuModel item, {
  int qtyToAdd = 1,
  String? note,
}) {
  if (item.isOutOfStock) return cart;
  final current = cart.items[item.id] ?? 0;
  final capped = math.min(item.stock, current + qtyToAdd);
  if (capped <= 0) return cart;

  final nextNotes = {...cart.notes};
  if (note != null && note.trim().isNotEmpty) {
    nextNotes[item.id] = note.trim();
  }
  return CartState(
    standId: item.standId,
    items: {...cart.items, item.id: capped},
    notes: nextNotes,
  );
}

CartState replaceCartWithItem(
  MenuModel item, {
  int qtyToAdd = 1,
  String? note,
}) {
  if (item.isOutOfStock) return CartState.empty;
  final capped = math.min(item.stock, math.max(1, qtyToAdd));
  final notes = <String, String>{};
  if (note != null && note.trim().isNotEmpty) {
    notes[item.id] = note.trim();
  }
  return CartState(
    standId: item.standId,
    items: {item.id: capped},
    notes: notes,
  );
}

CartState removeItemFromCart(CartState cart, String itemId) {
  final current = cart.items[itemId] ?? 0;
  final nextItems = {...cart.items};
  final nextNotes = {...cart.notes};
  if (current <= 1) {
    nextItems.remove(itemId);
    nextNotes.remove(itemId);
  } else {
    nextItems[itemId] = current - 1;
  }
  return CartState(
    standId: _sum(nextItems.values) > 0 ? cart.standId : null,
    items: nextItems,
    notes: nextNotes,
  );
}

CartState updateCartItemNote(CartState cart, String itemId, String note) {
  return CartState(
    standId: cart.standId,
    items: cart.items,
    notes: {...cart.notes, itemId: note},
  );
}

CartSummary getCartSummary(
  CartState cart,
  List<MenuModel> menuItems,
  List<StandModel> stands,
) {
  final itemMap = {for (final m in menuItems) m.id: m};
  var totalItems = 0;
  var totalPrice = 0;
  final lines = <OrderLineItem>[];

  cart.items.forEach((menuId, qty) {
    if (qty <= 0) return;
    final menu = itemMap[menuId];
    if (menu == null) return;
    totalItems += qty;
    totalPrice += menu.price * qty;
    final note = cart.notes[menu.id]?.trim();
    lines.add(OrderLineItem(
      menuId: menu.id,
      name: menu.name,
      quantity: qty,
      price: menu.price,
      note: (note == null || note.isEmpty) ? null : note,
    ));
  });

  var standName = '';
  if (cart.standId != null) {
    for (final s in stands) {
      if (s.id == cart.standId) standName = s.name;
    }
  }

  return CartSummary(
    standId: totalItems > 0 ? cart.standId : null,
    standName: standName,
    totalItems: totalItems,
    totalPrice: totalPrice,
    lines: lines,
  );
}

/// Menyesuaikan keranjang dengan stok terbaru. Menu yang habis dibuang dan
/// jumlah yang melebihi stok dipotong; hasilnya disertai pesan peringatan.
CartAdjustment adjustCartToStock(CartState cart, List<MenuModel> menuItems) {
  final itemMap = {for (final m in menuItems) m.id: m};
  final nextItems = <String, int>{};
  final nextNotes = <String, String>{};
  final warnings = <String>[];
  var changed = false;

  cart.items.forEach((menuId, qty) {
    if (qty <= 0) return;
    final menu = itemMap[menuId];
    if (menu == null || menu.isOutOfStock) {
      changed = true;
      warnings.add(
        'Stok ${menu?.name ?? 'menu'} sudah habis. Menu dihapus dari keranjang.',
      );
      return;
    }
    if (qty > menu.stock) {
      changed = true;
      nextItems[menuId] = menu.stock;
      warnings.add(
        'Stok ${menu.name} tinggal ${menu.stock}. Jumlah pesananmu sudah disesuaikan.',
      );
    } else {
      nextItems[menuId] = qty;
    }
    final note = cart.notes[menuId];
    if (note != null && note.isNotEmpty) nextNotes[menuId] = note;
  });

  return CartAdjustment(
    cart: CartState(
      standId: _sum(nextItems.values) > 0 ? cart.standId : null,
      items: nextItems,
      notes: nextNotes,
    ),
    warnings: warnings,
    changed: changed,
  );
}
