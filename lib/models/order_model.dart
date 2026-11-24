// Model data pesanan pembeli dan pesanan masuk penjual.
//
// Dokumen Firestore: orders/{orderId}
// Satu dokumen dibaca dua cara: OrderModel (sisi pembeli) dan
// SellerOrderModel (sisi penjual).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_values.dart';
import '../core/constants/order_status.dart';
import 'user_model.dart' show formatJamTimestamp;

class OrderLineItem {
  const OrderLineItem({
    required this.menuId,
    required this.name,
    required this.quantity,
    required this.price,
    this.note,
  });

  final String menuId;
  final String name;
  final int quantity;
  final int price;
  final String? note;

  int get subtotal => price * quantity;

  OrderLineItem withNote(String note) => OrderLineItem(
    menuId: menuId,
    name: name,
    quantity: quantity,
    price: price,
    note: note,
  );

  /// Satu elemen array `items`.
  factory OrderLineItem.fromMap(Map<String, dynamic> data) {
    final note = data['catatan'] as String?;
    return OrderLineItem(
      menuId: (data['menuId'] as String?) ?? '',
      name: (data['nama'] as String?) ?? '',
      quantity: (data['jumlah'] as num?)?.toInt() ?? 0,
      price: (data['harga'] as num?)?.toInt() ?? 0,
      note: (note == null || note.isEmpty) ? null : note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'nama': name,
      'harga': price,
      'jumlah': quantity,
      'catatan': note ?? '',
    };
  }
}

/// Satu langkah pada stepper progres pesanan.
class OrderTimelineStep {
  const OrderTimelineStep({
    required this.status,
    required this.label,
    required this.description,
    this.time,
  });

  final OrderStatus status;
  final String label;
  final String description;
  final String? time;

