// screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({super.key, required this.token});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadDashboardData();
    });
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

  // --------------------- HEADER ----------------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/Vector.png',
                      width: 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "WARGA KITA",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Notifikasi Button dengan Functionality
              _buildNotificationButton(),
            ],
          ),

          SizedBox(height: 24),

          Text(
            "Hai Admin! 👋",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Mari pantau perkembangan warga hari ini",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --------------------- NOTIFICATION BUTTON ----------------------
  Widget _buildNotificationButton() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        // Gunakan unreadNotifications dari AdminProvider
        final unreadCount = admin.unreadNotifications;

        return Stack(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  _showNotifications(context, admin);
                },
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context, AdminProvider admin) {
    // Gunakan notifications dari AdminProvider
    final notifications = admin.notifications;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Notifikasi",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (admin.unreadNotifications > 0)
                    TextButton(
                      onPressed: () {
                        admin.markAllNotificationsAsRead();
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Tandai semua dibaca",
                        style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              color: Colors.grey.shade400,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Tidak ada notifikasi",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _notificationItem(notification, admin);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationItem(
    Map<String, dynamic> notification,
    AdminProvider admin,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.grey.shade50 : Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification['isRead']
              ? Colors.grey.shade200
              : Color(0xFF1E88E5).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getNotificationIcon(notification['type']),
            color: notification['isRead']
                ? Colors.grey.shade400
                : Color(0xFF1E88E5),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: notification['isRead']
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification['message'],
                  style: TextStyle(
                    fontSize: 12,
                    color: notification['isRead']
                        ? Colors.grey.shade500
                        : Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification['time'],
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          if (!notification['isRead'])
            IconButton(
              onPressed: () => admin.markNotificationAsRead(notification['id']),
              icon: Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Color(0xFF1E88E5),
              ),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'report':
        return Icons.report_problem_outlined;
      case 'emergency':
        return Icons.warning_amber_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'user':
        return Icons.person_outline;
      case 'stats':
        return Icons.analytics_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  // --------------------- TAB MENU ----------------------
  Widget _buildTabMenu() {
    final List<String> tabLabels = [
      "Semua Data",
      "Prioritas",
      "Butuh Tindakan",
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabLabels.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 12),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Color(0xFF1E88E5) : Colors.grey.shade300,
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Color(0xFF1E88E5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
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
          onRefresh: () => admin.loadDashboardData(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat Cards Grid - termasuk Laporan
                _buildStatsGrid(stats),
          
                SizedBox(height: 20),
          
                // Quick Actions Section
                _buildQuickActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E88E5), strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            "Memuat data...",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            "Terjadi kesalahan",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          SizedBox(height: 16),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic stats) {
    List<Map<String, dynamic>> cardData = _getFilteredData(stats);

    if (cardData.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
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
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aksi Cepat",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
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
            SizedBox(width: 12),
            Expanded(
              child: _quickActionButton(
                icon: Icons.analytics_outlined,
                label: "Lihat\nLaporan",
                color: Color(0xFF4CAF50),
                onTap: () => Navigator.pushNamed(context, "/reports"),
              ),
            ),
            SizedBox(width: 12),
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
          title: Text("Buat Pengumuman Baru"),
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
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Isi Pengumuman",
                    border: OutlineInputBorder(),
                    hintText: "Masukkan isi pengumuman",
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 16),
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
                    Text("Tandai sebagai penting"),
                    Icon(Icons.priority_high, color: Colors.red, size: 16),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
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
              ),
              child: Text("Buat Pengumuman"),
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
          content: Text("Judul dan isi pengumuman harus diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulasi pembuatan pengumuman
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pengumuman '${title.length > 20 ? title.substring(0, 20) + '...' : title}' berhasil dibuat",
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Refresh data dashboard
    Provider.of<AdminProvider>(context, listen: false).refreshData();
  }

  // --------------------- PENGATURAN BOTTOM SHEET ----------------------
  void _showSettingsBottomSheet(BuildContext context) {
    bool _notificationsEnabled = true;
    bool _darkMode = false;
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
              padding: EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Pengaturan",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

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

                  SizedBox(height: 20),

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

                  SizedBox(height: 20),

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

                  SizedBox(height: 20),

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
                              content: Text("Membuka pengaturan keamanan..."),
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
                              content: Text("Membuka pengaturan privasi..."),
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
                              content: Text("Membuka halaman bantuan..."),
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
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E88E5),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Simpan Pengaturan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF1E88E5), size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _settingsSwitch({
    required bool value,
    required String label,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFF1E88E5),
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
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
      height: 44, // Fixed height untuk konsistensi
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade600, size: 20),
        title: Text(label, style: TextStyle(fontSize: 14)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        dense: true, // Buat lebih compact
      ),
    );
  }

  void _saveSettings(
    BuildContext context,
    bool notifications,
    bool darkMode,
    String language,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Pengaturan berhasil disimpan"),
        backgroundColor: Colors.green,
      ),
    );

    print("Settings saved:");
    print("- Notifications: $notifications");
    print("- Dark Mode: $darkMode");
    print("- Language: $language");
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
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
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 64),
          SizedBox(height: 16),
          Text(
            "Tidak ada data",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Semua data sudah ditangani dengan baik",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --------------------- FILTER DATA BERDASARKAN TAB ----------------------
  List<Map<String, dynamic>> _getFilteredData(dynamic stats) {
    final baseData = [
      {
        'color': Color(0xFFE3F2FD),
        'icon': Icons.people_alt_outlined,
        'title': "Data Warga",
        'count': stats?.totalUsers ?? 0,
        'subtitle': "Warga",
        'badgeCount': 0,
        'onTap': () => Navigator.pushNamed(context, "/users"),
      },
      {
        'color': Color(0xFFE8F5E9),
        'icon': Icons.campaign_outlined,
        'title': "Pengumuman",
        'count': stats?.totalAnnouncements ?? 0,
        'subtitle': "Postingan",
        'badgeCount': 0,
        'onTap': () => Navigator.pushNamed(context, "/announcements"),
      },
      {
        'color': Color(0xFFFFEBEE),
        'icon': Icons.warning_amber_outlined,
        'title': "Darurat",
        'count': stats?.activeEmergencies ?? 0,
        'subtitle': "Aktif",
        'badgeCount': stats?.activeEmergencies ?? 0,
        'onTap': () => Navigator.pushNamed(context, "/emergencies"),
      },
      {
        'color': Color(0xFFFFF8E1),
        'icon': Icons.assignment_outlined,
        'title': "Laporan",
        'count': _getFilteredReportCount(stats),
        'subtitle': _getReportSubtitle(),
        'badgeCount': _getReportBadgeCount(stats),
        'onTap': () => Navigator.pushNamed(context, "/reports"),
      },
    ];

    switch (_selectedTab) {
      case 0: // Semua Data
        return baseData;

      case 1: // Prioritas
        // Urutkan berdasarkan count tertinggi dan beri badge
        List<Map<String, dynamic>> sortedData = List.from(baseData);
        sortedData.sort((a, b) => b['count'].compareTo(a['count']));
        return sortedData;

      case 2: // Butuh Tindakan
        // Filter data yang membutuhkan perhatian (badgeCount > 0)
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

  int _getReportBadgeCount(dynamic stats) {
    final totalReports = stats?.totalReports ?? 0;

    switch (_selectedTab) {
      case 0:
        return 0;
      case 1:
        return (totalReports * 0.2).round();
      case 2:
        return (totalReports * 0.3).round();
      default:
        return 0;
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 28, color: Colors.black54),
                  ),

                  Spacer(),

                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    "$count $subtitle",
                    style: TextStyle(
                      fontSize: 12,
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
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
