// State sementara (di memori) supaya layar bisa dijalankan dan dipindah-pindah.
//
// Ini kerangka, bukan logika final. Titik sambung untuk tim:
// - Rafli  : login/daftar, CRUD menu & stok, status pesanan -> Firestore
// - Herlina: validasi stok & keranjang saat checkout (lihat checkoutWarnings)
// Tiap method cukup diganti isinya; layar tidak perlu diubah.

import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/order_status.dart';
import '../core/utils/hap_logic.dart';
import '../data/mock_data.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

class AppStore extends ChangeNotifier {
  List<StandModel> _stands = [...mockStands];
  List<MenuModel> _menus = [...mockMenus];
  CartState _cart = initialCart;
  List<OrderModel> _buyerOrders = [...mockBuyerOrders];
  List<SellerOrderModel> _sellerOrders = [...mockSellerOrders];
  UserModel? _currentUser;
  bool _sellerPending = false;
  int _nextOrderNumber = 21;
  int _buyerTab = 0;

  List<StandModel> get stands => _stands;
  List<MenuModel> get menus => _menus;
  CartState get cart => _cart;
  List<OrderModel> get buyerOrders => _buyerOrders;
  List<SellerOrderModel> get sellerOrders => _sellerOrders;
  UserModel? get currentUser => _currentUser;

  /// Titik sambung (Herlina): isi dengan peringatan stok saat checkout.
  List<String> get checkoutWarnings => const [];
  void refreshCartForCheckout() {}

  int get buyerTab => _buyerTab;
  void setBuyerTab(int index) {
    if (_buyerTab == index) return;
    _buyerTab = index;
    notifyListeners();
  }

  String get buyerName => _currentUser?.name ?? buyerProfile.name;
  List<OrderModel> get myOrders =>
      _buyerOrders.where((o) => o.buyerName == buyerName).toList();

  /// Prototipe: penjual yang login memegang stand pertama.
  StandModel get sellerStand => _stands.first;

  CartSummary get cartSummary => getCartSummary(_cart, _menus, _stands);

  StandModel? standById(String id) {
    for (final s in _stands) {
      if (s.id == id) return s;
    }
    return null;
  }

  MenuModel? menuById(String id) {
    for (final m in _menus) {
      if (m.id == id) return m;
    }
    return null;
  }