  OrderTimelineStep withTime(String time) => OrderTimelineStep(
    status: status,
    label: label,
    description: description,
    time: time,
  );
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.buyerName,
    required this.standId,
    required this.standName,
    required this.pickupTime,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.timeline,
    this.ratingSubmitted = false,
    this.cancelReason,
  });

  final String id;
  final String orderCode;
  final String buyerName;
  final String standId;
  final String standName;
  final String pickupTime;
  final OrderStatus status;
  final String paymentMethod;
  final List<OrderLineItem> items;
  final List<OrderTimelineStep> timeline;
  final bool ratingSubmitted;
  final String? cancelReason;

  int get total => items.fold(0, (sum, i) => sum + i.subtotal);

  /// Membaca dokumen `orders/{orderId}` untuk layar pembeli.
  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    final orderCode = (data['nomorPesanan'] as String?) ?? '';
    final standName = (data['namaStand'] as String?) ?? '';
    final waktu = (data['waktuStatus'] as Map<String, dynamic>?) ?? const {};
    return OrderModel(
      id: id,
      orderCode: orderCode,
      buyerName: (data['namaPembeli'] as String?) ?? '',
      standId: (data['standId'] as String?) ?? '',
      standName: standName,
      pickupTime: (data['jamAmbil'] as String?) ?? '',
      status: orderStatusFromValue(data['status']),
      paymentMethod: data['metodeBayar'] == PaymentValue.tunai
          ? PaymentValue.labelTunai
          : (data['metodeBayar'] as String?) ?? PaymentValue.labelTunai,
      items: _itemsFromData(data['items']),
      timeline: buildOrderTimeline(
        standName: standName,
        orderCode: orderCode,
        times: {
          OrderStatus.menunggu: formatJamTimestamp(
            waktu[OrderStatusValue.menunggu] ?? data['createdAt'],
          ),
          OrderStatus.diproses: formatJamTimestamp(
            waktu[OrderStatusValue.diproses],
          ),
          OrderStatus.siapDiambil: formatJamTimestamp(
            waktu[OrderStatusValue.siap],
          ),
          OrderStatus.selesai: formatJamTimestamp(
            waktu[OrderStatusValue.selesai],
          ),
        },
      ),
      ratingSubmitted: (data['sudahDirating'] as bool?) ?? false,
      cancelReason: data['alasanBatal'] as String?,
    );
  }

  /// Data untuk membuat dokumen pesanan baru.
  /// `nomorPesanan`, `createdAt`, dan `waktuStatus` diisi oleh service
  /// (buatPesanan, Minggu 3).
  Map<String, dynamic> toMap({required String buyerId}) {
    return {
      'nomorPesanan': orderCode,
      'pembeliId': buyerId,
      'namaPembeli': buyerName,
      'standId': standId,
      'namaStand': standName,
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'jamAmbil': pickupTime,
      'metodeBayar': PaymentValue.tunai,
      'status': orderStatusToValue(status),
      'sudahDirating': ratingSubmitted,
      if (cancelReason != null) 'alasanBatal': cancelReason,
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    List<OrderTimelineStep>? timeline,
    bool? ratingSubmitted,
    String? cancelReason,
  }) {
    return OrderModel(
      id: id,
      orderCode: orderCode,
      buyerName: buyerName,
      standId: standId,
      standName: standName,
      pickupTime: pickupTime,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      items: items,
      timeline: timeline ?? this.timeline,
      ratingSubmitted: ratingSubmitted ?? this.ratingSubmitted,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}

class SellerOrderModel {
  const SellerOrderModel({
    required this.id,
    required this.orderCode,
    required this.buyerName,
    required this.pickupTime,
    required this.createdAt,
    required this.status,
    required this.items,
    this.isOverduePickup = false,
    this.cancelReason,
  });

  final String id;
  final String orderCode;
  final String buyerName;
  final String pickupTime;
  final String createdAt;
  final SellerOrderStatus status;
  final List<OrderLineItem> items;
  final bool isOverduePickup;
  final String? cancelReason;

  /// Membaca dokumen `orders/{orderId}` untuk layar penjual.
  factory SellerOrderModel.fromMap(String id, Map<String, dynamic> data) {
    return SellerOrderModel(
      id: id,
      orderCode: (data['nomorPesanan'] as String?) ?? '',
      buyerName: (data['namaPembeli'] as String?) ?? '',
      pickupTime: (data['jamAmbil'] as String?) ?? '',
      createdAt: formatJamTimestamp(data['createdAt']),
      status: sellerStatusFromValue(data['status']),
      items: _itemsFromData(data['items']),
      cancelReason: data['alasanBatal'] as String?,
    );
  }

  SellerOrderModel copyWith({SellerOrderStatus? status, String? cancelReason}) {
    return SellerOrderModel(
      id: id,
      orderCode: orderCode,
      buyerName: buyerName,
      pickupTime: pickupTime,
      createdAt: createdAt,
      status: status ?? this.status,
      items: items,
      isOverduePickup: isOverduePickup,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}

List<OrderLineItem> _itemsFromData(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((m) => OrderLineItem.fromMap(Map<String, dynamic>.from(m)))
      .toList();
}

/// Menyusun langkah stepper pesanan. Teksnya sama dengan createOrderFromCart
/// di hap_logic.dart supaya tampilan tidak berubah setelah pindah ke Firestore.
List<OrderTimelineStep> buildOrderTimeline({
  required String standName,
  required String orderCode,
  Map<OrderStatus, String> times = const {},
}) {
  String? t(OrderStatus s) {
    final v = times[s];
    return (v == null || v.isEmpty) ? null : v;
  }

  return [
    OrderTimelineStep(
      status: OrderStatus.menunggu,
      label: 'Pesanan masuk',
      description: 'Menunggu konfirmasi $standName',
      time: t(OrderStatus.menunggu),
    ),
    OrderTimelineStep(
      status: OrderStatus.diproses,
      label: 'Pesananmu lagi disiapkan',
      description: '$standName sedang menyiapkan pesanan',
      time: t(OrderStatus.diproses),
    ),
    OrderTimelineStep(
      status: OrderStatus.siapDiambil,
      label: 'Siap! Ambil di $standName',
      description: 'Tunjukkan tiket $orderCode saat mengambil',
      time: t(OrderStatus.siapDiambil),
    ),
    OrderTimelineStep(
      status: OrderStatus.selesai,
      label: 'Pesanan selesai',
      description: 'Sudah diambil dan dibayar di tempat',
      time: t(OrderStatus.selesai),
    ),
  ];
}

/// Dipakai service saat mencatat waktu perubahan status.
Map<String, dynamic> waktuStatusUpdate(OrderStatus status) => {
  'waktuStatus.${orderStatusToValue(status)}': FieldValue.serverTimestamp(),
};
