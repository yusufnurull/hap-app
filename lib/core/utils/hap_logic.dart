// Aturan bisnis Hap! yang murni (tanpa UI): filter, stok, status pesanan.

import '../../core/constants/app_enums.dart';
import '../../core/constants/order_status.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../models/stand_model.dart';
import '../../models/user_model.dart';

/// Urutan stabil: elemen yang lolos [test] dulu, sisanya menyusul, urutan
/// aslinya dipertahankan.
List<T> _passingFirst<T>(List<T> items, bool Function(T) test) => [
      ...items.where(test),
      ...items.where((e) => !test(e)),
    ];

class StandFilterResult {
  const StandFilterResult(this.open, this.closed);
  final List<StandModel> open;
  final List<StandModel> closed;
}

StandFilterResult filterStands(
  List<StandModel> stands, {
  required String searchQuery,
  StandCategory? category,
}) {
  final query = searchQuery.trim().toLowerCase();
  final matching = stands.where((s) {
    if (category != null && !s.categories.contains(category)) return false;
    if (query.isNotEmpty) {
      final inName = s.name.toLowerCase().contains(query);
      final inFoods = s.foodTypes.toLowerCase().contains(query);
      if (!inName && !inFoods) return false;
    }
    return true;
  }).toList();

  return StandFilterResult(
    matching.where((s) => s.isOpen).toList(),
    matching.where((s) => !s.isOpen).toList(),
  );
}

bool isMenuOrderable(MenuModel item, bool standOpen) =>
    standOpen && !item.isOutOfStock;

List<MenuModel> searchMenus(
  List<MenuModel> items,
  List<StandModel> stands,
  String searchQuery,
) {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) return [];
  final standOpen = {for (final s in stands) s.id: s.isOpen};

  final matching = items
      .where((i) =>
          i.name.toLowerCase().contains(query) ||
          i.standName.toLowerCase().contains(query))
      .toList();
  return _passingFirst(
    matching,
    (i) => isMenuOrderable(i, standOpen[i.standId] ?? false),
  );
}

List<MenuModel> filterMenusForStand(
  List<MenuModel> items,
  String standId,
  MenuCategory? category,
) {
  final matching = items
      .where((i) =>
          i.standId == standId && (category == null || i.category == category))
      .toList();
  return _passingFirst(matching, (i) => !i.isOutOfStock);
}

List<SellerOrderModel> sortOrdersByPickupTime(List<SellerOrderModel> orders) {
  final indexed = orders.asMap().entries.toList()
    ..sort((a, b) {
      final byTime = a.value.pickupTime.compareTo(b.value.pickupTime);
      return byTime != 0 ? byTime : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList();
}

({int baru, int diproses, int siap}) getOrderCounts(
  List<SellerOrderModel> orders,
) {
  var baru = 0, diproses = 0, siap = 0;
  for (final o in orders) {
    switch (o.status) {
      case SellerOrderStatus.baru:
        baru++;
      case SellerOrderStatus.diproses:
        diproses++;
      case SellerOrderStatus.siap:
        siap++;
      default:
        break;
    }
  }
  return (baru: baru, diproses: diproses, siap: siap);
}

List<MenuModel> setMenuStock(
  List<MenuModel> menuItems,
  String menuId,
  int nextStock,
) {
  final clamped = nextStock < 0 ? 0 : nextStock;
  return menuItems.map((item) {
    if (item.id != menuId) return item;
    final isAvailable = clamped == 0
        ? false
        : (item.stock == 0 ? true : item.isAvailable);
    return item.copyWith(stock: clamped, isAvailable: isAvailable);
  }).toList();
}

/// Mengurangi ([deduct] = true) atau mengembalikan stok sesuai isi pesanan.
List<MenuModel> applyStockDelta(
  List<MenuModel> menuItems,
  List<OrderLineItem> orderLines, {
  required bool deduct,
}) {
  final delta = <String, int>{};
  for (final line in orderLines) {
    delta[line.menuId] = (delta[line.menuId] ?? 0) + line.quantity;
  }
  return menuItems.map((item) {
    final qty = delta[item.id];
    if (qty == null || qty == 0) return item;
    if (deduct) {
      final next = item.stock - qty < 0 ? 0 : item.stock - qty;
      return item.copyWith(
        stock: next,
        isAvailable: next == 0 ? false : item.isAvailable,
      );
    }
    final next = item.stock + qty;
    return item.copyWith(
      stock: next,
      isAvailable: next > 0 ? true : item.isAvailable,
    );
  }).toList();
}

int? _parseTimeToMinutes(String time) {
  final match = RegExp(r'^(\d{1,2})[.:](\d{2})$').firstMatch(time.trim());
  if (match == null) return null;
  return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

/// Pesanan "Siap" yang belum diambil >= 30 menit setelah jam ambil.
bool isPickupOverdue(
  String pickupTime, {
  String nowTime = '11.55',
  bool overdueFlag = false,
}) {
  if (overdueFlag) return true;
  final pickup = _parseTimeToMinutes(pickupTime);
  final now = _parseTimeToMinutes(nowTime);
  if (pickup == null || now == null) return false;
  return now - pickup >= 30;
}

List<SellerOrderModel> transitionSellerOrder(
  List<SellerOrderModel> orders,
  String orderId,
  SellerOrderStatus nextStatus, {
  String? cancelReason,
}) {
  return orders
      .map((o) => o.id == orderId
          ? o.copyWith(status: nextStatus, cancelReason: cancelReason)
          : o)
      .toList();
}

int calculateOrderTotal(List<OrderLineItem> items) =>
    items.fold(0, (sum, i) => sum + i.subtotal);

({List<OrderModel> active, List<OrderModel> history}) splitBuyerOrders(
  List<OrderModel> orders,
) {
  return (
    active: orders.where((o) => o.status.isActive).toList(),
    history: orders.where((o) => !o.status.isActive).toList(),
  );
}

List<UserModel> filterUsersByRole(List<UserModel> users, UserRole? role) =>
    role == null ? users : users.where((u) => u.role == role).toList();

OrderModel createOrderFromCart({
  required String orderCode,
  required String buyerName,
  required String standId,
  required String standName,
  required String pickupTime,
  required List<OrderLineItem> lines,
  required String note,
  required String nowTime,
}) {
  final trimmedNote = note.trim();
  final itemsWithNote = <OrderLineItem>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.note == null && i == 0 && trimmedNote.isNotEmpty) {
      itemsWithNote.add(line.withNote(trimmedNote));
    } else {
      itemsWithNote.add(line);
    }
  }

  return OrderModel(
    id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
    orderCode: orderCode,
    buyerName: buyerName,
    standId: standId,
    standName: standName,
    pickupTime: pickupTime,
    status: OrderStatus.menunggu,
    paymentMethod: 'Bayar di tempat',
    items: itemsWithNote,
    timeline: [
      OrderTimelineStep(
        status: OrderStatus.menunggu,
        label: 'Pesanan masuk',
        description: 'Menunggu konfirmasi $standName',
        time: nowTime,
      ),
      OrderTimelineStep(
        status: OrderStatus.diproses,
        label: 'Pesananmu lagi disiapkan',
        description: '$standName sedang menyiapkan pesanan',
      ),
      OrderTimelineStep(
        status: OrderStatus.siapDiambil,
        label: 'Siap! Ambil di $standName',
        description: 'Tunjukkan tiket $orderCode saat mengambil',
      ),
      const OrderTimelineStep(
        status: OrderStatus.selesai,
        label: 'Pesanan selesai',
        description: 'Sudah diambil dan dibayar di tempat',
      ),
    ],
  );
}