  OrderModel? buyerOrderById(String id) {
    for (final o in _buyerOrders) {
      if (o.id == id) return o;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Akun (sementara: peran ditebak dari email, tanpa cek password)
  // ---------------------------------------------------------------------------

  bool get isCurrentSellerPending =>
      _sellerPending && _currentUser?.role == UserRole.penjual;

  /// Mengembalikan pesan galat, atau null bila berhasil.
  String? login(String email, String password) {
    final e = email.trim();
    final role = AuthProvider.roleForEmail(e);
    final local = e.split('@').first;
    final name = local.isEmpty
        ? 'Pengguna'
        : local[0].toUpperCase() + local.substring(1);
    _currentUser = UserModel(
      id: 'usr-demo',
      name: name,
      email: e,
      phone: buyerProfile.phone,
      role: role,
    );
    _sellerPending = false;
    _cart = e == buyerProfile.email ? initialCart : CartState.empty;
    notifyListeners();
    return null;
  }

  UserModel registerUser({
    required String name,
    required String email,
    required String phone,
    required String password, // dipakai saat Firebase Auth terpasang
    required UserRole role,
    String? standName,
  }) {
    final user = UserModel(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
    _currentUser = user;
    _sellerPending = role == UserRole.penjual;
    _cart = CartState.empty;
    notifyListeners();
    return user;
  }

  void logout() {
    _currentUser = null;
    _sellerPending = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Keranjang & pesanan pembeli
  // ---------------------------------------------------------------------------

  bool canAddDirectly(MenuModel item) =>
      canAddDirectlyToCart(_cart, item.standId);

  void addToCart(MenuModel item, {int qty = 1, String? note}) {
    _cart = addItemToCart(_cart, item, qtyToAdd: qty, note: note);
    notifyListeners();
  }

  void replaceCart(MenuModel item, {int qty = 1, String? note}) {
    _cart = replaceCartWithItem(item, qtyToAdd: qty, note: note);
    notifyListeners();
  }

  void removeFromCart(MenuModel item) {
    _cart = removeItemFromCart(_cart, item.id);
    notifyListeners();
  }

  void updateCartNote(String itemId, String note) {
    _cart = updateCartItemNote(_cart, itemId, note);
  }

  void clearCart() {
    _cart = CartState.empty;
    notifyListeners();
  }

  /// Titik sambung (Rafli/Herlina): transaksi checkout sebenarnya.
  OrderModel? placeOrder(String pickupTime) {
    final summary = cartSummary;
    final standId = summary.standId;
    if (summary.totalItems == 0 || standId == null) return null;

    final orderCode = 'A-0$_nextOrderNumber';
    final order = createOrderFromCart(
      orderCode: orderCode,
      buyerName: buyerName,
      standId: standId,
      standName: summary.standName,
      pickupTime: pickupTime,
      lines: summary.lines,
      note: '',
      nowTime: '11.55',
    );
    _sellerOrders = [
      SellerOrderModel(
        id: 'sel-0$_nextOrderNumber',
        orderCode: orderCode,
        buyerName: buyerName,
        pickupTime: pickupTime,
        createdAt: '11.55',
        status: SellerOrderStatus.baru,
        items: order.items,
      ),
      ..._sellerOrders,
    ];
    _buyerOrders = [order, ..._buyerOrders];
    _nextOrderNumber++;
    _cart = CartState.empty;
    notifyListeners();
    return order;
  }

  void _setBuyerStatus(String orderCode, OrderStatus next, String time,
      {String? reason}) {
    _buyerOrders = _buyerOrders.map((o) {
      if (o.orderCode != orderCode) return o;
      return o.copyWith(
        status: next,
        cancelReason: reason,
        timeline: o.timeline
            .map((s) => s.status == next && s.time == null ? s.withTime(time) : s)
            .toList(),
      );
    }).toList();
  }

  void _setSellerStatus(String id, SellerOrderStatus next, {String? reason}) {
    _sellerOrders = _sellerOrders
        .map((o) =>
            o.id == id ? o.copyWith(status: next, cancelReason: reason) : o)
        .toList();
  }

  SellerOrderModel? _sellerOrder(String id) {
    for (final o in _sellerOrders) {
      if (o.id == id) return o;
    }
    return null;
  }

  void cancelBuyerOrder(String orderId, {String? reason}) {
    final t = buyerOrderById(orderId);
    if (t == null || t.status != OrderStatus.menunggu) return;
    _setBuyerStatus(t.orderCode, OrderStatus.dibatalkan, '11.56', reason: reason);
    for (final so in _sellerOrders) {
      if (so.orderCode == t.orderCode) {
        _setSellerStatus(so.id, SellerOrderStatus.dibatalkan, reason: reason);
      }
    }
    notifyListeners();
  }

  void confirmPickedUp(String orderId) {
    final t = buyerOrderById(orderId);
    if (t == null) return;
    _setBuyerStatus(t.orderCode, OrderStatus.selesai, '12.16');
    notifyListeners();
  }

  void submitRating(String orderId) {
    _buyerOrders = _buyerOrders
        .map((o) => o.id == orderId ? o.copyWith(ratingSubmitted: true) : o)
        .toList();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Pesanan masuk (penjual)
  // ---------------------------------------------------------------------------

  void acceptSellerOrder(String id) =>
      _sellerStep(id, SellerOrderStatus.diproses, OrderStatus.diproses, '11.56');

  void markReadySellerOrder(String id) =>
      _sellerStep(id, SellerOrderStatus.siap, OrderStatus.siapDiambil, '12.02');

  void completeSellerOrder(String id) =>
      _sellerStep(id, SellerOrderStatus.selesai, OrderStatus.selesai, '12.16');

  void markNoShowSellerOrder(String id) => _sellerStep(
      id, SellerOrderStatus.tidakDiambil, OrderStatus.tidakDiambil, '12.25');

  void rejectSellerOrder(String id, {String? reason}) => _sellerStep(
      id, SellerOrderStatus.dibatalkan, OrderStatus.dibatalkan, '11.56',
      reason: reason);

  void _sellerStep(String id, SellerOrderStatus next, OrderStatus buyerNext,
      String time, {String? reason}) {
    final t = _sellerOrder(id);
    _setSellerStatus(id, next, reason: reason);
    if (t != null) _setBuyerStatus(t.orderCode, buyerNext, time, reason: reason);
    notifyListeners();
  }

  void resetDemoSellerOrders() {
    _sellerOrders = [...mockSellerOrders];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Menu & stand (penjual) -- titik sambung Rafli (CRUD menu & stok)
  // ---------------------------------------------------------------------------

  void _mapMenu(String id, MenuModel Function(MenuModel) f) {
    _menus = _menus.map((m) => m.id == id ? f(m) : m).toList();
  }

  void toggleMenuAvailability(String menuId) {
    _mapMenu(menuId, (m) => m.isOutOfStock
        ? m.copyWith(isAvailable: true, stock: m.stock == 0 ? 1 : m.stock)
        : m.copyWith(isAvailable: false));
    notifyListeners();
  }

  void adjustStock(String menuId, int nextStock) {
    final s = nextStock < 0 ? 0 : nextStock;
    _mapMenu(menuId, (m) => m.copyWith(stock: s, isAvailable: s > 0));
    notifyListeners();
  }

  void bulkUpdateStocks(Map<String, int> updates) {
    updates.forEach((id, stock) {
      final s = stock < 0 ? 0 : stock;
      _mapMenu(id, (m) => m.copyWith(stock: s, isAvailable: s > 0));
    });
    notifyListeners();
  }

  void saveSellerMenu({
    String? id,
    required String name,
    required int price,
    required int stock,
    required MenuCategory category,
    required String description,
    required String icon,
  }) {
    if (id != null) {
      _mapMenu(
        id,
        (m) => m.copyWith(
          name: name,
          price: price,
          stock: stock,
          isAvailable: stock > 0 ? m.isAvailable : false,
          category: category,
          description: description,
          icon: icon,
        ),
      );
    } else {
      final stand = sellerStand;
      _menus = [
        MenuModel(
          id: 'menu-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          standId: stand.id,
          standName: stand.name,
          category: category,
          price: price,
          description: description,
          icon: icon,
          stock: stock,
          isAvailable: stock > 0,
        ),
        ..._menus,
      ];
    }
    notifyListeners();
  }

  void toggleStandOpen(String standId) {
    _stands = _stands
        .map((s) => s.id == standId ? s.copyWith(isOpen: !s.isOpen) : s)
        .toList();
    notifyListeners();
  }

  void updateStandInfo(
    String standId, {
    required String name,
    required String foodTypes,
    required String openHours,
  }) {
    _stands = _stands
        .map((s) => s.id == standId
            ? s.copyWith(name: name, foodTypes: foodTypes, openHours: openHours)
            : s)
        .toList();
    _menus = _menus
        .map((m) => m.standId == standId ? m.copyWith(standName: name) : m)
        .toList();
    notifyListeners();
  }
}
