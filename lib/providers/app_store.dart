import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/order_status.dart';
import '../data/mock_data.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

class AppStore extends ChangeNotifier {
  AppStore({OrderService? orderService})
    : _orderService = orderService ?? OrderService();

  final OrderService _orderService;

  List<StandModel> _stands = [...mockStands];
  List<MenuModel> _menus = [...mockMenus];
  CartState _cart = initialCart;
  List<OrderModel> _buyerOrders = [...mockBuyerOrders];
  List<SellerOrderModel> _sellerOrders = [...mockSellerOrders];

  UserModel? _currentUser;
  bool _sellerPending = false;
  int _buyerTab = 0;
  bool _isPlacingOrder = false;

  List<StandModel> get stands => _stands;
  List<MenuModel> get menus => _menus;
  CartState get cart => _cart;
  List<OrderModel> get buyerOrders => _buyerOrders;
  List<SellerOrderModel> get sellerOrders => _sellerOrders;
  UserModel? get currentUser => _currentUser;
  bool get isPlacingOrder => _isPlacingOrder;

  // ---------------------------------------------------------------------------
  // Validasi checkout
  // ---------------------------------------------------------------------------

  List<String> get checkoutWarnings {
    final warnings = <String>[];
    final summary = cartSummary;

    if (summary.totalItems == 0) {
      return warnings;
    }

    final standId = _cart.standId;

    if (standId == null) {
      warnings.add('Stand pesanan tidak ditemukan.');
      return warnings;
    }

    final stand = standById(standId);

    if (stand == null) {
      warnings.add('Data stand tidak ditemukan.');
    } else if (!stand.isOpen) {
      warnings.add('Stand sedang tutup. Pesanan belum bisa dibuat.');
    }

    for (final entry in _cart.items.entries) {
      final menu = menuById(entry.key);
      final quantity = entry.value;

      if (menu == null) {
        warnings.add('Ada menu di keranjang yang sudah tidak tersedia.');
        continue;
      }

      if (menu.isOutOfStock) {
        warnings.add('${menu.name} sedang habis.');
      } else if (menu.stock < quantity) {
        warnings.add(
          'Stok ${menu.name} hanya tersisa ${menu.stock}. '
          'Jumlah di keranjang: $quantity.',
        );
      }
    }

    return warnings;
  }

