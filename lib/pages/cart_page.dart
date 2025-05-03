import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<CartItem>>(
      stream: databaseService.cartItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Shopping Cart'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Shopping Cart'),
            ),
            body: Center(child: Text('Your cart is empty')),
          );
        }

        final cartItems = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Shopping Cart'),
          ),
          body: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return ListTile(
                leading: item.product.imageUrl.isNotEmpty
                    ? Image.network(item.product.imageUrl)
                    : Icon(Icons.image_not_supported),
                title: Text(item.product.name),
                subtitle: Text('₹${item.product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => databaseService.updateCartItemQuantity(
                        item.id,
                        item.quantity - 1,
                      ),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => databaseService.updateCartItemQuantity(
                        item.id,
                        item.quantity + 1,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => databaseService.removeFromCart(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: _buildCheckoutBar(context, cartItems),
        );
      },
    );
  }

  Widget _buildCheckoutBar(BuildContext context, List<CartItem> items) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ₹${total.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: items.isEmpty ? null : () {
              // Implement checkout
            },
            child: Text('Checkout'),
          ),
        ],
      ),
    );
  }
}