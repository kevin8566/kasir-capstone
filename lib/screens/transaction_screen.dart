import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';
import '../widgets/cashier_layout.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<ProductModel> _products = [];
  List<TransactionModel> _recentTransactions = [];
  final List<CartItem> _cart = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  double _discount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await SupabaseService.getProducts();
      final transactions = await SupabaseService.getTransactions();
      setState(() {
        _products = products;
        _recentTransactions = transactions.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['Semua', ...cats];
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool _showPaymentSelection = false;

  // ── LOGIKA VALIDASI KERANJANG (DIUBAH) ──────────────────────────
  void _addToCart(ProductModel product) {
    if (product.stock <= 0) return; // Validasi Lapis 1: Stok habis

    setState(() {
      _showPaymentSelection = false;
      final existing = _cart.indexWhere((c) => c.product.id == product.id);
      
      // Validasi Lapis 2: Cegah penambahan jika melebihi stok
      final currentQtyInCart = existing != -1 ? _cart[existing].quantity : 0;
      if (currentQtyInCart >= product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok ${product.name} tidak mencukupi! (Sisa: ${product.stock})'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (existing != -1) {
        _cart[existing].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _showPaymentSelection = false;
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cart.remove(item);
      }
    });
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get _totalAmount => (_subtotal - _discount).clamp(0, double.infinity);

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _confirmPayment(String method) async {
    if (_cart.isEmpty) return;
    
    final transaction = TransactionModel(
      id: 'TRX-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      items: List.from(_cart),
      totalAmount: _totalAmount,
      date: DateTime.now(),
      paymentMethod: method,
      status: 'Completed',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
    );

    try {
      await SupabaseService.addTransaction(transaction);
      if (mounted) Navigator.pop(context); // Pop loading
      
      setState(() {
        _cart.clear();
        _discount = 0;
        _showPaymentSelection = false;
      });
      
      // Refresh data agar stok terbaru dan riwayat transaksi termuat
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transaksi $method Berhasil Disimpan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return CashierLayout(
      activeRoute: AppConstants.transactionRoute,
      title: 'POS Transaksi',
      child: isMobile 
        ? Column(
            children: [
              Expanded(child: _buildProductSection(isMobile)),
              if (_cart.isNotEmpty) _buildMobileCartSummary(),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Product Selection
              Expanded(
                flex: 3,
                child: _buildProductSection(isMobile),
              ),
              
              // Right Side: Cart & Payment
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade100)),
                ),
                child: _buildCartSection(),
              ),
            ],
          ),
    );
  }

  Widget _buildMobileCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_cart.length} Item', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                Text(_formatCurrency(_totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (_, scrollController) => _buildCartSection(scrollController: scrollController, isMobileSheet: true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('LIHAT KERANJANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Category
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 24),
              const Text(
                'Kategori Menu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildCategoryGrid(isMobile),
            ],
          ),
        ),
        
        // Product Grid Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: const Text(
            'Item Menu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),

        // Product Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
              : _buildProductGrid(isMobile),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Cari menu favorit...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isMobile) {
    final categoryList = _categories.take(6).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categoryList.map((cat) {
          final isSelected = _selectedCategory == cat;
          IconData icon;
          switch (cat) {
            case 'Makanan': icon = Icons.restaurant; break;
            case 'Minuman': icon = Icons.local_cafe; break;
            case 'Cemilan': icon = Icons.cookie; break;
            case 'Snack': icon = Icons.fastfood; break;
            default: icon = Icons.category_outlined;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: isMobile ? 100 : 120,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Column(
                  children: [
                    Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryBlue, size: isMobile ? 24 : 32),
                    const SizedBox(height: 8),
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGrid(bool isMobile) {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Menu tidak ditemukan', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
        childAspectRatio: isMobile ? 0.8 : 0.85,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  // ── DESAIN KARTU PRODUK DENGAN VISUAL BLOCKING (DIUBAH) ─────────
  Widget _buildProductCard(ProductModel product) {
    final isOutOfStock = product.stock <= 0;

    return InkWell(
      onTap: isOutOfStock ? null : () => _addToCart(product),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    // Filter abu-abu jika stok habis
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isOutOfStock ? Colors.grey : Colors.transparent,
                        BlendMode.saturation,
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                          : Container(
                              color: AppTheme.lightBlue,
                              width: double.infinity,
                              child: const Icon(Icons.fastfood, color: AppTheme.primaryBlue, size: 48),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatCurrency(product.price),
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          // Indikator Stok di layar
                          Text(
                            'Sisa: ${product.stock}',
                            style: TextStyle(
                              color: isOutOfStock ? Colors.red : AppTheme.textGrey,
                              fontSize: 12,
                              fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Overlay Teks "HABIS" jika stok 0
            if (isOutOfStock)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'HABIS',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection({ScrollController? scrollController, bool isMobileSheet = false}) {
    return Column(
      children: [
        if (scrollController != null) 
          Container(
            height: 4, width: 40,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_cart.isEmpty)
                      _buildEmptyCart()
                    else
                      ..._cart.map((item) => _buildCartItem(item)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildRecentTransactionsHeader(),
                  ]),
                ),
              ),
            ],
          ),
        ),
        
        _buildCartFooter(isMobileSheet),
      ],
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Transaksi Terakhir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(4)),
                child: const Text('HARI INI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentTransactions.isEmpty)
             const Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  children: ['No. Struk', 'Waktu', 'Total', 'Status'].map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  )).toList(),
                ),
                ..._recentTransactions.map((t) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(t.id.substring(t.id.length - 6), style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(DateFormat('HH:mm').format(t.date), style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_formatCurrency(t.totalAmount), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Sukses', textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('Belanjaan masih kosong', style: TextStyle(color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _formatCurrency(item.product.price),
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildQtyBtn(Icons.remove, () => _removeFromCart(item)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                // Tombol Add ini akan otomatis tertolak oleh _addToCart jika stok tidak cukup
                _buildQtyBtn(Icons.add, () => _addToCart(item.product)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(item.total),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildCartFooter(bool isMobileSheet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Column(
        children: [
          // Diskon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diskon', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
              Row(
                children: [
                  _buildQtyBtn(Icons.remove, () {
                    setState(() {
                      _showPaymentSelection = false;
                      if (_discount >= 1000) _discount -= 1000;
                    });
                  }),
                  const SizedBox(width: 8),
                  Text(_formatCurrency(_discount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildQtyBtn(Icons.add, () {
                    setState(() {
                      _showPaymentSelection = false;
                      _discount += 1000;
                    });
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL TAGIHAN', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
              Flexible(
                child: Text(
                  _formatCurrency(_totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _cart.isEmpty ? null : () => setState(() => _showPaymentSelection = !_showPaymentSelection),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(_showPaymentSelection ? 'BATAL' : 'BAYAR SEKARANG', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showPaymentSelection ? Colors.grey : AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_showPaymentSelection) ...[
            const SizedBox(height: 20),
            // Payment Methods
            Row(
              children: [
                _buildPaymentBtn('Tunai', Icons.money),
                const SizedBox(width: 12),
                _buildPaymentBtn('QRIS', Icons.qr_code),
                const SizedBox(width: 12),
                _buildPaymentBtn('Debit', Icons.credit_card),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Kasir Utama - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBtn(String label, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: _cart.isEmpty ? null : () {
            _confirmPayment(label);
            // Tutup bottom sheet di mobile jika transaksi sukses
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}