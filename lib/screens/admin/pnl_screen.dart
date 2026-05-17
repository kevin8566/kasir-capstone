import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin/admin_sidebar.dart';

class PnLScreen extends StatefulWidget {
  const PnLScreen({super.key});

  @override
  State<PnLScreen> createState() => _PnLScreenState();
}

class _PnLScreenState extends State<PnLScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'Bulan Ini';

  // Variabel Akuntansi
  double _totalRevenue = 0;
  double _cogs = 0; // Cost of Goods Sold (Bahan Baku)
  double _operatingExpenses = 0; // Biaya Operasional

  @override
  void initState() {
    super.initState();
    _calculatePnL();
  }

  Future<void> _calculatePnL() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await SupabaseService.getTransactions();
      final expenses = await SupabaseService.getExpenses();

      final now = DateTime.now();
      
      double revenue = 0;
      double cogs = 0;
      double opEx = 0;

      // 1. Hitung Pendapatan (Penjualan)
      for (var t in transactions) {
        // Filter waktu (Sederhana)
        bool isThisMonth = t.date.year == now.year && t.date.month == now.month;
        if (_selectedPeriod == 'Semua Waktu' || (_selectedPeriod == 'Bulan Ini' && isThisMonth)) {
          revenue += t.totalAmount;
        }
      }

      // 2. Hitung Pengeluaran (HPP vs Operasional)
      for (var e in expenses) {
        bool isThisMonth = e.date.year == now.year && e.date.month == now.month;
        if (_selectedPeriod == 'Semua Waktu' || (_selectedPeriod == 'Bulan Ini' && isThisMonth)) {
          if (e.category == 'Bahan Baku') {
            cogs += e.amount;
          } else {
            opEx += e.amount;
          }
        }
      }

      setState(() {
        _totalRevenue = revenue;
        _cogs = cogs;
        _operatingExpenses = opEx;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatIDR(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Perhitungan Laba
    final double grossProfit = _totalRevenue - _cogs;
    final double netProfit = grossProfit - _operatingExpenses;
    final bool isLoss = netProfit < 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(activeRoute: '/admin/pnl'), // Kita daftarkan rutenya nanti
          
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
                      const Text('Laporan Laba Rugi (P&L)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      _buildPeriodDropdown(),
                    ],
                  ),
                ),

                // Konten
                Expanded(
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            // Kartu Summary Atas
                            Row(
                              children: [
                                _buildSummaryCard('Total Pendapatan', _totalRevenue, Icons.arrow_upward, Colors.green),
                                const SizedBox(width: 24),
                                _buildSummaryCard('Total Pengeluaran', _cogs + _operatingExpenses, Icons.arrow_downward, Colors.red),
                                const SizedBox(width: 24),
                                _buildSummaryCard('Laba Bersih', netProfit, isLoss ? Icons.warning : Icons.account_balance_wallet, isLoss ? Colors.red : AppTheme.primaryBlue),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Kertas Laporan Rinci bergaya Akuntansi
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(child: Text('LAPORAN LABA RUGI KOMPREHENSIF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade800))),
                                  Center(child: Text('Periode: $_selectedPeriod', style: const TextStyle(color: Colors.grey))),
                                  const Divider(height: 40, thickness: 2),

                                  // Bagian Pendapatan
                                  const Text('PENDAPATAN', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  _buildReportRow('Penjualan Kasir (POS)', _totalRevenue),
                                  const Divider(height: 24),
                                  _buildReportRow('TOTAL PENDAPATAN', _totalRevenue, isBold: true),
                                  const SizedBox(height: 32),

                                  // Bagian HPP
                                  const Text('HARGA POKOK PENJUALAN (HPP)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  _buildReportRow('Pembelian Bahan Baku', _cogs),
                                  const Divider(height: 24),
                                  _buildReportRow('LABA KOTOR', grossProfit, isBold: true, color: Colors.green),
                                  const SizedBox(height: 32),

                                  // Bagian Operasional
                                  const Text('BIAYA OPERASIONAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  _buildReportRow('Pengeluaran Operasional & Gaji', _operatingExpenses),
                                  const Divider(height: 24),
                                  _buildReportRow('TOTAL BIAYA OPERASIONAL', _operatingExpenses, isBold: true),
                                  const Divider(height: 40, thickness: 2),

                                  // Hasil Akhir
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isLoss ? Colors.red.shade50 : AppTheme.lightBlue,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isLoss ? Colors.red : AppTheme.primaryBlue)
                                    ),
                                    child: _buildReportRow(
                                      isLoss ? 'RUGI BERSIH' : 'LABA BERSIH', 
                                      netProfit, 
                                      isBold: true, 
                                      color: isLoss ? Colors.red : AppTheme.primaryBlue,
                                      fontSize: 20
                                    ),
                                  )
                                ],
                              ),
                            ),
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

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.backgroundGrey, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          items: ['Bulan Ini', 'Semua Waktu'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)));
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _selectedPeriod = newValue);
              _calculatePnL();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_formatIDR(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, double amount, {bool isBold = false, Color color = AppTheme.textDark, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: color)),
        Text(_formatIDR(amount), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: color)),
      ],
    );
  }
}