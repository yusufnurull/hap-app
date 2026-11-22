// Data contoh untuk prototipe. Nanti diganti data dari Firestore.

import '../core/constants/app_enums.dart';
import '../core/constants/order_status.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/stand_model.dart';
import '../models/user_model.dart';
import '../providers/cart_provider.dart';

class BuyerProfile {
  const BuyerProfile({
    required this.name,
    required this.email,
    required this.phone,
  });
  final String name;
  final String email;
  final String phone;
}

const buyerProfile = BuyerProfile(
  name: 'Yusuf',
  email: 'yusuf@kampus.ac.id',
  phone: '0812-3456-7890',
);

const List<StandModel> mockStands = [
  StandModel(
    id: 'bu-sri',
    name: 'Warung Bu Sri',
    isOpen: true,
    foodTypes: 'Ayam geprek, nasi, lauk',
    openHours: '07.00–15.00',
    locationNote: 'Kios 1 · Kiri tangga',
    categories: [StandCategory.makananBerat, StandCategory.camilan],
    icon: 'lunch_dining',
    todayOrders: 11,
  ),
  StandModel(
    id: 'mas-joko',
    name: 'Kedai Mas Joko',
    isOpen: true,
    foodTypes: 'Mie goreng, nasi goreng, camilan',
    openHours: '07.30–16.00',
    locationNote: 'Kios 2 · Tengah',
    categories: [StandCategory.makananBerat, StandCategory.camilan],
    icon: 'ramen_dining',
    todayOrders: 8,
  ),
  StandModel(
    id: 'pojok-minuman',
    name: 'Pojok Minuman',
    isOpen: true,
    foodTypes: 'Es teh, es jeruk, kopi susu',
    openHours: '07.00–16.30',
    locationNote: 'Kios 4 · Dekat pintu',
    categories: [StandCategory.minuman],
    icon: 'local_cafe',
    todayOrders: 5,
  ),
  StandModel(
    id: 'pak-darmo',
    name: 'Soto Pak Darmo',
    isOpen: false,
    foodTypes: 'Soto ayam, nasi hangat',
    openHours: '13.00–17.00',
    locationNote: 'Kios 5 · Buka siang',
    categories: [StandCategory.makananBerat],
    icon: 'soup_kitchen',
    todayOrders: 0,
  ),
];

