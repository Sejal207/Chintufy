import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database_service.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!, width: 0.5),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: _buildProductImage(),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 22.0, 
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Product Price
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0, 
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stock and Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock Indicator
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 20, // Increased from 14 to 20
                              color: product.stock > 0 ? Colors.black54 : Colors.grey[400],
                            ),
                            const SizedBox(width: 4), // Increased from 2 to 4 for better spacing
                            Flexible(
                              child: Text(
                                product.stock > 0 ? '${product.stock}' : 'Out',
                                style: TextStyle(
                                  fontSize: 16, // Increased from 12 to 16
                                  color: product.stock > 0 ? Colors.black54 : Colors.grey[400],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons Container - fixed width to avoid overflow
                      Container(
                        height: 24,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Remove Stock Button
                            _buildIconButton(
                              Icons.remove,
                              () {
                                if (product.stock > 0) {
                                  databaseService.updateProductStock(
                                    product.id, product.stock - 1);
                                }
                              },
                              enabled: product.stock > 0,
                            ),
                            // Add Stock Button
                            _buildIconButton(
                              Icons.add,
                              () => databaseService.updateProductStock(
                                product.id, product.stock + 1),
                            ),
                            // More Options Menu
                            _buildPopupMenu(context, databaseService),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onPressed, {bool enabled = true}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: 24), // Increased from 14 to 18
        onPressed: enabled ? onPressed : null,
        color: enabled ? Colors.black54 : Colors.grey[300],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, DatabaseService databaseService) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 24, color: Colors.black54), // Increased from 16 to 20
      tooltip: 'More options',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          height: 36, // Smaller height
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.black54, size: 16),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'delete') {
          final confirmed = await _showDeleteConfirmation(context);
          if (confirmed == true) {
            await databaseService.deleteProduct(product.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} deleted'),
                backgroundColor: Colors.black87,
              ),
            );
          }
        }
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[50],
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.black87)),
        content: Text(
          'Are you sure you want to delete ${product.name}?',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[100],
        width: double.infinity,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40, color: Colors.black26),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: product.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black38),
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[100],
          child: const Center(
            child: Icon(Icons.error_outline, size: 40, color: Colors.black26),
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle/Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: mediaQuery.size.height * 0.3,
                        width: double.infinity,
                        child: _buildProductImage(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Product details
                    Text(
                      product.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price & Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStockChip(context),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description.isNotEmpty 
                          ? product.description 
                          : 'No description available.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: product.stock > 0
                          ? ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                databaseService.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                databaseService.addRequest(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Item requested'),
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notification_add),
                              label: const Text('Request Item'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.black54, width: 1),
                              ),
                            ),
                    ),
                    // Add padding at bottom to avoid being covered by system UI
                    SizedBox(height: mediaQuery.padding.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStockChip(BuildContext context) {
    final isInStock = product.stock > 0;
    final color = isInStock ? Colors.black54 : Colors.grey[400]!;
    final text = isInStock ? 'In Stock (${product.stock})' : 'Out of Stock';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}