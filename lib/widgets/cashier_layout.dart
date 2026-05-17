import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';

class CashierLayout extends StatelessWidget {
  final Widget child;
  final String activeRoute;
  final String title;

  const CashierLayout({
    super.key,
    required this.child,
    required this.activeRoute,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      drawer: isMobile ? Drawer(
        width: 280,
        backgroundColor: Colors.white,
        child: _buildSidebar(context, isDrawer: true),
      ) : null,
      bottomNavigationBar: isMobile ? _buildBottomNav(context) : null,
      body: Row(
        children: [
          // Sidebar (Fixed for Desktop)
          if (!isMobile) _buildSidebar(context),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, isMobile),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        currentIndex: _getCurrentIndex(),
        onTap: (index) {
          final routes = [
            AppConstants.dashboardRoute,
            AppConstants.transactionRoute,
            AppConstants.historyRoute,
          ];
          if (activeRoute != routes[index]) {
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textGrey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), activeIcon: Icon(Icons.point_of_sale), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }

  int _getCurrentIndex() {
    if (activeRoute == AppConstants.dashboardRoute) return 0;
    if (activeRoute == AppConstants.transactionRoute) return 1;
    if (activeRoute == AppConstants.historyRoute) return 2;
    return 0;
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isDrawer ? null : Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sedap POS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textDark,
                  ),
                ),
                if (isDrawer) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Navigation Items (Wrapped in Expanded/ListView for scrollability)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  label: 'Beranda',
                  route: AppConstants.dashboardRoute,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.point_of_sale_outlined,
                  label: 'POS Transaksi',
                  route: AppConstants.transactionRoute,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.history_outlined,
                  label: 'Riwayat Transaksi',
                  route: AppConstants.historyRoute,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          // Logout Button
          _buildNavItem(
            context,
            icon: Icons.logout,
            label: 'Keluar',
            route: '/logout',
            isLogout: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool isLogout = false,
    bool isDisabled = false,
  }) {
    final isActive = activeRoute == route;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: InkWell(
          onTap: isDisabled ? null : () async {
            if (isLogout) {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
              }
            } else if (!isActive) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  icon,
                  color: isActive ? Colors.white : AppTheme.textGrey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textDark,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppTheme.textDark),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              if (isMobile) const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.lightBlue,
                child: Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              if (!isMobile)
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kasir Utama',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Shift Pagi',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
