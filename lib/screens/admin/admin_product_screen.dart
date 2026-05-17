import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin/admin_sidebar.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  bool _isLoading = true;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await SupabaseService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  // ── LOGIKA CRUD & FORM UI ───────────────────────────────────────
  
  void _showProductForm({ProductModel? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product.name : '');
    final priceCtrl = TextEditingController(text: isEdit ? product.price.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: isEdit ? product.stock.toString() : '');
    final imageCtrl = TextEditingController(text: isEdit && !product.imageUrl.contains('placehold') ? product.imageUrl : '');
    String selectedCategory = isEdit ? product.category : 'Makanan';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.add_box, color: AppTheme.primaryBlue),
                const SizedBox(width: 10),
                Text(isEdit ? 'Edit Menu' : 'Tambah Menu Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450, // Diperlebar sedikit agar UI gambar lebih proporsional
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl, 
                      decoration: InputDecoration(labelText: 'Nama Menu', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: ['Makanan', 'Minuman', 'Snack'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.attach_money)))),
                        const SizedBox(width: 16),
                        Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.inventory_2_outlined)))),
                      ],
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.only(top: 24, bottom: 12),
                      child: Text('Gambar Produk (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),

                    // ── AREA DUAL INPUT GAMBAR (URL ATAU UPLOAD) ──
                    TextField(
                      controller: imageCtrl, 
                      decoration: InputDecoration(
                        labelText: 'Opsi 1: Paste URL Gambar', 
                        hintText: 'https://...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.link)
                      )
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: Text('ATAU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5))),
                    ),
                    
                    InkWell(
                      onTap: () {
                        // Tampilkan info transisi ke Supabase Storage
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⏳ Fitur Upload File (Galeri/Kamera) akan diaktifkan setelah integrasi Supabase Storage di Fase 2. Sementara, silakan pakai URL.'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 4),
                          )
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey,
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryBlue, size: 32),
                            const SizedBox(height: 8),
                            const Text('Opsi 2: Klik untuk Upload File', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            Text('(Tersedia setelah integrasi Cloud)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                    // ──────────────────────────────────────────────
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama, Harga, dan Stok wajib diisi!'), backgroundColor: Colors.red));
                    return;
                  }

                  Navigator.pop(ctx); 
                  setState(() => _isLoading = true);

                  final newProduct = ProductModel(
                    id: isEdit ? product.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    category: selectedCategory,
                    price: double.parse(priceCtrl.text),
                    stock: int.parse(stockCtrl.text),
                    // Gunakan URL default jika kosong
                    imageUrl: imageCtrl.text.isEmpty ? 'https://placehold.co/400x400/eeeeee/999999?text=Sedap+POS' : imageCtrl.text,
                  );

                  if (isEdit) {
                    await SupabaseService.updateProduct(newProduct);
                  } else {
                    await SupabaseService.addProduct(newProduct);
                  }
                  
                  _fetchProducts(); 
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Menu diperbarui!' : 'Menu ditambahkan!'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                ),
                child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}" dari sistem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await SupabaseService.deleteProduct(product.id);
              _fetchProducts();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil dihapus'), backgroundColor: Colors.red));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('YA, HAPUS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatIDR(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(activeRoute: '/admin/products'),
          
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 80, padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Manajemen Menu & Stok (Admin)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      ElevatedButton.icon(
                        onPressed: () => _showProductForm(), 
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('TAMBAH MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final p = _products[index];
                            final isLowStock = p.stock < 10;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundGrey, borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Kategori: ${p.category}  •  Harga: ${_formatIDR(p.price)}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue), onPressed: () => _showProductForm(product: p), tooltip: 'Edit Menu'),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(p), tooltip: 'Hapus Menu'),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('STOK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green)),
                                        Text('${p.stock}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}