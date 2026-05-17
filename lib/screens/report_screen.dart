import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';
import '../services/excel_service.dart';
import '../widgets/cashier_layout.dart';
import '../widgets/custom_button.dart';

enum FilterPeriod { mingguan, bulanan, tahunan, semua }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;
  bool _isExporting = false;
  FilterPeriod _filter = FilterPeriod.bulanan;
  final int _selectedYear = DateTime.now().year;

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
    final now = DateTime.now();
    switch (_filter) {
      case FilterPeriod.mingguan:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return _allTransactions.where((t) => t.date.isAfter(start)).toList();
      case FilterPeriod.bulanan:
        final start = DateTime(_selectedYear, now.month, 1);
        return _allTransactions.where((t) => t.date.isAfter(start)).toList();
      case FilterPeriod.tahunan:
        return _allTransactions.where((t) => t.date.year == _selectedYear).toList();
      case FilterPeriod.semua:
        return _allTransactions;
    }
  }

  double get _totalFiltered => _filtered.fold(0, (s, t) => s + t.totalAmount);

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final filteredToExport = _filtered;
      if (filteredToExport.isEmpty) {
        setState(() => _isExporting = false);
        return;
      }
      await ExcelService.exportTransactionsToExcel(filteredToExport, 'Laporan_POS_${DateFormat('ddMMyyyy').format(DateTime.now())}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Laporan Excel Berhasil Diunduh!'), backgroundColor: AppTheme.primaryBlue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Export: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isExporting = false);
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return CashierLayout(
      activeRoute: AppConstants.reportRoute,
      title: 'Laporan Keuangan',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(isMobile),
                    const SizedBox(height: 32),
                    _buildMetricsSection(isMobile),
                    const SizedBox(height: 40),
                    _buildTableSection(isMobile),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis Keuangan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFilterSection(),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analisis Keuangan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Pantau performa penjualan Anda secara real-time.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
        _buildFilterSection(),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          _buildFilterButton('Mingguan', FilterPeriod.mingguan),
          _buildFilterButton('Bulanan', FilterPeriod.bulanan),
          _buildFilterButton('Semua', FilterPeriod.semua),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, FilterPeriod period) {
    final isSelected = _filter == period;
    return InkWell(
      onTap: () => setState(() => _filter = period),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildMetricsSection(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildMetricCard('Total Pendapatan', _formatCurrency(_totalFiltered), Icons.account_balance_wallet, AppTheme.primaryBlue),
          const SizedBox(height: 16),
          _buildMetricCard('Total Transaksi', '${_filtered.length} Nota', Icons.receipt_long, Colors.orange),
          const SizedBox(height: 16),
          _buildMetricCard('Rata-rata Nota', _formatCurrency(_filtered.isNotEmpty ? _totalFiltered / _filtered.length : 0), Icons.analytics, Colors.purple),
        ],
      );
    }
    return Row(
      children: [
        _buildMetricCard('Total Pendapatan', _formatCurrency(_totalFiltered), Icons.account_balance_wallet, AppTheme.primaryBlue),
        const SizedBox(width: 24),
        _buildMetricCard('Total Transaksi', '${_filtered.length} Nota', Icons.receipt_long, Colors.orange),
        const SizedBox(width: 24),
        _buildMetricCard('Rata-rata Nota', _formatCurrency(_filtered.isNotEmpty ? _totalFiltered / _filtered.length : 0), Icons.analytics, Colors.purple),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: isMobile 
              ? Column(
                  children: [
                    const Text('Daftar Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'EXPORT EXCEL',
                      onPressed: _isExporting ? null : () => _exportExcel(),
                      icon: Icons.download_outlined,
                      width: double.infinity,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    CustomButton(
                      label: 'EXPORT EXCEL',
                      onPressed: _isExporting ? null : () => _exportExcel(),
                      icon: Icons.download_outlined,
                      width: 160,
                    ),
                  ],
                ),
          ),
          const Divider(height: 1),
          if (_filtered.isEmpty)
            const Padding(padding: EdgeInsets.all(60), child: Text('Tidak ada data transaksi.', style: TextStyle(color: AppTheme.textGrey)))
          else
            _buildDataTable(isMobile),
        ],
      ),
    );
  }

  Widget _buildDataTable(bool isMobile) {
    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final t = _filtered[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('${DateFormat('dd MMM, HH:mm').format(t.date)} • ${t.paymentMethod}', style: const TextStyle(fontSize: 11)),
            trailing: Text(_formatCurrency(t.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          );
        },
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppTheme.lightBlue.withOpacity(0.5),
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filtered.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final t = _filtered[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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
            );
          },
        ),
      ],
    );
  }
}