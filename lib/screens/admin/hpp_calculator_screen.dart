import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [BARU] Wajib ditambahkan untuk TextInputFormatter
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin/admin_sidebar.dart';

// ── [BARU] FORMATTER OTOMATIS RIBUAN (TITIK) ──────────────────────
class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua karakter selain angka (membuang titik yang sudah ada)
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (numericOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format kembali angkanya dengan titik ribuan gaya Indonesia
    final number = int.parse(numericOnly);
    final newText = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(number).trim();

    // Pastikan posisi kursor selalu berada di ujung kanan agar ketikan nyaman
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
// ─────────────────────────────────────────────────────────────────

class IngredientItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(); 
  final TextEditingController costController = TextEditingController();
  final TextEditingController costPerPortionController = TextEditingController(); 
  String unit = 'gram'; 

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    costController.dispose();
    costPerPortionController.dispose();
  }
}

class ProductionItem {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
  ProductModel? selectedProduct;
  
  List<IngredientItem> ingredients = [IngredientItem()]; 
  
  final TextEditingController portionController = TextEditingController();
  final TextEditingController marginController = TextEditingController();
  final TextEditingController finalPriceController = TextEditingController(); 

  List<Map<String, dynamic>>? baseRecipe;
  bool isAutoRecipe = true; 
  int lastPortion = 0; 

  double calculatedHPP = 0;
  double finalPrice = 0;
  double totalIngredientCost = 0; 

  void dispose() {
    for (var ing in ingredients) { ing.dispose(); }
    portionController.dispose();
    marginController.dispose();
    finalPriceController.dispose(); 
  }
}

class HppCalculatorScreen extends StatefulWidget {
  const HppCalculatorScreen({super.key});

  @override
  State<HppCalculatorScreen> createState() => _HppCalculatorScreenState();
}

