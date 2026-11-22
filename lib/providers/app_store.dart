// Penyimpanan state utama aplikasi (stand, menu, keranjang, pesanan, pengguna).
//
// Padanan handler di App.tsx pada prototipe. Semua perubahan lewat method di
// sini lalu notifyListeners(), sehingga pembeli, penjual, dan admin selalu
// melihat data yang sama.

import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/order_status.dart';
import '../core/utils/hap_logic.dart';
import '../data/mock_data.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';
import 'cart_provider.dart';

class AppStore extends ChangeNotifier {
  List<StandModel> _stands = [...mockStands];
  List<MenuModel> _menus = [...mockMenus];
  CartState _cart = initialCart;
  List<String> _checkoutWarnings = [];
  List<OrderModel> _buyerOrders = [...mockBuyerOrders];
  List<SellerOrderModel> _sellerOrders = [...mockSellerOrders];
  List<PendingSellerModel> _pendingSellers = [...mockPendingSellers];
  List<UserModel> _users = [...mockUsers];
  int _nextOrderNumber = 21;
  int _buyerTab = 0;
  UserModel? _currentUser;
  final Map<String, String> _passwords = {};

  List<StandModel> get stands => _stands;
  List<MenuModel> get menus => _menus;
  CartState get cart => _cart;
  List<String> get checkoutWarnings => _checkoutWarnings;
  List<OrderModel> get buyerOrders => _buyerOrders;
  List<SellerOrderModel> get sellerOrders => _sellerOrders;
  List<PendingSellerModel> get pendingSellers => _pendingSellers;
  List<UserModel> get users => _users;

  /// Tab aktif pada beranda pembeli (0 Beranda, 1 Pesanan, 2 Profil).
  int get buyerTab => _buyerTab;
  void setBuyerTab(int index) {
    if (_buyerTab == index) return;
    _buyerTab = index;
    notifyListeners();
  }

  UserModel? get currentUser => _currentUser;

  /// Nama pembeli yang sedang login (dipakai di pesanan dan sapaan).
  String get buyerName => _currentUser?.name ?? buyerProfile.name;

  /// Pesanan milik pembeli yang sedang login.
  List<OrderModel> get myOrders =>
      _buyerOrders.where((o) => o.buyerName == buyerName).toList();