const List<MenuModel> mockMenus = [
  MenuModel(
    id: 'ayam-geprek',
    name: 'Nasi Ayam Geprek',
    standId: 'bu-sri',
    standName: 'Warung Bu Sri',
    category: MenuCategory.makanan,
    price: 12000,
    description:
        'Ayam goreng renyah digeprek dengan sambal bawang segar, lalapan timun, dan nasi putih hangat.',
    icon: 'lunch_dining',
    stock: 3,
    isAvailable: true,
  ),
  MenuModel(
    id: 'ayam-kremes',
    name: 'Nasi Ayam Kremes',
    standId: 'bu-sri',
    standName: 'Warung Bu Sri',
    category: MenuCategory.makanan,
    price: 10000,
    description:
        'Potongan ayam goreng gurih dengan taburan kremesan renyah dan sambal terasi.',
    icon: 'dinner_dining',
    stock: 14,
    isAvailable: true,
  ),
  MenuModel(
    id: 'nasi-telur-balado',
    name: 'Nasi Telur Balado',
    standId: 'bu-sri',
    standName: 'Warung Bu Sri',
    category: MenuCategory.makanan,
    price: 9000,
    description:
        'Telur bulat goreng disiram sambal balado merah dengan nasi hangat.',
    icon: 'rice_bowl',
    stock: 20,
    isAvailable: true,
  ),
  MenuModel(
    id: 'nasi-rendang',
    name: 'Nasi Rendang Sapi',
    standId: 'bu-sri',
    standName: 'Warung Bu Sri',
    category: MenuCategory.makanan,
    price: 18000,
    description:
        'Daging sapi masak bumbu rendang pekat, lengkap dengan sayur nangka dan sambal hijau.',
    icon: 'dinner_dining',
    stock: 8,
    isAvailable: true,
  ),
  MenuModel(
    id: 'tahu-tempe-penyet',
    name: 'Tahu Tempe Penyet',
    standId: 'bu-sri',
    standName: 'Warung Bu Sri',
    category: MenuCategory.camilan,
    price: 7000,
    description:
        'Dua tahu dan dua tempe goreng hangat penyet sambal kecap atau sambal bawang.',
    icon: 'tapas',
    stock: 16,
    isAvailable: true,
  ),
  MenuModel(
    id: 'mie-goreng',
    name: 'Mie Goreng Telur',
    standId: 'mas-joko',
    standName: 'Kedai Mas Joko',
    category: MenuCategory.makanan,
    price: 10000,
    description:
        'Mie kuning tumis kecap manis dengan telur orak-arik, sawi hijau, dan irisan bakso.',
    icon: 'ramen_dining',
    stock: 15,
    isAvailable: true,
  ),
  MenuModel(
    id: 'nasi-goreng-kampung',
    name: 'Nasi Goreng Kampung',
    standId: 'mas-joko',
    standName: 'Kedai Mas Joko',
    category: MenuCategory.makanan,
    price: 13000,
    description:
        'Nasi goreng bumbu terasi rumahan lengkap dengan telur ceplok dan kerupuk.',
    icon: 'skillet',
    stock: 12,
    isAvailable: true,
  ),
  MenuModel(
    id: 'cireng-rujak',
    name: 'Cireng Bumbu Rujak',
    standId: 'mas-joko',
    standName: 'Kedai Mas Joko',
    category: MenuCategory.camilan,
    price: 6000,
    description:
        'Lima potong cireng garing di luar dan kenyal di dalam, dicocol bumbu rujak asam manis.',
    icon: 'bakery_dining',
    stock: 18,
    isAvailable: true,
  ),
  MenuModel(
    id: 'pisang-bakar',
    name: 'Pisang Bakar Cokelat',
    standId: 'mas-joko',
    standName: 'Kedai Mas Joko',
    category: MenuCategory.camilan,
    price: 8000,
    description:
        'Pisang kepok bakar mentega dengan taburan meses cokelat dan susu kental manis.',
    icon: 'bakery_dining',
    stock: 10,
    isAvailable: true,
  ),
  MenuModel(
    id: 'es-teh',
    name: 'Es Teh Manis',
    standId: 'pojok-minuman',
    standName: 'Pojok Minuman',
    category: MenuCategory.minuman,
    price: 3000,
    description:
        'Teh melati seduh segar dengan gula tebu asli dan es batu kristal.',
    icon: 'local_cafe',
    stock: 25,
    isAvailable: true,
  ),
  MenuModel(
    id: 'es-jeruk',
    name: 'Es Jeruk',
    standId: 'pojok-minuman',
    standName: 'Pojok Minuman',
    category: MenuCategory.minuman,
    price: 5000,
    description: 'Perasan jeruk pontianak manis segar disajikan dingin.',
    icon: 'local_bar',
    stock: 15,
    isAvailable: true,
  ),
  MenuModel(
    id: 'kopi-gula-aren',
    name: 'Es Kopi Susu Gula Aren',
    standId: 'pojok-minuman',
    standName: 'Pojok Minuman',
    category: MenuCategory.minuman,
    price: 10000,
    description:
        'Espresso robusta, susu segar, dan sirup gula aren murni tanpa pemanis buatan.',
    icon: 'coffee',
    stock: 11,
    isAvailable: true,
  ),
  MenuModel(
    id: 'soto-ayam',
    name: 'Soto Ayam',
    standId: 'pak-darmo',
    standName: 'Soto Pak Darmo',
    category: MenuCategory.makanan,
    price: 11000,
    description:
        'Kuah kaldu kuning bening dengan suwiran ayam kampung, soun, kol, dan koya gurih.',
    icon: 'soup_kitchen',
    stock: 0,
    isAvailable: false,
  ),
];

const CartState initialCart = CartState(
  standId: 'bu-sri',
  items: {'ayam-geprek': 1, 'ayam-kremes': 1},
  notes: {'ayam-geprek': 'Sambal dipisah'},
);

