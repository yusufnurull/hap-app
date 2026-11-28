// State utama aplikasi untuk layar pembeli dan penjual.
//
// Sumber data: Firestore (real-time). Layar tetap memanggil method yang sama
// seperti versi prototipe, tetapi isinya kini:
// - MEMBACA lewat stream (stand, menu, pesanan) yang dimulai setelah login,
// - MENULIS lewat services/ (OrderService, FirestoreService).
// Karena data datang dari stream, dua HP otomatis melihat data yang sama,
// dan riwayat tetap ada setelah aplikasi ditutup.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';
import '../core/constants/order_status.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/order_service.dart';
import 'cart_provider.dart';

class AppStore extends ChangeNotifier {
  AppStore({OrderService? orderService, FirestoreService? firestoreService})
    : _orderService = orderService ?? OrderService(),
      _firestoreService = firestoreService ?? FirestoreService() {
    // Saat keluar akun, hentikan semua stream dan kosongkan data.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && _currentUser != null) _clearSession();
    });
  }

  final OrderService _orderService;
  final FirestoreService _firestoreService;

  // ---------------------------------------------------------------------------
  // Data (diisi stream)
  // ---------------------------------------------------------------------------

  List<StandModel> _stands = [];
  List<MenuModel> _menus = [];
  CartState _cart = CartState.empty;
  List<OrderModel> _buyerOrders = [];
  List<SellerOrderModel> _sellerOrders = [];

  /// Pesanan yang baru dibuat di HP ini dan belum muncul di stream
  /// (supaya layar detail pesanan langsung bisa dibuka setelah checkout).
  final Map<String, OrderModel> _pendingOrders = {};

  UserModel? _currentUser;
  int _buyerTab = 0;
  bool _isPlacingOrder = false;
  bool _catalogLoaded = false;
  bool _ordersLoaded = false;
  String? _lastError;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<StandModel>>? _standSub;
  StreamSubscription<List<MenuModel>>? _menuSub;
  StreamSubscription<List<OrderModel>>? _buyerOrderSub;
  StreamSubscription<List<SellerOrderModel>>? _sellerOrderSub;
  String? _sellerStandIdListening;

  List<StandModel> get stands => _stands;
  List<MenuModel> get menus => _menus;
  CartState get cart => _cart;
  List<OrderModel> get buyerOrders => _buyerOrders;
  List<SellerOrderModel> get sellerOrders => _sellerOrders;
  UserModel? get currentUser => _currentUser;
  bool get isPlacingOrder => _isPlacingOrder;

  /// true sampai stand, menu, dan pesanan pertama kali selesai dimuat.
  bool get isLoadingData => !_catalogLoaded || !_ordersLoaded;

  /// Pesan galat terakhir dari Firestore (mis. index belum dibuat).
  String? get lastError => _lastError;

  // ---------------------------------------------------------------------------
  // Mulai dan hentikan stream
  // ---------------------------------------------------------------------------

  /// Dipanggil app.dart setiap data akun berubah.
  void syncFirebaseUser(UserModel user) {
    final gantiAkun = _currentUser?.id != user.id;
    _currentUser = user;

    if (gantiAkun) {
      _cancelAll();
      _resetData();
      _listenCatalog();
    }

    if (user.status == 'aktif') {
      if (user.role == UserRole.pembeli && _buyerOrderSub == null) {
        _listenBuyerOrders(user.id);
      }
      if (user.role == UserRole.penjual &&
          user.standId != null &&
          user.standId != _sellerStandIdListening) {
        _listenSellerOrders(user.standId!);
      }
      if (user.role == UserRole.admin) _ordersLoaded = true;
    } else {
      _ordersLoaded = true;
    }

    notifyListeners();
  }

  void _listenCatalog() {
    _standSub = _firestoreService.streamStands().listen((stands) {
      _stands = stands;
      _catalogLoaded = true;
      notifyListeners();
    }, onError: _onStreamError);

    _menuSub = _firestoreService.streamSemuaMenu().listen((menus) {
      _menus = menus;
      notifyListeners();
    }, onError: _onStreamError);
  }

  void _listenBuyerOrders(String uid) {
    _buyerOrderSub = _orderService.streamPesananPembeli(uid).listen((orders) {
      final ids = orders.map((o) => o.id).toSet();
      _pendingOrders.removeWhere((id, _) => ids.contains(id));
      _buyerOrders = [..._pendingOrders.values, ...orders];
      _ordersLoaded = true;
      notifyListeners();
    }, onError: _onStreamError);
  }

  void _listenSellerOrders(String standId) {
    _sellerOrderSub?.cancel();
    _sellerStandIdListening = standId;
    _sellerOrderSub = _orderService.streamPesananStand(standId).listen((
      orders,
    ) {
      _sellerOrders = orders;
      _ordersLoaded = true;
      notifyListeners();
    }, onError: _onStreamError);
  }

  void _onStreamError(Object error) {
    // Error index Firestore berisi link untuk membuat index: lihat Debug Console.
    debugPrint('[AppStore] Firestore error: $error');
    _lastError = '$error';
    _catalogLoaded = true;
    _ordersLoaded = true;
    notifyListeners();
  }

  void _cancelAll() {
    _standSub?.cancel();
    _menuSub?.cancel();
    _buyerOrderSub?.cancel();
    _sellerOrderSub?.cancel();
    _standSub = null;
    _menuSub = null;
    _buyerOrderSub = null;
    _sellerOrderSub = null;
    _sellerStandIdListening = null;
  }

  void _resetData() {
    _stands = [];
    _menus = [];
    _buyerOrders = [];
    _sellerOrders = [];
    _pendingOrders.clear();
    _cart = CartState.empty;
    _buyerTab = 0;
    _catalogLoaded = false;
    _ordersLoaded = false;
    _lastError = null;
  }

  void _clearSession() {
    _cancelAll();
    _resetData();
    _currentUser = null;
    notifyListeners();
  }

  /// Menjalankan penulisan ke Firestore; galat disimpan di [lastError]
  /// dan dikembalikan sebagai pesan (null = berhasil).
  Future<String?> _jalankan(Future<void> Function() aksi) async {
    try {
      await aksi();
      _lastError = null;
      return null;
    } catch (e) {
      final pesan = e is OrderFailure ? e.message : '$e';
      debugPrint('[AppStore] Gagal menyimpan: $pesan');
      _lastError = pesan;
      notifyListeners();
      return pesan;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelAll();
    super.dispose();
  }

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

  /// Stok sudah real-time dari stream, jadi cukup gambar ulang layar.
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

  String get buyerName => _currentUser?.name ?? '';

  /// Stream pembeli sudah difilter per akun (pembeliId), jadi semua isinya
  /// adalah pesanan milik pengguna ini.
  List<OrderModel> get myOrders => _buyerOrders;

  /// Stand milik penjual yang login. Selama data belum dimuat, dikembalikan
  /// stand sementara supaya layar penjual tidak error.
  StandModel get sellerStand {
    final standId = _currentUser?.standId;

    if (standId != null) {
      final stand = standById(standId);
      if (stand != null) return stand;
    }

    return StandModel(
      id: standId ?? '',
      name: _catalogLoaded ? 'Stand tidak ditemukan' : 'Memuat stand...',
      isOpen: false,
      foodTypes: '',
      openHours: '',
      locationNote: '',
      categories: const [],
      icon: 'storefront',
    );
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
      _currentUser?.role == UserRole.penjual &&
      _currentUser?.status == 'menunggu';

  /// Membersihkan data saat keluar. Keluar dari Firebase tetap lewat
  /// AuthService().keluar(); AppStore juga ikut bersih otomatis.
  void logout() => _clearSession();

  // ---------------------------------------------------------------------------
  // Keranjang (tetap lokal di HP, belum perlu disimpan ke Firestore)
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

      // Tampilkan langsung; akan diganti data stream begitu sampai.
      // Stok menu dan daftar pesanan penjual ikut ter-update lewat stream.
      if (buyerOrderById(order.id) == null) {
        _pendingOrders[order.id] = order;
        _buyerOrders = [order, ..._buyerOrders];
      }

      _cart = CartState.empty;

      return order;
    } on OrderFailure catch (e) {
      throw Exception(e.message);
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Aksi pembeli
  // ---------------------------------------------------------------------------

  /// Pembeli membatalkan pesanan (hanya saat Menunggu). Stok dikembalikan.
  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> cancelBuyerOrder(String orderId, {String? reason}) {
    final order = buyerOrderById(orderId);

    if (order == null || order.status != OrderStatus.menunggu) {
      return Future.value('Pesanan sudah diproses, tidak bisa dibatalkan.');
    }

    return _jalankan(
      () => _orderService.batalkanPesanan(orderId, alasan: reason),
    );
  }

  /// Pesanan ditandai selesai oleh PENJUAL saat pembeli mengambil dan
  /// membayar. Pembeli tidak bisa menandai sendiri (dibatasi Security Rules).
  Future<String?> confirmPickedUp(String orderId) {
    return Future.value(
      'Tunjukkan tiket ke penjual. Penjual yang akan menandai pesanan selesai.',
    );
  }

  /// Menyimpan rating 1-5 dan ulasan. Mengembalikan pesan galat atau null.
  Future<String?> submitRating(
    String orderId, {
    int bintang = 5,
    String ulasan = '',
  }) {
    return _jalankan(
      () => _orderService.beriRating(orderId, bintang: bintang, ulasan: ulasan),
    );
  }

  // ---------------------------------------------------------------------------
  // Pesanan masuk penjual (perubahan tampil lewat stream)
  // ---------------------------------------------------------------------------

  Future<void> acceptSellerOrder(String id) => _orderService.terimaPesanan(id);

  Future<void> markReadySellerOrder(String id) => _orderService.tandaiSiap(id);

  Future<void> completeSellerOrder(String id) =>
      _orderService.selesaikanPesanan(id);

  Future<void> markNoShowSellerOrder(String id) =>
      _orderService.tandaiTidakDiambil(id);

  Future<void> rejectSellerOrder(String id, {String? reason}) {
    final alasan = (reason == null || reason.trim().isEmpty)
        ? 'Ditolak penjual'
        : reason.trim();

    return _orderService.tolakPesanan(id, alasan: alasan);
  }

  /// Dulu memuat ulang pesanan contoh. Sekarang data selalu real-time,
  /// jadi cukup gambar ulang layar.
  void resetDemoSellerOrders() {
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Menu dan stand milik penjual (perubahan tampil lewat stream)
  // ---------------------------------------------------------------------------

  String get _myStandId => sellerStand.id;

  Future<String?> toggleMenuAvailability(String menuId) {
    final menu = menuById(menuId);
    if (menu == null) return Future.value('Menu tidak ditemukan.');

    return _jalankan(
      () => _firestoreService.ubahKetersediaan(
        menu.standId,
        menu,
        menu.isOutOfStock, // habis -> tersedia, tersedia -> habis
      ),
    );
  }

  Future<String?> adjustStock(String menuId, int nextStock) {
    final menu = menuById(menuId);
    if (menu == null) return Future.value('Menu tidak ditemukan.');

    return _jalankan(
      () => _firestoreService.ubahStok(menu.standId, menuId, nextStock),
    );
  }

  Future<String?> bulkUpdateStocks(Map<String, int> updates) {
    return _jalankan(
      () => _firestoreService.aturStokHariIni(_myStandId, updates),
    );
  }

  Future<String?> saveSellerMenu({
    String? id,
    required String name,
    required int price,
    required int stock,
    required MenuCategory category,
    required String description,
    required String icon,
  }) {
    final stand = sellerStand;

    if (id != null) {
      final lama = menuById(id);
      if (lama == null) return Future.value('Menu tidak ditemukan.');

      return _jalankan(
        () => _firestoreService.ubahMenu(
          stand.id,
          lama.copyWith(
            name: name,
            price: price,
            stock: stock,
            isAvailable: stock > 0 ? lama.isAvailable : false,
            category: category,
            description: description,
            icon: icon,
          ),
        ),
      );
    }

    return _jalankan(
      () => _firestoreService.tambahMenu(
        stand.id,
        MenuModel(
          id: '',
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
      ),
    );
  }

  Future<String?> toggleStandOpen(String standId) {
    final stand = standById(standId);
    if (stand == null) return Future.value('Stand tidak ditemukan.');

    return _jalankan(
      () => _firestoreService.ubahStatusBuka(standId, !stand.isOpen),
    );
  }

  /// [openHours] berformat "07.00–15.00".
  Future<String?> updateStandInfo(
    String standId, {
    required String name,
    required String foodTypes,
    required String openHours,
  }) {
    final stand = standById(standId);
    if (stand == null) return Future.value('Stand tidak ditemukan.');

    final jam = stand.copyWith(openHours: openHours);

    return _jalankan(
      () => _firestoreService.ubahInfoStand(
        standId,
        namaStand: name,
        deskripsi: foodTypes,
        jamBuka: jam.openTime,
        jamTutup: jam.closeTime,
      ),
    );
  }
}
