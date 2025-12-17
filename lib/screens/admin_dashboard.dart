// screens/admin_dashboard_screen.dart - DENGAN FITUR LOGOUT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/models/auth_response.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart'; // IMPORT AUTH PROVIDER

class AdminDashboardScreen extends StatefulWidget {
  // HAPUS token parameter karena sekarang menggunakan auth provider
  const AdminDashboardScreen({super.key, required String token});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;
  late AdminProvider _adminProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminProvider = Provider.of<AdminProvider>(context, listen: false);
      _adminProvider.loadDashboardData();
    });
  }

  @override
  void dispose() {
    _adminProvider.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildTabMenu(),
            SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // --------------------- HEADER dengan LOGOUT ----------------------
  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      // Gunakan AuthProvider untuk mendapatkan info user
      builder: (context, auth, child) {
        return Consumer<AdminProvider>(
          builder: (context, admin, child) {
            final user = auth.user;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Logo dan Nama App
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              'assets/Vector.png',
                              width: 28,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "WARGA KITA",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),

                      // User Profile dengan Dropdown Menu
                      _buildUserProfileDropdown(auth, user),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Greeting dengan nama user
                  Text(
                    "Hai ${user?.name.split(' ').first ?? 'Admin'}!",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "Mari pantau perkembangan warga hari ini",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  // Tampilkan status auto-refresh di header
                  SizedBox(height: 8),
                  _buildAutoRefreshStatus(admin),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget untuk dropdown menu user profile
  Widget _buildUserProfileDropdown(AuthProvider auth, User? user) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_outline, color: Colors.white, size: 20),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // User info
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                user?.email ?? '-',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRoleColor(user?.role),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user?.role ?? 'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        PopupMenuDivider(),

        // Menu items
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined, size: 18),
              SizedBox(width: 10),
              Text('Profil Saya'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 10),
              Text('Pengaturan'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 18),
              SizedBox(width: 10),
              Text('Bantuan'),
            ],
          ),
        ),

        PopupMenuDivider(),

        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_outlined, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Keluar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        _handleUserMenuSelection(value, auth);
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return Colors.purple.shade700;
      case 'ADMIN':
        return Colors.blue.shade700;
      case 'SECURITY':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void _handleUserMenuSelection(String value, AuthProvider auth) {
    switch (value) {
      case 'profile':
        _showProfileDialog(auth.user);
        break;
      case 'settings':
        _showSettingsBottomSheet(context);
        break;
      case 'help':
        _showHelpDialog();
        break;
      case 'logout':
        _showLogoutConfirmation(auth);
        break;
    }
  }

  void _showProfileDialog(User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil Saya'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: Color(0xFF1E88E5),
                  radius: 40,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              SizedBox(height: 16),
              _profileInfoRow('Nama', user?.name ?? '-'),
              _profileInfoRow('Email', user?.email ?? '-'),
              _profileInfoRow('Role', user?.role ?? '-'),
              _profileInfoRow('ID', user?.id.toString() ?? '-'),
              if (user?.createdAt != null)
                _profileInfoRow(
                  'Bergabung',
                  '${user!.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('Bantuan & Dukungan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halaman Bantuan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              _helpItem(
                icon: Icons.phone,
                title: 'Hubungi Kami',
                subtitle: '021-1234-5678',
              ),
              _helpItem(
                icon: Icons.email,
                title: 'Email Dukungan',
                subtitle: 'support@wargakita.com',
              ),
              _helpItem(
                icon: Icons.chat,
                title: 'Live Chat',
                subtitle: 'Tersedia 24/7',
              ),
              SizedBox(height: 16),
              Text(
                'Panduan Penggunaan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Dashboard menampilkan statistik utama\n'
                '2. Gunakan tab untuk filter data\n'
                '3. Klik kartu untuk navigasi ke halaman detail\n'
                '4. Notifikasi menunjukkan update terbaru',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Panduan telah dikirim ke email Anda'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Dapatkan Panduan'),
          ),
        ],
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Color(0xFF1E88E5)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }

  void _showLogoutConfirmation(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(auth);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Keluar' , style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(AuthProvider auth) async {
    try {
      // Tampilkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Logout dari auth provider
      await auth.logout();

      // Tutup loading dialog
      Navigator.pop(context);

      // Tampilkan konfirmasi logout berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil keluar'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigation akan di-handle oleh main.dart
      // AuthProvider akan memicu rebuild dan mengarahkan ke login screen
    } catch (e) {
      Navigator.pop(context); // Tutup loading dialog jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget untuk menampilkan status auto-refresh
  Widget _buildAutoRefreshStatus(AdminProvider admin) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                admin.isAutoRefreshEnabled ? Icons.autorenew : Icons.pause,
                size: 10,
                color: Colors.white70,
              ),
              SizedBox(width: 3),
              Text(
                admin.isAutoRefreshEnabled
                    ? "Auto-refresh ON"
                    : "Auto-refresh OFF",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 6),
        if (admin.isAutoRefreshEnabled)
          Expanded(
            child: Text(
              "Update: ${_formatTime(admin.lastUpdate)}",
              style: TextStyle(color: Colors.white70, fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }



  // --------------------- TAB MENU ----------------------
  Widget _buildTabMenu() {
    final List<String> tabLabels = [
      "Semua Data",
      "Prioritas",
      "Butuh Tindakan",
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabLabels.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: _tab(tabLabels[index], index),
          );
        },
      ),
    );
  }

  Widget _tab(String text, int index) {
    bool selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Color(0xFF1E88E5) : Colors.grey.shade300,
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Color(0xFF1E88E5).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --------------------- CONTENT ----------------------
  Widget _buildContent() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        if (admin.isLoading) {
          return _buildLoadingState();
        }

        if (admin.error != null) {
          return _buildErrorState(admin.error!);
        }

        final stats = admin.dashboardStats;

        return RefreshIndicator(
          onRefresh: () => admin.refreshData(),
          color: Color(0xFF1E88E5),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLastUpdatedInfo(admin),
                SizedBox(height: 12),
                _buildStatsGrid(stats, admin),
                SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget untuk menampilkan info last updated
  Widget _buildLastUpdatedInfo(AdminProvider admin) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 12, // Reduced size
                color: Colors.blue.shade600,
              ),
              SizedBox(width: 5), // Reduced spacing
              Text(
                "Data diperbarui otomatis",
                style: TextStyle(
                  fontSize: 11, // Reduced font size
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            "Update: ${_formatTimeWithSeconds(admin.lastUpdate)}",
            style: TextStyle(
              fontSize: 10, // Reduced font size
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeWithSeconds(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E88E5), strokeWidth: 2),
          SizedBox(height: 12), // Reduced spacing
          Text(
            "Memuat data...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ), // Reduced font size
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ), // Reduced size
          SizedBox(height: 12), // Reduced spacing
          Text(
            "Terjadi kesalahan",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14, // Reduced font size
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6), // Reduced spacing
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ), // Reduced font size
            ),
          ),
          SizedBox(height: 12), // Reduced spacing
          ElevatedButton(
            onPressed: () {
              Provider.of<AdminProvider>(
                context,
                listen: false,
              ).loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ), // Reduced padding
            ),
            child: Text(
              "Coba Lagi",
              style: TextStyle(fontSize: 12),
            ), // Reduced font size
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic stats, AdminProvider admin) {
    List<Map<String, dynamic>> cardData = _getFilteredData(stats, admin);

    if (cardData.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12, // Reduced spacing
        mainAxisSpacing: 12, // Reduced spacing
        childAspectRatio: 0.8, // Adjusted aspect ratio
      ),
      itemCount: cardData.length,
      itemBuilder: (context, index) {
        final data = cardData[index];
        return _statCard(
          color: data['color'],
          icon: data['icon'],
          title: data['title'],
          count: data['count'],
          subtitle: data['subtitle'],
          onTap: data['onTap'],
          badgeCount: data['badgeCount'],
          admin: admin,
          cardType: data['cardType'],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // IMPORTANT: Prevent overflow
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Aksi Cepat",
              style: TextStyle(
                fontSize: 16, // Reduced font size
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Consumer<AdminProvider>(
              builder: (context, admin, child) {
                return IconButton(
                  onPressed: () => admin.forceRefresh(),
                  icon: Icon(Icons.refresh, size: 18), // Reduced size
                  tooltip: "Refresh Sekarang",
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 10), // Reduced spacing
        Row(
          children: [
            Expanded(
              child: _quickActionButton(
                icon: Icons.add_circle_outline,
                label: "Buat\nPengumuman",
                color: Color(0xFF1E88E5),
                onTap: () => _showCreateAnnouncementDialog(context),
              ),
            ),
            SizedBox(width: 10), // Reduced spacing
            Expanded(
              child: _quickActionButton(
                icon: Icons.analytics_outlined,
                label: "Lihat\nLaporan",
                color: Color(0xFF4CAF50),
                onTap: () => Navigator.pushNamed(context, "/reports"),
              ),
            ),
            SizedBox(width: 10), // Reduced spacing
            Expanded(
              child: _quickActionButton(
                icon: Icons.settings_outlined,
                label: "Pengaturan",
                color: Color(0xFF9C27B0),
                onTap: () => _showSettingsBottomSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------- BUAT PENGUMUMAN DIALOG ----------------------
  void _showCreateAnnouncementDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool _isImportant = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Buat Pengumuman Baru",
            style: TextStyle(fontSize: 16),
          ), // Reduced font size
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Judul Pengumuman",
                    border: OutlineInputBorder(),
                    hintText: "Masukkan judul pengumuman",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ), // Reduced padding
                  ),
                ),
                SizedBox(height: 12), // Reduced spacing
                TextField(
                  controller: messageController,
                  maxLines: 3, // Reduced max lines
                  decoration: InputDecoration(
                    labelText: "Isi Pengumuman",
                    border: OutlineInputBorder(),
                    hintText: "Masukkan isi pengumuman",
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ), // Reduced padding
                  ),
                ),
                SizedBox(height: 12), // Reduced spacing
                Row(
                  children: [
                    Checkbox(
                      value: _isImportant,
                      onChanged: (value) {
                        setState(() {
                          _isImportant = value!;
                        });
                      },
                    ),
                    Text(
                      "Tandai sebagai penting",
                      style: TextStyle(fontSize: 12),
                    ), // Reduced font size
                    Icon(
                      Icons.priority_high,
                      color: Colors.red,
                      size: 14,
                    ), // Reduced size
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Batal",
                style: TextStyle(fontSize: 12),
              ), // Reduced font size
            ),
            ElevatedButton(
              onPressed: () {
                _createAnnouncement(
                  context,
                  titleController.text,
                  messageController.text,
                  _isImportant,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ), // Reduced padding
              ),
              child: Text(
                "Buat Pengumuman",
                style: TextStyle(fontSize: 12),
              ), // Reduced font size
            ),
          ],
        );
      },
    );
  }

  void _createAnnouncement(
    BuildContext context,
    String title,
    String message,
    bool isImportant,
  ) {
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Judul dan isi pengumuman harus diisi",
            style: TextStyle(fontSize: 12),
          ), // Reduced font size
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pengumuman '${title.length > 20 ? title.substring(0, 20) + '...' : title}' berhasil dibuat",
          style: TextStyle(fontSize: 12), // Reduced font size
        ),
        backgroundColor: Colors.green,
      ),
    );

    Provider.of<AdminProvider>(context, listen: false).refreshData();
  }

  // --------------------- PENGATURAN BOTTOM SHEET ----------------------
  void _showSettingsBottomSheet(BuildContext context) {
    bool _notificationsEnabled = true;
    bool _darkMode = false;
    bool _autoRefreshEnabled = _adminProvider.isAutoRefreshEnabled;
    String _language = 'Indonesia';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16), // Reduced padding
              height:
                  MediaQuery.of(context).size.height * 0.8, // Reduced height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        "Pengaturan",
                        style: TextStyle(
                          fontSize: 18, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: 20), // Reduced size
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // AUTO REFRESH SETTINGS
                  _settingsSection(
                    title: "Auto Refresh",
                    icon: Icons.autorenew_outlined,
                    children: [
                      _settingsSwitch(
                        value: _autoRefreshEnabled,
                        label: "Refresh Otomatis",
                        subtitle: "Update data setiap 30 detik",
                        onChanged: (value) {
                          setState(() {
                            _autoRefreshEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Notifikasi Settings
                  _settingsSection(
                    title: "Notifikasi",
                    icon: Icons.notifications_active_outlined,
                    children: [
                      _settingsSwitch(
                        value: _notificationsEnabled,
                        label: "Aktifkan Notifikasi",
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Tampilan Settings
                  _settingsSection(
                    title: "Tampilan",
                    icon: Icons.palette_outlined,
                    children: [
                      _settingsSwitch(
                        value: _darkMode,
                        label: "Mode Gelap",
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Bahasa Settings
                  _settingsSection(
                    title: "Bahasa",
                    icon: Icons.language_outlined,
                    children: [
                      _settingsDropdown(
                        value: _language,
                        items: ['Indonesia', 'English', 'Jawa', 'Sunda'],
                        label: "Pilih Bahasa",
                        onChanged: (value) {
                          setState(() {
                            _language = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Account Settings
                  _settingsSection(
                    title: "Akun",
                    icon: Icons.account_circle_outlined,
                    children: [
                      _settingsButton(
                        icon: Icons.security_outlined,
                        label: "Keamanan Akun",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Membuka pengaturan keamanan...",
                                style: TextStyle(fontSize: 12),
                              ), // Reduced font size
                            ),
                          );
                        },
                      ),
                      _settingsButton(
                        icon: Icons.privacy_tip_outlined,
                        label: "Privasi",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Membuka pengaturan privasi...",
                                style: TextStyle(fontSize: 12),
                              ), // Reduced font size
                            ),
                          );
                        },
                      ),
                      _settingsButton(
                        icon: Icons.help_outline,
                        label: "Bantuan & Dukungan",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Membuka halaman bantuan...",
                                style: TextStyle(fontSize: 12),
                              ), // Reduced font size
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  Spacer(),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveSettings(
                          context,
                          _notificationsEnabled,
                          _darkMode,
                          _language,
                          _autoRefreshEnabled,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E88E5),
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                        ), // Reduced padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Simpan Pengaturan",
                        style: TextStyle(
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _settingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF1E88E5), size: 18), // Reduced size
            SizedBox(width: 6), // Reduced spacing
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ), // Reduced font size
            ),
          ],
        ),
        SizedBox(height: 10), // Reduced spacing
        ...children,
      ],
    );
  }

  Widget _settingsSwitch({
    required bool value,
    required String label,
    String subtitle = '',
    required Function(bool) onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ), // Reduced font size
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11, // Reduced font size
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Color(0xFF1E88E5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingsDropdown({
    required String value,
    required List<String> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ), // Reduced font size
        ),
        SizedBox(height: 6), // Reduced spacing
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ), // Reduced padding
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: 13)),
              ); // Reduced font size
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _settingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 40, // Reduced height
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.grey.shade600,
          size: 18,
        ), // Reduced size
        title: Text(label, style: TextStyle(fontSize: 13)), // Reduced font size
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: 18,
        ), // Reduced size
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  void _saveSettings(
    BuildContext context,
    bool notifications,
    bool darkMode,
    String language,
    bool autoRefresh,
  ) {
    _adminProvider.setAutoRefresh(autoRefresh);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pengaturan berhasil disimpan",
          style: TextStyle(fontSize: 12),
        ), // Reduced font size
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12), // Reduced padding
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20), // Reduced size
            SizedBox(height: 6), // Reduced spacing
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11, // Reduced font size
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(30), // Reduced padding
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Colors.grey.shade400,
            size: 50,
          ), // Reduced size
          SizedBox(height: 12), // Reduced spacing
          Text(
            "Tidak ada data",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14, // Reduced font size
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6), // Reduced spacing
          Text(
            "Semua data sudah ditangani dengan baik",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ), // Reduced font size
          ),
        ],
      ),
    );
  }

  // --------------------- FILTER DATA BERDASARKAN TAB ----------------------
  List<Map<String, dynamic>> _getFilteredData(
    dynamic stats,
    AdminProvider admin,
  ) {
    final baseData = [
      {
        'color': Color(0xFFE3F2FD),
        'icon': Icons.people_alt_outlined,
        'title': "Data Warga",
        'count': stats?.totalUsers ?? 0,
        'subtitle': "Warga",
        'badgeCount': 0,
        'onTap': () => Navigator.pushNamed(context, "/users"),
        'cardType': 'users',
      },
      {
        'color': Color(0xFFE8F5E9),
        'icon': Icons.campaign_outlined,
        'title': "Pengumuman",
        'count': stats?.totalAnnouncements ?? 0,
        'subtitle': "Postingan",
        'badgeCount': 0,
        'onTap': () => Navigator.pushNamed(context, "/announcements"),
        'cardType': 'announcements',
      },
      {
        'color': Color(0xFFFFEBEE),
        'icon': Icons.warning_amber_outlined,
        'title': "Darurat",
        'count': stats?.activeEmergencies ?? 0,
        'subtitle': "Aktif",
        'badgeCount': admin.getUnreadEmergencyCount(),
        'onTap': () {
          admin.markAllEmergenciesAsRead();
          Navigator.pushNamed(context, "/emergencies");
        },
        'cardType': 'emergencies',
      },
      {
        'color': Color(0xFFFFF8E1),
        'icon': Icons.assignment_outlined,
        'title': "Laporan",
        'count': _getFilteredReportCount(stats),
        'subtitle': _getReportSubtitle(),
        'badgeCount': admin.getUnreadReportCount(),
        'onTap': () {
          admin.markAllReportsAsRead();
          Navigator.pushNamed(context, "/reports");
        },
        'cardType': 'reports',
      },
      // Di dalam _getFilteredData method, tambahkan card untuk bills:
       {
        'color': Color(0xFFE1F5FE),
        'icon': Icons.receipt_long,
        'title': "Tagihan",
        'count': stats?.totalBills ?? 0,
        'subtitle': "Aktif",
        'badgeCount': admin.getPendingBillsCount(),
        'onTap': () => Navigator.pushNamed(context, "/bills"),
        'cardType': 'bills',
      },
    ];

    switch (_selectedTab) {
      case 0: // Semua Data
        return baseData;

      case 1: // Prioritas
        List<Map<String, dynamic>> sortedData = List.from(baseData);
        sortedData.sort((a, b) => b['count'].compareTo(a['count']));
        return sortedData;

      case 2: // Butuh Tindakan
        return baseData.where((item) => item['badgeCount'] > 0).toList();

      default:
        return baseData;
    }
  }

  int _getFilteredReportCount(dynamic stats) {
    final totalReports = stats?.totalReports ?? 0;

    switch (_selectedTab) {
      case 0: // Semua Data
        return totalReports;

      case 1: // Prioritas
        return totalReports;

      case 2: // Butuh Tindakan
        return (totalReports * 0.3).round();

      default:
        return totalReports;
    }
  }

  String _getReportSubtitle() {
    switch (_selectedTab) {
      case 0:
        return "Total";
      case 1:
        return "Prioritas";
      case 2:
        return "Pending";
      default:
        return "Laporan";
    }
  }

  // --------------------- CARD ITEM ----------------------
  Widget _statCard({
    required Color color,
    required IconData icon,
    required String title,
    required int count,
    required String subtitle,
    required VoidCallback onTap,
    required int badgeCount,
    required AdminProvider admin,
    required String cardType,
  }) {
    return GestureDetector(
      onTap: () {
        // MARK AS READ WHEN CARD IS TAPPED
        if (cardType == 'emergencies' && badgeCount > 0) {
          admin.markAllEmergenciesAsRead();
        } else if (cardType == 'reports' && badgeCount > 0) {
          admin.markAllReportsAsRead();
        }
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.black54,
                    ), // Reduced size
                  ),

                  Spacer(),

                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Reduced font size
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 3), // Reduced spacing

                  Text(
                    "$count $subtitle",
                    style: TextStyle(
                      fontSize: 11, // Reduced font size
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Badge untuk notifikasi
            if (badgeCount > 0)
              Positioned(
                top: 8, // Adjusted position
                right: 8, // Adjusted position
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
