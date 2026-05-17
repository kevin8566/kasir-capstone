import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

// ── CORE & SERVICES ───────────────────────────────────────────
import 'core/constants.dart';
import 'core/theme.dart';
import 'services/supabase_service.dart';

// ── SCREENS (KASIR & UMUM) ────────────────────────────────────
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/product_screen.dart';
import 'screens/report_screen.dart';
import 'screens/history_screen.dart';

// ── SCREENS (ADMIN) ───────────────────────────────────────────
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/admin/pnl_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/hpp_calculator_screen.dart';
import 'screens/admin/admin_product_screen.dart'; // [TAMBAHAN] Layar Stok Admin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);

  // Eksekusi data dummy saat aplikasi mulai
  await SupabaseService.seedDummyData();

  runApp(const KasirKuApp());
}

class KasirKuApp extends StatelessWidget {
  const KasirKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      initialRoute: AppConstants.loginRoute,
      
      routes: {
        // Rute Kasir
        AppConstants.loginRoute: (_) => const LoginScreen(),
        AppConstants.dashboardRoute: (_) => const DashboardScreen(),
        AppConstants.transactionRoute: (_) => const TransactionScreen(),
        AppConstants.productRoute: (_) => const ProductScreen(),
        AppConstants.reportRoute: (_) => const ReportScreen(),
        AppConstants.historyRoute: (_) => const HistoryScreen(),
        
        // Rute Admin
        '/admin/dashboard': (_) => const AdminDashboardScreen(), 
        '/admin/expense': (_) => const ExpenseScreen(),
        '/admin/pnl': (_) => const PnLScreen(),
        '/admin/users': (_) => const UserManagementScreen(),
        '/admin/hpp': (_) => const HppCalculatorScreen(),
        '/admin/products': (_) => const AdminProductScreen(), // [TAMBAHAN] Rute Stok Admin
      },
    );
  }
}