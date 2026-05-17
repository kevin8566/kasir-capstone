import '../models/transaction_model.dart';
import 'supabase_service.dart';

class AdminService {
  /// Mengambil transaksi berdasarkan filter waktu
  static Future<List<TransactionModel>> getReportData(String period) async {
    final allTransactions = await SupabaseService.getTransactions();
    final now = DateTime.now();

    return allTransactions.where((t) {
      if (period == 'Harian') {
        return t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      } else if (period == 'Bulanan') {
        return t.date.year == now.year && t.date.month == now.month;
      } else if (period == 'Tahunan') {
        return t.date.year == now.year;
      }
      return true; // Default (Semua data)
    }).toList();
  }
}