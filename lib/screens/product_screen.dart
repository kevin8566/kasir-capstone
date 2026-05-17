import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import '../widgets/cashier_layout.dart';
import '../widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<ProductModel> _products = [];
  String _search = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await SupabaseService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    }
  }

  List<ProductModel> get _filtered {
    if (_search.isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  String _cleanAngka(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }

  // ── Upload foto ke Supabase Storage ─────────────────────────────
  Future<String?> _uploadImage(Uint8List bytes, String fileName) async {
    try {
      // [MODIFIKASI AMAN] Cek apakah Supabase sudah diinisialisasi
      // Jika error (karena sedang pakai mock data), kita berikan simulasi upload
      try {
        Supabase.instance.client;
      } catch (_) {
        // Simulasi delay upload jaringan
        await Future.delayed(const Duration(seconds: 2));
        // Kembalikan URL gambar dummy agar aplikasi tidak crash
        return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
      }

      // Logika asli jika Supabase sudah terhubung
      final path = 'products/$fileName';
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  // ── Dialog Tambah / Edit Produk ──────────────────────────────────
  void _showProductDialog({ProductModel? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final priceCtrl = TextEditingController(
      text: product != null
          ? product.price
              .toStringAsFixed(0)
              .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]}.')
          : '',
    );
    final stockCtrl = TextEditingController(text: product?.stock.toString() ?? '');
    final isEdit = product != null;

    Uint8List? selectedImageBytes;
    String? selectedFileName;
    String? currentImageUrl = product?.imageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit : Icons.add,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(isEdit ? 'Edit Produk' : 'Tambah Produk',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Foto Produk ──────────────────────────────
                const Text('Foto Produk',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setDialogState(() {
                        selectedImageBytes = bytes;
                        selectedFileName = '${const Uuid().v4()}_${picked.name}';
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: selectedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: currentImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (_, __, ___) => _photoPlaceholder(),
                                ),
                              )
                            : _photoPlaceholder(),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Ketuk untuk pilih foto dari galeri',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textGrey.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Nama Produk ──────────────────────────────
                _buildLabel('Nama Produk'),
                const SizedBox(height: 6),
                _buildField(nameCtrl, 'Contoh: Paracetamol 500mg',
                    Icons.inventory_2_outlined),

                const SizedBox(height: 12),

                // ── Kategori ─────────────────────────────────
                _buildLabel('Kategori'),
                const SizedBox(height: 6),
                _buildField(categoryCtrl, 'Contoh: Obat, Minuman, Makanan',
                    Icons.category_outlined),

                const SizedBox(height: 12),

                // ── Harga ────────────────────────────────────
                _buildLabel('Harga (Rp)'),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final clean = _cleanAngka(val);
                    final formatted = clean.isEmpty
                        ? ''
                        : int.parse(clean).toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]}.');
                    if (formatted != val) {
                      priceCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: _inputDecoration('Contoh: 15.000', Icons.attach_money),
                ),

                const SizedBox(height: 12),

                // ── Stok ─────────────────────────────────────
                _buildLabel('Stok'),
                const SizedBox(height: 6),
                _buildField(stockCtrl, 'Jumlah stok tersedia', Icons.numbers,
                    keyboard: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      setDialogState(() => isUploading = true);

                      String imageUrl = currentImageUrl ?? '';

                      // Upload foto jika ada yang dipilih
                      if (selectedImageBytes != null && selectedFileName != null) {
                        final uploadedUrl =
                            await _uploadImage(selectedImageBytes!, selectedFileName!);
                        if (uploadedUrl != null) imageUrl = uploadedUrl;
                      }

                      // Harga: hapus titik, ambil angka saja
                      final hargaBersih =
                          double.tryParse(_cleanAngka(priceCtrl.text)) ?? 0;

                      final newProduct = ProductModel(
                        id: product?.id ?? const Uuid().v4(),
                        name: nameCtrl.text,
                        category: categoryCtrl.text,
                        price: hargaBersih,
                        stock: int.tryParse(stockCtrl.text) ?? 0,
                        imageUrl: imageUrl,
                      );

                      try {
                        if (isEdit) {
                          await SupabaseService.updateProduct(newProduct);
                        } else {
                          await SupabaseService.addProduct(newProduct);
                        }
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _loadProducts();
                        }
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan' : 'Tambah',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo,
            size: 36, color: AppTheme.primaryBlue.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text('Tambah Foto',
            style: TextStyle(
                color: AppTheme.primaryBlue.withOpacity(0.7), fontSize: 13)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      filled: true,
      fillColor: AppTheme.backgroundGrey,
    );
  }

  void _deleteProduct(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?'),
        content: const Text('Produk ini akan dihapus secara permanen dari database.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deleteProduct(id);
                _loadProducts();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return CashierLayout(
      activeRoute: AppConstants.productRoute,
      title: 'Kelola Produk',
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showProductDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('Total: ${_products.length} Produk', AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  _buildChip('Stok Rendah: ${_products.where((p) => p.stock <= 5).length}', Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                  : _filtered.isEmpty
                      ? const Center(child: Text('Tidak ada produk'))
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          color: AppTheme.primaryBlue,
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => ProductCard(
                              product: _filtered[i],
                              showActions: true,
                              onEdit: () => _showProductDialog(product: _filtered[i]),
                              onDelete: () => _deleteProduct(_filtered[i].id),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}