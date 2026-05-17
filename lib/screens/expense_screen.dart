import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/expense_model.dart';
import '../../models/product_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin/admin_sidebar.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await SupabaseService.getExpenses();
      final products = await SupabaseService.getProducts();
      setState(() {
        _expenses = expenses;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatIDR(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _cleanAngka(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }

  // ── LOGIKA POP-UP FORM PENGELUARAN & RESTOCK ─────────────────────
  void _showAddExpenseDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    
    String selectedCategory = 'Operasional';
    ProductModel? selectedProduct;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          
          // Kalkulasi HPP Real-time
          double currentAmount = double.tryParse(_cleanAngka(amountCtrl.text)) ?? 0;
          int addedStock = int.tryParse(stockCtrl.text) ?? 0;
          double hpp = (addedStock > 0) ? currentAmount / addedStock : 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Catat Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Kategori Pengeluaran
                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppTheme.backgroundGrey,
                      ),
                      items: ['Operasional', 'Bahan Baku', 'Gaji Pegawai', 'Lain-lain'].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                            if (val != 'Bahan Baku') {
                              selectedProduct = null;
                              stockCtrl.clear();
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Jika Bahan Baku, Tampilkan Pilihan Produk & Stok
                    if (selectedCategory == 'Bahan Baku') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_2, size: 16, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('Injeksi Stok Otomatis', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ProductModel>(
                              value: selectedProduct,
                              hint: const Text('Pilih Produk yang direstock...'),
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                filled: true, fillColor: Colors.white,
                              ),
                              items: _products.map((p) {
                                return DropdownMenuItem(value: p, child: Text(p.name));
                              }).toList(),
                              onChanged: (val) => setDialogState(() => selectedProduct = val),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setDialogState((){}), // Trigger hitung ulang HPP
                              decoration: InputDecoration(
                                labelText: 'Jumlah Porsi/Item Masuk',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                filled: true, fillColor: Colors.white,
                              ),
                            ),
                            if (hpp > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text('HPP per item: ${_formatIDR(hpp)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Deskripsi & Nominal
                    const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        hintText: selectedCategory == 'Bahan Baku' ? 'Misal: Belanja Ayam 5 Ekor di Pasar' : 'Misal: Bayar Listrik Bulan Ini',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppTheme.backgroundGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Total Biaya (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        // Format ke Rupiah saat mengetik
                        final clean = _cleanAngka(val);
                        final formatted = clean.isEmpty ? '' : int.parse(clean).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                        if (formatted != val) {
                          amountCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                        }
                        setDialogState((){}); // Trigger hitung ulang HPP
                      },
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppTheme.backgroundGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppTheme.textGrey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  final amount = double.tryParse(_cleanAngka(amountCtrl.text)) ?? 0;
                  final stock = int.tryParse(stockCtrl.text);

                  // Validasi
                  if (descCtrl.text.isEmpty || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi deskripsi dan nominal!'), backgroundColor: Colors.orange));
                    return;
                  }
                  if (selectedCategory == 'Bahan Baku' && (selectedProduct == null || stock == null || stock <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih produk dan isi jumlah stok masuk!'), backgroundColor: Colors.orange));
                    return;
                  }

                  setDialogState(() => isSubmitting = true);

                  final expense = ExpenseModel(
                    id: 'EXP-${const Uuid().v4().substring(0, 8).toUpperCase()}',
                    description: descCtrl.text,
                    amount: amount,
                    date: DateTime.now(),
                    category: selectedCategory,
                    linkedProductId: selectedProduct?.id,
                    addedStock: stock,
                    calculatedHPP: hpp > 0 ? hpp : null,
                  );

                  try {
                    await SupabaseService.addExpense(expense);
                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadData(); // Segarkan tabel
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pengeluaran dicatat & Stok diperbarui!'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isSubmitting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(activeRoute: '/admin/expense'),
          
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 80, padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Buku Pengeluaran & Injeksi Stok', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      ElevatedButton.icon(
                        onPressed: _showAddExpenseDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('CATAT PENGELUARAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Konten Tabel
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _expenses.isEmpty
                      ? _buildEmptyState()
                      : _buildExpenseTable(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada catatan pengeluaran', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildExpenseTable() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final e = _expenses[index];
          final isRestock = e.category == 'Bahan Baku' && e.linkedProductId != null;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isRestock ? AppTheme.lightBlue : Colors.red.shade50,
              child: Icon(isRestock ? Icons.inventory_2 : Icons.money_off, color: isRestock ? AppTheme.primaryBlue : Colors.red),
            ),
            title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(e.date), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                      child: Text(e.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (isRestock && e.calculatedHPP != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Stok masuk: +${e.addedStock} | HPP: ${_formatIDR(e.calculatedHPP!)}/item', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            trailing: Text('- ${_formatIDR(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
          );
        },
      ),
    );
  }
}