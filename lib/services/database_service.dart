import 'package:chintufy/models/cart_item.dart';
import 'package:chintufy/models/request.dart';
import 'package:chintufy/models/Orders.dart' as custom;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all products
  Stream<List<Product>> get products {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new product
  Future<void> addProduct(Product product) async {
    try {
      final docRef = _db.collection('products').doc();
      await docRef.set({
        'id': docRef.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'stock': product.stock,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    await _db.collection('products').doc(productId).update({
      'stock': newStock,
    });
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      throw e;
    }
  }

  // Current user ID (replace with your actual logic to get the user ID)
  String get currentUserId {
    // Example: Replace this with your authentication logic
    return 'exampleUserId'; // Replace with actual user ID retrieval logic
  }

  // Simplified Cart methods
  Stream<List<CartItem>> get cartItems {
    return _db.collection('cart').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addToCart(Product product) async {
    final cartRef = _db.collection('cart');
    final existingItem = await cartRef
        .where('productId', isEqualTo: product.id)
        .get();

    if (existingItem.docs.isNotEmpty) {
      final item = CartItem.fromMap(
          existingItem.docs.first.id, existingItem.docs.first.data());
      await cartRef.doc(item.id).update({'quantity': item.quantity + 1});
    } else {
      await cartRef.add({
        'productId': product.id,
        'product': product.toMap(),
        'quantity': 1,
      });
    }
  }

  // Add method to remove item from cart
  Future<void> removeFromCart(String itemId) async {
    await _db.collection('cart').doc(itemId).delete();
  }

  // Add method to update cart item quantity
  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(itemId);
    } else {
      await _db.collection('cart').doc(itemId).update({
        'quantity': quantity,
      });
    }
  }

  // Add method to clear the cart
  Future<void> clearCart() async {
    try {
      // Get all cart items
      final cartDocs = await _db.collection('cart').get();
      
      // Delete each cart item
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Simplified Request methods
  Stream<List<Request>> get requests {
    return _db.collection('requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addRequest(Product product) async {
    await _db.collection('requests').add({
      'productId': product.id,
      'productName': product.name,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _db
          .collection('requests')
          .doc(requestId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  // Simplified Order methods
  Stream<List<custom.Order>> get orders {
    return _db.collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => custom.Order.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> placeOrder(List<CartItem> items, String roomNumber) async {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    // Create order with simplified structure
    await _db.collection('orders').add({
      'items': items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
      }).toList(),
      'roomNumber': roomNumber,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'total': total,
    });

    // Clear cart after order is placed
    final batch = _db.batch();
    final cartDocs = await _db.collection('cart').get();
    for (var doc in cartDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}