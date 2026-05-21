import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/expense_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin/admin_sidebar.dart';

// ── FORMATTER ANGKA RIBUAN (Otomatis Titik) ────────────────────────
class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (numericOnly.isEmpty) return const TextEditingValue(text: '');
    final number = int.parse(numericOnly);
    final newText = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(number).trim();
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// ── KELAS PEMBANTU UNTUK DYNAMIC FORM BAHAN BAKU ──────────────────────
class RawMaterialItem {
  // [PERBAIKAN 1]: Mengembalikan dua baris Controller yang sempat terhapus
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  
  String unit = 'kg';

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
  }
}
// ──────────────────────────────────────────────────────────────────────

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  
  // [PERBAIKAN 2]: List<ProductModel> _products; DIHAPUS karena sudah tidak dipakai

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await SupabaseService.getExpenses();
      // [PERBAIKAN 3]: Pemanggilan SupabaseService.getProducts(); DIHAPUS agar performa lebih ringan
      setState(() {
        _expenses = expenses;
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

  // Memanggil Modal yang sudah dipisah menjadi StatefulWidget
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ExpenseModalDialog(),
    ).then((isSaved) {
      if (isSaved == true) {
        _loadData(); // Segarkan tabel jika modal sukses menyimpan
      }
    });
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
                      const Text('Buku Pengeluaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
          final isRestock = e.category == 'Bahan Baku';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isRestock ? AppTheme.lightBlue : Colors.red.shade50,
              child: Icon(isRestock ? Icons.kitchen : Icons.money_off, color: isRestock ? AppTheme.primaryBlue : Colors.red),
            ),
            title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(DateFormat('dd MMM yyyy, HH:mm').format(e.date), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                      child: Text(e.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
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

// ── KELAS MODAL TERSENDIRI (STATEFUL) UNTUK LOGIKA DYNAMIC FORM ────────
class ExpenseModalDialog extends StatefulWidget {
  const ExpenseModalDialog({super.key});

  @override
  State<ExpenseModalDialog> createState() => _ExpenseModalDialogState();
}

class _ExpenseModalDialogState extends State<ExpenseModalDialog> {
  String _selectedCategory = 'Operasional';
  final List<String> _categories = ['Operasional', 'Bahan Baku', 'Gaji Pegawai', 'Lain-lain'];
  final List<String> _unitOptions = ['kg', 'gram', 'liter', 'ml', 'pcs', 'ikat', 'pack'];
  
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  bool _isSubmitting = false;

  // List untuk menyimpan deretan form bahan baku dinamis
  final List<RawMaterialItem> _rawMaterials = [];

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    for (var item in _rawMaterials) {
      item.dispose();
    }
    super.dispose();
  }

  void _addRawMaterialRow() {
    setState(() {
      _rawMaterials.add(RawMaterialItem());
    });
  }

  void _removeRawMaterialRow(int index) {
    setState(() {
      _rawMaterials[index].dispose();
      _rawMaterials.removeAt(index);
    });
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isSubmitting = true);

    try {
      double totalAmount = double.parse(_amountController.text.replaceAll(RegExp(r'[^\d]'), ''));
      
      // Menggabungkan deskripsi utama dengan rincian bahan baku (jika ada)
      String finalDescription = _descController.text;
      if (_selectedCategory == 'Bahan Baku' && _rawMaterials.isNotEmpty) {
        List<String> details = _rawMaterials
            .where((item) => item.nameCtrl.text.isNotEmpty && item.qtyCtrl.text.isNotEmpty)
            .map((item) => "${item.nameCtrl.text} (${item.qtyCtrl.text} ${item.unit})")
            .toList();
            
        if (details.isNotEmpty) {
          finalDescription += "\n[Rincian: ${details.join(', ')}]";
        }
      }

      final expense = ExpenseModel(
        id: 'EXP-${const Uuid().v4().substring(0, 8).toUpperCase()}',
        description: finalDescription.trim().isEmpty ? 'Pengeluaran $_selectedCategory' : finalDescription,
        amount: totalAmount,
        date: DateTime.now(),
        category: _selectedCategory,
      );

      await SupabaseService.addExpense(expense);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pengeluaran dicatat!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Tutup dan kembalikan nilai 'true'
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsivitas Lebar Modal
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 800 ? 650.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Modal
            Row(
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
            const SizedBox(height: 24),
            
            // Area Scroll (Jika form bertambah banyak tidak tertutup layar)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dropdown Kategori
                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppTheme.backgroundGrey,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val!;
                          if (_selectedCategory != 'Bahan Baku') {
                            _rawMaterials.clear();
                          } else if (_rawMaterials.isEmpty) {
                            _addRawMaterialRow(); // Langsung tambah 1 baris kosong
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 2. ── DYNAMIC FORM BAHAN BAKU ─────────────────────────────
                    if (_selectedCategory == 'Bahan Baku') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey.withOpacity(0.6), // Soft grey background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.kitchen, size: 18, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('Daftar Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_rawMaterials.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('Belum ada bahan baku ditambahkan', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _rawMaterials.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _rawMaterials[index];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nama Bahan Baku (Kiri, Lebih Lebar / flex 5)
                                      Expanded(
                                        flex: 5,
                                        child: TextField(
                                          controller: item.nameCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'Nama Bahan Baku',
                                            hintText: 'Misal: Bawang Putih',
                                            isDense: true,
                                            filled: true, fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Jumlah / Takaran (Tengah / flex 3)
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: item.qtyCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Jumlah',
                                            hintText: '10',
                                            isDense: true,
                                            filled: true, fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Dropdown Satuan (Kanan / flex 3)
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          height: 48, // Menyamakan tinggi dengan TextField isDense
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(8)
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: item.unit,
                                              isExpanded: true,
                                              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
                                              items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                              onChanged: (val) {
                                                if (val != null) setState(() => item.unit = val);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Tombol Hapus (Ujung Kanan)
                                      IconButton(
                                        onPressed: () => _removeRawMaterialRow(index),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Hapus baris',
                                      )
                                    ],
                                  );
                                },
                              ),

                            const SizedBox(height: 16),
                            // Tombol Tambah Bahan Baku (Full Width)
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: OutlinedButton.icon(
                                onPressed: _addRawMaterialRow,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Bahan Baku', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryBlue,
                                  side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // ────────────────────────────────────────────────────────────

                    // 3. Deskripsi Umum
                    const Text('Deskripsi Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: _selectedCategory == 'Bahan Baku' ? 'Misal: Belanja sayur di pasar pagi...' : 'Misal: Bayar Listrik Bulan Ini',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppTheme.backgroundGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Total Biaya (Rp)
                    const Text('Total Biaya (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [NumericTextFormatter()], // Menggunakan formatter otomatis
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppTheme.backgroundGrey,
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tombol Aksi (Batal & Simpan)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}