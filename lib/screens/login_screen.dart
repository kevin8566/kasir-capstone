import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _obscurePassword = true;

  String _companyName = 'KasirKu';
  String _companyTagline = 'Aplikasi Kasir Digital';
  String _logoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      // Paksa fetch terbaru dari Supabase (tidak pakai cache)
      CompanyService.clearCache();
      final profile = await CompanyService.getCompanyProfile();
      if (mounted) {
        setState(() {
          _companyName = profile['name']?.toString() ?? 'KasirKu';
          _companyTagline = profile['tagline']?.toString() ?? 'Aplikasi Kasir Digital';
          _logoUrl = profile['logo_url']?.toString() ?? '';
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // ── Fungsi Login Asli (Production) ───────────────────────────
  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final success = await AuthService.login(
        _emailCtrl.text.trim(), _passwordCtrl.text);
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (success) {
      // Secara default masuk ke Dashboard Kasir
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau password salah!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── [TAMBAHAN] Fungsi Login Cepat (Testing/Developer) ──────────
  Future<void> _quickLogin(String role) async {
    setState(() => _isLoading = true);
    
    // Simulasi jeda waktu server agar terlihat natural
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;

    // Navigasi cerdas berdasarkan hak akses (Role-Based Routing)
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } else if (role == 'kasir') {
      Navigator.pushReplacementNamed(context, AppConstants.transactionRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ───────────────────────────────────────
                _isLoadingProfile
                    ? _defaultLogo()
                    : (_logoUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _logoUrl,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              // Paksa reload tanpa cache
                              cacheKey: 'logo_${DateTime.now().millisecondsSinceEpoch}',
                              placeholder: (_, __) => _defaultLogo(),
                              errorWidget: (_, __, ___) => _defaultLogo(),
                            ),
                          )
                        : _defaultLogo()),

                const SizedBox(height: 16),

                // ── Nama & Tagline ─────────────────────────────
                Text(
                  _companyName,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _companyTagline,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Card Login ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 24,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Masuk',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Masukkan email & password Anda',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 24),

                      const Text('Email',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                            'email@contoh.com', Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),

                      const Text('Password',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          'Masukkan password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primaryBlue))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.primaryBlue
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _login, // Tetap memanggil fungsi asli
                                  icon: const Icon(Icons.login,
                                      color: Colors.white),
                                  label: const Text('Masuk',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── [TAMBAHAN] PANEL DEVELOPER (QUICK LOGIN) ───
                const Text('🚀 Mode Pengujian Cepat', 
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.white),
                      label: const Text('Login Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.purple.shade400,
                      side: BorderSide.none,
                      onPressed: _isLoading ? null : () => _quickLogin('admin'),
                    ),
                    const SizedBox(width: 12),
                    ActionChip(
                      avatar: const Icon(Icons.point_of_sale, size: 16, color: Colors.white),
                      label: const Text('Login Kasir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.orange.shade400,
                      side: BorderSide.none,
                      onPressed: _isLoading ? null : () => _quickLogin('kasir'),
                    ),
                  ],
                ),
                // ───────────────────────────────────────────────

                const SizedBox(height: 24),
                Text('© 2025 $_companyName',
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: const Icon(Icons.point_of_sale, size: 46, color: Colors.white),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textGrey),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      filled: true,
      fillColor: AppTheme.backgroundGrey,
    );
  }
}