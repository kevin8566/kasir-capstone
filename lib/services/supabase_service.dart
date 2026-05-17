import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart';

class SupabaseService {
  // ── 1. MOCK DATA DASAR ─────────────────────────────────────────────
  static final List<ProductModel> _mockProducts = [
    ProductModel(id: '1', name: 'Nasi Goreng Spesial', category: 'Makanan', price: 25000, stock: 50, imageUrl: 'https://images.unsplash.com/photo-1512058560366-cd2429598aee?w=400'),
    ProductModel(id: '2', name: 'Es Teh Manis', category: 'Minuman', price: 5000, stock: 100, imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400'),
    ProductModel(id: '3', name: 'Ayam Bakar Madu', category: 'Makanan', price: 35000, stock: 20, imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400'),
    ProductModel(id: '4', name: 'Jus Alpukat', category: 'Minuman', price: 15000, stock: 15, imageUrl: 'https://images.unsplash.com/photo-1589733901241-5e55428303f7?w=400'),
  ];

  static final List<TransactionModel> _mockTransactions = [];
  static final List<ExpenseModel> _mockExpenses = [];
  static final List<Map<String, dynamic>> _productionHistoryCache = [];

  // ── 2. BUKU RESEP MASTER (BOM) ─────────────────────────────────────
  static final Map<String, List<Map<String, dynamic>>> _mockRecipes = {
    '1': [
      {'name': 'Nasi Putih', 'baseQty': 250, 'unit': 'gram', 'baseCost': 3000},
      {'name': 'Telur', 'baseQty': 1, 'unit': 'pcs', 'baseCost': 2000},
      {'name': 'Bumbu Nasgor', 'baseQty': 20, 'unit': 'gram', 'baseCost': 1500},
    ],
    '2': [
      {'name': 'Teh Seduh', 'baseQty': 200, 'unit': 'ml', 'baseCost': 1000},
      {'name': 'Gula Pasir', 'baseQty': 30, 'unit': 'gram', 'baseCost': 500},
      {'name': 'Es Batu', 'baseQty': 1, 'unit': 'pcs', 'baseCost': 500},
    ],
    '3': [ 
      {'name': 'Ayam Potong', 'baseQty': 1, 'unit': 'pcs', 'baseCost': 15000},
      {'name': 'Bumbu Bakar Madu', 'baseQty': 50, 'unit': 'gram', 'baseCost': 3000},
      {'name': 'Kecap Manis', 'baseQty': 20, 'unit': 'ml', 'baseCost': 1000},
      {'name': 'Lalapan & Sambal', 'baseQty': 1, 'unit': 'pcs', 'baseCost': 2000},
    ],
    '4': [
      {'name': 'Alpukat', 'baseQty': 150, 'unit': 'gram', 'baseCost': 4000},
      {'name': 'Gula Cair', 'baseQty': 30, 'unit': 'ml', 'baseCost': 1000},
      {'name': 'Susu Kental Manis', 'baseQty': 40, 'unit': 'gram', 'baseCost': 1500},
      {'name': 'Es Batu', 'baseQty': 1, 'unit': 'pcs', 'baseCost': 500},
    ],
  };

  static Future<List<Map<String, dynamic>>?> getRecipeForProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockRecipes[productId];
  }

  static Future<void> updateMasterRecipe(String productId, List<Map<String, dynamic>> newBaseRecipe) async {
    _mockRecipes[productId] = newBaseRecipe;
  }

  // ── 3. STATE & CACHE MANAGEMENT ────────────────────────────────────
  static List<Map<String, dynamic>> getProductionHistoryCache() => _productionHistoryCache;
  static void updateProductionHistoryCache(List<Map<String, dynamic>> cache) {
    _productionHistoryCache.clear();
    _productionHistoryCache.addAll(cache);
  }

  // ── 4. CRUD PRODUK ─────────────────────────────────────────────────
  static Future<List<ProductModel>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_mockProducts);
  }

  static Future<void> addProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockProducts.add(product);
  }

  static Future<void> updateProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) _mockProducts[index] = product;
  }

  static Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockProducts.removeWhere((p) => p.id == id);
  }

  static Future<void> decreaseStock(String productId, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = _mockProducts[index];
      _mockProducts[index] = ProductModel(
        id: p.id, name: p.name, category: p.category, price: p.price, stock: (p.stock - quantity).clamp(0, 999999), imageUrl: p.imageUrl,
      );
    }
  }

  // ── 5. TRANSAKSI & PENGELUARAN ─────────────────────────────────────
  static Future<List<TransactionModel>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_mockTransactions);
  }

  static Future<void> addTransaction(TransactionModel transaction) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockTransactions.insert(0, transaction);
    for (final item in transaction.items) {
      await decreaseStock(item.product.id, item.quantity);
    }
  }

  static Future<List<ExpenseModel>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = List<ExpenseModel>.from(_mockExpenses)..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  static Future<void> addExpense(ExpenseModel expense) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockExpenses.add(expense);
    if (expense.category == 'Bahan Baku' && expense.linkedProductId != null && expense.addedStock != null) {
      final productIndex = _mockProducts.indexWhere((p) => p.id == expense.linkedProductId);
      if (productIndex != -1) {
        final p = _mockProducts[productIndex];
        _mockProducts[productIndex] = ProductModel(
          id: p.id, name: p.name, category: p.category, price: p.price, stock: p.stock + expense.addedStock!, imageUrl: p.imageUrl,
        );
      }
    }
  }

  static Future<double> getTotalExpenses() async {
    return _mockExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  // ── 6. DUMMY DATA GENERATOR (MENCEGAH DASHBOARD KOSONG) ────────────
  static Future<void> seedDummyData() async {
    if (_mockTransactions.isNotEmpty) return;
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      DateTime fakeDate = i < 5 ? now.subtract(Duration(hours: i * 2)) : (i < 10 ? now.subtract(Duration(days: 5, hours: i)) : now.subtract(Duration(days: 40, hours: i)));
      final product = _mockProducts[i % _mockProducts.length];
      final transactionTotal = product.price * ((i % 3) + 1);

      _mockTransactions.add(
        TransactionModel(
          id: 'TRX-DUMMY-00${15 - i}', 
          items: [], 
          totalAmount: transactionTotal, 
          date: fakeDate, 
          paymentMethod: i % 2 == 0 ? 'QRIS' : 'Tunai', 
          status: 'Completed'
        ),
      );
    }
  }

  // ── 7. FUNGSI STATISTIK UNTUK DASHBOARD ────────────────────────────
  static Future<double> getTotalSales() async {
    return _mockTransactions.fold<double>(0, (sum, t) => sum + t.totalAmount);
  }

  static Future<int> getTotalTransactions() async {
    return _mockTransactions.length;
  }

  static Future<int> getTotalProducts() async {
    return _mockProducts.length;
  }

  // ── 8. FUNGSI EKSEKUSI PRODUKSI HPP ────────────────────────────────
  static Future<void> submitProductionCosting({
    required String productId, required double totalCost, required int generatedPortions, required double newSellingPrice, required double calculatedHPP,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockExpenses.add(
      ExpenseModel(id: 'PROD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', description: 'Biaya Produksi & Bahan Baku', amount: totalCost, date: DateTime.now(), category: 'Bahan Baku')
    );
    final index = _mockProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = _mockProducts[index];
      _mockProducts[index] = ProductModel(
        id: p.id, name: p.name, category: p.category, price: newSellingPrice, stock: p.stock + generatedPortions, imageUrl: p.imageUrl,
      );
    }
  }
}