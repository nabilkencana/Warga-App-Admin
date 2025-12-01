// screens/admin_dashboard_screen.dart - PERBAIKAN OVERFLOW + FITUR NOTIFIKASI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_management_app/screens/bill_management_screen.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({super.key, required this.token});

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
            Expanded(
              // PASTIKAN INI ADA - Ini yang memperbaiki overflow
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------- HEADER ----------------------
  Widget _buildHeader() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ), // Reduced vertical padding
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
            mainAxisSize: MainAxisSize.min, // IMPORTANT: Prevent overflow
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/Vector.png',
                          width: 28, // Reduced size
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8), // Reduced spacing
                      Text(
                        "WARGA KITA",
                        style: TextStyle(
                          fontSize: 16, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  _buildNotificationButton(),
                ],
              ),

              SizedBox(height: 16), // Reduced spacing

              Text(
                "Hai Admin!!",
                style: TextStyle(
                  fontSize: 20, // Reduced font size
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 6), // Reduced spacing

              Text(
                "Mari pantau perkembangan warga hari ini",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ), // Reduced font size
              ),

              // Tampilkan status auto-refresh di header
              SizedBox(height: 8),
              _buildAutoRefreshStatus(admin),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk menampilkan status auto-refresh
  Widget _buildAutoRefreshStatus(AdminProvider admin) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ), // Reduced padding
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                admin.isAutoRefreshEnabled ? Icons.autorenew : Icons.pause,
                size: 10, // Reduced size
                color: Colors.white70,
              ),
              SizedBox(width: 3), // Reduced spacing
              Text(
                admin.isAutoRefreshEnabled
                    ? "Auto-refresh ON"
                    : "Auto-refresh OFF",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9, // Reduced font size
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 6), // Reduced spacing
        if (admin.isAutoRefreshEnabled)
          Expanded(
            // Added Expanded to prevent text overflow
            child: Text(
              "Update: ${_formatTime(admin.lastUpdate)}",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9, // Reduced font size
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // --------------------- NOTIFICATION BUTTON ----------------------
  Widget _buildNotificationButton() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        final unreadCount = admin.unreadNotifications;

        return Stack(
          children: [
            Container(
              padding: EdgeInsets.all(8), // Reduced padding
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
                  size: 20, // Reduced size
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6, // Adjusted position
                right: 6, // Adjusted position
                child: Container(
                  padding: EdgeInsets.all(1), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ), // Reduced size
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7, // Reduced font size
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
    final notifications = admin.notifications;

    // MARK ALL NOTIFICATIONS AS READ WHEN OPENED
    admin.markAllNotificationsAsRead();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16), // Reduced padding
          height: MediaQuery.of(context).size.height * 0.7, // Reduced height
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    "Notifikasi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ), // Reduced font size
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
                          fontSize: 11, // Reduced font size
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 18), // Reduced size
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              SizedBox(height: 12), // Reduced spacing
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              color: Colors.grey.shade400,
                              size: 40, // Reduced size
                            ),
                            SizedBox(height: 8), // Reduced spacing
                            Text(
                              "Tidak ada notifikasi",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ), // Reduced font size
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
      margin: EdgeInsets.only(bottom: 8), // Reduced margin
      padding: EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.grey.shade50 : Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
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
            size: 18, // Reduced size
          ),
          SizedBox(width: 10), // Reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // Reduced font size
                    color: notification['isRead']
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
                SizedBox(height: 3), // Reduced spacing
                Text(
                  notification['message'],
                  style: TextStyle(
                    fontSize: 11, // Reduced font size
                    color: notification['isRead']
                        ? Colors.grey.shade500
                        : Colors.black54,
                  ),
                ),
                SizedBox(height: 3), // Reduced spacing
                Text(
                  notification['time'],
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade400,
                  ), // Reduced font size
                ),
              ],
            ),
          ),
          if (!notification['isRead'])
            IconButton(
              onPressed: () => admin.markNotificationAsRead(notification['id']),
              icon: Icon(
                Icons.check_circle_outline,
                size: 16, // Reduced size
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
      padding: EdgeInsets.symmetric(horizontal: 16), // Reduced padding
      height: 40, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabLabels.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 8), // Reduced spacing
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
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // Reduced padding
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
            fontSize: 12, // Reduced font size
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
            padding: EdgeInsets.all(12), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // IMPORTANT: Prevent overflow
              children: [
                // Tampilkan info last updated
                _buildLastUpdatedInfo(admin),
                SizedBox(height: 12),

                // Stat Cards Grid
                _buildStatsGrid(stats, admin),

                SizedBox(height: 16),

                // Quick Actions Section
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