  UserModel? _findByEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final u in _users) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  bool emailTaken(String email) => _findByEmail(email) != null;

  /// Penjual yang baru daftar dan belum disetujui admin.
  bool get isCurrentSellerPending =>
      _currentUser != null &&
      _currentUser!.role == UserRole.penjual &&
      _pendingSellers.any((p) => p.applicantName == _currentUser!.name);

  /// Mengembalikan pesan galat, atau null bila berhasil.
  /// Akun contoh (tanpa password tersimpan) menerima password apa saja.
  String? login(String email, String password) {
    final user = _findByEmail(email);
    if (user == null) {
      return 'Akun tidak ditemukan. Cek emailnya atau daftar dulu.';
    }
    if (!user.isActive) return 'Akun ini dinonaktifkan admin.';
    final saved = _passwords[user.email.toLowerCase()];
    if (saved != null && saved != password) return 'Password salah.';
    _currentUser = user;
    _cart = user.email == buyerProfile.email ? initialCart : CartState.empty;
    _checkoutWarnings = [];
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Prototipe: penjual yang login memegang stand pertama.
  StandModel get sellerStand => _stands.first;

  CartSummary get cartSummary => getCartSummary(_cart, _menus, _stands);

  int get totalOrdersToday => _stands.fold(0, (s, st) => s + st.todayOrders);
  int get completedOrdersToday =>
      18 +
      _sellerOrders.where((o) => o.status == SellerOrderStatus.selesai).length;

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
  // Keranjang
  // ---------------------------------------------------------------------------

  /// Apakah [item] boleh langsung masuk keranjang (stand sama / keranjang kosong).
  bool canAddDirectly(MenuModel item) =>
      canAddDirectlyToCart(_cart, item.standId);

  void addToCart(MenuModel item, {int qty = 1, String? note}) {
    _cart = addItemToCart(_cart, item, qtyToAdd: qty, note: note);
    notifyListeners();
  }

  /// Mengosongkan keranjang lama lalu mengisinya dengan [item] (ganti stand).
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
    // Tidak perlu notifyListeners: teks diketik di field yang punya controller
    // sendiri, dan ringkasan keranjang tidak menampilkan catatan.
  }

  void clearCart() {
    _cart = CartState.empty;
    _checkoutWarnings = [];
    notifyListeners();
  }

  /// Dipanggil saat membuka checkout: sesuaikan keranjang dengan stok terbaru.
  void refreshCartForCheckout() {
    final adjusted = adjustCartToStock(_cart, _menus);
    if (adjusted.changed) {
      _cart = adjusted.cart;
      _checkoutWarnings = adjusted.warnings;
      notifyListeners();
    }
  }

  void _syncCartWith(List<MenuModel> nextMenus) {
    final adjusted = adjustCartToStock(_cart, nextMenus);
    if (adjusted.changed) {
      _cart = adjusted.cart;
      _checkoutWarnings = adjusted.warnings;
    }
  }

  /// Membuat pesanan dari keranjang. Mengembalikan null bila keranjang kosong
  /// atau stok berubah (peringatan tampil di checkout).
  OrderModel? placeOrder(String pickupTime) {
    final adjusted = adjustCartToStock(_cart, _menus);
    if (adjusted.changed) {
      _cart = adjusted.cart;
      _checkoutWarnings = adjusted.warnings;
      notifyListeners();
      return null;
    }

    final summary = cartSummary;
    final standId = summary.standId;
    if (summary.totalItems == 0 || standId == null) return null;

    final orderCode = 'A-0$_nextOrderNumber';
    final buyerOrder = createOrderFromCart(
      orderCode: orderCode,
      buyerName: buyerName,
      standId: standId,
      standName: summary.standName,
      pickupTime: pickupTime,
      lines: summary.lines,
      note: '',
      nowTime: '11.55',
    );
    final sellerOrder = SellerOrderModel(
      id: 'sel-0$_nextOrderNumber',
      orderCode: orderCode,
      buyerName: buyerName,
      pickupTime: pickupTime,
      createdAt: '11.55',
      status: SellerOrderStatus.baru,
      items: buyerOrder.items,
    );

    _nextOrderNumber++;
    _menus = applyStockDelta(_menus, summary.lines, deduct: true);
    _buyerOrders = [buyerOrder, ..._buyerOrders];
    _sellerOrders = [sellerOrder, ..._sellerOrders];
    _stands = _stands
        .map((s) =>
            s.id == standId ? s.copyWith(todayOrders: s.todayOrders + 1) : s)
        .toList();
    _cart = CartState.empty;
    _checkoutWarnings = [];
    notifyListeners();
    return buyerOrder;
  }

  // ---------------------------------------------------------------------------
  // Pesanan (pembeli)
  // ---------------------------------------------------------------------------

  void _syncBuyerOrderStatus(
    String orderCode,
    OrderStatus next,
    String timeStamp, {
    String? cancelReason,
  }) {
    _buyerOrders = _buyerOrders.map((order) {
      if (order.orderCode != orderCode) return order;
      return order.copyWith(
        status: next,
        cancelReason: cancelReason,
        timeline: order.timeline
            .map((step) => step.status == next && step.time == null
                ? step.withTime(timeStamp)
                : step)
            .toList(),
      );
    }).toList();
  }

  /// Pembeli hanya boleh membatalkan pesanan yang masih "Menunggu".
  void cancelBuyerOrder(String orderId, {String? reason}) {
    final target = buyerOrderById(orderId);
    if (target == null || target.status != OrderStatus.menunggu) return;

    _syncBuyerOrderStatus(
      target.orderCode,
      OrderStatus.dibatalkan,
      '11.56',
      cancelReason: reason,
    );
    _sellerOrders = _sellerOrders
        .map((so) => so.orderCode == target.orderCode
            ? so.copyWith(
                status: SellerOrderStatus.dibatalkan,
                cancelReason: reason,
              )
            : so)
        .toList();
    _menus = applyStockDelta(_menus, target.items, deduct: false);
    notifyListeners();
  }

  /// Demo: pembeli mengonfirmasi pesanan sudah diambil.
  void confirmPickedUp(String orderId) {
    final target = buyerOrderById(orderId);
    if (target == null) return;
    _syncBuyerOrderStatus(target.orderCode, OrderStatus.selesai, '12.16');
    notifyListeners();
  }

  void submitRating(String orderId) {
    _buyerOrders = _buyerOrders
        .map((o) => o.id == orderId ? o.copyWith(ratingSubmitted: true) : o)
        .toList();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Pesanan (penjual)
  // ---------------------------------------------------------------------------

  SellerOrderModel? _sellerOrderById(String id) {
    for (final o in _sellerOrders) {
      if (o.id == id) return o;
    }
    return null;
  }

  void acceptSellerOrder(String orderId) {
    final target = _sellerOrderById(orderId);
    _sellerOrders =
        transitionSellerOrder(_sellerOrders, orderId, SellerOrderStatus.diproses);
    if (target != null) {
      _syncBuyerOrderStatus(target.orderCode, OrderStatus.diproses, '11.56');
    }
    notifyListeners();
  }

  void rejectSellerOrder(String orderId, {String? reason}) {
    final target = _sellerOrderById(orderId);
    _sellerOrders = transitionSellerOrder(
      _sellerOrders,
      orderId,
      SellerOrderStatus.dibatalkan,
      cancelReason: reason,
    );
    if (target != null) {
      _syncBuyerOrderStatus(
        target.orderCode,
        OrderStatus.dibatalkan,
        '11.56',
        cancelReason: reason,
      );
      _menus = applyStockDelta(_menus, target.items, deduct: false);
    }
    notifyListeners();
  }

  void markReadySellerOrder(String orderId) {
    final target = _sellerOrderById(orderId);
    _sellerOrders =
        transitionSellerOrder(_sellerOrders, orderId, SellerOrderStatus.siap);
    if (target != null) {
      _syncBuyerOrderStatus(target.orderCode, OrderStatus.siapDiambil, '12.02');
    }
    notifyListeners();
  }

  void completeSellerOrder(String orderId) {
    final target = _sellerOrderById(orderId);
    _sellerOrders =
        transitionSellerOrder(_sellerOrders, orderId, SellerOrderStatus.selesai);
    if (target != null) {
      _syncBuyerOrderStatus(target.orderCode, OrderStatus.selesai, '12.16');
    }
    notifyListeners();
  }

  /// Pembeli tidak datang. Stok sengaja TIDAK dikembalikan (makanan sudah dibuat).
  void markNoShowSellerOrder(String orderId) {
    final target = _sellerOrderById(orderId);
    _sellerOrders = transitionSellerOrder(
      _sellerOrders,
      orderId,
      SellerOrderStatus.tidakDiambil,
    );
    if (target != null) {
      _syncBuyerOrderStatus(target.orderCode, OrderStatus.tidakDiambil, '12.25');
      _users = _users
          .map((u) => u.role == UserRole.pembeli &&
                  u.name.toLowerCase() == target.buyerName.toLowerCase()
              ? u.copyWith(noShowCount: u.noShowCount + 1)
              : u)
          .toList();
    }
    notifyListeners();
  }

  void resetDemoSellerOrders() {
    _sellerOrders = [...mockSellerOrders];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Menu & stand (penjual)
  // ---------------------------------------------------------------------------

  void toggleMenuAvailability(String menuId) {
    final next = _menus.map((item) {
      if (item.id != menuId) return item;
      if (!item.isOutOfStock) return item.copyWith(isAvailable: false);
      return item.copyWith(
        isAvailable: true,
        stock: item.stock == 0 ? 1 : item.stock,
      );
    }).toList();
    _menus = next;
    _syncCartWith(next);
    notifyListeners();
  }

  void adjustStock(String menuId, int nextStock) {
    final next = setMenuStock(_menus, menuId, nextStock);
    _menus = next;
    _syncCartWith(next);
    notifyListeners();
  }

  void bulkUpdateStocks(Map<String, int> updates) {
    var next = _menus;
    updates.forEach((menuId, stock) {
      next = setMenuStock(next, menuId, stock);
    });
    _menus = next;
    _syncCartWith(next);
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
      final next = _menus
          .map((item) => item.id == id
              ? item.copyWith(
                  name: name,
                  price: price,
                  stock: stock,
                  isAvailable: stock > 0 ? item.isAvailable : false,
                  category: category,
                  description: description,
                  icon: icon,
                )
              : item)
          .toList();
      _menus = next;
      _syncCartWith(next);
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

  // ---------------------------------------------------------------------------
  // Pendaftaran & admin
  // ---------------------------------------------------------------------------

  UserModel registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? standName,
  }) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final user = UserModel(
      id: 'usr-$stamp',
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
    _users = [user, ..._users];
    _passwords[email.toLowerCase()] = password;
    _currentUser = user;
    _cart = CartState.empty;
    if (role == UserRole.penjual) {
      _pendingSellers = [
        PendingSellerModel(
          id: 'pend-$stamp',
          applicantName: name,
          standName: standName ?? 'Stand Baru',
          appliedDate: '13 Nov 2026',
          foodTypes: 'Menu kantin harian',
        ),
        ..._pendingSellers,
      ];
    }
    notifyListeners();
    return user;
  }

  void approveSeller(String pendingId) {
    PendingSellerModel? target;
    for (final p in _pendingSellers) {
      if (p.id == pendingId) target = p;
    }
    _pendingSellers = _pendingSellers.where((p) => p.id != pendingId).toList();
    if (target != null) {
      _stands = [
        ..._stands,
        StandModel(
          id: 'stand-${DateTime.now().millisecondsSinceEpoch}',
          name: target.standName,
          isOpen: true,
          foodTypes: target.foodTypes,
          openHours: '07.30–15.30',
          locationNote: 'Kios ${_stands.length + 1}',
          categories: const [StandCategory.makananBerat],
          icon: 'storefront',
        ),
      ];
    }
    notifyListeners();
  }

  void rejectSeller(String pendingId) {
    _pendingSellers = _pendingSellers.where((p) => p.id != pendingId).toList();
    notifyListeners();
  }

  void adminSaveStand({
    String? id,
    required String name,
    required String foodTypes,
    required String openHours,
    required String locationNote,
    required bool isOpen,
    required List<StandCategory> categories,
  }) {
    if (id != null) {
      _stands = _stands
          .map((s) => s.id == id
              ? s.copyWith(
                  name: name,
                  foodTypes: foodTypes,
                  openHours: openHours,
                  locationNote: locationNote,
                  isOpen: isOpen,
                )
              : s)
          .toList();
    } else {
      _stands = [
        ..._stands,
        StandModel(
          id: 'stand-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          isOpen: isOpen,
          foodTypes: foodTypes,
          openHours: openHours,
          locationNote: locationNote,
          categories: categories,
          icon: 'storefront',
        ),
      ];
    }
    notifyListeners();
  }

  void toggleUserActive(String userId) {
    _users = _users
        .map((u) => u.id == userId ? u.copyWith(isActive: !u.isActive) : u)
        .toList();
    notifyListeners();
  }
}
