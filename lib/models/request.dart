import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String productName;
  final String userId;
  final DateTime timestamp;
  final String status;

  Request({
    required this.id,
    required this.productName,
    required this.userId,
    required this.timestamp,
    required this.status,
  });

  factory Request.fromFirestore(Map<String, dynamic> data, String id) {
    return Request(
      id: id,
      productName: data['productName'],
      userId: data['userId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}