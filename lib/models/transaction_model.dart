import 'product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class TransactionModel {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String paymentMethod;
  final String status;

  TransactionModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.paymentMethod,
    required this.status,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Parse items dari relasi transaction_items
    List<CartItem> items = [];
    final rawItems = map['transaction_items'];
    if (rawItems != null && rawItems is List && rawItems.isNotEmpty) {
      for (final item in rawItems) {
        final product = ProductModel(
          id: item['product_id']?.toString() ?? '',
          name: item['product_name']?.toString() ?? '-',
          category: '',
          price: (item['price'] as num?)?.toDouble() ?? 0,
          stock: 0,
          imageUrl: '',
        );
        items.add(CartItem(
          product: product,
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        ));
      }
    }

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      items: items,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      date: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      paymentMethod: map['payment_method']?.toString() ?? 'Tunai',
      status: map['status']?.toString() ?? 'Selesai',
    );
  }
}