class _HppCalculatorScreenState extends State<HppCalculatorScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<ProductModel> _products = [];
  List<ProductionItem> _formItems = [];

  final List<String> _unitOptions = ['kg', 'ons', 'gram', 'liter', 'ml', 'pcs'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (var item in _formItems) { item.dispose(); }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await SupabaseService.getProducts();
      final cache = SupabaseService.getProductionHistoryCache();
      
      setState(() {
        _products = products;
        _formItems.clear();

        if (cache.isNotEmpty) {
          for (var cachedItem in cache) {
            final newItem = ProductionItem();
            
            newItem.selectedProduct = _products.firstWhere(
              (p) => p.id == cachedItem['productId'],
              orElse: () => _products.first,
            );
            
            newItem.portionController.text = cachedItem['portions']?.toString() ?? '';
            // [PERBAIKAN] Hapus titik saat parse dari string ke angka
            newItem.lastPortion = int.tryParse(newItem.portionController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0; 
            newItem.marginController.text = cachedItem['margin']?.toString() ?? '';
            newItem.isAutoRecipe = cachedItem['isAutoRecipe'] ?? false; 
            
            SupabaseService.getRecipeForProduct(newItem.selectedProduct!.id).then((recipe) {
              newItem.baseRecipe = recipe;
            });

            newItem.ingredients.clear();
            
            final rawIngredients = cachedItem['ingredients'];
            if (rawIngredients != null && rawIngredients is List) {
              for (var cachedIng in rawIngredients) {
                if (cachedIng is Map) {
                  final ing = IngredientItem();
                  ing.nameController.text = cachedIng['name']?.toString() ?? '';
                  ing.qtyController.text = cachedIng['qty']?.toString() ?? ''; 
                  
                  final loadedUnit = cachedIng['unit']?.toString() ?? 'gram';
                  ing.unit = _unitOptions.contains(loadedUnit) ? loadedUnit : 'gram';
                  
                  ing.costController.text = cachedIng['cost']?.toString() ?? '';
                  newItem.ingredients.add(ing);
                }
              }
            }
            
            if (newItem.ingredients.isEmpty) newItem.ingredients.add(IngredientItem());
            
            _formItems.add(newItem);
            _calculateLive(newItem); 
          }
        } else {
          _formItems.add(ProductionItem());
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyBaseRecipe(ProductionItem item) {
    if (item.baseRecipe == null || !item.isAutoRecipe) return;

    // [PERBAIKAN] Pastikan membersihkan titik jika ada
    int portions = int.tryParse(item.portionController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
    if (portions < 1) portions = 1;

    item.ingredients.clear();

    for (var baseIng in item.baseRecipe!) {
      final ing = IngredientItem();
      ing.nameController.text = baseIng['name'];
      ing.unit = baseIng['unit'];

      double scaledQty = (baseIng['baseQty'] * portions).toDouble();
      // Tulis dengan titik otomatis
      ing.qtyController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(scaledQty).trim();

      double scaledCost = (baseIng['baseCost'] * portions).toDouble();
      // Tulis dengan titik otomatis
      ing.costController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(scaledCost).trim();

      item.ingredients.add(ing);
    }
  }

  void _handlePortionChange(ProductionItem item, String value) {
    // [PERBAIKAN] Bersihkan pemisah titik terlebih dahulu
    int newPortion = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    if (newPortion > 0) {
      if (item.baseRecipe != null && item.isAutoRecipe) {
        _applyBaseRecipe(item);
      } else {
        if (item.lastPortion > 0 && newPortion != item.lastPortion) {
          double ratio = newPortion / item.lastPortion;
          
          for (var ing in item.ingredients) {
            // [PERBAIKAN] Bersihkan titik pada string agar takaran bisa dihitung
            double currentQty = double.tryParse(ing.qtyController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
            double currentCost = double.tryParse(ing.costController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

            if (currentQty > 0) {
              double scaledQty = currentQty * ratio;
              ing.qtyController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(scaledQty).trim();
            }
            if (currentCost > 0) {
              double scaledCost = currentCost * ratio;
              ing.costController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(scaledCost).trim();
            }
          }
        }
      }
      item.lastPortion = newPortion; 
    } else {
      item.lastPortion = 0; 
    }

    _calculateLive(item);
  }

  void _calculateLive(ProductionItem item) {
    // [PERBAIKAN] Bersihkan titik pada Porsi
    final int portions = int.tryParse(item.portionController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    
    double sumCost = 0;
    for (var ing in item.ingredients) {
      // Harga Total sudah dibersihkan sebelumnya
      double ingCost = double.tryParse(ing.costController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      sumCost += ingCost;
      
      if (portions > 0) {
        double costPerPortion = ingCost / portions;
        ing.costPerPortionController.text = _formatIDR(costPerPortion);
      } else {
        ing.costPerPortionController.text = ''; 
      }
    }
    
    item.totalIngredientCost = sumCost;
    final double margin = double.tryParse(item.marginController.text) ?? 0;

    setState(() {
      if (portions > 0) {
        item.calculatedHPP = item.totalIngredientCost / portions;
        item.finalPrice = item.calculatedHPP + (item.calculatedHPP * (margin / 100));
      } else {
        item.calculatedHPP = 0;
        item.finalPrice = 0;
      }
      
      if (item.finalPrice > 0) {
        item.finalPriceController.text = _formatIDR(item.finalPrice);
      } else {
        item.finalPriceController.text = ''; 
      }
    });
  }

  void _addNewProductForm() {
    setState(() { _formItems.add(ProductionItem()); });
  }

  void _removeProductForm(int index) {
    if (_formItems.length > 1) {
      setState(() {
        _formItems[index].dispose();
        _formItems.removeAt(index);
      });
    }
  }

  void _addIngredient(ProductionItem item) {
    setState(() { item.ingredients.add(IngredientItem()); });
  }

  void _removeIngredient(ProductionItem item, int ingIndex) {
    if (item.ingredients.length > 1) {
      setState(() {
        item.ingredients[ingIndex].dispose();
        item.ingredients.removeAt(ingIndex);
      });
      _calculateLive(item); 
    }
  }

  String _formatIDR(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Future<void> _submitBatchData() async {
    List<ProductionItem> validItems = _formItems.where((item) => 
      item.selectedProduct != null && item.calculatedHPP > 0
    ).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data produksi minimal 1 produk!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> currentCache = [];
      for (var item in _formItems) {
        if (item.selectedProduct != null) {
          List<Map<String, dynamic>> ingList = []; 
          for (var ing in item.ingredients) {
            ingList.add({
              'name': ing.nameController.text,
              'qty': ing.qtyController.text, 
              'unit': ing.unit, 
              'cost': ing.costController.text,
            });
          }
          currentCache.add({
            'productId': item.selectedProduct!.id,
            'portions': item.portionController.text,
            'margin': item.marginController.text,
            'isAutoRecipe': item.isAutoRecipe,
            'ingredients': ingList,
          });
        }
      }
      SupabaseService.updateProductionHistoryCache(currentCache);

      for (var item in validItems) {
        // [PERBAIKAN] Buang titik
        final int portions = int.tryParse(item.portionController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;

        List<Map<String, dynamic>> generatedMasterRecipe = [];
        for (var ing in item.ingredients) {
           // [PERBAIKAN] Buang titik dari angka takaran dan biaya
           double currentQty = double.tryParse(ing.qtyController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
           double currentCost = double.tryParse(ing.costController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

           generatedMasterRecipe.add({
             'name': ing.nameController.text,
             'baseQty': currentQty / portions, 
             'unit': ing.unit,
             'baseCost': currentCost / portions, 
           });
        }
        
        await SupabaseService.updateMasterRecipe(item.selectedProduct!.id, generatedMasterRecipe);

        await SupabaseService.submitProductionCosting(
          productId: item.selectedProduct!.id,
          totalCost: item.totalIngredientCost,
          generatedPortions: portions,
          newSellingPrice: item.finalPrice,
          calculatedHPP: item.calculatedHPP,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Produksi Selesai! Resep baru otomatis tersimpan di Sistem Master.'), backgroundColor: Colors.green));
      }

      setState(() {
        _isSubmitting = false; 
      });

    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(activeRoute: '/admin/hpp'),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildHeader(),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4, 
                              child: ListView.separated(
                                itemCount: _formItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 24),
                                itemBuilder: (ctx, index) => _buildProductionCard(index),
                              ),
                            ),
                            
                            const SizedBox(width: 32),

                            Expanded(
                              flex: 2,
                              child: _buildLargeSimulationPanel(),
                            )
                          ],
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

  Widget _buildHeader() {
    return Container(
      height: 80, padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.precision_manufacturing, color: AppTheme.primaryBlue, size: 28),
              SizedBox(width: 12),
              Text('Batch Produksi & Kalkulator HPP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _addNewProductForm,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('TAMBAH BARIS PRODUKSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionCard(int index) {
    final item = _formItems[index];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRODUK #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13, letterSpacing: 1.1)),
              if (_formItems.length > 1)
                IconButton(onPressed: () => _removeProductForm(index), icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 22)),
            ],
          ),
          const Divider(height: 32),
          
          DropdownButtonFormField<ProductModel>(
            value: item.selectedProduct,
            hint: const Text('Pilih Menu yang diproduksi...'),
            decoration: InputDecoration(
              labelText: 'Pilih Produk',
              prefixIcon: const Icon(Icons.restaurant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
              filled: true, fillColor: Colors.white
            ),
            items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (val) async { 
              if (val == null) return;
              setState(() { item.selectedProduct = val; });
              
              final recipe = await SupabaseService.getRecipeForProduct(val.id);
              setState(() {
                item.baseRecipe = recipe;
                item.isAutoRecipe = true; 
                if (recipe != null) _applyBaseRecipe(item);
              });
              
              _calculateLive(item); 
            },
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.kitchen, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Rincian Bahan Mentah (Resep)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    if (item.baseRecipe != null)
                      Row(
                        children: [
                          const Text('Auto-Skala Resep', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                          Switch(
                            value: item.isAutoRecipe,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setState(() { item.isAutoRecipe = val; });
                              if (val) {
                                _applyBaseRecipe(item);
                                _calculateLive(item);
                              }
                            },
                          ),
                        ],
                      )
                  ],
                ),
                const SizedBox(height: 16),
                
                ...List.generate(item.ingredients.length, (ingIndex) {
                  final ing = item.ingredients[ingIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4, 
                          child: TextField(
                            controller: ing.nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Bahan',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true, fillColor: Colors.white
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: ing.qtyController,
                            onChanged: (_) => _calculateLive(item),
                            keyboardType: TextInputType.number,
                            inputFormatters: [NumericTextFormatter()], // <== [BARU] Menerapkan Auto-Titik
                            decoration: InputDecoration(
                              labelText: 'Berat/Takaran',
                              hintText: '100',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true, fillColor: Colors.white,
                              suffixIcon: Container(
                                padding: const EdgeInsets.only(right: 6, left: 6),
                                decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ing.unit,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                    isDense: true,
                                    items: _unitOptions.map((String u) => DropdownMenuItem<String>(value: u, child: Text(u, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => ing.unit = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: ing.costController,
                            onChanged: (_) => _calculateLive(item), 
                            keyboardType: TextInputType.number,
                            inputFormatters: [NumericTextFormatter()], // <== [BARU] Menerapkan Auto-Titik
                            decoration: InputDecoration(
                              labelText: 'Harga Total',
                              prefixText: 'Rp ',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true, fillColor: Colors.white
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: ing.costPerPortionController,
                            readOnly: true, 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            decoration: InputDecoration(
                              labelText: 'Harga / Porsi',
                              isDense: true,
                              filled: true, 
                              fillColor: AppTheme.primaryBlue.withOpacity(0.05), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        
                        if (item.ingredients.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeIngredient(item, ingIndex),
                          )
                        else
                          const SizedBox(width: 40), 
                      ],
                    ),
                  );
                }),
                
                TextButton.icon(
                  onPressed: () => _addIngredient(item),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Bahan Mentah Manual', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Biaya Bahan:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(_formatIDR(item.totalIngredientCost), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.portionController,
                  onChanged: (val) {
                    setState(() {
                      _handlePortionChange(item, val);
                    });
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [NumericTextFormatter()], // <== [BARU] Sekalian diterapkan di Porsi
                  decoration: InputDecoration(
                    labelText: 'Porsi Jadi',
                    hintText: 'Misal: 50',
                    prefixIcon: const Icon(Icons.restaurant_menu),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: item.marginController,
                  onChanged: (_) => _calculateLive(item),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Margin (%)',
                    hintText: 'Misal: 60',
                    prefixIcon: const Icon(Icons.trending_up),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          TextField(
            controller: item.finalPriceController,
            readOnly: true, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
            decoration: InputDecoration(
              labelText: 'Harga Jual per Porsi (Hasil Kalkulasi Otomatis)',
              prefixIcon: const Icon(Icons.sell_outlined, color: Colors.orange),
              filled: true,
              fillColor: Colors.orange.withOpacity(0.05), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: Colors.orange.withOpacity(0.5))
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: const BorderSide(color: Colors.orange)
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildLargeSimulationPanel() {
    double totalBatchCost = 0;
    for(var item in _formItems) {
       totalBatchCost += item.totalIngredientCost;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)], 
          begin: Alignment.topCenter, 
          end: Alignment.bottomCenter
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LIVE SIMULATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                    Text('Rangkuman Produksi (${_formItems.length} Item)', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              itemCount: _formItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 32),
              itemBuilder: (ctx, idx) {
                final it = _formItems[idx];
                final hasData = it.selectedProduct != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.selectedProduct?.name ?? 'PRODUK #${idx + 1} BELUM DIPILIH', 
                      style: TextStyle(
                        color: hasData ? Colors.white : Colors.white38, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 15
                      )
                    ),
                    const SizedBox(height: 12),
                    _buildSimRow('Modal/Porsi (HPP)', _formatIDR(it.calculatedHPP), Colors.white70),
                    const SizedBox(height: 8),
                    _buildSimRow('Harga Jual Baru', _formatIDR(it.finalPrice), Colors.orangeAccent, isLarge: true),
                  ],
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Biaya Produksi', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(_formatIDR(totalBatchCost), style: const TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitBatchData,
                    icon: _isSubmitting 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                      : const Icon(Icons.save_outlined, color: Colors.white, size: 26),
                    label: const Text('SIMPAN SEMUA DATA KE SISTEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.black38
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

  Widget _buildSimRow(String label, String value, Color color, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(
          value, 
          style: TextStyle(
            color: color, 
            fontWeight: isLarge ? FontWeight.bold : FontWeight.w600, 
            fontSize: isLarge ? 18 : 14
          )
        ),
      ],
    );
  }
}