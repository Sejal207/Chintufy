import 'package:chintufy/models/cart_item.dart';
import 'package:chintufy/models/request.dart';
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
    await _db.collection('products').add(product.toFirestore());
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

  // Cart methods
  Stream<List<CartItem>> get cartItems {
    return _db
        .collection('carts')
        .doc(currentUserId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addToCart(String productId, int quantity) async {
    await _db
        .collection('carts')
        .doc(currentUserId)
        .collection('items')
        .doc(productId)
        .set({
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<void> removeFromCart(String itemId) async {
    await _db
        .collection('carts')
        .doc(currentUserId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(itemId);
    } else {
      await _db
          .collection('carts')
          .doc(currentUserId)
          .collection('items')
          .doc(itemId)
          .update({'quantity': quantity});
    }
  }

  // Request methods
  Stream<List<Request>> get requests {
    return _db.collection('requests').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Request.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addRequest(String productName) async {
    await _db.collection('requests').add({
      'productName': productName,
      'userId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}