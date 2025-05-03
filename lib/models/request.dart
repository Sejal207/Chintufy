import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String productId;
  final String productName;
  final DateTime timestamp;
  final String status;

  Request({
    required this.id,
    required this.productId,
    required this.productName,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory Request.fromMap(String id, Map<String, dynamic> map) {
    return Request(
      id: id,
      productId: map['productId'],
      productName: map['productName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'],
    );
  }
}