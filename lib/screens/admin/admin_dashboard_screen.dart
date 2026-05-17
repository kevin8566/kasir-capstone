import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Diperlukan untuk format mata uang (NumberFormat)

import '../../core/theme.dart';
import '../../services/admin_service.dart';
import '../../services/excel_service.dart';
import '../../services/supabase_service.dart'; // [TAMBAHAN] Import Supabase untuk filter manual
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/analytics_card.dart';
import '../../widgets/admin/sales_chart.dart';
import '../../models/transaction_model.dart'; // [TAMBAHAN] Untuk tipe data transaksi

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedPeriod = 'Harian'; // Default filter
  
  // Variabel state untuk menyimpan data dinamis
  bool _isLoading = true;
  double _totalEarnings = 0;
  int _transactionCount = 0;
  String _topProduct = '-';

  @override
  void initState() {
    super.initState();
    // Tarik data saat layar pertama kali dibuka
    _fetchDashboardData();
  }

  // Logika Utama: Mengambil dan mengolah data dari database (SupabaseService via AdminService)
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    // 1. Ambil data transaksi sesuai filter (Harian/Bulanan/Tahunan)
    final data = await AdminService.getReportData(_selectedPeriod);

    // 2. Siapkan variabel penampung perhitungan
    double earnings = 0;
    Map<String, int> productCount = {};

    // 3. Lakukan iterasi (loop) pada setiap nota dan item yang terjual
    for (var t in data) {
      earnings += t.totalAmount;
      for (var item in t.items) {
        // Hitung frekuensi penjualan produk untuk mencari "Produk Terlaris"
        productCount[item.product.name] = (productCount[item.product.name] ?? 0) + item.quantity;
      }
    }

    // 4. Tentukan produk terlaris
    String topP = '-';
    if (productCount.isNotEmpty) {
      topP = productCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // 5. Perbarui tampilan layar (UI) dengan data terbaru
    setState(() {
      _totalEarnings = earnings;
      _transactionCount = data.length;
      _topProduct = topP;
      _isLoading = false;
    });
  }

  // Fungsi pembantu untuk mengubah angka (1500000) menjadi format Rupiah (Rp 1.500.000)
  String _formatIDR(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        children: [
          // 1. Sidebar Navigasi
          const AdminSidebar(activeRoute: '/admin/dashboard'),

          // 2. Konten Utama
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(),
                        const SizedBox(height: 32),
                        _buildMetricsGrid(),
                        const SizedBox(height: 32),
                        // Grafik penjualan
                        SalesChart(selectedPeriod: _selectedPeriod),
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dashboard Analitik',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.textDark,
            ),
          ),
          
          // ── [REVISI] TOMBOL GENERATE EXCEL OTOMATIS BERDASARKAN FILTER ──
          ElevatedButton.icon(
            onPressed: () async {
              // Menampilkan UI Loading yang elegan
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 16),
                      Text('Merekap data Excel, mohon tunggu...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              try {
                // 1. Tarik semua transaksi dasar
                final allTransactions = await SupabaseService.getTransactions();
                
                // 2. Terapkan Filter Tanggal Real-Time Layaknya Mesin Analitik
                List<TransactionModel> filteredData = [];
                DateTime now = DateTime.now();

                if (_selectedPeriod == 'Harian') {
                  filteredData = allTransactions.where((t) =>
                    t.date.year == now.year && t.date.month == now.month && t.date.day == now.day
                  ).toList();
                } else if (_selectedPeriod == 'Bulanan') {
                  filteredData = allTransactions.where((t) =>
                    t.date.year == now.year && t.date.month == now.month
                  ).toList();
                } else if (_selectedPeriod == 'Tahunan') {
                  filteredData = allTransactions.where((t) =>
                    t.date.year == now.year
                  ).toList();
                } else {
                  filteredData = allTransactions;
                }

                // 3. Pencegahan jika data kosong
                if (filteredData.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tidak ada penjualan di periode $_selectedPeriod ini.'), 
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                // 4. Proses Pembuatan File Excel
                await ExcelService.exportTransactionsToExcel(filteredData, _selectedPeriod);

                // 5. Notifikasi Berhasil
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Laporan Excel berhasil diunduh!'), 
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Gagal mengekspor: $e'), 
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            label: const Text(
              'GENERATE EXCEL', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Menggunakan warna hijau Excel
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
          // ────────────────────────────────────────────────────────────────
          
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final periods = ['Harian', 'Bulanan', 'Tahunan'];
    return Row(
      children: periods.map((p) {
        final isSelected = _selectedPeriod == p;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(p),
            selected: isSelected,
            onSelected: (val) {
              // Jika filter ditekan, ubah status dan tarik data ulang
              setState(() => _selectedPeriod = p);
              _fetchDashboardData(); 
            },
            selectedColor: AppTheme.primaryBlue,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsGrid() {
    // Tampilkan indikator loading saat memproses perhitungan agar UI terasa responsif
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsivitas kolom
        int crossAxisCount = constraints.maxWidth < 900 ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.5,
          // List children tidak lagi menggunakan 'const' karena memuat data dinamis
          children: [
            AnalyticsCard(
              title: 'Total Pendapatan',
              value: _formatIDR(_totalEarnings),
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.primaryBlue,
            ),
            AnalyticsCard(
              title: 'Total Transaksi',
              value: '$_transactionCount Nota',
              icon: Icons.receipt_long_outlined,
              color: Colors.orange,
            ),
            AnalyticsCard(
              title: 'Produk Terlaris',
              value: _topProduct,
              icon: Icons.auto_graph_outlined,
              color: Colors.purple,
            ),
            const AnalyticsCard(
              title: 'Status Sistem',
              value: 'Online',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }
}