class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      imageUrl: map['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
    };
  }
}