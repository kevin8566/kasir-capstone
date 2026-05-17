import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';
import '../services/excel_service.dart'; // [TAMBAHAN] Import Excel Service
import '../widgets/cashier_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalSalesToday = 0;
  int _transactionCountToday = 0;
  List<TransactionModel> _recentTransactions = [];
  List<TransactionModel> _allTransactions = []; // [TAMBAHAN] Untuk ditarik ke Excel
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getTotalSales(),
        SupabaseService.getTotalTransactions(),
        SupabaseService.getTransactions(),
      ]);
      
      setState(() {
        _totalSalesToday = results[0] as double;
        _transactionCountToday = results[1] as int;
        _allTransactions = results[2] as List<TransactionModel>; // Simpan semua untuk Excel
        _recentTransactions = _allTransactions.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return CashierLayout(
      activeRoute: AppConstants.dashboardRoute,
      title: 'Beranda',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(isMobile),
                    SizedBox(height: isMobile ? 24 : 40),
                    _buildRecentAndInfo(isMobile),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.auto_awesome, size: isMobile ? 120 : 200, color: AppTheme.primaryBlue.withOpacity(0.03)),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildHeroContent(),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: isMobile ? 140 : 220,
                  child: Image.network(
                    'https://img.freepik.com/free-vector/cashier-working-supermarket_23-2148480371.jpg?w=400',
                    height: isMobile ? 150 : 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront, size: 150, color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(30)),
          child: const Text('STATUS: AKTIF', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Selamat Datang, Kasir!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Optimalkan pelayanan hari ini dengan sistem POS yang lebih cepat dan efisien.',
          style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.transactionRoute),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text('MULAI TRANSAKSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAndInfo(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildRecentTransactionsTable(),
          const SizedBox(height: 24),
          _buildShiftInfo(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecentTransactionsTable(),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildShiftInfo(),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transaksi Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_recentTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Belum ada transaksi hari ini', style: TextStyle(color: AppTheme.textGrey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (context, index) => Divider(height: 32, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final t = _recentTransactions[index];
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd MMM, HH:mm').format(t.date), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatCurrency(t.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        Text(t.paymentMethod, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShiftInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Shift', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.person_outline, 'Kasir Utama'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.receipt_long_outlined, '$_transactionCountToday Transaksi Hari Ini'), 
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time, 'Mulai: 08:00 WIB'),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('Uang Tunai di Laci', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(_totalSalesToday), 
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ── [TAMBAHAN] TOMBOL EXCEL UNTUK TUTUP SHIFT KASIR ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 16),
                        Text('Menyiapkan Laporan Excel Shift...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                try {
                  await ExcelService.exportTransactionsToExcel(
                    _allTransactions, // Data transaksi kasir
                    "Shift Kasir Hari Ini",
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Laporan Shift Excel berhasil diunduh!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Gagal membuat Excel: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download, color: Colors.white, size: 20),
              label: const Text('UNDUH LAPORAN SHIFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Warna hijau khas Excel
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
          // ─────────────────────────────────────────────────────

        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}