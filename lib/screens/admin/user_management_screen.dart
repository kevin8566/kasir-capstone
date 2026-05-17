import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/admin/admin_sidebar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Simulasi Database User Lokal
  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'Super Admin', 'username': 'admin', 'role': 'Admin', 'status': 'Aktif'},
    {'id': '2', 'name': 'Kasir Utama', 'username': 'kasir', 'role': 'Kasir', 'status': 'Aktif'},
    {'id': '3', 'name': 'Budi Santoso', 'username': 'budi_k', 'role': 'Kasir', 'status': 'Nonaktif'},
  ];

  bool _isLoading = false;

  // ── LOGIKA TAMBAH/EDIT USER ─────────────────────────────────────
  void _showUserDialog({Map<String, dynamic>? userToEdit}) {
    final isEdit = userToEdit != null;
    final nameCtrl = TextEditingController(text: isEdit ? userToEdit['name'] : '');
    final usernameCtrl = TextEditingController(text: isEdit ? userToEdit['username'] : '');
    final passwordCtrl = TextEditingController(); // Dikosongkan, hanya diisi jika ingin diubah
    
    String selectedRole = isEdit ? userToEdit['role'] : 'Kasir';
    String selectedStatus = isEdit ? userToEdit['status'] : 'Aktif';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.person_add, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna Baru', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nama Lengkap'),
                    TextField(controller: nameCtrl, decoration: _inputStyle('Misal: Siti Aminah')),
                    const SizedBox(height: 16),

                    _buildLabel('Username (Untuk Login)'),
                    TextField(controller: usernameCtrl, decoration: _inputStyle('Misal: siti_kasir')),
                    const SizedBox(height: 16),

                    _buildLabel(isEdit ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password'),
                    TextField(controller: passwordCtrl, obscureText: true, decoration: _inputStyle('Minimal 6 karakter')),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Hak Akses (Role)'),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: _inputStyle(''),
                                items: ['Admin', 'Kasir'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                onChanged: (val) => setDialogState(() => selectedRole = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Status Akun'),
                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: _inputStyle(''),
                                items: ['Aktif', 'Nonaktif'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setDialogState(() => selectedStatus = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty || usernameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan Username wajib diisi!'), backgroundColor: Colors.orange));
                    return;
                  }
                  
                  setState(() {
                    if (isEdit) {
                      final index = _users.indexWhere((u) => u['id'] == userToEdit['id']);
                      if (index != -1) {
                        _users[index] = {
                          'id': userToEdit['id'],
                          'name': nameCtrl.text,
                          'username': usernameCtrl.text,
                          'role': selectedRole,
                          'status': selectedStatus,
                        };
                      }
                    } else {
                      _users.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameCtrl.text,
                        'username': usernameCtrl.text,
                        'role': selectedRole,
                        'status': selectedStatus,
                      });
                    }
                  });
                  
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? '✅ Akun diperbarui!' : '✅ Akun baru berhasil dibuat!'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textGrey)),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      filled: true, fillColor: AppTheme.backgroundGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(activeRoute: '/admin/users'),
          
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
                      const Text('Manajemen Pengguna & Akses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      ElevatedButton.icon(
                        onPressed: () => _showUserDialog(),
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text('TAMBAH PENGGUNA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Konten Tabel Karyawan
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isActive = user['status'] == 'Aktif';
                            final isAdmin = user['role'] == 'Admin';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isAdmin ? Colors.purple.shade50 : Colors.orange.shade50,
                                child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.point_of_sale, color: isAdmin ? Colors.purple : Colors.orange),
                              ),
                              title: Row(
                                children: [
                                  Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(user['status'], style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Username: ${user['username']} | Role: ${user['role']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
                                onPressed: () => _showUserDialog(userToEdit: user),
                                tooltip: 'Edit Akun',
                              ),
                            );
                          },
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
}