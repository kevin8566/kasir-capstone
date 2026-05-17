import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({
    super.key,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260, 
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header / Logo ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Diperbesar sedikit agar lebih proporsional
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue, // [REVISI] Latar belakang solid biru
                    borderRadius: BorderRadius.circular(12), // [REVISI] Sudut lebih membulat
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ], // [TAMBAHAN] Bayangan tipis agar logo pop-up elegan
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 24), // [REVISI] Ikon putih
                ),
                const SizedBox(width: 14),
                const Text('Sedap POS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: 0.5)),
              ],
            ),
          ),

          // ── Menu Items ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(
                  context,
                  label: 'Dashboard Analitik',
                  outlineIcon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  route: '/admin/dashboard', 
                ),
                const SizedBox(height: 4),
                
                _buildNavItem(
                  context,
                  label: 'Menu & Stok',
                  outlineIcon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  route: '/admin/products', 
                ),
                const SizedBox(height: 4),
                
                _buildNavItem(
                  context,
                  label: 'Kalkulator HPP',
                  outlineIcon: Icons.precision_manufacturing_outlined,
                  activeIcon: Icons.precision_manufacturing,
                  route: '/admin/hpp',
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  label: 'Pengeluaran',
                  outlineIcon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  route: '/admin/expense',
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  label: 'Laba Rugi (PnL)',
                  outlineIcon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  route: '/admin/pnl',
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  label: 'Manajemen User',
                  outlineIcon: Icons.people_outline,
                  activeIcon: Icons.people,
                  route: '/admin/users',
                ),
              ],
            ),
          ),

          // ── Bottom Settings & Logout ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNavItem(
                  context,
                  label: 'Pengaturan',
                  outlineIcon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  route: '/admin/settings',
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  label: 'Keluar',
                  outlineIcon: Icons.logout,
                  activeIcon: Icons.logout,
                  route: AppConstants.loginRoute, 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required String label, required IconData outlineIcon, required IconData activeIcon, required String route}) {
    final isActive = activeRoute == route;
    return InkWell(
      onTap: () {
        if (!isActive) {
          if (route == AppConstants.loginRoute) {
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : outlineIcon, 
              color: isActive ? Colors.white : AppTheme.textGrey, 
              size: 22
            ),
            const SizedBox(width: 14),
            Text(
              label, 
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textGrey, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500, 
                fontSize: 14
              )
            ),
          ],
        ),
      ),
    );
  }
}