  void refreshCartForCheckout() {
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Navigasi pembeli
  // ---------------------------------------------------------------------------

  int get buyerTab => _buyerTab;

  void setBuyerTab(int index) {
    if (_buyerTab == index) return;

    _buyerTab = index;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Data pengguna dan pencarian data
  // ---------------------------------------------------------------------------

  String get buyerName => _currentUser?.name ?? buyerProfile.name;

  List<OrderModel> get myOrders =>
      _buyerOrders.where((order) => order.buyerName == buyerName).toList();

  StandModel get sellerStand {
    final standId = _currentUser?.standId;

    if (standId != null) {
      for (final stand in _stands) {
        if (stand.id == standId) return stand;
      }
    }

    return _stands.first;
  }

  CartSummary get cartSummary => getCartSummary(_cart, _menus, _stands);

  StandModel? standById(String id) {
    for (final stand in _stands) {
      if (stand.id == id) return stand;
    }

    return null;
  }

  MenuModel? menuById(String id) {
    for (final menu in _menus) {
      if (menu.id == id) return menu;
    }

    return null;
  }

  OrderModel? buyerOrderById(String id) {
    for (final order in _buyerOrders) {
      if (order.id == id) return order;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Akun
  // ---------------------------------------------------------------------------

  bool get isCurrentSellerPending =>
      _sellerPending && _currentUser?.role == UserRole.penjual;

  void syncFirebaseUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

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
    required String password,
    required UserRole role,
    String? standName,
  }) {
    final firebaseUid = AuthService().currentFirebaseUser?.uid;

    final user = UserModel(
      id: firebaseUid ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
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
  // Keranjang
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
    notifyListeners();
  }

  void clearCart() {
    _cart = CartState.empty;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Checkout Firestore
  // ---------------------------------------------------------------------------

  Future<OrderModel?> placeOrder(String pickupTime) async {
    if (_isPlacingOrder) return null;

    final summary = cartSummary;
    final standId = summary.standId;

    if (summary.totalItems == 0 || standId == null) {
      throw Exception('Keranjang masih kosong.');
    }

    final user = _currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    if (user.role != UserRole.pembeli) {
      throw Exception('Hanya akun pembeli yang bisa membuat pesanan.');
    }

    final stand = standById(standId);

    if (stand == null) {
      throw Exception('Data stand tidak ditemukan.');
    }

    final warnings = checkoutWarnings;

    if (warnings.isNotEmpty) {
      throw Exception(warnings.join('\n'));
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      final order = await _orderService.buatPesanan(
        pembeli: user,
        stand: stand,
        items: summary.lines,
        jamAmbil: pickupTime,
      );

      _buyerOrders = [
        order,
        ..._buyerOrders.where((item) => item.id != order.id),
      ];

      final createdAt = order.timeline.isEmpty
          ? ''
          : order.timeline
                    .where((step) => step.status == OrderStatus.menunggu)
                    .map((step) => step.time)
                    .firstOrNull ??
                '';

      _sellerOrders = [
        SellerOrderModel(
          id: order.id,
          orderCode: order.orderCode,
          buyerName: order.buyerName,
          pickupTime: order.pickupTime,
          createdAt: createdAt,
          status: SellerOrderStatus.baru,
          items: order.items,
        ),
        ..._sellerOrders.where((item) => item.id != order.id),
      ];

      for (final item in order.items) {
        final currentMenu = menuById(item.menuId);

        if (currentMenu == null) continue;

        final remainingStock = currentMenu.stock - item.quantity;
        final safeStock = remainingStock < 0 ? 0 : remainingStock;

        _mapMenu(
          item.menuId,
          (menu) => menu.copyWith(stock: safeStock, isAvailable: safeStock > 0),
        );
      }

      _cart = CartState.empty;

      return order;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Status pesanan pembeli
  // ---------------------------------------------------------------------------

  void _setBuyerStatus(
    String orderCode,
    OrderStatus next,
    String time, {
    String? reason,
  }) {
    _buyerOrders = _buyerOrders.map((order) {
      if (order.orderCode != orderCode) return order;

      return order.copyWith(
        status: next,
        cancelReason: reason,
        timeline: order.timeline.map((step) {
          return step.status == next && step.time == null
              ? step.withTime(time)
              : step;
        }).toList(),
      );
    }).toList();
  }

  void _setSellerStatus(String id, SellerOrderStatus next, {String? reason}) {
    _sellerOrders = _sellerOrders.map((order) {
      return order.id == id
          ? order.copyWith(status: next, cancelReason: reason)
          : order;
    }).toList();
  }

  SellerOrderModel? _sellerOrder(String id) {
    for (final order in _sellerOrders) {
      if (order.id == id) return order;
    }

    return null;
  }

  void cancelBuyerOrder(String orderId, {String? reason}) {
    final order = buyerOrderById(orderId);

    if (order == null || order.status != OrderStatus.menunggu) {
      return;
    }

    _setBuyerStatus(
      order.orderCode,
      OrderStatus.dibatalkan,
      '11.56',
      reason: reason,
    );

    for (final sellerOrder in _sellerOrders) {
      if (sellerOrder.orderCode == order.orderCode) {
        _setSellerStatus(
          sellerOrder.id,
          SellerOrderStatus.dibatalkan,
          reason: reason,
        );
      }
    }

    notifyListeners();
  }

  void confirmPickedUp(String orderId) {
    final order = buyerOrderById(orderId);

    if (order == null) return;

    _setBuyerStatus(order.orderCode, OrderStatus.selesai, '12.16');

    notifyListeners();
  }

  void submitRating(String orderId) {
    _buyerOrders = _buyerOrders.map((order) {
      return order.id == orderId
          ? order.copyWith(ratingSubmitted: true)
          : order;
    }).toList();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Pesanan masuk penjual - FIRESTORE
  // ---------------------------------------------------------------------------

  Future<void> acceptSellerOrder(String id) async {
    await _orderService.terimaPesanan(id);

    _sellerStep(id, SellerOrderStatus.diproses, OrderStatus.diproses, '11.56');
  }

  Future<void> markReadySellerOrder(String id) async {
    await _orderService.tandaiSiap(id);

    _sellerStep(id, SellerOrderStatus.siap, OrderStatus.siapDiambil, '12.02');
  }

  Future<void> completeSellerOrder(String id) async {
    await _orderService.selesaikanPesanan(id);

    _sellerStep(id, SellerOrderStatus.selesai, OrderStatus.selesai, '12.16');
  }

  Future<void> markNoShowSellerOrder(String id) async {
    await _orderService.tandaiTidakDiambil(id);

    _sellerStep(
      id,
      SellerOrderStatus.tidakDiambil,
      OrderStatus.tidakDiambil,
      '12.25',
    );
  }

  Future<void> rejectSellerOrder(String id, {String? reason}) async {
    final alasan = (reason == null || reason.trim().isEmpty)
        ? 'Ditolak penjual'
        : reason.trim();

    await _orderService.tolakPesanan(id, alasan: alasan);

    _sellerStep(
      id,
      SellerOrderStatus.dibatalkan,
      OrderStatus.dibatalkan,
      '11.56',
      reason: alasan,
    );
  }

  // ---------------------------------------------------------------------------
  // Sinkronisasi status lokal pembeli dan penjual
  // ---------------------------------------------------------------------------

  void _sellerStep(
    String id,
    SellerOrderStatus next,
    OrderStatus buyerNext,
    String time, {
    String? reason,
  }) {
    final order = _sellerOrder(id);

    _setSellerStatus(id, next, reason: reason);

    if (order != null) {
      _setBuyerStatus(order.orderCode, buyerNext, time, reason: reason);
    }

    notifyListeners();
  }

  void resetDemoSellerOrders() {
    _sellerOrders = [...mockSellerOrders];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Menu dan stand
  // ---------------------------------------------------------------------------

  void _mapMenu(String id, MenuModel Function(MenuModel) transform) {
    _menus = _menus.map((menu) {
      return menu.id == id ? transform(menu) : menu;
    }).toList();
  }

  void toggleMenuAvailability(String menuId) {
    _mapMenu(
      menuId,
      (menu) => menu.isOutOfStock
          ? menu.copyWith(
              isAvailable: true,
              stock: menu.stock == 0 ? 1 : menu.stock,
            )
          : menu.copyWith(isAvailable: false),
    );

    notifyListeners();
  }

  void adjustStock(String menuId, int nextStock) {
    final stock = nextStock < 0 ? 0 : nextStock;

    _mapMenu(
      menuId,
      (menu) => menu.copyWith(stock: stock, isAvailable: stock > 0),
    );

    notifyListeners();
  }

  void bulkUpdateStocks(Map<String, int> updates) {
    updates.forEach((id, stock) {
      final safeStock = stock < 0 ? 0 : stock;

      _mapMenu(
        id,
        (menu) => menu.copyWith(stock: safeStock, isAvailable: safeStock > 0),
      );
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
        (menu) => menu.copyWith(
          name: name,
          price: price,
          stock: stock,
          isAvailable: stock > 0 ? menu.isAvailable : false,
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
    _stands = _stands.map((stand) {
      return stand.id == standId
          ? stand.copyWith(isOpen: !stand.isOpen)
          : stand;
    }).toList();

    notifyListeners();
  }

  void updateStandInfo(
    String standId, {
    required String name,
    required String foodTypes,
    required String openHours,
  }) {
    _stands = _stands.map((stand) {
      return stand.id == standId
          ? stand.copyWith(
              name: name,
              foodTypes: foodTypes,
              openHours: openHours,
            )
          : stand;
    }).toList();

    _menus = _menus.map((menu) {
      return menu.standId == standId ? menu.copyWith(standName: name) : menu;
    }).toList();

    notifyListeners();
  }
}
