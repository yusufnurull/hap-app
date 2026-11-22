// Model data pesanan pembeli dan pesanan masuk penjual.

import '../core/constants/order_status.dart';

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

  SellerOrderModel copyWith({
    SellerOrderStatus? status,
    String? cancelReason,
  }) {
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
