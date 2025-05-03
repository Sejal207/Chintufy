import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'retailer/add_product_dialog.dart';
import 'cart_page.dart';
import 'requested_items_page.dart';
import 'orders_page.dart'; // Ensure this file exists and contains the OrdersPage class

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuck Shop Chintufy'),
        actions: [
          // Requested Items button
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Requested Items',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RequestedItemsPage()),
              );
            },
          ),
          // Shopping Cart button
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  CartPage()),
              );
            },
          ),
          // Add Product button for retailer
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) =>  AddProductDialog(),
              );
            },
          ),
          // Orders button
          IconButton(
            icon: Icon(Icons.receipt_long),
            tooltip: 'Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrdersPage()),
              );
            },
          ),
          // Add some spacing before the edge of the screen
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: databaseService.products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading products: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products available'),
                ],
              ),
            );
          }
          
          final products = snapshot.data!;
          
          // Responsive grid based on screen width
          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal cross-axis count based on screen width
              final width = constraints.maxWidth;
              final crossAxisCount = width ~/ 180; // ~/ is integer division
              
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 2,
                  childAspectRatio: 0.75, // Slightly taller cards for better readability
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: products[index]);
                },
              );
            }
          );
        },
      ),
    );
  }
}