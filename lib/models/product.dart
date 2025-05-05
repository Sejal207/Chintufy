class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final String category;
  final double discount;
  final double? rating;
  final int? reviews;
  final Map<String, String>? specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.category,
    this.discount = 0.0,
    this.rating,
    this.reviews,
    this.specifications,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
      category: data['category'] ?? '',
      discount: data['discount']?.toDouble() ?? 0.0,
      rating: data['rating']?.toDouble(),
      reviews: data['reviews'],
      specifications: data['specifications'] != null 
          ? Map<String, String>.from(data['specifications'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'category': category,
      'discount': discount,
      'rating': rating,
      'reviews': reviews,
      'specifications': specifications,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'category': category,
      'discount': discount,
      'rating': rating,
      'reviews': reviews,
      'specifications': specifications,
    };
  }
}