const List<OrderModel> mockBuyerOrders = [
  OrderModel(
    id: 'ord-017',
    orderCode: 'A-017',
    buyerName: 'Yusuf',
    standId: 'bu-sri',
    standName: 'Warung Bu Sri',
    pickupTime: '12.15',
    status: OrderStatus.diproses,
    paymentMethod: 'Bayar di tempat',
    items: [
      OrderLineItem(
        menuId: 'ayam-geprek',
        name: 'Nasi Ayam Geprek',
        quantity: 1,
        price: 12000,
        note: 'Sambal dipisah, tidak pakai kol',
      ),
      OrderLineItem(
        menuId: 'tahu-tempe-penyet',
        name: 'Tahu Tempe Penyet',
        quantity: 1,
        price: 7000,
        note: 'Cabe sedang saja',
      ),
    ],
    timeline: [
      OrderTimelineStep(
        status: OrderStatus.menunggu,
        label: 'Pesanan masuk',
        description: 'Menunggu konfirmasi Warung Bu Sri',
        time: '11.42',
      ),
      OrderTimelineStep(
        status: OrderStatus.diproses,
        label: 'Pesananmu lagi disiapkan',
        description: 'Warung Bu Sri sedang menyiapkan pesanan',
        time: '11.44',
      ),
      OrderTimelineStep(
        status: OrderStatus.siapDiambil,
        label: 'Siap! Ambil di Warung Bu Sri',
        description: 'Tunjukkan tiket A-017 saat mengambil',
      ),
      OrderTimelineStep(
        status: OrderStatus.selesai,
        label: 'Pesanan selesai',
        description: 'Sudah diambil dan dibayar di tempat',
      ),
    ],
  ),
  OrderModel(
    id: 'ord-012',
    orderCode: 'A-012',
    buyerName: 'Yusuf',
    standId: 'mas-joko',
    standName: 'Kedai Mas Joko',
    pickupTime: '10.15',
    status: OrderStatus.selesai,
    paymentMethod: 'Bayar di tempat',
    ratingSubmitted: false,
    items: [
      OrderLineItem(
        menuId: 'mie-goreng',
        name: 'Mie Goreng Telur',
        quantity: 1,
        price: 10000,
      ),
      OrderLineItem(
        menuId: 'cireng-rujak',
        name: 'Cireng Bumbu Rujak',
        quantity: 1,
        price: 6000,
      ),
    ],
    timeline: [
      OrderTimelineStep(
        status: OrderStatus.menunggu,
        label: 'Pesanan masuk',
        description: 'Menunggu konfirmasi Kedai Mas Joko',
        time: '09.50',
      ),
      OrderTimelineStep(
        status: OrderStatus.diproses,
        label: 'Pesananmu lagi disiapkan',
        description: 'Kedai Mas Joko sedang menyiapkan pesanan',
        time: '09.52',
      ),
      OrderTimelineStep(
        status: OrderStatus.siapDiambil,
        label: 'Siap! Ambil di Kedai Mas Joko',
        description: 'Tunjukkan tiket A-012 saat mengambil',
        time: '10.08',
      ),
      OrderTimelineStep(
        status: OrderStatus.selesai,
        label: 'Pesanan selesai',
        description: 'Sudah diambil dan dibayar di tempat',
        time: '10.14',
      ),
    ],
  ),
];

