import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      price: (data['price'] as num).toDouble(),
      quantity: data['quantity'] as int,
    );
  }
}

class Order {
  final String id;
  final String status;
  final double total;
  final DateTime timestamp;
  final String roomNumber;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.timestamp,
    required this.roomNumber,
    required this.items,
  });

  factory Order.fromMap(String id, Map<String, dynamic> data) {
    return Order(
      id: id,
      status: data['status'] as String,
      total: (data['total'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      roomNumber: data['roomNumber'] as String,
      items: (data['items'] as List)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}