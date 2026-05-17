import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';
import '../widgets/cashier_layout.dart';
import '../widgets/custom_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> _allTransactions = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await SupabaseService.getTransactions();
      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<TransactionModel> get _filtered {
    return _allTransactions.where((t) {
      return t.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             t.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // ── [TAMBAHAN] Logika Pop-up Detail Struk (Receipt) ─────────────
  void _showTransactionDetail(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400, // Lebar ideal untuk meniru kertas struk kasir
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Struk
              const Icon(Icons.receipt_long, size: 48, color: AppTheme.primaryBlue),
              const SizedBox(height: 12),
              const Text('SEDAP POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
              const Text('Struk Pembelian', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              const SizedBox(height: 16),
              
              // Info Waktu & ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ID: ${transaction.id.substring(transaction.id.length - 8)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(DateFormat('dd MMM yyyy, HH:mm').format(transaction.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Divider(thickness: 1.5, height: 32),

              // Daftar Item yang dibeli
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: transaction.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${item.quantity}x @ ${_formatCurrency(item.product.price)}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(_formatCurrency(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),

              const Divider(thickness: 1.5, height: 32),

              // Total & Pembayaran
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Metode Pembayaran', style: TextStyle(color: AppTheme.textGrey)),
                  Text(transaction.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL BELANJA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_formatCurrency(transaction.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                ],
              ),

              const SizedBox(height: 32),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('TUTUP', style: TextStyle(color: AppTheme.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🖨️ Mencetak struk ke printer kasir...'), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.print, color: Colors.white, size: 18),
                      label: const Text('CETAK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return CashierLayout(
      activeRoute: AppConstants.historyRoute,
      title: 'Riwayat Transaksi',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderActions(isMobile),
                  const SizedBox(height: 24),
                  Expanded(child: _buildTransactionList(isMobile)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderActions(bool isMobile) {
    return isMobile 
      ? Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Cari Transaksi...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'REFRESH',
              onPressed: _loadData,
              icon: Icons.refresh,
              width: double.infinity,
            ),
          ],
        )
      : Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari ID Transaksi atau Metode...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            CustomButton(
              label: 'REFRESH',
              onPressed: _loadData,
              icon: Icons.refresh,
              width: 140,
            ),
          ],
        );
  }

  Widget _buildTransactionList(bool isMobile) {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text('Tidak ada riwayat transaksi', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.builder(
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final t = _filtered[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell( // [DIUBAH] Membuat kartu bisa diklik
              onTap: () => _showTransactionDetail(t),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.id.substring(t.id.length - 8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_formatCurrency(t.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM, HH:mm').format(t.date), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        const Icon(Icons.payment, size: 14, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Text(t.paymentMethod, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('COMPLETED', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('ID TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey))),
                Expanded(child: Text('WAKTU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey))),
                Expanded(child: Text('METODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey))),
                Expanded(child: Text('TOTAL', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey))),
                SizedBox(width: 40),
                Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final t = _filtered[index];
                return InkWell( // [DIUBAH] Membuat baris tabel bisa diklik
                  onTap: () => _showTransactionDetail(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(t.id.substring(t.id.length - 8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(child: Text(DateFormat('dd MMM, HH:mm').format(t.date), style: const TextStyle(fontSize: 13))),
                        Expanded(child: Text(t.paymentMethod, style: const TextStyle(fontSize: 13))),
                        Expanded(child: Text(_formatCurrency(t.totalAmount), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 14))),
                        const SizedBox(width: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('COMPLETED', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}