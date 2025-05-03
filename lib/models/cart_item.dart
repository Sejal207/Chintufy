import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      product: Product.fromFirestore(data['product'], data['productId']),
      quantity: data['quantity'],
    );
  }
   factory CartItem.fromMap(String id, Map<String, dynamic> data) {
    return CartItem(
      id: id,
      product: Product.fromFirestore(data['product'] as Map<String, dynamic>, id),
      quantity: data['quantity'] as int,
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      'productId': product.id,
      'product': product.toFirestore(),
      'quantity': quantity,
    };
  }
}