const List<SellerOrderModel> mockSellerOrders = [
  SellerOrderModel(
    id: 'sel-020',
    orderCode: 'A-020',
    buyerName: 'Rizky Pratama',
    pickupTime: '12.15',
    createdAt: '11.50',
    status: SellerOrderStatus.baru,
    items: [
      OrderLineItem(
        menuId: 'ayam-geprek',
        name: 'Nasi Ayam Geprek',
        quantity: 1,
        price: 12000,
        note: 'Level pedas 3, nasi setengah',
      ),
      OrderLineItem(
        menuId: 'tahu-tempe-penyet',
        name: 'Tahu Tempe Penyet',
        quantity: 1,
        price: 7000,
      ),
    ],
  ),
  SellerOrderModel(
    id: 'sel-018',
    orderCode: 'A-018',
    buyerName: 'Nadia Kusuma',
    pickupTime: '12.00',
    createdAt: '11.48',
    status: SellerOrderStatus.baru,
    items: [
      OrderLineItem(
        menuId: 'nasi-telur-balado',
        name: 'Nasi Telur Balado',
        quantity: 2,
        price: 9000,
        note: '1 bungkus pisah sambal',
      ),
    ],
  ),
  SellerOrderModel(
    id: 'sel-019',
    orderCode: 'A-019',
    buyerName: 'Bagas Aditia',
    pickupTime: '12.05',
    createdAt: '11.49',
    status: SellerOrderStatus.baru,
    items: [
      OrderLineItem(
        menuId: 'ayam-geprek',
        name: 'Nasi Ayam Geprek',
        quantity: 1,
        price: 12000,
        note: 'Tanpa timun, sambal banyak',
      ),
    ],
  ),
  SellerOrderModel(
    id: 'sel-017',
    orderCode: 'A-017',
    buyerName: 'Yusuf',
    pickupTime: '12.15',
    createdAt: '11.42',
    status: SellerOrderStatus.diproses,
    items: [
      OrderLineItem(
        menuId: 'ayam-geprek',
        name: 'Nasi Ayam Geprek',
        quantity: 1,
        price: 12000,
        note: 'Sambal dipisah, tidak pakai kol',
      ),
      OrderLineItem(
        menuId: 'tahu-tempe-penyet',
        name: 'Tahu Tempe Penyet',
        quantity: 1,
        price: 7000,
        note: 'Cabe sedang saja',
      ),
    ],
  ),
  SellerOrderModel(
    id: 'sel-016',
    orderCode: 'A-016',
    buyerName: 'Dinda Maharani',
    pickupTime: '12.05',
    createdAt: '11.40',
    status: SellerOrderStatus.diproses,
    items: [
      OrderLineItem(
        menuId: 'nasi-telur-balado',
        name: 'Nasi Telur Balado',
        quantity: 1,
        price: 9000,
      ),
    ],
  ),
  SellerOrderModel(
    id: 'sel-015',
    orderCode: 'A-015',
    buyerName: 'Fajar Ramadhan',
    pickupTime: '11.15',
    createdAt: '10.50',
    status: SellerOrderStatus.siap,
    isOverduePickup: true,
    items: [
      OrderLineItem(
        menuId: 'ayam-geprek',
        name: 'Nasi Ayam Geprek',
        quantity: 1,
        price: 12000,
        note: 'Sambal sedang',
      ),
    ],
  ),
];

const List<PendingSellerModel> mockPendingSellers = [
  PendingSellerModel(
    id: 'pend-1',
    applicantName: 'Siti Aminah',
    standName: 'Warung Mbak Siti',
    appliedDate: '13 Nov 2026',
    foodTypes: 'Nasi uduk, gorengan',
  ),
  PendingSellerModel(
    id: 'pend-2',
    applicantName: 'Budi Santoso',
    standName: 'Bakso Pak Budi',
    appliedDate: '12 Nov 2026',
    foodTypes: 'Bakso urat, mie ayam',
  ),
];

const List<UserModel> mockUsers = [
  UserModel(
    id: 'usr-1',
    name: 'Yusuf',
    email: 'yusuf@kampus.ac.id',
    phone: '0812-3456-7890',
    role: UserRole.pembeli,
  ),
  UserModel(
    id: 'usr-2',
    name: 'Nadia Kusuma',
    email: 'nadia.k@kampus.ac.id',
    phone: '0813-9988-1122',
    role: UserRole.pembeli,
    noShowCount: 3,
  ),
  UserModel(
    id: 'usr-3',
    name: 'Ibu Sri Wahyuni',
    email: 'busri@kantin.ac.id',
    phone: '0815-7700-4321',
    role: UserRole.penjual,
  ),
  UserModel(
    id: 'usr-4',
    name: 'Mas Joko Susilo',
    email: 'masjoko@kantin.ac.id',
    phone: '0856-3311-2200',
    role: UserRole.penjual,
  ),
  UserModel(
    id: 'usr-5',
    name: 'Rendra Pratama',
    email: 'admin@kantin.ac.id',
    phone: '0811-2233-4455',
    role: UserRole.admin,
  ),
];
