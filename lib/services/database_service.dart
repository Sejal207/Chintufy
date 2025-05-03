import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products
  Stream<List<Product>> get products {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new product
  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toFirestore());
  }

  // Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    await _firestore.collection('products').doc(productId).update({
      'stock': newStock,
    });
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }
}